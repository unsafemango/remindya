import 'dart:math';

/// Everything the dog says. `{task}` is replaced with the reminder title.

/// Escalation stages for a single reminder's notification chain.
/// Stage 0 fires at the due time; later stages are follow-up nags.
const nagStages = <List<String>>[
  // 0 — polite
  [
    'Woof! Time to {task} 🐾',
    'Hey hey hey! It\'s time: {task}',
    '*wags tail* Reminder: {task}',
  ],
  // 1 — follow-up
  [
    'Woof? You said you\'d {task}.',
    'Just checking… did you {task} yet? 👀',
    'I\'m sitting very nicely. Waiting for you to {task}.',
  ],
  // 2 — passive-aggressive
  [
    'It\'s fine. I\'ll just wait here. Alone. While you don\'t {task}.',
    'I\'m not mad. I\'m just disappointed. {task}.',
    'Other dogs\' humans already did their tasks. Just saying. {task}.',
  ],
  // 3 — unhinged
  [
    'I have chewed through 3 of your shoes. {task}. NOW.',
    'BARK BARK BARK BARK. {task}. BARK.',
    'I know where you sleep. {task}. 🐕🔥',
    'This is your final warning before I eat the couch. {task}.',
  ],
];

/// Snooze reactions, indexed by how many times the reminder was snoozed
/// (clamped to the last entry).
const snoozeReactions = <String>[
  'Okay! I\'ll be back soon 🐶',
  'Again? …okay.',
  'Snoozing. Like your potential.',
  'I\'m counting, you know. I\'m a very good counter.',
  'Snooze Lord detected. 💀',
];

const completionPraise = <String>[
  'GOOD HUMAN! 🦴',
  'You did it!! *zoomies*',
  'Best human in the whole world!!',
  'I knew you could do it! *happy spin*',
  'Treat time? Treat time. 🦴',
];

final _rng = Random();

String _pick(List<String> options, [Random? rng]) =>
    options[(rng ?? _rng).nextInt(options.length)];

String _fill(String template, String task) {
  final t = task.trim();
  // Lower-case the first letter so "Call mom" reads naturally mid-sentence.
  final lowered = t.isEmpty ? t : t[0].toLowerCase() + t.substring(1);
  return template.startsWith('{task}')
      ? template.replaceAll('{task}', t)
      : template.replaceAll('{task}', lowered);
}

/// Maps a nag index (0 = at due time) to an escalation stage, spreading the
/// follow-ups evenly over stages 1..3.
int stageForNag(int nagIndex, int totalFollowUps) {
  if (nagIndex <= 0) return 0;
  if (totalFollowUps <= 0) return 1;
  final stage = 1 + ((nagIndex - 1) * 3) ~/ totalFollowUps;
  return stage.clamp(1, 3);
}

String nagMessage(String task, int stage, [Random? rng]) =>
    _fill(_pick(nagStages[stage.clamp(0, nagStages.length - 1)], rng), task);

String snoozeReaction(int snoozeCount) =>
    snoozeReactions[(snoozeCount - 1).clamp(0, snoozeReactions.length - 1)];

String praise([Random? rng]) => _pick(completionPraise, rng);

String streakLostMessage(int lost) =>
    'We had a $lost-day streak. I guess that meant nothing to you. 💔';

String treatsUsedMessage(int used) => used == 1
    ? 'You missed a day, so I ate a Treat to save your streak. You\'re welcome.'
    : 'You missed $used days. I ate $used Treats to save your streak. I\'m full.';
