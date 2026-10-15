import 'package:flutter_test/flutter_test.dart';
import 'package:remindya/logic/dog_mood.dart';
import 'package:remindya/logic/quiet_hours.dart';
import 'package:remindya/logic/streak.dart';
import 'package:remindya/models/annoyance_level.dart';
import 'package:remindya/models/bark_mode.dart';
import 'package:remindya/models/reminder.dart';
import 'package:remindya/services/reminder_scheduler.dart';
import 'package:remindya/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingScheduler implements ReminderScheduler {
  final scheduled = <String>[];
  BarkMode? lastBark;
  final cancelled = <String>[];

  @override
  Future<void> schedule(
    Reminder reminder,
    AnnoyanceLevel level,
    QuietHours quiet,
    BarkMode bark,
  ) async {
    scheduled.add(reminder.id);
    lastBark = bark;
  }

  @override
  Future<void> cancel(Reminder reminder) async => cancelled.add(reminder.id);
}

void main() {
  late DateTime now;
  late RecordingScheduler scheduler;

  Future<AppState> makeState() async {
    final s = AppState(
      prefs: await SharedPreferences.getInstance(),
      scheduler: scheduler,
      clock: () => now,
    );
    await s.load();
    return s;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 15, 9);
    scheduler = RecordingScheduler();
  });

  test('adding schedules notifications and the dog is happy', () async {
    final s = await makeState();
    final r = await s.addReminder(
      title: '  Water plants ',
      dueAt: now.add(const Duration(hours: 1)),
    );
    expect(r.title, 'Water plants');
    expect(scheduler.scheduled, [r.id]);
    expect(s.upcoming, hasLength(1));
    expect(s.mood, DogMood.happy);
  });

  test('overdue reminders upset the dog', () async {
    final s = await makeState();
    await s.addReminder(title: 'A', dueAt: now.add(const Duration(minutes: 5)));
    now = now.add(const Duration(minutes: 10));
    expect(s.overdue, hasLength(1));
    expect(s.mood, DogMood.sad);
  });

  test('completing on time earns bones and starts a streak', () async {
    final s = await makeState();
    final r = await s.addReminder(
      title: 'A',
      dueAt: now.add(const Duration(minutes: 5)),
    );
    final result = await s.completeReminder(r.id);
    expect(
      result!.bonesEarned,
      AppState.bonesPerCompletion + AppState.onTimeBonus,
    );
    expect(s.bones, result.bonesEarned);
    expect(s.streak.current, 1);
    expect(s.doneToday, hasLength(1));
    expect(s.mood, DogMood.ecstatic);
    expect(scheduler.cancelled, [r.id]);
    expect(await s.completeReminder(r.id), isNull);
  });

  test('snoozing pushes the reminder out and costs bones later', () async {
    final s = await makeState();
    final r = await s.addReminder(
      title: 'A',
      dueAt: now.add(const Duration(minutes: 1)),
    );
    final first = await s.snoozeReminder(r.id);
    expect(first!.duration, const Duration(hours: 1));
    final second = await s.snoozeReminder(r.id);
    expect(second!.duration, const Duration(minutes: 30));
    expect(s.byId(r.id)!.snoozeCount, 2);
    expect(s.byId(r.id)!.nextAlertAt, now.add(const Duration(minutes: 30)));
    expect(s.byId(r.id)!.dueAt, r.dueAt);

    now = now.add(const Duration(hours: 2)); // late now
    final done = await s.completeReminder(r.id);
    expect(done!.bonesEarned, AppState.bonesPerCompletion - 4);
  });

  test('repeating reminders roll forward instead of finishing', () async {
    final s = await makeState();
    final r = await s.addReminder(
      title: 'Meds',
      dueAt: DateTime(2026, 10, 15, 9, 30),
      repeat: RepeatRule.daily,
    );
    await s.snoozeReminder(r.id);
    await s.completeReminder(r.id);
    final after = s.byId(r.id)!;
    expect(after.isDone, isFalse);
    expect(after.dueAt, DateTime(2026, 10, 16, 9, 30));
    expect(after.snoozeCount, 0);
  });

  test('state persists, and stale streaks are reconciled on load', () async {
    final s = await makeState();
    final r = await s.addReminder(
      title: 'A',
      dueAt: now.add(const Duration(minutes: 5)),
    );
    await s.completeReminder(r.id);
    await s.setLevel(AnnoyanceLevel.feralChihuahua);
    await s.markOnboarded();

    now = now.add(const Duration(days: 3));
    final reloaded = await makeState();
    expect(reloaded.level, AnnoyanceLevel.feralChihuahua);
    expect(reloaded.onboarded, isTrue);
    expect(reloaded.bones, s.bones);
    // The finished one-off reminder from days ago is cleaned up.
    expect(reloaded.reminders, isEmpty);
    expect(reloaded.streak.current, 0);
    expect(reloaded.pendingBanner, streakLostMessageMatcher);
  });

  test('changing the level reschedules pending reminders', () async {
    final s = await makeState();
    await s.addReminder(title: 'A', dueAt: now.add(const Duration(hours: 1)));
    await s.addReminder(title: 'B', dueAt: now.add(const Duration(hours: 2)));
    scheduler.scheduled.clear();
    await s.setLevel(AnnoyanceLevel.chillPup);
    expect(scheduler.scheduled, hasLength(2));
  });

  test('bark mode persists and reschedules with the new sound', () async {
    final s = await makeState();
    expect(s.barkMode, BarkMode.angryNags);
    await s.addReminder(title: 'A', dueAt: now.add(const Duration(hours: 1)));
    await s.setBarkMode(BarkMode.always);
    expect(scheduler.lastBark, BarkMode.always);
    final reloaded = await makeState();
    expect(reloaded.barkMode, BarkMode.always);
  });

  test('mood icon setting persists', () async {
    final s = await makeState();
    expect(s.moodIcon, isTrue);
    await s.setMoodIcon(false);
    expect((await makeState()).moodIcon, isFalse);
  });

  test('dateOnly strips time', () {
    expect(dateOnly(DateTime(2026, 1, 2, 3, 4)), DateTime(2026, 1, 2));
  });
}

final streakLostMessageMatcher = contains('1-day streak');
