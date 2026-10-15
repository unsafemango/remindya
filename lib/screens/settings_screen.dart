import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/annoyance_level.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notifications = context.read<NotificationService?>();
    final loc = MaterialLocalizations.of(context);
    final quiet = state.quietHours;

    String fmt(int minute) =>
        loc.formatTimeOfDay(TimeOfDay(hour: minute ~/ 60, minute: minute % 60));

    Future<int?> pick(int minute) async {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      );
      return t == null ? null : t.hour * 60 + t.minute;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Annoyance level'),
          AnnoyanceLevelPicker(value: state.level, onChanged: state.setLevel),
          const _Header('Quiet hours'),
          SwitchListTile(
            title: const Text('Let the dog sleep at night'),
            subtitle: const Text(
              'Follow-up nags are skipped during quiet hours. Reminders still fire at the time you picked.',
            ),
            value: quiet.enabled,
            onChanged: (v) => state.setQuietHours(quiet.copyWith(enabled: v)),
          ),
          ListTile(
            enabled: quiet.enabled,
            leading: const Icon(Icons.bedtime_outlined),
            title: const Text('Starts'),
            trailing: Text(fmt(quiet.startMinute)),
            onTap: () async {
              final m = await pick(quiet.startMinute);
              if (m != null) {
                await state.setQuietHours(quiet.copyWith(startMinute: m));
              }
            },
          ),
          ListTile(
            enabled: quiet.enabled,
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Ends'),
            trailing: Text(fmt(quiet.endMinute)),
            onTap: () async {
              final m = await pick(quiet.endMinute);
              if (m != null) {
                await state.setQuietHours(quiet.copyWith(endMinute: m));
              }
            },
          ),
          if (notifications != null) ...[
            const _Header('Test notifications'),
            ListTile(
              leading: const Text('🐶', style: TextStyle(fontSize: 24)),
              title: const Text('Send a polite nag'),
              onTap: () => notifications.sendTestNag(0),
            ),
            ListTile(
              leading: const Text('🔥', style: TextStyle(fontSize: 24)),
              title: const Text('Send an unhinged nag'),
              onTap: () => notifications.sendTestNag(3),
            ),
          ],
          const _Header('Stats'),
          ListTile(
            leading: const Text('🏆', style: TextStyle(fontSize: 24)),
            title: Text('Best streak: ${state.streak.best} days'),
          ),
        ],
      ),
    );
  }
}

class AnnoyanceLevelPicker extends StatelessWidget {
  const AnnoyanceLevelPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AnnoyanceLevel value;
  final ValueChanged<AnnoyanceLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final level in AnnoyanceLevel.values)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: level == value ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              leading: Text(level.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(level.label),
              subtitle: Text(
                '${level.description}\n${level.nagOffsets.length} follow-up nags',
              ),
              isThreeLine: true,
              selected: level == value,
              onTap: () => onChanged(level),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
