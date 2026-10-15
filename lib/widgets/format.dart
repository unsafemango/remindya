import 'package:flutter/material.dart';

import '../logic/snooze.dart';
import '../logic/streak.dart';

String formatDue(BuildContext context, DateTime due, DateTime now) {
  final loc = MaterialLocalizations.of(context);
  final time = loc.formatTimeOfDay(
    TimeOfDay.fromDateTime(due),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  if (due.isBefore(now)) {
    final late = now.difference(due);
    if (late.inDays >= 1) {
      return 'Overdue by ${late.inDays} day${late.inDays == 1 ? '' : 's'}';
    }
    final minutes = late.inMinutes < 1 ? 1 : late.inMinutes;
    return 'Overdue by ${formatDuration(Duration(minutes: minutes))}';
  }
  final days = DateTime.utc(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  return switch (days) {
    0 => 'Today, $time',
    1 => 'Tomorrow, $time',
    _ => '${loc.formatShortDate(dateOnly(due))}, $time',
  };
}
