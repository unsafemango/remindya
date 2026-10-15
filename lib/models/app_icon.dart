import '../logic/dog_mood.dart';

/// Launcher icon variants. Names match the native side (MainActivity.kt
/// aliases and the iOS alternate icon sets).
enum AppIcon {
  happy,
  sad,
  feral;

  static AppIcon fromMood(DogMood mood) => switch (mood) {
    DogMood.bored || DogMood.happy || DogMood.ecstatic => AppIcon.happy,
    DogMood.sad || DogMood.devastated => AppIcon.sad,
    DogMood.feral => AppIcon.feral,
  };
}
