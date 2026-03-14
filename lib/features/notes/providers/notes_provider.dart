import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../../../core/constants.dart';
import '../../../services/ai/embedding_service.dart';
import '../../../services/storage/database_service.dart';
import '../../../services/storage/vector_store.dart';
import '../../../services/actions/file_service.dart';

/// Manages all note CRUD operations, full-text search, and semantic indexing.
class NotesProvider extends ChangeNotifier {
  NotesProvider({
    required this.databaseService,
    required this.embeddingService,
    required this.vectorStore,
    required this.fileService,
  });

  final DatabaseService databaseService;
  final EmbeddingService embeddingService;
  final VectorStore vectorStore;
  final FileService fileService;

  final _uuid = const Uuid();

  final List<Note> _notes = [];
  List<Note> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => List.unmodifiable(_notes);
  List<Note> get searchResults => List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rows = await databaseService.query(
        'notes',
        orderBy: 'updated_at DESC',
      );
      _notes
        ..clear()
        ..addAll(rows.map(Note.fromMap));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Creates a new note with [title] and [content], persists it, and indexes it.
  Future<Note> createNote({
    required String title,
    String content = '',
    List<String> tags = const [],
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final filename = '$id${AppConstants.noteExtension}';

    final file = await fileService.saveNote(filename, content);

    final note = Note(
      id: id,
      title: title,
      filePath: file.path,
      createdAt: now,
      updatedAt: now,
      content: content,
      tags: tags,
    );

    await databaseService.insert('notes', note.toMap());
    await _indexNote(note);

    _notes.insert(0, note);
    notifyListeners();
    return note;
  }

  /// Updates an existing note's title, content, and tags.
  Future<void> updateNote(
    String id, {
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    final note = _notes[idx];
    final updated = note.copyWith(
      title: title,
      content: content,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    // Persist content to file system.
    if (content != null) {
      await fileService.saveNote(p.basename(note.filePath), content);
    }

    await databaseService.update(
      'notes',
      updated.toMap(),
      'id = ?',
      [id],
    );

    // Re-index the updated note.
    await vectorStore.deleteBySource(id);
    await _indexNote(updated);

    _notes[idx] = updated;
    notifyListeners();
  }

  /// Deletes the note with [id] and all associated embeddings.
  Future<void> deleteNote(String id) async {
    final note = _notes.firstWhere((n) => n.id == id,
        orElse: () => throw StateError('Note $id not found'));

    await fileService.deleteNote(note.filePath);
    await databaseService.delete('notes', 'id = ?', [id]);
    await vectorStore.deleteBySource(id);

    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /// Performs a full-text search using SQLite FTS5.
  Future<void> searchFts(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      final rows = await databaseService.rawQuery(
        '''
        SELECT n.* FROM notes n
        JOIN notes_fts f ON n.rowid = f.rowid
        WHERE notes_fts MATCH ?
        ORDER BY rank
        ''',
        [query.trim()],
      );
      _searchResults = rows.map(Note.fromMap).toList();
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    }
    notifyListeners();
  }

  // ── Indexing ──────────────────────────────────────────────────────────────

  Future<void> _indexNote(Note note) async {
    // Split note content into overlapping chunks.
    final chunks = _chunkText(note.content);

    for (var i = 0; i < chunks.length; i++) {
      final chunkId = '${note.id}_chunk_$i';
      final embedding = await embeddingService.embed(chunks[i]);

      await vectorStore.upsert(
        id: chunkId,
        sourceId: note.id,
        chunkIndex: i,
        text: chunks[i],
        vector: embedding,
      );
    }
  }

  static List<String> _chunkText(String text) {
    if (text.isEmpty) return const [];
    final chunks = <String>[];
    var start = 0;
    while (start < text.length) {
      final end = (start + AppConstants.chunkSize).clamp(0, text.length);
      chunks.add(text.substring(start, end));
      start += AppConstants.chunkSize - AppConstants.chunkOverlap;
    }
    return chunks;
  }
}
