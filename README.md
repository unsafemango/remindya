# Remindya 🐶

A reminder app that's as annoying as Duolingo, delivered by a dog.

Remind yourself of something. If you don't do it, the dog gets sad. Then it gets loud.

## Features (MVP)

- **Escalating nags.** Each reminder fires at its due time, then follows up
  with increasingly unhinged messages: polite, then passive-aggressive, then
  "I have chewed through 3 of your shoes."
- **Annoyance levels.** Chill Pup (2 follow-ups), Good Boy (4), Feral
  Chihuahua (7).
- **Snooze shaming.** Every snooze is shorter than the last (1h → 30m → 15m →
  10m → 5m). The snooze count shows on the reminder and costs you bones.
- **Mood-reactive mascot.** The dog is bored, happy, ecstatic, sad,
  devastated or feral depending on how you're doing. It's drawn with a
  `CustomPainter` and animated.
- **Streaks and Treats.** Complete at least one reminder a day to keep your
  streak. Every 7 days you earn a Treat (max 2), which saves your streak
  if you miss a day.
- **Bones.** +10 per completion, +5 if on time, −2 per snooze.
- **Quiet hours.** Follow-up nags are skipped overnight. The reminder itself
  still fires at the time you picked.
- **Notification actions.** Done ✅ / Snooze 😴 straight from the notification.
- One-off, daily and weekly reminders.

## Project layout

```
lib/
  main.dart                       app bootstrap, theme, providers
  models/                         Reminder, AnnoyanceLevel
  logic/                          pure Dart, unit tested
    dog_voice.dart                all the dog's lines (edit these!)
    dog_mood.dart                 mood from overdue/snooze/completion state
    nag_plan.dart                 which notifications to schedule, and when
    streak.dart                   streak + Treat rules
    snooze.dart, quiet_hours.dart
  state/app_state.dart            ChangeNotifier: persistence, bones, streaks
  services/notification_service.dart  flutter_local_notifications wrapper
  screens/                        onboarding, home, edit reminder, settings
  widgets/dog_mascot.dart         the dog
```

## Running

```sh
flutter pub get
flutter test
flutter run   # Android or iOS device/emulator
```

On Android 13+ the app asks for notification permission on first launch and
for exact alarm permission, so nags arrive on time. If exact alarms are
denied, it falls back to inexact scheduling.

## Ideas for v2

- Custom bark notification sound
- Changing the app icon based on mood
- Dog growth (puppy → adult), cosmetics bought with bones
- Pack mode: shared reminders, leaderboards, opt-in "tattle" to a friend
- Location-based reminders
- Natural-language entry ("remind me to pay rent on the 1st")
