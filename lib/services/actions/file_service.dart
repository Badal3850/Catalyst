import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

/// Provides file-system operations for notes, voice recordings, and imported
/// documents. All files live inside the app's private storage so no
/// `READ_EXTERNAL_STORAGE` permission is required.
class FileService {
  static const MethodChannel _channel = MethodChannel(AppConstants.fileChannel);

  // ── Directory helpers ─────────────────────────────────────────────────────

  Future<Directory> get _appDocDir => getApplicationDocumentsDirectory();

  Future<Directory> _ensureSubDir(String name) async {
    final base = await _appDocDir;
    final dir = Directory(p.join(base.path, name));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get notesDir => _ensureSubDir(AppConstants.notesFolderName);

  Future<Directory> get voiceDir => _ensureSubDir(AppConstants.voiceFolderName);

  Future<Directory> get documentsDir =>
      _ensureSubDir(AppConstants.documentsFolderName);

  // ── Notes ─────────────────────────────────────────────────────────────────

  /// Writes [content] (Markdown) to a file named [filename] inside [notesDir].
  Future<File> saveNote(String filename, String content) async {
    final dir = await notesDir;
    final file = File(p.join(dir.path, filename));
    return file.writeAsString(content, flush: true);
  }

  /// Reads and returns the raw content of a note file at [filePath].
  Future<String> readNote(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('Note file not found', filePath);
    }
    return file.readAsString();
  }

  /// Deletes the note file at [filePath].
  Future<void> deleteNote(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) await file.delete();
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  /// Copies [sourceFile] into the app's documents directory.
  Future<File> importDocument(File sourceFile) async {
    final dir = await documentsDir;
    final dest = File(p.join(dir.path, p.basename(sourceFile.path)));
    return sourceFile.copy(dest.path);
  }

  /// Lists all files inside [documentsDir].
  Future<List<File>> listDocuments() async {
    final dir = await documentsDir;
    return dir.listSync().whereType<File>().toList();
  }

  // ── CSV / Data export ─────────────────────────────────────────────────────

  /// Appends [row] as a CSV line to [filename] under [documentsDir].
  Future<void> appendCsvRow(String filename, List<String> row) async {
    final dir = await documentsDir;
    final file = File(p.join(dir.path, filename));
    final line = '${row.map(_escapeCsv).join(',')}\n';
    await file.writeAsString(line, mode: FileMode.append, flush: true);
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ── Native share ──────────────────────────────────────────────────────────

  /// Triggers the native share sheet for [filePath].
  Future<void> shareFile(String filePath) async {
    try {
      await _channel.invokeMethod('shareFile', {'path': filePath});
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('FileService.shareFile error: ${e.message}');
    }
  }
}
