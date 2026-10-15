import 'package:flutter/material.dart';

import '../logic/dog_voice.dart';
import '../logic/snooze.dart';
import '../logic/streak.dart';
import '../state/app_state.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void _show(String text) {
  scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

void showCompletion(CompletionResult? r) {
  if (r == null) return;
  final streak = switch (r.streakEvent.event) {
    StreakEventType.treatEarned =>
      ' 🔥 ${r.streakEvent.amount}-day streak! You earned a Treat 🍖',
    StreakEventType.extended => ' 🔥 ${r.streakEvent.amount}-day streak!',
    _ => '',
  };
  _show('${r.message} +${r.bonesEarned} 🦴$streak');
}

void showSnooze(SnoozeResult? r) {
  if (r == null) return;
  _show('${r.message} (back in ${formatDuration(r.duration)})');
}

/// Handles taps on notification action buttons.
Future<void> handleNotificationAction(
  AppState state,
  String reminderId,
  String? actionId,
) async {
  switch (actionId) {
    case 'done':
      showCompletion(await state.completeReminder(reminderId));
    case 'snooze':
      showSnooze(await state.snoozeReminder(reminderId));
    default:
      final r = state.byId(reminderId);
      if (r != null && !r.isDone) _show(nagMessage(r.title, 1));
  }
}
