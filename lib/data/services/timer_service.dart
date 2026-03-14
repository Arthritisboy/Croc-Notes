// lib/data/services/timer_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:modular_journal/features/notes/models/note.dart';
import 'package:path_provider/path_provider.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  final Map<String, Timer> _activeTimers = {};
  final Map<String, AudioPlayer> _activeAlarms = {};
  final Map<String, String> _itemTitles = {};
  String? get defaultAlarmPath => _defaultAlarmPath;

  // Initialize as late but set in initialize()
  late final FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  // Default alarm sound path
  String? _defaultAlarmPath;

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

    // Find default alarm sound
    await _findDefaultAlarm();

    _isInitialized = true;
    debugPrint('TimerService: Initialization complete');
  }

  Future<void> _findDefaultAlarm() async {
    try {
      // Look for alarm.mp3 in various locations
      final List<String> possiblePaths = [];

      // In release build, next to executable
      if (Platform.isWindows) {
        final exeDir = Directory(Platform.resolvedExecutable).parent;
        possiblePaths.add('${exeDir.path}\\assets\\sounds\\alarm.mp3');
        possiblePaths.add('${exeDir.path}\\alarm.mp3');
        possiblePaths.add(
          '${exeDir.path}\\data\\flutter_assets\\assets\\sounds\\alarm.mp3',
        );
      }

      // In debug build, in project
      possiblePaths.add('${Directory.current.path}\\assets\\sounds\\alarm.mp3');
      possiblePaths.add('${Directory.current.path}\\alarm.mp3');

      // In app support directory
      final appDir = await getApplicationSupportDirectory();
      possiblePaths.add('${appDir.path}\\alarm.mp3');

      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          _defaultAlarmPath = path;
          debugPrint('TimerService: Found default alarm at: $path');
          break;
        }
      }

      if (_defaultAlarmPath == null) {
        debugPrint('TimerService: No default alarm sound found');
      }
    } catch (e) {
      debugPrint('TimerService: Error finding default alarm: $e');
    }
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

    final timer = Timer(duration, () async {
      // Before completing, validate the sound path
      final validPath = await getValidSoundPath(soundPath);
      await _onTimerComplete(itemId, validPath, loopSound, onComplete);
    });

    _activeTimers[itemId] = timer;
    debugPrint(
      'Timer started for item $itemId ($itemTitle), duration: $duration',
    );
  }

  Future<bool> isSoundFileValid(String? soundPath) async {
    if (soundPath == null || soundPath.isEmpty) return false;

    try {
      final file = File(soundPath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking sound file: $e');
      return false;
    }
  }

  // Get valid sound path with fallback to default
  Future<String?> getValidSoundPath(String? customPath) async {
    // If custom path is provided and valid, use it
    if (customPath != null && await isSoundFileValid(customPath)) {
      return customPath;
    }

    // Otherwise fall back to default alarm
    if (_defaultAlarmPath != null &&
        await isSoundFileValid(_defaultAlarmPath)) {
      debugPrint('⚠️ Using default alarm sound (custom sound not found)');
      return _defaultAlarmPath;
    }

    // No valid sound found
    debugPrint('❌ No valid alarm sound found');
    return null;
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

    // Get valid sound path (with fallback to default)
    final validSoundPath = await getValidSoundPath(soundPath);

    // Play alarm sound if available
    if (validSoundPath != null) {
      await playAlarm(itemId, validSoundPath, loopSound);
    } else {
      debugPrint('⚠️ No valid alarm sound available');
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
    try {
      stopAlarm(itemId);

      final player = AudioPlayer();
      _activeAlarms[itemId] = player;

      if (loop) {
        await player.setReleaseMode(ReleaseMode.loop);
      }

      await player.setPlayerMode(PlayerMode.lowLatency);

      // Check if file exists
      final file = File(soundPath);
      if (!await file.exists()) {
        debugPrint('TimerService: Alarm file not found: $soundPath');
        return;
      }

      await player.play(DeviceFileSource(soundPath));
      debugPrint('Alarm playing for item $itemId from: $soundPath');
    } catch (e) {
      debugPrint('TimerService: Error playing alarm: $e');
    }
  }

  void stopAlarm(String itemId) {
    debugPrint('TimerService: Stopping alarm for item $itemId');
    final player = _activeAlarms[itemId];
    if (player != null) {
      player.stop();
      player.dispose();
      _activeAlarms.remove(itemId);
      debugPrint('Alarm stopped for item $itemId');
    } else {
      debugPrint('No active alarm found for item $itemId');
    }
  }

  void stopAllAlarms() {
    for (final player in _activeAlarms.values) {
      player.stop();
      player.dispose();
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
      if (!_isInitialized) {
        debugPrint('TimerService: Not initialized, cannot show notification');
        return;
      }

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

  Future<void> checkForCompletedTimers(List<Note> allTimerItems) async {
    final now = DateTime.now();

    for (final item in allTimerItems) {
      if (item.timerState == TimerState.running &&
          item.timerStartTime != null &&
          item.timerDuration != null) {
        final elapsed = now.difference(item.timerStartTime!);

        if (elapsed >= item.timerDuration!) {
          // Timer completed while PC was off
          debugPrint('⏰ Timer completed while PC was off: ${item.title}');

          // Trigger completion
          await triggerTimerCompletion(item.id, item.title);

          // Update item state
          item.completeTimer();

          // Save to database
          if (onTimerComplete != null) {
            onTimerComplete!(item.id, item.title);
          }
        } else if (elapsed.inSeconds > 0) {
          // Timer is still running, update the UI to show correct remaining time
          debugPrint(
            '⏰ Timer still running after PC off: ${item.title}, elapsed: ${elapsed.inSeconds}s',
          );
        }
      }
    }
  }

  Future<void> triggerTimerCompletion(
    String itemId,
    String itemTitle, {
    String? soundPath,
    bool loopSound = false,
  }) async {
    debugPrint('⏰ Triggering completion for timer: $itemTitle');

    // Show window
    if (onShowWindow != null) {
      onShowWindow!();
    }

    // Play alarm with validated path
    if (soundPath != null) {
      await playAlarm(itemId, soundPath, loopSound);
    }

    // Show notification
    await _showNotification(itemId, itemTitle);

    // Trigger callback
    if (onTimerComplete != null) {
      onTimerComplete!(itemId, itemTitle);
    }
  }

  void dispose() {
    debugPrint('TimerService: Disposing all timers and alarms');

    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _itemTitles.clear();
    stopAllAlarms();

    debugPrint('TimerService: Cleanup complete');
  }
}
