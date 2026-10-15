/// Duolingo-style daily streak. A day counts once you complete at least one
/// reminder. Missed days eat a Treat (streak freeze) if you have one.
class StreakState {
  const StreakState({
    this.current = 0,
    this.best = 0,
    this.treats = 0,
    this.lastActiveDay,
  });

  static const maxTreats = 2;

  /// A Treat is earned every time the streak hits a multiple of this.
  static const treatEvery = 7;

  final int current;
  final int best;
  final int treats;

  /// Date-only (local midnight) of the last day that counted.
  final DateTime? lastActiveDay;

  Map<String, dynamic> toJson() => {
    'current': current,
    'best': best,
    'treats': treats,
    'lastActiveDay': lastActiveDay?.toIso8601String(),
  };

  factory StreakState.fromJson(Map<String, dynamic> json) => StreakState(
    current: json['current'] as int? ?? 0,
    best: json['best'] as int? ?? 0,
    treats: json['treats'] as int? ?? 0,
    lastActiveDay: json['lastActiveDay'] == null
        ? null
        : DateTime.parse(json['lastActiveDay'] as String),
  );
}

enum StreakEventType { none, treatsUsed, streakLost, extended, treatEarned }

class StreakUpdate {
  const StreakUpdate(this.state, this.event, {this.amount = 0});

  final StreakState state;
  final StreakEventType event;

  /// Treats used for [StreakEventType.treatsUsed], the lost streak length for
  /// [StreakEventType.streakLost], the new streak otherwise.
  final int amount;
}

DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Accounts for days missed since the last activity. Call on app open.
StreakUpdate reconcileStreak(StreakState s, DateTime now) {
  final last = s.lastActiveDay;
  if (last == null || s.current == 0) {
    return StreakUpdate(s, StreakEventType.none);
  }
  final today = dateOnly(now);
  final missed = _daysBetween(last, today) - 1;
  if (missed <= 0) return StreakUpdate(s, StreakEventType.none);

  if (s.treats >= missed) {
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    return StreakUpdate(
      StreakState(
        current: s.current,
        best: s.best,
        treats: s.treats - missed,
        lastActiveDay: yesterday,
      ),
      StreakEventType.treatsUsed,
      amount: missed,
    );
  }
  return StreakUpdate(
    StreakState(best: s.best, treats: 0, lastActiveDay: last),
    StreakEventType.streakLost,
    amount: s.current,
  );
}

/// Records a completed reminder at [now].
StreakUpdate recordActivity(StreakState s, DateTime now) {
  final reconciled = reconcileStreak(s, now).state;
  final today = dateOnly(now);
  if (reconciled.lastActiveDay != null &&
      _daysBetween(reconciled.lastActiveDay!, today) == 0) {
    return StreakUpdate(reconciled, StreakEventType.none);
  }
  final current = reconciled.current + 1;
  final earned =
      current % StreakState.treatEvery == 0 &&
      reconciled.treats < StreakState.maxTreats;
  return StreakUpdate(
    StreakState(
      current: current,
      best: current > reconciled.best ? current : reconciled.best,
      treats: reconciled.treats + (earned ? 1 : 0),
      lastActiveDay: today,
    ),
    earned ? StreakEventType.treatEarned : StreakEventType.extended,
    amount: current,
  );
}
