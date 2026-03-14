/// A voice memo with an optional transcript and AI-generated summary.
class VoiceMemo {
  VoiceMemo({
    required this.id,
    required this.audioPath,
    required this.createdAt,
    required this.durationSecs,
    this.transcript = '',
    this.summary = '',
  });

  factory VoiceMemo.fromMap(Map<String, dynamic> map) => VoiceMemo(
        id: map['id'] as String,
        audioPath: map['audio_path'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        durationSecs: map['duration_secs'] as int,
        transcript: map['transcript'] as String? ?? '',
        summary: map['summary'] as String? ?? '',
      );

  final String id;
  final String audioPath;
  final DateTime createdAt;
  final int durationSecs;
  final String transcript;
  final String summary;

  bool get hasTranscript => transcript.isNotEmpty;
  bool get hasSummary => summary.isNotEmpty;

  /// Formatted duration string, e.g. "1:32".
  String get durationLabel {
    final m = durationSecs ~/ 60;
    final s = durationSecs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'audio_path': audioPath,
        'created_at': createdAt.millisecondsSinceEpoch,
        'duration_secs': durationSecs,
        'transcript': transcript,
        'summary': summary,
      };

  VoiceMemo copyWith({
    String? transcript,
    String? summary,
  }) =>
      VoiceMemo(
        id: id,
        audioPath: audioPath,
        createdAt: createdAt,
        durationSecs: durationSecs,
        transcript: transcript ?? this.transcript,
        summary: summary ?? this.summary,
      );
}
