import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/voice_memo.dart';
import '../providers/voice_provider.dart';

/// Voice journaling screen — record, transcribe, and review voice memos.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<VoiceProvider>().loadMemos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Journal')),
      body: Consumer<VoiceProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _RecordingControls(provider: provider),
              const Divider(height: 1),
              Expanded(
                child:
                    provider.memos.isEmpty
                        ? const _EmptyState()
                        : _MemoList(memos: provider.memos),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Recording controls ────────────────────────────────────────────────────────

class _RecordingControls extends StatelessWidget {
  const _RecordingControls({required this.provider});

  final VoiceProvider provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget button;
    if (provider.isRecording) {
      button = FloatingActionButton.large(
        heroTag: 'stop_recording',
        backgroundColor: colorScheme.error,
        onPressed: () => provider.stopRecording(durationSecs: 0),
        child: const Icon(Icons.stop, size: 36),
      );
    } else if (provider.isProcessing) {
      button = FloatingActionButton.large(
        heroTag: 'processing',
        backgroundColor: colorScheme.secondaryContainer,
        onPressed: null,
        child: const CircularProgressIndicator(),
      );
    } else {
      button = FloatingActionButton.large(
        heroTag: 'start_recording',
        backgroundColor: colorScheme.primary,
        onPressed: () {
          // In production the `record` plugin creates the file path.
          final path =
              '/tmp/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          provider.startRecording(path);
        },
        child: const Icon(Icons.mic, size: 36),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          button,
          const SizedBox(height: 12),
          Text(
            provider.isRecording
                ? 'Recording… tap to stop'
                : provider.isProcessing
                ? 'Transcribing…'
                : 'Tap to record',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Memo list ─────────────────────────────────────────────────────────────────

class _MemoList extends StatelessWidget {
  const _MemoList({required this.memos});

  final List<VoiceMemo> memos;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: memos.length,
      itemBuilder: (context, index) => _MemoCard(memo: memos[index]),
    );
  }
}

class _MemoCard extends StatelessWidget {
  const _MemoCard({required this.memo});

  final VoiceMemo memo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  _formatDate(memo.createdAt),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(180),
                  ),
                ),
                const Spacer(),
                Text(
                  memo.durationLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(180),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed:
                      () => context.read<VoiceProvider>().deleteMemo(memo.id),
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (memo.hasSummary) ...[
              const SizedBox(height: 8),
              Text(
                memo.summary,
                style: theme.textTheme.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (memo.hasTranscript) ...[
              const SizedBox(height: 8),
              Text(
                memo.transcript,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(180),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Processing…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(120),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none,
              size: 64,
              color: colorScheme.primary.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              'No voice memos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the mic to record your first memo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
