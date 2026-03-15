import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../../../services/ai/rag_pipeline.dart';
import '../../../services/actions/calendar_service.dart';

/// Manages the state for the AI chat interface.
///
/// Responsibilities:
/// - Holds the conversation history.
/// - Delegates queries to [RagPipeline].
/// - Parses LLM-extracted actions and shows confirmation prompts.
/// - Delegates confirmed calendar/reminder actions to [CalendarService].
class ChatProvider extends ChangeNotifier {
  ChatProvider({required this.ragPipeline, required this.calendarService});

  final RagPipeline ragPipeline;
  final CalendarService calendarService;

  final _uuid = const Uuid();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String? get error => _error;

  // ── Query ─────────────────────────────────────────────────────────────────

  /// Sends [text] as a user message and triggers the RAG pipeline.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Append the user message immediately.
    final userMsg = ChatMessage.user(id: _uuid.v4(), text: text.trim());
    _messages.add(userMsg);

    // Show typing indicator.
    final loadingId = _uuid.v4();
    _messages.add(ChatMessage.loading(id: loadingId));
    _isTyping = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ragPipeline.query(text.trim());

      // Replace loading message with the real answer.
      final idx = _messages.indexWhere((m) => m.id == loadingId);
      if (idx != -1) {
        _messages[idx] = ChatMessage.assistant(
          id: loadingId,
          text: result.answer,
          sources: result.sources.map((s) => s.sourceId).toList(),
          suggestedActions: result.suggestedActions,
        );
      }
    } catch (e) {
      final idx = _messages.indexWhere((m) => m.id == loadingId);
      if (idx != -1) {
        _messages[idx] = ChatMessage.assistant(
          id: loadingId,
          text: 'Sorry, I encountered an error. Please try again.',
        );
      }
      _error = e.toString();
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // ── Action confirmation ───────────────────────────────────────────────────

  /// Executes a suggested action after the user confirms.
  ///
  /// Returns `true` if the action was completed successfully.
  Future<bool> executeAction(Map<String, dynamic> action) async {
    final type = action['type'] as String?;

    switch (type) {
      case 'calendar_event':
        final title = action['title'] as String? ?? 'Untitled Event';
        final dateStr = action['date'] as String?;
        final description = action['description'] as String?;

        DateTime startTime;
        try {
          startTime = dateStr != null
              ? DateTime.parse(dateStr)
              : DateTime.now().add(const Duration(days: 1));
        } catch (_) {
          startTime = DateTime.now().add(const Duration(days: 1));
        }

        final hasPermission =
            await calendarService.hasCalendarPermission() ||
            await calendarService.requestCalendarPermission();
        if (!hasPermission) return false;

        final eventId = await calendarService.createEvent(
          CalendarEventRequest(
            title: title,
            startTime: startTime,
            description: description,
          ),
        );
        return eventId != null;

      case 'reminder':
        final title = action['title'] as String? ?? 'Reminder';
        final dateStr = action['date'] as String?;
        final body = action['body'] as String?;

        DateTime triggerTime;
        try {
          triggerTime = dateStr != null
              ? DateTime.parse(dateStr)
              : DateTime.now().add(const Duration(hours: 1));
        } catch (_) {
          triggerTime = DateTime.now().add(const Duration(hours: 1));
        }

        return calendarService.scheduleReminder(
          ReminderRequest(title: title, triggerTime: triggerTime, body: body),
        );

      default:
        return false;
    }
  }

  // ── Conversation management ───────────────────────────────────────────────

  void clearConversation() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
