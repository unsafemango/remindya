/// How hard the dog nags you after a reminder goes overdue.
enum AnnoyanceLevel {
  chillPup(
    label: 'Chill Pup',
    emoji: '🐶',
    description: 'A couple of gentle nudges. Very good boy energy.',
    nagOffsets: [Duration(minutes: 30), Duration(hours: 2)],
  ),
  goodBoy(
    label: 'Good Boy',
    emoji: '🐕',
    description: 'Follows you around the house until you do it.',
    nagOffsets: [
      Duration(minutes: 10),
      Duration(minutes: 30),
      Duration(hours: 1),
      Duration(hours: 2),
    ],
  ),
  feralChihuahua(
    label: 'Feral Chihuahua',
    emoji: '🔥',
    description:
        'Will not stop. Has chewed through your shoes. Chose violence.',
    nagOffsets: [
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
      Duration(minutes: 30),
      Duration(minutes: 45),
      Duration(hours: 1),
      Duration(hours: 2),
    ],
  );

  const AnnoyanceLevel({
    required this.label,
    required this.emoji,
    required this.description,
    required this.nagOffsets,
  });

  final String label;
  final String emoji;
  final String description;

  /// Follow-up nag times, measured from the reminder's due time.
  final List<Duration> nagOffsets;

  static AnnoyanceLevel fromName(String? name) => AnnoyanceLevel.values
      .firstWhere((l) => l.name == name, orElse: () => AnnoyanceLevel.goodBoy);
}
