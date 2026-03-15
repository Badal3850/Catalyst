/// Represents a note in CoreBrain's memory.
class Note {
  Note({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    this.content = '',
    this.tags = const [],
  });

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'] as String,
    title: map['title'] as String,
    filePath: map['file_path'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    tags: (map['tags'] as String? ?? '')
        .split(',')
        .where((t) => t.isNotEmpty)
        .toList(),
  );

  final String id;
  final String title;
  final String filePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// In-memory content (loaded on demand from the file system).
  final String content;

  final List<String> tags;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'file_path': filePath,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
    'tags': tags.join(','),
    'content': content,
  };

  Note copyWith({
    String? title,
    String? content,
    List<String>? tags,
    DateTime? updatedAt,
  }) => Note(
    id: id,
    title: title ?? this.title,
    filePath: filePath,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    content: content ?? this.content,
    tags: tags ?? this.tags,
  );
}
