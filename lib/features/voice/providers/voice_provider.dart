import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/voice_memo.dart';
import '../../../services/ai/llm_service.dart';
import '../../../services/storage/database_service.dart';

/// Recording state machine.
enum RecordingState { idle, recording, processing }

/// Manages voice memo recording, transcription, and AI summarisation.
class VoiceProvider extends ChangeNotifier {
  VoiceProvider({
    required this.databaseService,
    required this.llmService,
  });

  final DatabaseService databaseService;
  final LlmService llmService;

  final _uuid = const Uuid();

  final List<VoiceMemo> _memos = [];
  RecordingState _recordingState = RecordingState.idle;
  VoiceMemo? _currentMemo;
  String? _error;

  List<VoiceMemo> get memos => List.unmodifiable(_memos);
  RecordingState get recordingState => _recordingState;
  VoiceMemo? get currentMemo => _currentMemo;
  String? get error => _error;

  bool get isRecording => _recordingState == RecordingState.recording;
  bool get isProcessing => _recordingState == RecordingState.processing;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> loadMemos() async {
    try {
      final rows = await databaseService.query(
        'voice_memos',
        orderBy: 'created_at DESC',
      );
      _memos
        ..clear()
        ..addAll(rows.map(VoiceMemo.fromMap));
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  /// Starts a new recording session.
  ///
  /// In production this calls the `record` package. The [audioPath] parameter
  /// is provided by the caller after the recording plugin creates the file.
  Future<void> startRecording(String audioPath) async {
    if (_recordingState != RecordingState.idle) return;

    _recordingState = RecordingState.recording;
    _error = null;

    // Persist a placeholder memo so the ID is stable.
    final id = _uuid.v4();
    _currentMemo = VoiceMemo(
      id: id,
      audioPath: audioPath,
      createdAt: DateTime.now(),
      durationSecs: 0,
    );

    await databaseService.insert('voice_memos', _currentMemo!.toMap());
    _memos.insert(0, _currentMemo!);
    notifyListeners();
  }

  /// Stops the current recording, triggers transcription and summarisation.
  Future<void> stopRecording({required int durationSecs}) async {
    if (_recordingState != RecordingState.recording) return;
    if (_currentMemo == null) return;

    _recordingState = RecordingState.processing;
    notifyListeners();

    try {
      // Update the duration.
      final memo = _currentMemo!;

      // TODO(phase4): Replace stub with real Whisper.tflite transcription.
      final transcript = await _transcribe(memo.audioPath);
      final summary = await llmService.summarise(transcript);

      final updated = memo.copyWith(transcript: transcript, summary: summary);
      _currentMemo = updated;

      await databaseService.update(
        'voice_memos',
        {
          'transcript': transcript,
          'summary': summary,
          'duration_secs': durationSecs,
        },
        'id = ?',
        [memo.id],
      );

      final idx = _memos.indexWhere((m) => m.id == memo.id);
      if (idx != -1) _memos[idx] = updated;
    } catch (e) {
      _error = e.toString();
    } finally {
      _recordingState = RecordingState.idle;
      notifyListeners();
    }
  }

  /// Deletes the voice memo with [id].
  Future<void> deleteMemo(String id) async {
    await databaseService.delete('voice_memos', 'id = ?', [id]);
    _memos.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ── Transcription stub ───────────────────────────────────────────────────

  /// Placeholder transcription — will be replaced by Whisper.tflite in Phase 4.
  Future<String> _transcribe(String audioPath) async {
    return '[Transcription not yet available — Whisper model not loaded. '
        'Record path: $audioPath]';
  }
}
