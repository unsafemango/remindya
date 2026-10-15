import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../state/app_state.dart';
import '../widgets/format.dart';

class EditReminderScreen extends StatefulWidget {
  const EditReminderScreen({super.key, this.existing});

  final Reminder? existing;

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title,
  );
  late DateTime _due;
  late RepeatRule _repeat = widget.existing?.repeat ?? RepeatRule.none;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = context.read<AppState>().now;
    // Default: the next round quarter hour, at least 15 minutes out.
    final soon = now.add(const Duration(minutes: 15));
    _due =
        widget.existing?.dueAt ??
        DateTime(
          soon.year,
          soon.month,
          soon.day,
          soon.hour,
          (soon.minute ~/ 15 + 1) * 15,
        );
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = context.read<AppState>().now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _due.isBefore(now) ? now : _due,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(
        () => _due = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _due.hour,
          _due.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (picked != null) {
      setState(
        () => _due = DateTime(
          _due.year,
          _due.month,
          _due.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Woof? What should I remind you about?');
      return;
    }
    if (!_due.isAfter(state.now)) {
      setState(
        () => _error =
            'That time already happened. I can’t time travel. I’m a dog.',
      );
      return;
    }
    final existing = widget.existing;
    if (existing == null) {
      await state.addReminder(title: title, dueAt: _due, repeat: _repeat);
    } else {
      await state.updateReminder(
        existing.copyWith(
          title: title,
          dueAt: _due,
          repeat: _repeat,
          snoozeCount: 0,
          clearSnoozedUntil: true,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final now = context.watch<AppState>().now;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New reminder' : 'Edit reminder'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Remind me to…',
              hintText: 'Call mom',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(loc.formatFullDate(_due)),
            onTap: _pickDate,
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(loc.formatTimeOfDay(TimeOfDay.fromDateTime(_due))),
            subtitle: Text(formatDue(context, _due, now)),
            onTap: _pickTime,
          ),
          const SizedBox(height: 16),
          SegmentedButton<RepeatRule>(
            segments: [
              for (final r in RepeatRule.values)
                ButtonSegment(
                  value: r,
                  label: Text(r == RepeatRule.none ? 'Once' : r.label),
                ),
            ],
            selected: {_repeat},
            onSelectionChanged: (s) => setState(() => _repeat = s.first),
          ),
        ],
      ),
    );
  }
}
