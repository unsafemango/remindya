/// When notifications play the bark sound instead of the default chime.
enum BarkMode {
  off('Off', 'Default notification sound'),
  angryNags('Angry nags', 'Barks once the dog gets passive-aggressive'),
  always('Always', 'Every reminder barks. For the brave.');

  const BarkMode(this.label, this.description);
  final String label;
  final String description;

  /// Whether a nag at escalation [stage] (0 = due time, 3 = unhinged) barks.
  bool barksAt(int stage) => switch (this) {
    BarkMode.off => false,
    BarkMode.angryNags => stage >= 2,
    BarkMode.always => true,
  };

  static BarkMode fromName(String? name) => BarkMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => BarkMode.angryNags,
  );
}
