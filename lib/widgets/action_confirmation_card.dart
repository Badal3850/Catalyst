import 'package:flutter/material.dart';

/// Shown below an assistant message when the LLM suggests a system action
/// (e.g. creating a calendar event). The user must explicitly confirm before
/// any action is taken — satisfying the "Confirmation Toast" requirement.
class ActionConfirmationCard extends StatefulWidget {
  const ActionConfirmationCard({
    super.key,
    required this.action,
    required this.onConfirm,
  });

  /// The structured action map extracted by the LLM, e.g.:
  /// `{"type": "calendar_event", "title": "Meet Sarah", "date": "2025-03-15T10:00:00"}`
  final Map<String, dynamic> action;

  /// Called when the user taps "Confirm". Should return `true` on success.
  final Future<bool> Function() onConfirm;

  @override
  State<ActionConfirmationCard> createState() => _ActionConfirmationCardState();
}

class _ActionConfirmationCardState extends State<ActionConfirmationCard> {
  _CardState _state = _CardState.pending;

  Future<void> _handleConfirm() async {
    setState(() => _state = _CardState.loading);
    final success = await widget.onConfirm();
    setState(() => _state = success ? _CardState.done : _CardState.error);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actionType = widget.action['type'] as String? ?? 'action';
    final title = widget.action['title'] as String? ?? 'Unnamed';
    final date = widget.action['date'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withAlpha(60), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _ActionIcon(actionType: actionType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForType(actionType),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (date != null)
                  Text(
                    date,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(state: _state, onConfirm: _handleConfirm),
        ],
      ),
    );
  }

  String _labelForType(String type) => switch (type) {
    'calendar_event' => 'CALENDAR EVENT',
    'reminder' => 'REMINDER',
    'file_save' => 'SAVE FILE',
    _ => type.toUpperCase(),
  };
}

// ── Action icon ───────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.actionType});

  final String actionType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (actionType) {
      'calendar_event' => Icons.calendar_today_outlined,
      'reminder' => Icons.alarm_outlined,
      'file_save' => Icons.save_outlined,
      _ => Icons.bolt_outlined,
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: colorScheme.primary),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

enum _CardState { pending, loading, done, error }

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.state, required this.onConfirm});

  final _CardState state;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (state) {
      _CardState.pending => FilledButton(
        onPressed: onConfirm,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Add'),
      ),
      _CardState.loading => SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colorScheme.primary,
        ),
      ),
      _CardState.done => Icon(
        Icons.check_circle,
        color: Colors.green.shade600,
        size: 26,
      ),
      _CardState.error => Icon(
        Icons.error_outline,
        color: colorScheme.error,
        size: 26,
      ),
    };
  }
}
