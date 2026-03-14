/// Represents a single message in the AI chat interface.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.sources = const [],
    this.suggestedActions = const [],
    this.isLoading = false,
  });

  factory ChatMessage.user({
    required String id,
    required String text,
  }) =>
      ChatMessage(
        id: id,
        role: MessageRole.user,
        text: text,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant({
    required String id,
    required String text,
    List<String> sources = const [],
    List<Map<String, dynamic>> suggestedActions = const [],
  }) =>
      ChatMessage(
        id: id,
        role: MessageRole.assistant,
        text: text,
        timestamp: DateTime.now(),
        sources: sources,
        suggestedActions: suggestedActions,
      );

  factory ChatMessage.loading({required String id}) => ChatMessage(
        id: id,
        role: MessageRole.assistant,
        text: '',
        timestamp: DateTime.now(),
        isLoading: true,
      );

  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  /// IDs of the source notes/documents used to generate the answer.
  final List<String> sources;

  /// Structured actions extracted by the LLM (e.g. calendar events).
  final List<Map<String, dynamic>> suggestedActions;

  /// True while the assistant is generating the response.
  final bool isLoading;

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
}

enum MessageRole { user, assistant }
