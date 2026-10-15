/// Quiet hours, as minutes since midnight. May wrap past midnight
/// (e.g. 22:00 to 08:00).
class QuietHours {
  const QuietHours({
    this.enabled = true,
    this.startMinute = 22 * 60,
    this.endMinute = 8 * 60,
  });

  final bool enabled;
  final int startMinute;
  final int endMinute;

  bool contains(DateTime t) {
    if (!enabled || startMinute == endMinute) return false;
    final m = t.hour * 60 + t.minute;
    return startMinute < endMinute
        ? m >= startMinute && m < endMinute
        : m >= startMinute || m < endMinute;
  }

  QuietHours copyWith({bool? enabled, int? startMinute, int? endMinute}) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        startMinute: startMinute ?? this.startMinute,
        endMinute: endMinute ?? this.endMinute,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'start': startMinute,
    'end': endMinute,
  };

  factory QuietHours.fromJson(Map<String, dynamic> json) => QuietHours(
    enabled: json['enabled'] as bool? ?? true,
    startMinute: json['start'] as int? ?? 22 * 60,
    endMinute: json['end'] as int? ?? 8 * 60,
  );
}
