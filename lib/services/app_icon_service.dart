import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/app_icon.dart';
import '../state/app_state.dart';

/// Switches the launcher icon via the `remindya/app_icon` platform channel.
class AppIconService {
  static const _channel = MethodChannel('remindya/app_icon');

  AppIcon? _applied;

  Future<void> apply(AppIcon icon) async {
    if (icon == _applied) return;
    try {
      await _channel.invokeMethod<void>('setIcon', {'name': icon.name});
      _applied = icon;
    } on PlatformException catch (e) {
      debugPrint('Could not change app icon: ${e.message}');
    } on MissingPluginException {
      // Not supported on this platform.
    }
  }
}

/// Keeps the launcher icon in sync with the dog's mood.
///
/// iOS only allows icon changes while the app is in the foreground (and shows
/// a short system notice), so it updates as the mood changes. On Android,
/// switching the launcher entry while the app is open can restart it on some
/// devices, so it updates when the app goes to the background.
class AppIconUpdater with WidgetsBindingObserver {
  AppIconUpdater(this._state, this._service);

  final AppState _state;
  final AppIconService _service;
  Timer? _timer;
  bool _foreground = true;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  AppIcon get _desired =>
      _state.moodIcon ? AppIcon.fromMood(_state.mood) : AppIcon.happy;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    if (_isIOS) {
      _state.addListener(_syncIfForeground);
      // Mood also changes with time, as reminders become overdue.
      _timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _syncIfForeground(),
      );
      _syncIfForeground();
    }
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _state.removeListener(_syncIfForeground);
    _timer?.cancel();
  }

  void _syncIfForeground() {
    if (_foreground) _service.apply(_desired);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_isIOS) {
      _syncIfForeground();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _service.apply(_desired);
    }
  }
}
