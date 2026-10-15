import '../models/annoyance_level.dart';
import '../models/reminder.dart';
import '../logic/quiet_hours.dart';

/// Schedules the OS-level notifications for a reminder. Abstracted so the app
/// state can be tested without a platform.
abstract class ReminderScheduler {
  Future<void> schedule(
    Reminder reminder,
    AnnoyanceLevel level,
    QuietHours quiet,
  );

  Future<void> cancel(Reminder reminder);
}

class NoopScheduler implements ReminderScheduler {
  @override
  Future<void> schedule(
    Reminder reminder,
    AnnoyanceLevel level,
    QuietHours quiet,
  ) async {}

  @override
  Future<void> cancel(Reminder reminder) async {}
}
