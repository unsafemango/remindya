enum RepeatRule {
  none('Does not repeat'),
  daily('Every day'),
  weekly('Every week');

  const RepeatRule(this.label);
  final String label;

  static RepeatRule fromName(String? name) => RepeatRule.values.firstWhere(
    (r) => r.name == name,
    orElse: () => RepeatRule.none,
  );
}

class Reminder {
  Reminder({
    required this.id,
    required this.notificationBaseId,
    required this.title,
    required this.dueAt,
    this.repeat = RepeatRule.none,
    this.completedAt,
    this.snoozeCount = 0,
    this.snoozedUntil,
  });

  final String id;

  /// Notification ids for this reminder live in
  /// [notificationBaseId, notificationBaseId + [maxNotificationsPerReminder]).
  final int notificationBaseId;
  final String title;
  final DateTime dueAt;
  final RepeatRule repeat;
  final DateTime? completedAt;
  final int snoozeCount;

  /// Set while snoozed. Kept separate from [dueAt] so snoozing a repeating
  /// reminder doesn't shift its schedule.
  final DateTime? snoozedUntil;

  /// When the dog next expects this to be done.
  DateTime get nextAlertAt => snoozedUntil ?? dueAt;

  static const maxNotificationsPerReminder = 16;

  bool get isDone => completedAt != null;

  bool isOverdue(DateTime now) => !isDone && nextAlertAt.isBefore(now);

  /// The occurrence after the current one for a repeating reminder, skipping
  /// any that are already in the past. Completing early still moves on.
  DateTime? nextOccurrence(DateTime now) {
    final stepDays = switch (repeat) {
      RepeatRule.none => null,
      RepeatRule.daily => 1,
      RepeatRule.weekly => 7,
    };
    if (stepDays == null) return null;
    var next = dueAt;
    do {
      // Add calendar days rather than a raw Duration so the wall-clock time
      // survives daylight-saving changes.
      next = DateTime(
        next.year,
        next.month,
        next.day + stepDays,
        next.hour,
        next.minute,
      );
    } while (!next.isAfter(now));
    return next;
  }

  Reminder copyWith({
    String? title,
    DateTime? dueAt,
    RepeatRule? repeat,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? snoozeCount,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
  }) {
    return Reminder(
      id: id,
      notificationBaseId: notificationBaseId,
      title: title ?? this.title,
      dueAt: dueAt ?? this.dueAt,
      repeat: repeat ?? this.repeat,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozedUntil: clearSnoozedUntil
          ? null
          : (snoozedUntil ?? this.snoozedUntil),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notificationBaseId': notificationBaseId,
    'title': title,
    'dueAt': dueAt.toIso8601String(),
    'repeat': repeat.name,
    'completedAt': completedAt?.toIso8601String(),
    'snoozeCount': snoozeCount,
    'snoozedUntil': snoozedUntil?.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    notificationBaseId: json['notificationBaseId'] as int,
    title: json['title'] as String,
    dueAt: DateTime.parse(json['dueAt'] as String),
    repeat: RepeatRule.fromName(json['repeat'] as String?),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    snoozeCount: json['snoozeCount'] as int? ?? 0,
    snoozedUntil: json['snoozedUntil'] == null
        ? null
        : DateTime.parse(json['snoozedUntil'] as String),
  );
}
