import 'package:flutter/material.dart';

import '../models/reminder.dart';
import 'format.dart';

class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    required this.now,
    required this.onComplete,
    required this.onSnooze,
    required this.onTap,
    required this.onDelete,
  });

  final Reminder reminder;
  final DateTime now;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = reminder.isOverdue(now);
    final done = reminder.isDone;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: scheme.errorContainer,
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: overdue ? scheme.errorContainer.withValues(alpha: 0.6) : null,
        child: ListTile(
          onTap: done ? null : onTap,
          leading: IconButton(
            tooltip: done ? 'Done' : 'Mark done',
            icon: Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? Colors.green : scheme.primary,
              size: 30,
            ),
            onPressed: done ? null : onComplete,
          ),
          title: Text(
            reminder.title,
            style: done
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(
            done
                ? 'Done ✅'
                : [
                    formatDue(context, reminder.nextAlertAt, now),
                    if (reminder.repeat != RepeatRule.none)
                      reminder.repeat.label,
                  ].join(' · '),
          ),
          trailing: done
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (reminder.snoozeCount > 0)
                      Tooltip(
                        message: 'Snoozed ${reminder.snoozeCount} times',
                        child: Text(
                          '😴×${reminder.snoozeCount}${reminder.snoozeCount >= 5 ? ' 💀' : ''}',
                        ),
                      ),
                    IconButton(
                      tooltip: 'Snooze',
                      icon: const Icon(Icons.snooze),
                      onPressed: onSnooze,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
