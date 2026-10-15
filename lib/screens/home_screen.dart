import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../state/app_state.dart';
import '../widgets/dog_mascot.dart';
import '../widgets/feedback.dart';
import '../widgets/reminder_tile.dart';
import 'edit_reminder_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Rebuild periodically so reminders flip to overdue (and the dog gets sad)
  // while the app is open.
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _openEditor([Reminder? r]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditReminderScreen(existing: r),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = state.now;
    final overdue = state.overdue;
    final upcoming = state.upcoming;
    final done = state.doneToday;

    Widget tile(Reminder r) => ReminderTile(
      reminder: r,
      now: now,
      onComplete: () async =>
          showCompletion(await state.completeReminder(r.id)),
      onSnooze: () async => showSnooze(await state.snoozeReminder(r.id)),
      onTap: () => _openEditor(r),
      onDelete: () => state.deleteReminder(r.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remindya'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add),
        label: const Text('New reminder'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (state.pendingBanner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: const Text('🐶', style: TextStyle(fontSize: 28)),
                  title: Text(state.pendingBanner!),
                  trailing: IconButton(
                    tooltip: 'Dismiss',
                    icon: const Icon(Icons.close),
                    onPressed: state.clearBanner,
                  ),
                ),
              ),
            ),
          const _DogHeader(),
          if (overdue.isNotEmpty) ...[
            const _SectionHeader('Overdue 😠'),
            ...overdue.map(tile),
          ],
          if (upcoming.isNotEmpty) ...[
            const _SectionHeader('Coming up'),
            ...upcoming.map(tile),
          ],
          if (done.isNotEmpty) ...[
            const _SectionHeader('Done today ✅'),
            ...done.map(tile),
          ],
          if (overdue.isEmpty && upcoming.isEmpty && done.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No reminders yet. Tap “New reminder” and I’ll make sure you never forget. Ever. 🐾',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _DogHeader extends StatelessWidget {
  const _DogHeader();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final mood = state.mood;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: mood.isUpset
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mood.line,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          DogMascot(mood: mood),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Stat('🔥', '${state.streak.current}', 'day streak'),
              _Stat('🦴', '${state.bones}', 'bones'),
              _Stat('🍖', '${state.streak.treats}', 'treats'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.emoji, this.value, this.label);
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Text(emoji), label: Text('$value $label'));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
