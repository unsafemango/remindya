import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../logic/dog_voice.dart';
import '../logic/nag_plan.dart';
import '../logic/quiet_hours.dart';
import '../models/annoyance_level.dart';
import '../models/reminder.dart';
import 'reminder_scheduler.dart';

const actionDone = 'done';
const actionSnooze = 'snooze';
const _iosCategory = 'remindya_nag';

typedef NotificationActionHandler = void Function(
  String reminderId,
  String? actionId,
);

class NotificationService implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _exactAlarms = false;

  NotificationActionHandler? onAction;

  /// A tap that launched the app from a terminated state, delivered once
  /// [onAction] is set.
  NotificationResponse? _launchResponse;

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      debugPrint('Could not resolve local timezone, using UTC: $e');
    }

    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _iosCategory,
          actions: [
            DarwinNotificationAction.plain(
              actionDone,
              'Done ✅',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              actionSnooze,
              'Snooze 😴',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
      ),
      onDidReceiveNotificationResponse: _dispatch,
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchResponse = launch!.notificationResponse;
    }
  }

  void deliverLaunchAction() {
    final r = _launchResponse;
    _launchResponse = null;
    if (r != null) _dispatch(r);
  }

  void _dispatch(NotificationResponse response) {
    final id = response.payload;
    if (id == null || id.isEmpty) return;
    onAction?.call(id, response.actionId);
  }

  /// Asks for notification permission. The exact-alarm prompt opens a system
  /// settings page on Android, so only pass [askExactAlarms] on first launch.
  Future<void> requestPermissions({bool askExactAlarms = false}) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      _exactAlarms = await android.canScheduleExactNotifications() ?? false;
      if (!_exactAlarms && askExactAlarms) {
        await android.requestExactAlarmsPermission();
        _exactAlarms = await android.canScheduleExactNotifications() ?? false;
      }
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails _details(int stage) {
    // Escalated nags go to a louder, higher-priority channel.
    final loud = stage >= 2;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        loud ? 'remindya_nags_loud' : 'remindya_nags',
        loud ? 'Unhinged nags' : 'Reminders',
        channelDescription: loud
            ? 'The dog is upset. These are louder.'
            : 'Your reminders, delivered by a dog.',
        importance: loud ? Importance.max : Importance.high,
        priority: loud ? Priority.max : Priority.high,
        category: AndroidNotificationCategory.reminder,
        actions: const [
          AndroidNotificationAction(
            actionDone,
            'Done ✅',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            actionSnooze,
            'Snooze 😴',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: _iosCategory,
        interruptionLevel: loud
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
  }

  @override
  Future<void> schedule(
    Reminder reminder,
    AnnoyanceLevel level,
    QuietHours quiet,
  ) async {
    await cancel(reminder);
    final plan = buildNagPlan(reminder, level, quiet, DateTime.now());
    for (final nag in plan) {
      await _plugin.zonedSchedule(
        id: nag.notificationId,
        title: nag.stage == 0 ? 'Remindya 🐶' : 'Remindya 🐶 (still waiting)',
        body: nag.body,
        scheduledDate: tz.TZDateTime.from(nag.at, tz.local),
        notificationDetails: _details(nag.stage),
        androidScheduleMode: _exactAlarms
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.id,
      );
    }
  }

  @override
  Future<void> cancel(Reminder reminder) async {
    for (var i = 0; i < Reminder.maxNotificationsPerReminder; i++) {
      await _plugin.cancel(id: reminder.notificationBaseId + i);
    }
  }

  /// Fires a nag right now so you can feel the pain.
  Future<void> sendTestNag(int stage) async {
    await _plugin.show(
      id: 0,
      title: 'Remindya 🐶',
      body: nagMessage('test your notifications', stage),
      notificationDetails: _details(stage),
    );
  }
}
