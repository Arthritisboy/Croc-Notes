import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  final Map<String, Timer> _activeTimers = {};
  final Map<String, AudioPlayer> _activeAlarms = {};
  final Map<String, String> _itemTitles = {};

  // Use a single instance of notifications plugin
  late final FlutterLocalNotificationsPlugin _notifications;

  // Callbacks
  Function(String itemId, String itemTitle)? onTimerComplete;
  Function()? onShowWindow;

  Future<void> initialize() async {
    debugPrint('TimerService: Initializing...');

    // Initialize notifications
    _notifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    debugPrint('TimerService: Notifications initialized');
  }

  void startTimer({
    required String itemId,
    required String itemTitle,
    required Duration duration,
    String? soundPath,
    bool loopSound = false,
    required Function() onComplete,
  }) {
    // Cancel existing timer for this item
    stopTimer(itemId);

    // Store the item title
    _itemTitles[itemId] = itemTitle;

    final timer = Timer(duration, () {
      _onTimerComplete(itemId, soundPath, loopSound, onComplete);
    });

    _activeTimers[itemId] = timer;
    debugPrint(
      'Timer started for item $itemId ($itemTitle), duration: $duration',
    );
  }

  Future<void> _onTimerComplete(
    String itemId,
    String? soundPath,
    bool loopSound,
    Function() onComplete,
  ) async {
    _activeTimers.remove(itemId);

    // Get the item title
    final itemTitle = _itemTitles[itemId] ?? 'Timer';
    _itemTitles.remove(itemId);

    debugPrint('Timer completed for item $itemId ($itemTitle)');

    // SHOW WINDOW using callback
    if (onShowWindow != null) {
      onShowWindow!();
    }

    // Play alarm sound
    if (soundPath != null) {
      await playAlarm(itemId, soundPath, loopSound);
    }

    // Show notification
    await _showNotification(itemId, itemTitle);

    // Trigger callback with item title
    if (onTimerComplete != null) {
      onTimerComplete!(itemId, itemTitle);
    }

    // Trigger original onComplete
    onComplete();
  }

  Future<void> playAlarm(String itemId, String soundPath, bool loop) async {
    stopAlarm(itemId);

    final player = AudioPlayer();
    _activeAlarms[itemId] = player;

    if (loop) {
      await player.setReleaseMode(ReleaseMode.loop);
    }

    // The warning about platform thread is from audioplayers plugin
    // It's harmless but we can try to minimize it by setting a different player mode
    await player.setPlayerMode(PlayerMode.lowLatency);

    await player.play(DeviceFileSource(soundPath));
    debugPrint('Alarm playing for item $itemId');
  }

  void stopAlarm(String itemId) {
    debugPrint('TimerService: Stopping alarm for item $itemId');
    final player = _activeAlarms[itemId];
    if (player != null) {
      player.stop();
      player.dispose(); // Dispose the player to free resources
      _activeAlarms.remove(itemId);
      debugPrint('Alarm stopped for item $itemId');
    } else {
      debugPrint('No active alarm found for item $itemId');
    }
  }

  void stopAllAlarms() {
    for (final player in _activeAlarms.values) {
      player.stop();
    }
    _activeAlarms.clear();
  }

  void stopTimer(String itemId) {
    _activeTimers[itemId]?.cancel();
    _activeTimers.remove(itemId);
    _itemTitles.remove(itemId);
    stopAlarm(itemId);
  }

  Future<void> _showNotification(String itemId, String itemTitle) async {
    try {
      debugPrint('TimerService: Showing notification for $itemTitle');

      const androidDetails = AndroidNotificationDetails(
        'timer_channel',
        'Timer Notifications',
        channelDescription: 'Notifications when timers complete',
        importance: Importance.high,
        priority: Priority.high,
        fullScreenIntent: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails();

      await _notifications.show(
        itemId.hashCode,
        '⏰ Timer Complete!',
        '$itemTitle has finished!',
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );

      debugPrint('TimerService: Notification shown');
    } catch (e) {
      debugPrint('TimerService: Error showing notification: $e');
    }
  }

  bool isTimerRunning(String itemId) {
    return _activeTimers.containsKey(itemId);
  }

  void dispose() {
    debugPrint('TimerService: Disposing all timers and alarms');

    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _itemTitles.clear();

    // Properly stop and dispose all alarms
    for (final player in _activeAlarms.values) {
      player.stop();
      player.dispose();
    }
    _activeAlarms.clear();

    debugPrint('TimerService: Cleanup complete');
  }
}
