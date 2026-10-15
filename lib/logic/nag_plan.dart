import 'dart:math';

import '../models/annoyance_level.dart';
import '../models/reminder.dart';
import 'dog_voice.dart';
import 'quiet_hours.dart';

class PlannedNag {
  const PlannedNag({
    required this.notificationId,
    required this.at,
    required this.stage,
    required this.body,
  });

  final int notificationId;
  final DateTime at;
  final int stage;
  final String body;
}

/// The full notification chain for one reminder: the reminder itself at its
/// due time, then escalating follow-ups. Follow-ups that land in quiet hours
/// or in the past are dropped. The first notification always fires at the
/// time the user picked, even during quiet hours.
List<PlannedNag> buildNagPlan(
  Reminder reminder,
  AnnoyanceLevel level,
  QuietHours quiet,
  DateTime now, [
  Random? rng,
]) {
  if (reminder.isDone) return const [];
  final offsets = level.nagOffsets;
  final plan = <PlannedNag>[];
  final start = reminder.nextAlertAt;
  for (var i = 0; i <= offsets.length; i++) {
    final at = i == 0 ? start : start.add(offsets[i - 1]);
    if (!at.isAfter(now)) continue;
    if (i > 0 && quiet.contains(at)) continue;
    final stage = stageForNag(i, offsets.length);
    plan.add(
      PlannedNag(
        notificationId: reminder.notificationBaseId + i,
        at: at,
        stage: stage,
        body: nagMessage(reminder.title, stage, rng),
      ),
    );
  }
  return plan;
}
