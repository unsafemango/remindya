import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/dog_mood.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../widgets/dog_mascot.dart';
import 'settings_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            const Center(child: DogMascot(mood: DogMood.ecstatic, size: 160)),
            const SizedBox(height: 16),
            Text(
              'Hi! I’m your Remindya dog.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(32, 8, 32, 16),
              child: Text(
                'Tell me what to remind you about and I’ll make sure you do it. '
                'If you don’t… I will get sad. And then I will get loud.',
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'How annoying should I be?',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            AnnoyanceLevelPicker(value: state.level, onChanged: state.setLevel),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: () async {
                  await context
                      .read<NotificationService?>()
                      ?.requestPermissions(askExactAlarms: true);
                  await state.markOnboarded();
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Let’s go! 🐾'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
