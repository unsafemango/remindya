enum DogMood {
  bored('Give me something to remind you about! I\'m so bored!'),
  happy('All caught up! Who\'s a good human? You are!'),
  ecstatic('You got stuff DONE today! *zoomies* 🐾'),
  sad('*puppy eyes* You have something overdue…'),
  devastated('So many overdue things. I\'m lying by the door. Waiting.'),
  feral('I HAVE BECOME FERAL. DO YOUR TASKS. 🔥');

  const DogMood(this.line);
  final String line;

  bool get isUpset => index >= DogMood.sad.index;
}

DogMood computeMood({
  required int overdueCount,
  required int maxSnoozesOnOverdue,
  required int completedToday,
  required int pendingCount,
}) {
  if (overdueCount >= 4 || (overdueCount > 0 && maxSnoozesOnOverdue >= 5)) {
    return DogMood.feral;
  }
  if (overdueCount >= 2) return DogMood.devastated;
  if (overdueCount == 1) return DogMood.sad;
  if (completedToday > 0) return DogMood.ecstatic;
  if (pendingCount > 0) return DogMood.happy;
  return DogMood.bored;
}
