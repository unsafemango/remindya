import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../logic/dog_mood.dart';
import '../logic/dog_voice.dart';
import '../logic/quiet_hours.dart';
import '../logic/snooze.dart';
import '../logic/streak.dart';
import '../models/annoyance_level.dart';
import '../models/bark_mode.dart';
import '../models/reminder.dart';
import '../services/reminder_scheduler.dart';

class CompletionResult {
  const CompletionResult(this.message, this.bonesEarned, this.streakEvent);
  final String message;
  final int bonesEarned;
  final StreakUpdate streakEvent;
}

class SnoozeResult {
  const SnoozeResult(this.message, this.duration);
  final String message;
  final Duration duration;
}

class AppState extends ChangeNotifier {
  AppState({
    required this._prefs,
    required this._scheduler,
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random();

  static const _storageKey = 'remindya_state_v1';
  static const bonesPerCompletion = 10;
  static const onTimeBonus = 5;
  static const onTimeGrace = Duration(minutes: 5);

  final SharedPreferences _prefs;
  final ReminderScheduler _scheduler;
  final DateTime Function() _clock;
  final Random _random;
  final _uuid = const Uuid();

  List<Reminder> _reminders = [];
  StreakState _streak = const StreakState();
  int _bones = 0;
  AnnoyanceLevel _level = AnnoyanceLevel.goodBoy;
  QuietHours _quiet = const QuietHours();
  BarkMode _bark = BarkMode.angryNags;
  bool _moodIcon = true;
  List<DateTime> _recentCompletions = [];
  bool _onboarded = false;

  /// A one-off message to show on the home screen (streak lost, treat used).
  String? pendingBanner;

  DateTime get now => _clock();
  List<Reminder> get reminders => List.unmodifiable(_reminders);
  StreakState get streak => _streak;
  int get bones => _bones;
  AnnoyanceLevel get level => _level;
  QuietHours get quietHours => _quiet;
  BarkMode get barkMode => _bark;

  /// Whether the launcher icon follows the dog's mood.
  bool get moodIcon => _moodIcon;
  bool get onboarded => _onboarded;

  List<Reminder> get overdue =>
      _reminders.where((r) => r.isOverdue(now)).toList()
        ..sort((a, b) => a.nextAlertAt.compareTo(b.nextAlertAt));

  List<Reminder> get upcoming =>
      _reminders.where((r) => !r.isDone && !r.isOverdue(now)).toList()
        ..sort((a, b) => a.nextAlertAt.compareTo(b.nextAlertAt));

  List<Reminder> get doneToday => _reminders
      .where((r) => r.isDone && dateOnly(r.completedAt!) == dateOnly(now))
      .toList();

  int get completedToday =>
      _recentCompletions.where((t) => dateOnly(t) == dateOnly(now)).length;

  DogMood get mood {
    final od = overdue;
    return computeMood(
      overdueCount: od.length,
      maxSnoozesOnOverdue: od.fold(
        0,
        (m, r) => r.snoozeCount > m ? r.snoozeCount : m,
      ),
      completedToday: completedToday,
      pendingCount: upcoming.length,
    );
  }

  // ---------------------------------------------------------------- storage

  Future<void> load() async {
    final raw = _prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _reminders = (json['reminders'] as List? ?? [])
            .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
            .toList();
        _streak = StreakState.fromJson(
          json['streak'] as Map<String, dynamic>? ?? const {},
        );
        _bones = json['bones'] as int? ?? 0;
        _level = AnnoyanceLevel.fromName(json['level'] as String?);
        _quiet = QuietHours.fromJson(
          json['quiet'] as Map<String, dynamic>? ?? const {},
        );
        _bark = BarkMode.fromName(json['bark'] as String?);
        _moodIcon = json['moodIcon'] as bool? ?? true;
        _recentCompletions = (json['recentCompletions'] as List? ?? [])
            .map((e) => DateTime.parse(e as String))
            .toList();
        _onboarded = json['onboarded'] as bool? ?? false;
      } catch (e) {
        debugPrint('Failed to load saved state, starting fresh: $e');
      }
    }

    // Done one-off reminders from previous days are no longer interesting.
    final today = dateOnly(now);
    _reminders.removeWhere(
      (r) => r.isDone && dateOnly(r.completedAt!).isBefore(today),
    );
    _recentCompletions.removeWhere((t) => dateOnly(t).isBefore(today));

    final update = reconcileStreak(_streak, now);
    _streak = update.state;
    pendingBanner = switch (update.event) {
      StreakEventType.streakLost => streakLostMessage(update.amount),
      StreakEventType.treatsUsed => treatsUsedMessage(update.amount),
      _ => null,
    };
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _prefs.setString(
    _storageKey,
    jsonEncode({
      'reminders': _reminders.map((r) => r.toJson()).toList(),
      'streak': _streak.toJson(),
      'bones': _bones,
      'level': _level.name,
      'quiet': _quiet.toJson(),
      'bark': _bark.name,
      'moodIcon': _moodIcon,
      'recentCompletions': _recentCompletions
          .map((t) => t.toIso8601String())
          .toList(),
      'onboarded': _onboarded,
    }),
  );

  /// Re-schedules every pending reminder, e.g. after settings change or on
  /// app start (to top up nags that were dropped as "in the past").
  Future<void> rescheduleAll() async {
    for (final r in _reminders.where((r) => !r.isDone)) {
      await _scheduler.schedule(r, _level, _quiet, _bark);
    }
  }

  // -------------------------------------------------------------- mutations

  Future<void> markOnboarded() async {
    _onboarded = true;
    await _save();
    notifyListeners();
  }

  Reminder? byId(String id) {
    for (final r in _reminders) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<Reminder> addReminder({
    required String title,
    required DateTime dueAt,
    RepeatRule repeat = RepeatRule.none,
  }) async {
    final reminder = Reminder(
      id: _uuid.v4(),
      notificationBaseId: _newNotificationBase(),
      title: title.trim(),
      dueAt: dueAt,
      repeat: repeat,
    );
    _reminders.add(reminder);
    await _save();
    notifyListeners();
    await _scheduler.schedule(reminder, _level, _quiet, _bark);
    return reminder;
  }

  Future<void> updateReminder(Reminder updated) async {
    final i = _reminders.indexWhere((r) => r.id == updated.id);
    if (i < 0) return;
    _reminders[i] = updated;
    await _save();
    notifyListeners();
    await _scheduler.schedule(updated, _level, _quiet, _bark);
  }

  Future<void> deleteReminder(String id) async {
    final r = byId(id);
    if (r == null) return;
    _reminders.removeWhere((x) => x.id == id);
    await _save();
    notifyListeners();
    await _scheduler.cancel(r);
  }

  Future<CompletionResult?> completeReminder(String id) async {
    final r = byId(id);
    if (r == null || r.isDone) return null;
    final t = now;

    final onTime = !t.isAfter(r.dueAt.add(onTimeGrace));
    final earned = max(
      1,
      bonesPerCompletion + (onTime ? onTimeBonus : 0) - 2 * r.snoozeCount,
    );
    _bones += earned;
    _recentCompletions.add(t);

    final streakUpdate = recordActivity(_streak, t);
    _streak = streakUpdate.state;

    final next = r.nextOccurrence(t);
    final updated = next == null
        ? r.copyWith(completedAt: t)
        : r.copyWith(dueAt: next, snoozeCount: 0, clearSnoozedUntil: true);
    _reminders[_reminders.indexWhere((x) => x.id == id)] = updated;

    await _save();
    notifyListeners();
    await _scheduler.cancel(r);
    if (next != null) await _scheduler.schedule(updated, _level, _quiet, _bark);

    return CompletionResult(praise(_random), earned, streakUpdate);
  }

  Future<SnoozeResult?> snoozeReminder(String id) async {
    final r = byId(id);
    if (r == null || r.isDone) return null;
    final d = snoozeDuration(r.snoozeCount);
    final updated = r.copyWith(
      snoozedUntil: now.add(d),
      snoozeCount: r.snoozeCount + 1,
    );
    _reminders[_reminders.indexWhere((x) => x.id == id)] = updated;
    await _save();
    notifyListeners();
    await _scheduler.schedule(updated, _level, _quiet, _bark);
    return SnoozeResult(snoozeReaction(updated.snoozeCount), d);
  }

  Future<void> setLevel(AnnoyanceLevel level) async {
    _level = level;
    await _save();
    notifyListeners();
    await rescheduleAll();
  }

  Future<void> setQuietHours(QuietHours quiet) async {
    _quiet = quiet;
    await _save();
    notifyListeners();
    await rescheduleAll();
  }

  Future<void> setBarkMode(BarkMode bark) async {
    _bark = bark;
    await _save();
    notifyListeners();
    await rescheduleAll();
  }

  Future<void> setMoodIcon(bool enabled) async {
    _moodIcon = enabled;
    await _save();
    notifyListeners();
  }

  void clearBanner() {
    pendingBanner = null;
    notifyListeners();
  }

  int _newNotificationBase() {
    final used = _reminders.map((r) => r.notificationBaseId).toSet();
    while (true) {
      // Keep ids within a 32-bit int; slot 0 is reserved for test nags.
      final base =
          (1 + _random.nextInt(1 << 20)) * Reminder.maxNotificationsPerReminder;
      if (!used.contains(base)) return base;
    }
  }
}
