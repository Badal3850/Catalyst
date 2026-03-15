import 'dart:typed_data';
import 'dart:math' as math;

import '../../core/constants.dart';
import 'database_service.dart';

/// A chunk record stored in the vector store.
class VectorChunk {
  const VectorChunk({
    required this.id,
    required this.sourceId,
    required this.text,
    required this.vector,
    required this.score,
  });

  final String id;
  final String sourceId;
  final String text;
  final Float32List vector;

  /// Similarity score (0–1). Only meaningful after a [VectorStore.search] call.
  final double score;
}

/// Local vector store backed by SQLite.
///
/// Each embedding is stored as a raw BLOB (packed [Float32List]) alongside its
/// text chunk. Similarity search performs cosine distance in-memory over the
/// full set — acceptable for up to ~50 k chunks. Larger corpora should migrate
/// to ObjectBox or sqlite-vec for ANN (approximate nearest-neighbour) support.
class VectorStore {
  VectorStore({required this.databaseService});

  final DatabaseService databaseService;

  static const String _table = 'vector_embeddings';

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    await databaseService.db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id          TEXT  PRIMARY KEY,
        source_id   TEXT  NOT NULL,
        chunk_index INTEGER NOT NULL,
        text        TEXT  NOT NULL,
        vector      BLOB  NOT NULL,
        created_at  INTEGER NOT NULL
      )
    ''');
    await databaseService.db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vs_source ON $_table (source_id)',
    );
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Inserts or replaces a single vector chunk.
  Future<void> upsert({
    required String id,
    required String sourceId,
    required int chunkIndex,
    required String text,
    required Float32List vector,
  }) async {
    await databaseService.insert(_table, {
      'id': id,
      'source_id': sourceId,
      'chunk_index': chunkIndex,
      'text': text,
      'vector': vector.buffer.asUint8List(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Deletes all chunks associated with [sourceId].
  Future<void> deleteBySource(String sourceId) async {
    await databaseService.delete(_table, 'source_id = ?', [sourceId]);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the [topK] most semantically similar chunks for [queryVector].
  Future<List<VectorChunk>> search(
    Float32List queryVector, {
    int topK = AppConstants.ragTopK,
  }) async {
    final rows = await databaseService.rawQuery(
      'SELECT id, source_id, text, vector FROM $_table',
    );

    if (rows.isEmpty) return const [];

    // Compute cosine similarity for each stored chunk.
    final scored = <({VectorChunk chunk, double score})>[];
    for (final row in rows) {
      final blobBytes = row['vector'] as Uint8List;
      final storedVector = Float32List.view(
        blobBytes.buffer,
        blobBytes.offsetInBytes,
      );

      final score = _cosineSimilarity(queryVector, storedVector);
      scored.add((
        chunk: VectorChunk(
          id: row['id'] as String,
          sourceId: row['source_id'] as String,
          text: row['text'] as String,
          vector: storedVector,
          score: score,
        ),
        score: score,
      ));
    }

    // Sort descending by similarity and return top-k.
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).map((e) => e.chunk).toList();
  }

  // ── Maths ─────────────────────────────────────────────────────────────────

  /// Public wrapper for use in tests.
  // ignore: invalid_use_of_visible_for_testing_member
  static double cosineSimilarityPublic(Float32List a, Float32List b) =>
      _cosineSimilarity(a, b);

  /// Cosine similarity between two vectors (range −1 to 1).
  static double _cosineSimilarity(Float32List a, Float32List b) {
    assert(a.length == b.length, 'Vector dimension mismatch.');
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    return denom == 0 ? 0 : dot / denom;
  }
}
