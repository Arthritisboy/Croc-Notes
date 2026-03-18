import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:modular_journal/data/services/mobile/audio_helper.dart';
import 'package:modular_journal/features/notes/models/note.dart';
import 'package:path_provider/path_provider.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  final Map<String, Timer> _activeTimers = {};
  final Map<String, AudioPlayer> _activeAlarms = {};
  final Map<String, String> _itemTitles = {};
  final Map<String, String?> _itemSoundPaths = {};
  final Map<String, bool> _itemLoopSettings = {};
  final AudioHelper _audioHelper = AudioHelper();

  String? get defaultAlarmPath => _defaultAlarmPath;

  // Initialize as late but set in initialize()
  late final FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  // Default alarm sound path
  String? _defaultAlarmPath;

  // Platform detection
  final bool _isAndroid = Platform.isAndroid;
  final bool _isWindows = Platform.isWindows;

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

    // Platform-specific default alarm loading
    if (_isAndroid) {
      await _loadDefaultAlarmMobile();
    } else if (_isWindows) {
      await _findDefaultAlarmWindows();
    }

    _isInitialized = true;
    debugPrint('TimerService: Initialization complete');
  }

  // Windows-specific default alarm finder
  Future<void> _findDefaultAlarmWindows() async {
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

  // Android-specific default alarm loader (from assets)
  Future<void> _loadDefaultAlarmMobile() async {
    // Extract alarm from assets to a temporary file
    _defaultAlarmPath = await _audioHelper.getAlarmSoundPath();

    if (_defaultAlarmPath != null) {
      debugPrint('✅ Android default alarm ready at: $_defaultAlarmPath');
    } else {
      debugPrint('❌ Failed to load Android default alarm');
    }
  }

  void startTimer({
    required String itemId,
    required String itemTitle,
    required Duration duration,
    String? soundPath, // null means use default
    bool loopSound = false,
    required Function() onComplete,
  }) {
    // Cancel existing timer for this item
    stopTimer(itemId);

    // Store all preferences
    _itemTitles[itemId] = itemTitle;
    _itemSoundPaths[itemId] = soundPath;
    _itemLoopSettings[itemId] = loopSound;

    final timer = Timer(duration, () async {
      // Get the stored sound path
      final storedPath = _itemSoundPaths[itemId];

      // Get valid sound path (platform-specific)
      final validPath = await getValidSoundPath(storedPath);

      await _onTimerComplete(
        itemId,
        validPath,
        _itemLoopSettings[itemId] ?? false,
        onComplete,
      );
    });

    _activeTimers[itemId] = timer;
    debugPrint(
      'Timer started for item $itemId ($itemTitle), duration: $duration, sound: ${soundPath ?? "default"}',
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

  // Platform-specific sound path validation
  Future<String?> getValidSoundPath(String? customPath) async {
    debugPrint(
      '🔍 getValidSoundPath called with: ${customPath ?? "null (default)"} on ${_isAndroid ? "Android" : "Windows"}',
    );

    // If custom path is provided and valid, use it
    if (customPath != null && customPath.isNotEmpty) {
      try {
        final file = File(customPath);
        final exists = await file.exists();
        debugPrint('  Custom path exists: $exists');
        if (exists) {
          return customPath;
        }
      } catch (e) {
        debugPrint('  Error checking custom path: $e');
      }
    }

    // Platform-specific default sound handling
    if (_isAndroid) {
      return await _getValidAndroidDefaultSound();
    } else if (_isWindows) {
      return await _getValidWindowsDefaultSound();
    }

    return null;
  }

  // Android-specific default sound handler (uses temp files)
  Future<String?> _getValidAndroidDefaultSound() async {
    if (_defaultAlarmPath != null) {
      try {
        final file = File(_defaultAlarmPath!);
        final exists = await file.exists();
        debugPrint('  Android default path exists: $exists');
        if (exists) {
          return _defaultAlarmPath;
        } else {
          // Try to reload from assets
          await _loadDefaultAlarmMobile();
          if (_defaultAlarmPath != null &&
              await File(_defaultAlarmPath!).exists()) {
            return _defaultAlarmPath;
          }
        }
      } catch (e) {
        debugPrint('  Error checking Android default path: $e');
      }
    }

    debugPrint('❌ No valid Android alarm sound found');
    return null;
  }

  // Windows-specific default sound handler (uses file system)
  Future<String?> _getValidWindowsDefaultSound() async {
    if (_defaultAlarmPath != null) {
      try {
        final file = File(_defaultAlarmPath!);
        final exists = await file.exists();
        debugPrint('  Windows default path exists: $exists');
        if (exists) {
          return _defaultAlarmPath;
        }
      } catch (e) {
        debugPrint('  Error checking Windows default path: $e');
      }
    }

    debugPrint('❌ No valid Windows alarm sound found');
    return null;
  }

  Future<void> _onTimerComplete(
    String itemId,
    String? soundPath,
    bool loopSound,
    Function() onComplete,
  ) async {
    _activeTimers.remove(itemId);

    final itemTitle = _itemTitles[itemId] ?? 'Timer';
    _itemTitles.remove(itemId);

    debugPrint('Timer completed for item $itemId ($itemTitle)');

    if (_isWindows && onShowWindow != null) {
      onShowWindow!();
    }

    final validSoundPath = await getValidSoundPath(soundPath);

    // Play alarm using platform-specific method
    if (validSoundPath != null) {
      if (_isAndroid) {
        await playAlarmMobile(itemId, validSoundPath, loopSound);
      } else {
        await playAlarm(itemId, validSoundPath, loopSound);
      }
    } else {
      debugPrint('⚠️ No valid alarm sound available');
    }

    await _showNotification(itemId, itemTitle);

    if (onTimerComplete != null) {
      onTimerComplete!(itemId, itemTitle);
    }

    onComplete();
  }

  // Original Windows version (kept unchanged)
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

  // New Android-specific version with AudioCache fix
  Future<void> playAlarmMobile(
    String itemId,
    String soundPath,
    bool loop,
  ) async {
    try {
      stopAlarm(itemId);

      final player = AudioPlayer();
      _activeAlarms[itemId] = player;

      // Use AudioCache for better asset handling on Android
      final cache = AudioCache();

      if (loop) {
        // For looping, use media player mode for better streaming
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setPlayerMode(PlayerMode.mediaPlayer);
      } else {
        await player.setPlayerMode(PlayerMode.lowLatency);
      }

      // Check if file exists
      final file = File(soundPath);
      if (!await file.exists()) {
        debugPrint('❌ TimerService: Alarm file not found: $soundPath');
        return;
      }

      // Play using the file directly
      await player.play(DeviceFileSource(soundPath));
      debugPrint('🔊 Mobile alarm playing for item $itemId');

      // Monitor duration for debugging
      final duration = await player.getDuration();
      if (duration != null) {
        debugPrint('⏱️ Alarm duration: ${duration.inSeconds} seconds');

        // Track playback progress
        bool hasLoggedProgress = false;
        player.onPositionChanged.listen((position) {
          if (!hasLoggedProgress &&
              position.inMilliseconds > duration.inMilliseconds * 0.8) {
            debugPrint('✅ Alarm playing full duration for item $itemId');
            hasLoggedProgress = true;
          }
        });

        // Track loops if enabled
        if (loop) {
          int loopCount = 0;
          player.onPlayerComplete.listen((_) {
            loopCount++;
            debugPrint('🔄 Loop #$loopCount completed for item $itemId');
          });
        }
      }
    } catch (e) {
      debugPrint('❌ TimerService: Error playing mobile alarm: $e');
    }
  }

  Future<void> testAlarm() async {
    debugPrint('🧪 Testing alarm system...');

    // Get the default alarm path
    final soundPath = await getValidSoundPath(null);

    if (soundPath != null) {
      debugPrint('✅ Test: Found alarm at: $soundPath');

      // Try to play it using platform-specific method
      if (_isAndroid) {
        await playAlarmMobile('test_alarm', soundPath, true);
      } else {
        await playAlarm('test_alarm', soundPath, true);
      }

      // Stop it after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        stopAlarm('test_alarm');
        debugPrint('🧪 Test alarm stopped');
      });
    } else {
      debugPrint('❌ Test: No alarm sound found');
    }
  }

  void stopAlarm(String itemId) {
    debugPrint('🔴 STOP ALARM CALLED for item $itemId');
    debugPrint('  Stack trace: ${StackTrace.current}');

    final player = _activeAlarms[itemId];
    if (player != null) {
      player.stop();
      player.dispose();
      _activeAlarms.remove(itemId);
      debugPrint('✅ Alarm stopped for item $itemId');
    } else {
      debugPrint('⚠️ No active alarm found for item $itemId');
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
    _itemSoundPaths.remove(itemId);
    _itemLoopSettings.remove(itemId);
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
          debugPrint('⏰ Timer completed while device was off: ${item.title}');

          // Get valid sound path
          final validPath = await getValidSoundPath(item.alarmSoundPath);

          // Trigger completion with platform-specific playback
          await triggerTimerCompletion(
            item.id,
            item.title,
            soundPath: validPath,
            loopSound: item.isLoopingAlarm,
          );

          item.completeTimer();

          if (onTimerComplete != null) {
            onTimerComplete!(item.id, item.title);
          }
        } else if (elapsed.inSeconds > 0) {
          debugPrint(
            '⏰ Timer still running after restart: ${item.title}, elapsed: ${elapsed.inSeconds}s',
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

    // Show window (Windows only)
    if (_isWindows && onShowWindow != null) {
      onShowWindow!();
    }

    // Play alarm with platform-specific method
    if (soundPath != null) {
      if (_isAndroid) {
        await playAlarmMobile(itemId, soundPath, loopSound);
      } else {
        await playAlarm(itemId, soundPath, loopSound);
      }
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
    _itemSoundPaths.clear();
    _itemLoopSettings.clear();
    stopAllAlarms();

    // Clean up temp files (Android only)
    if (_isAndroid) {
      _audioHelper.cleanOldTempFiles();
    }

    debugPrint('TimerService: Cleanup complete');
  }
}
