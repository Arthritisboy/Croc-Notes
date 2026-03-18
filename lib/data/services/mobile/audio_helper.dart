import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class AudioHelper {
  static final AudioHelper _instance = AudioHelper._internal();
  factory AudioHelper() => _instance;
  AudioHelper._internal();

  String? _cachedAlarmPath;

  Future<String?> getAlarmSoundPath() async {
    // Return cached path if it exists
    if (_cachedAlarmPath != null) {
      final cachedFile = File(_cachedAlarmPath!);
      if (await cachedFile.exists()) {
        final size = await cachedFile.length();
        debugPrint('✅ Using cached alarm: ${_cachedAlarmPath} ($size bytes)');
        return _cachedAlarmPath;
      }
    }

    try {
      debugPrint('📦 Loading alarm.mp3 from assets...');

      // Load from asset bundle
      final byteData = await rootBundle.load('assets/sounds/alarm.mp3');
      final bytes = byteData.buffer.asUint8List();

      debugPrint('  Loaded ${bytes.length} bytes from asset');

      if (bytes.isEmpty) {
        debugPrint('❌ Alarm asset is empty!');
        return null;
      }

      // Create temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'alarm_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final tempFile = File('${tempDir.path}/$fileName');

      // Write file
      await tempFile.writeAsBytes(bytes);

      // Verify
      if (await tempFile.exists()) {
        final size = await tempFile.length();
        debugPrint('✅ Alarm saved to: ${tempFile.path} ($size bytes)');
        _cachedAlarmPath = tempFile.path;
        return tempFile.path;
      }
    } catch (e) {
      debugPrint('❌ Failed to load alarm: $e');
    }

    return null;
  }

  Future<void> cleanOldTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) return;

      final files = tempDir.list();
      int deleted = 0;

      await for (final entity in files) {
        if (entity is File &&
            entity.path.contains('alarm_') &&
            entity.path.endsWith('.mp3') &&
            entity.path != _cachedAlarmPath) {
          await entity.delete();
          deleted++;
        }
      }

      if (deleted > 0) {
        debugPrint('🧹 Cleaned up $deleted old temp files');
      }
    } catch (e) {
      debugPrint('Error cleaning temp files: $e');
    }
  }
}
