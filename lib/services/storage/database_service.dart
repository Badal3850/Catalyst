import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

/// Manages the local SQLite database used for notes metadata, FTS search,
/// voice memo records, and supporting tables.
class DatabaseService {
  DatabaseService();

  Database? _db;

  Database get db {
    assert(
      _db != null,
      'DatabaseService has not been initialised. Call init().',
    );
    return _db!;
  }

  bool get isInitialised => _db != null;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Opens (or creates) the database and runs all migrations.
  Future<void> init() async {
    if (_db != null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, AppConstants.dbName);

    _db = await openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  // ── Schema ────────────────────────────────────────────────────────────────

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA journal_mode=WAL');
    await db.execute('PRAGMA foreign_keys=ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Notes table — stores metadata; raw content is on the filesystem.
    await db.execute('''
      CREATE TABLE notes (
        id          TEXT    PRIMARY KEY,
        title       TEXT    NOT NULL,
        file_path   TEXT    NOT NULL,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        tags        TEXT    DEFAULT '',
        content     TEXT    NOT NULL DEFAULT ''
      )
    ''');

    // FTS5 virtual table for full-text search over note content.
    // Uses external-content mode so the raw text is stored in `notes.content`
    // and the FTS index stays in sync via the triggers below.
    await db.execute('''
      CREATE VIRTUAL TABLE notes_fts USING fts5(
        title,
        content,
        content='notes',
        content_rowid='rowid'
      )
    ''');

    // Triggers to keep notes_fts in sync with the notes table.
    await db.execute('''
      CREATE TRIGGER notes_ai AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(rowid, title, content)
          VALUES (new.rowid, new.title, new.content);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER notes_ad AFTER DELETE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, title, content)
          VALUES ('delete', old.rowid, old.title, old.content);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER notes_au AFTER UPDATE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, title, content)
          VALUES ('delete', old.rowid, old.title, old.content);
        INSERT INTO notes_fts(rowid, title, content)
          VALUES (new.rowid, new.title, new.content);
      END
    ''');

    // Voice memos table.
    await db.execute('''
      CREATE TABLE voice_memos (
        id              TEXT    PRIMARY KEY,
        audio_path      TEXT    NOT NULL,
        transcript      TEXT    DEFAULT '',
        summary         TEXT    DEFAULT '',
        duration_secs   INTEGER NOT NULL DEFAULT 0,
        created_at      INTEGER NOT NULL
      )
    ''');

    // Embedded chunks table — pairs a text chunk with its source document.
    await db.execute('''
      CREATE TABLE embedded_chunks (
        id          TEXT    PRIMARY KEY,
        source_id   TEXT    NOT NULL,
        source_type TEXT    NOT NULL,
        chunk_index INTEGER NOT NULL,
        text        TEXT    NOT NULL,
        created_at  INTEGER NOT NULL
      )
    ''');

    // Agentic action log — records every system action taken by the AI.
    await db.execute('''
      CREATE TABLE action_log (
        id          TEXT    PRIMARY KEY,
        action_type TEXT    NOT NULL,
        payload     TEXT    NOT NULL,
        status      TEXT    NOT NULL DEFAULT 'pending',
        created_at  INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will be applied here per version increment.
  }

  // ── Generic helpers ───────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) =>
      db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<int> update(
    String table,
    Map<String, dynamic> values,
    String where,
    List<Object?> whereArgs,
  ) => db.update(table, values, where: where, whereArgs: whereArgs);

  Future<int> delete(String table, String where, List<Object?> whereArgs) =>
      db.delete(table, where: where, whereArgs: whereArgs);

  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) => db.query(
    table,
    columns: columns,
    where: where,
    whereArgs: whereArgs,
    orderBy: orderBy,
    limit: limit,
  );

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) => db.rawQuery(sql, arguments);

  Future<void> close() async => _db?.close();
}
