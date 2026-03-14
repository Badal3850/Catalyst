/// App-wide constants and configuration values for CoreBrain.
class AppConstants {
  AppConstants._();

  // ── Application metadata ────────────────────────────────────────────────
  static const String appName = 'CoreBrain';
  static const String appVersion = '1.0.0';

  // ── Database ─────────────────────────────────────────────────────────────
  static const String dbName = 'corebrain.db';
  static const int dbVersion = 1;

  /// SQLite page size for FTS5 performance.
  static const int dbPageSize = 4096;

  // ── AI / LLM ─────────────────────────────────────────────────────────────
  /// Default model filename stored under the app's private assets directory.
  static const String defaultModelFilename = 'llama3_2_1b_q4.bin';

  /// Expected SHA-256 hash of the bundled model weights.
  ///
  /// **SECURITY NOTE:** This placeholder MUST be replaced with the actual
  /// SHA-256 hash of the model file before any production release. Using the
  /// placeholder string will cause model-integrity verification to fail,
  /// preventing the model from loading and protecting users from tampered
  /// model weights.
  static const String defaultModelSha256 =
      'PLACEHOLDER_SHA256_VERIFY_BEFORE_RELEASE';

  /// Maximum tokens the LLM should generate in a single response.
  static const int llmMaxTokens = 512;

  /// Temperature for LLM sampling (lower = more deterministic).
  static const double llmTemperature = 0.7;

  // ── RAG pipeline ─────────────────────────────────────────────────────────
  /// Number of top-k similar chunks to retrieve for context.
  static const int ragTopK = 5;

  /// Maximum characters per text chunk when splitting documents.
  static const int chunkSize = 512;

  /// Overlap between consecutive chunks (in characters).
  static const int chunkOverlap = 64;

  // ── Vector embeddings ────────────────────────────────────────────────────
  /// Dimension of the embedding vectors produced by the local model.
  static const int embeddingDimension = 384;

  // ── Voice journaling ─────────────────────────────────────────────────────
  /// Maximum recording duration in seconds (5 minutes).
  static const int maxRecordingSeconds = 300;

  /// Whisper model filename for offline transcription.
  static const String whisperModelFilename = 'whisper_tiny_en.tflite';

  // ── File handling ────────────────────────────────────────────────────────
  /// Subdirectory inside the app documents folder where notes are stored.
  static const String notesFolderName = 'notes';

  /// Subdirectory for voice recordings.
  static const String voiceFolderName = 'voice';

  /// Subdirectory for imported documents.
  static const String documentsFolderName = 'documents';

  /// File extension for all notes.
  static const String noteExtension = '.md';

  // ── Calendar / Actions ───────────────────────────────────────────────────
  /// Flutter Method Channel name for calendar operations.
  static const String calendarChannel = 'corebrain/calendar';

  /// Flutter Method Channel name for system reminder operations.
  static const String reminderChannel = 'corebrain/reminders';

  /// Flutter Method Channel name for file operations.
  static const String fileChannel = 'corebrain/files';
}
