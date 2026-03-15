import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:corebrain/services/storage/vector_store.dart';
import 'package:corebrain/services/ai/rag_pipeline.dart';
import 'package:corebrain/features/chat/models/chat_message.dart';
import 'package:corebrain/features/notes/models/note.dart';
import 'package:corebrain/features/voice/models/voice_memo.dart';
import 'package:corebrain/core/constants.dart';

void main() {
  // ── AppConstants ───────────────────────────────────────────────────────────
  group('AppConstants', () {
    test('embedding dimension is 384', () {
      expect(AppConstants.embeddingDimension, 384);
    });

    test('ragTopK is positive', () {
      expect(AppConstants.ragTopK, greaterThan(0));
    });

    test('chunkSize is greater than chunkOverlap', () {
      expect(AppConstants.chunkSize, greaterThan(AppConstants.chunkOverlap));
    });
  });

  // ── Note model ─────────────────────────────────────────────────────────────
  group('Note model', () {
    test('round-trips through toMap/fromMap', () {
      final now = DateTime.now();
      final note = Note(
        id: 'note-1',
        title: 'Test Note',
        filePath: '/tmp/note-1.md',
        createdAt: now,
        updatedAt: now,
        content: 'Hello world',
        tags: ['work', 'idea'],
      );

      final map = note.toMap();
      final restored = Note.fromMap(map);

      expect(restored.id, note.id);
      expect(restored.title, note.title);
      expect(restored.filePath, note.filePath);
      expect(restored.tags, note.tags);
    });

    test('copyWith only changes specified fields', () {
      final now = DateTime.now();
      final note = Note(
        id: 'note-2',
        title: 'Original',
        filePath: '/tmp/note-2.md',
        createdAt: now,
        updatedAt: now,
        content: 'Old content',
        tags: [],
      );

      final updated = note.copyWith(title: 'Updated', content: 'New content');

      expect(updated.id, note.id);
      expect(updated.title, 'Updated');
      expect(updated.content, 'New content');
      expect(updated.filePath, note.filePath);
    });
  });

  // ── VoiceMemo model ────────────────────────────────────────────────────────
  group('VoiceMemo model', () {
    test('durationLabel formats correctly', () {
      final memo = VoiceMemo(
        id: 'memo-1',
        audioPath: '/tmp/memo.m4a',
        createdAt: DateTime.now(),
        durationSecs: 92,
      );
      expect(memo.durationLabel, '1:32');
    });

    test('hasTranscript is false when transcript is empty', () {
      final memo = VoiceMemo(
        id: 'memo-2',
        audioPath: '/tmp/memo2.m4a',
        createdAt: DateTime.now(),
        durationSecs: 30,
        transcript: '',
      );
      expect(memo.hasTranscript, isFalse);
    });

    test('hasTranscript is true when transcript is set', () {
      final memo = VoiceMemo(
        id: 'memo-3',
        audioPath: '/tmp/memo3.m4a',
        createdAt: DateTime.now(),
        durationSecs: 60,
        transcript: 'Hello world',
      );
      expect(memo.hasTranscript, isTrue);
    });

    test('round-trips through toMap/fromMap', () {
      final now = DateTime.now();
      final memo = VoiceMemo(
        id: 'memo-4',
        audioPath: '/tmp/test.m4a',
        createdAt: now,
        durationSecs: 45,
        transcript: 'Test transcript',
        summary: 'Summary',
      );

      final restored = VoiceMemo.fromMap(memo.toMap());
      expect(restored.id, memo.id);
      expect(restored.transcript, memo.transcript);
      expect(restored.summary, memo.summary);
      expect(restored.durationSecs, memo.durationSecs);
    });
  });

  // ── ChatMessage model ──────────────────────────────────────────────────────
  group('ChatMessage model', () {
    test('user factory creates correct role', () {
      final msg = ChatMessage.user(id: 'msg-1', text: 'Hello');
      expect(msg.isUser, isTrue);
      expect(msg.isAssistant, isFalse);
    });

    test('assistant factory creates correct role', () {
      final msg = ChatMessage.assistant(id: 'msg-2', text: 'Hi there');
      expect(msg.isAssistant, isTrue);
      expect(msg.isUser, isFalse);
    });

    test('loading factory sets isLoading = true', () {
      final msg = ChatMessage.loading(id: 'msg-3');
      expect(msg.isLoading, isTrue);
      expect(msg.text, isEmpty);
    });
  });

  // ── VectorStore cosine similarity ──────────────────────────────────────────
  group('VectorStore._cosineSimilarity', () {
    // Access via a public wrapper for testability.
    double cosine(Float32List a, Float32List b) =>
        VectorStore.cosineSimilarityPublic(a, b);

    test('identical vectors have similarity 1.0', () {
      final v = Float32List.fromList([1.0, 0.0, 0.0]);
      expect(cosine(v, v), closeTo(1.0, 1e-6));
    });

    test('orthogonal vectors have similarity 0.0', () {
      final a = Float32List.fromList([1.0, 0.0]);
      final b = Float32List.fromList([0.0, 1.0]);
      expect(cosine(a, b), closeTo(0.0, 1e-6));
    });

    test('opposite vectors have similarity -1.0', () {
      final a = Float32List.fromList([1.0, 0.0]);
      final b = Float32List.fromList([-1.0, 0.0]);
      expect(cosine(a, b), closeTo(-1.0, 1e-6));
    });

    test('zero vector returns 0.0', () {
      final a = Float32List.fromList([0.0, 0.0]);
      final b = Float32List.fromList([1.0, 0.0]);
      expect(cosine(a, b), equals(0.0));
    });
  });

  // ── RagPipeline JSON parsing ───────────────────────────────────────────────
  group('RagPipeline action parsing', () {
    test('parses calendar_event action from LLM response', () {
      const response = '''
Here is what I found in your notes.

```json
{"actions": [{"type": "calendar_event", "title": "Meet Sarah", "date": "2025-03-15T10:00:00"}]}
```
''';
      final actions = RagPipeline.parseActionsPublic(response);
      expect(actions.length, 1);
      expect(actions.first['type'], 'calendar_event');
      expect(actions.first['title'], 'Meet Sarah');
    });

    test('returns empty list when no JSON block present', () {
      const response = 'No actions needed for this query.';
      final actions = RagPipeline.parseActionsPublic(response);
      expect(actions, isEmpty);
    });

    test('returns empty list on malformed JSON', () {
      const response = '```json\n{bad json\n```';
      final actions = RagPipeline.parseActionsPublic(response);
      expect(actions, isEmpty);
    });

    test('strips JSON block from answer', () {
      const response = '''
Some answer text.

```json
{"actions": []}
```
''';
      final cleaned = RagPipeline.stripJsonBlockPublic(response);
      expect(cleaned, isNot(contains('```json')));
      expect(cleaned.trim(), 'Some answer text.');
    });
  });
}
