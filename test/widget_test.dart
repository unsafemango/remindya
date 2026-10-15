import 'package:flutter_test/flutter_test.dart';
import 'package:remindya/main.dart';
import 'package:remindya/services/reminder_scheduler.dart';
import 'package:remindya/state/app_state.dart';
import 'package:remindya/widgets/dog_mascot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('onboarding, then complete a reminder from the home screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      prefs: await SharedPreferences.getInstance(),
      scheduler: NoopScheduler(),
    );
    await state.load();

    await tester.pumpWidget(RemindyaApp(state: state));
    expect(find.text('How annoying should I be?'), findsOneWidget);

    await tester.tap(find.text('Feral Chihuahua'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Let’s go! 🐾'), 200);
    await tester.tap(find.text('Let’s go! 🐾'));
    await tester.pump();

    expect(find.text('Remindya'), findsOneWidget);
    expect(find.byType(DogMascot), findsOneWidget);
    expect(find.textContaining('No reminders yet'), findsOneWidget);

    await state.addReminder(
      title: 'Feed the actual dog',
      dueAt: DateTime.now().add(const Duration(hours: 1)),
    );
    await tester.pump();
    expect(find.text('Feed the actual dog'), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);

    await tester.tap(find.byTooltip('Mark done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Done today ✅'), findsOneWidget);
    expect(find.textContaining('+15 🦴'), findsOneWidget);
    expect(find.text('1 day streak'), findsOneWidget);
  });
}
