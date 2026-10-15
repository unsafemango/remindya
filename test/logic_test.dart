import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:remindya/logic/dog_mood.dart';
import 'package:remindya/logic/dog_voice.dart';
import 'package:remindya/logic/nag_plan.dart';
import 'package:remindya/logic/quiet_hours.dart';
import 'package:remindya/logic/snooze.dart';
import 'package:remindya/logic/streak.dart';
import 'package:remindya/models/annoyance_level.dart';
import 'package:remindya/models/bark_mode.dart';
import 'package:remindya/models/reminder.dart';

Reminder _reminder({DateTime? due, RepeatRule repeat = RepeatRule.none}) =>
    Reminder(
      id: 'r1',
      notificationBaseId: 160,
      title: 'Call mom',
      dueAt: due ?? DateTime(2026, 10, 15, 12),
      repeat: repeat,
    );

void main() {
  group('streak', () {
    final day1 = DateTime(2026, 10, 1, 9);

    test('first completion starts a streak', () {
      final u = recordActivity(const StreakState(), day1);
      expect(u.state.current, 1);
      expect(u.event, StreakEventType.extended);
    });

    test('second completion on the same day does nothing', () {
      final s = recordActivity(const StreakState(), day1).state;
      final u = recordActivity(s, day1.add(const Duration(hours: 5)));
      expect(u.state.current, 1);
      expect(u.event, StreakEventType.none);
    });

    test('consecutive days extend the streak', () {
      var s = const StreakState();
      for (var i = 0; i < 3; i++) {
        s = recordActivity(s, day1.add(Duration(days: i))).state;
      }
      expect(s.current, 3);
      expect(s.best, 3);
    });

    test('a 7-day streak earns a treat', () {
      var s = const StreakState();
      late StreakUpdate u;
      for (var i = 0; i < 7; i++) {
        u = recordActivity(s, DateTime(2026, 10, 1 + i, 9));
        s = u.state;
      }
      expect(u.event, StreakEventType.treatEarned);
      expect(s.treats, 1);
    });

    test('a missed day eats a treat and keeps the streak', () {
      final s = StreakState(
        current: 10,
        best: 10,
        treats: 1,
        lastActiveDay: DateTime(2026, 10, 1),
      );
      final u = reconcileStreak(s, DateTime(2026, 10, 3, 8));
      expect(u.event, StreakEventType.treatsUsed);
      expect(u.state.current, 10);
      expect(u.state.treats, 0);
      final next = recordActivity(u.state, DateTime(2026, 10, 3, 9));
      expect(next.state.current, 11);
    });

    test('missing more days than treats loses the streak', () {
      final s = StreakState(
        current: 10,
        best: 12,
        treats: 1,
        lastActiveDay: DateTime(2026, 10, 1),
      );
      final u = reconcileStreak(s, DateTime(2026, 10, 5));
      expect(u.event, StreakEventType.streakLost);
      expect(u.amount, 10);
      expect(u.state.current, 0);
      expect(u.state.best, 12);
    });

    test('streak survives a daylight-saving change', () {
      final s = StreakState(
        current: 3,
        best: 3,
        lastActiveDay: DateTime(2026, 10, 24),
      );
      // Oct 25 2026 is the EU DST change.
      final u = recordActivity(s, DateTime(2026, 10, 25, 23));
      expect(u.state.current, 4);
    });
  });

  test('snoozes get shorter', () {
    expect(snoozeDuration(0), const Duration(hours: 1));
    expect(snoozeDuration(1), const Duration(minutes: 30));
    expect(snoozeDuration(4), const Duration(minutes: 5));
    expect(snoozeDuration(99), const Duration(minutes: 5));
  });

  group('quiet hours', () {
    const q = QuietHours(startMinute: 22 * 60, endMinute: 8 * 60);
    test('wraps midnight', () {
      expect(q.contains(DateTime(2026, 1, 1, 23)), isTrue);
      expect(q.contains(DateTime(2026, 1, 1, 3)), isTrue);
      expect(q.contains(DateTime(2026, 1, 1, 8)), isFalse);
      expect(q.contains(DateTime(2026, 1, 1, 12)), isFalse);
    });
    test('disabled never matches', () {
      expect(
        q.copyWith(enabled: false).contains(DateTime(2026, 1, 1, 23)),
        isFalse,
      );
    });
  });

  group('nag plan', () {
    final now = DateTime(2026, 10, 15, 11);

    test('one notification at due time plus one per follow-up', () {
      final plan = buildNagPlan(
        _reminder(),
        AnnoyanceLevel.goodBoy,
        const QuietHours(enabled: false),
        now,
        Random(1),
      );
      expect(plan, hasLength(1 + AnnoyanceLevel.goodBoy.nagOffsets.length));
      expect(plan.first.at, DateTime(2026, 10, 15, 12));
      expect(plan.first.stage, 0);
      expect(plan.last.stage, 3);
      expect(plan.map((n) => n.notificationId).toSet(), hasLength(plan.length));
      expect(
        plan.every(
          (n) => n.body.contains('call mom') || n.body.contains('Call mom'),
        ),
        isTrue,
      );
    });

    test('stages escalate monotonically', () {
      final plan = buildNagPlan(
        _reminder(),
        AnnoyanceLevel.feralChihuahua,
        const QuietHours(enabled: false),
        now,
      );
      final stages = plan.map((n) => n.stage).toList();
      final sorted = [...stages]..sort();
      expect(stages, sorted);
    });

    test('follow-ups in quiet hours and the past are skipped', () {
      final late = _reminder(due: DateTime(2026, 10, 15, 21, 50));
      final plan = buildNagPlan(
        late,
        AnnoyanceLevel.goodBoy,
        const QuietHours(),
        DateTime(2026, 10, 15, 21, 55),
      );
      // Due time is past; +10 min = 22:00 is quiet; everything else is too.
      expect(plan, isEmpty);
    });

    test('a snoozed reminder nags from the snooze time', () {
      final snoozed = _reminder().copyWith(
        snoozedUntil: DateTime(2026, 10, 15, 13),
        snoozeCount: 1,
      );
      final plan = buildNagPlan(
        snoozed,
        AnnoyanceLevel.chillPup,
        const QuietHours(enabled: false),
        now,
      );
      expect(plan.first.at, DateTime(2026, 10, 15, 13));
    });

    test('ids stay inside the reminder\'s range', () {
      final plan = buildNagPlan(
        _reminder(),
        AnnoyanceLevel.feralChihuahua,
        const QuietHours(enabled: false),
        now,
      );
      for (final n in plan) {
        expect(n.notificationId, greaterThanOrEqualTo(160));
        expect(
          n.notificationId,
          lessThan(160 + Reminder.maxNotificationsPerReminder),
        );
      }
    });
  });

  test('stageForNag spreads follow-ups over stages 1-3', () {
    expect(stageForNag(0, 4), 0);
    expect([1, 2, 3, 4].map((i) => stageForNag(i, 4)), [1, 1, 2, 3]);
    expect(stageForNag(1, 2), 1);
    expect(stageForNag(2, 2), 2);
  });

  test('bark mode decides which stages bark', () {
    final stages = [0, 1, 2, 3];
    expect(stages.map(BarkMode.off.barksAt), everyElement(isFalse));
    expect(stages.map(BarkMode.angryNags.barksAt), [false, false, true, true]);
    expect(stages.map(BarkMode.always.barksAt), everyElement(isTrue));
    expect(BarkMode.fromName('nonsense'), BarkMode.angryNags);
  });

  test('mood follows behavior', () {
    DogMood m(int overdue, {int snoozes = 0, int done = 0, int pending = 0}) =>
        computeMood(
          overdueCount: overdue,
          maxSnoozesOnOverdue: snoozes,
          completedToday: done,
          pendingCount: pending,
        );
    expect(m(0), DogMood.bored);
    expect(m(0, pending: 1), DogMood.happy);
    expect(m(0, done: 1), DogMood.ecstatic);
    expect(m(1, done: 3), DogMood.sad);
    expect(m(2), DogMood.devastated);
    expect(m(4), DogMood.feral);
    expect(m(1, snoozes: 5), DogMood.feral);
  });

  group('reminder', () {
    test('next occurrence skips to the future and keeps wall time', () {
      final r = _reminder(
        due: DateTime(2026, 10, 20, 9),
        repeat: RepeatRule.daily,
      );
      expect(
        r.nextOccurrence(DateTime(2026, 10, 27, 10)),
        DateTime(2026, 10, 28, 9),
      );
      final w = _reminder(
        due: DateTime(2026, 10, 20, 9),
        repeat: RepeatRule.weekly,
      );
      expect(
        w.nextOccurrence(DateTime(2026, 10, 20, 9, 1)),
        DateTime(2026, 10, 27, 9),
      );
      // Completing before it's due still moves to the next one.
      expect(
        r.nextOccurrence(DateTime(2026, 10, 20, 8)),
        DateTime(2026, 10, 21, 9),
      );
      expect(_reminder().nextOccurrence(DateTime(2026)), isNull);
    });

    test('json round trip', () {
      final r = _reminder(repeat: RepeatRule.weekly).copyWith(
        snoozeCount: 3,
        completedAt: DateTime(2026, 10, 15, 13),
        snoozedUntil: DateTime(2026, 10, 15, 12, 30),
      );
      final back = Reminder.fromJson(r.toJson());
      expect(back.toJson(), r.toJson());
    });
  });
}
