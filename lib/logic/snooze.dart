/// Every snooze is shorter than the last. The dog's patience is finite.
const _snoozeLadder = [
  Duration(hours: 1),
  Duration(minutes: 30),
  Duration(minutes: 15),
  Duration(minutes: 10),
  Duration(minutes: 5),
];

Duration snoozeDuration(int previousSnoozes) =>
    _snoozeLadder[previousSnoozes.clamp(0, _snoozeLadder.length - 1)];

String formatDuration(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}
