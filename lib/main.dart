import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_icon_service.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'widgets/feedback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  await notifications.init();

  final state = AppState(prefs: prefs, scheduler: notifications);
  await state.load();
  notifications.onAction = (id, action) =>
      handleNotificationAction(state, id, action);

  if (state.onboarded) {
    await notifications.requestPermissions();
    await state.rescheduleAll();
  }

  AppIconUpdater(state, AppIconService()).start();

  runApp(RemindyaApp(state: state, notifications: notifications));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => notifications.deliverLaunchAction(),
  );
}

class RemindyaApp extends StatelessWidget {
  const RemindyaApp({super.key, required this.state, this.notifications});

  final AppState state;
  final NotificationService? notifications;

  static const _seed = Color(0xFFFF9F1C);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        Provider<NotificationService?>.value(value: notifications),
      ],
      child: MaterialApp(
        title: 'Remindya',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _seed),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _seed,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: Selector<AppState, bool>(
          selector: (_, s) => s.onboarded,
          builder: (_, onboarded, _) =>
              onboarded ? const HomeScreen() : const OnboardingScreen(),
        ),
      ),
    );
  }
}
