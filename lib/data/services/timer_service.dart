// lib/core/services/timer_service.dart
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
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Callback when timer completes
  Function(String itemId)? onTimerComplete;

  Future<void> initialize() async {
    // Initialize notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  void startTimer({
    required String itemId,
    required Duration duration,
    String? soundPath,
    bool loopSound = false,
    required Function() onComplete,
  }) {
    // Cancel existing timer for this item
    stopTimer(itemId);

    final timer = Timer(duration, () {
      _onTimerComplete(itemId, soundPath, loopSound, onComplete);
    });

    _activeTimers[itemId] = timer;
  }

  void pauseTimer(String itemId) {
    // Can't easily pause Timer in Dart, so we'll handle this in the UI
    // by storing elapsed time and recreating timer
  }

  void stopTimer(String itemId) {
    _activeTimers[itemId]?.cancel();
    _activeTimers.remove(itemId);
    stopAlarm(itemId);
  }

  Future<void> _onTimerComplete(
    String itemId,
    String? soundPath,
    bool loopSound,
    Function() onComplete,
  ) async {
    _activeTimers.remove(itemId);

    // Play alarm sound
    if (soundPath != null) {
      await playAlarm(itemId, soundPath, loopSound);
    }

    // Show notification
    await _showNotification(itemId);

    // Trigger callback
    onComplete();
  }

  Future<void> playAlarm(String itemId, String soundPath, bool loop) async {
    stopAlarm(itemId);

    final player = AudioPlayer();
    _activeAlarms[itemId] = player;

    if (loop) {
      await player.setReleaseMode(ReleaseMode.loop);
    }

    // Use the path string directly
    await player.play(DeviceFileSource(soundPath));
  }

  void stopAlarm(String itemId) {
    _activeAlarms[itemId]?.stop();
    _activeAlarms.remove(itemId);
  }

  void stopAllAlarms() {
    for (final player in _activeAlarms.values) {
      player.stop();
    }
    _activeAlarms.clear();
  }

  Future<void> _showNotification(String itemId) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Notifications when timers complete',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _notifications.show(
      itemId.hashCode,
      'Timer Complete',
      'Your timer has finished!',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    stopAllAlarms();
  }
}
