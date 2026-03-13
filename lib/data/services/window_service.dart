import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  // Pop up the window when alarm triggers
  Future<void> showWindow() async {
    debugPrint('WindowService: Showing window');

    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    if (!await windowManager.isVisible()) {
      await windowManager.show();
    }
    await windowManager.focus();
  }

  // Minimize to tray
  Future<void> hideToTray() async {
    debugPrint('WindowService: Hiding to tray');
    await windowManager.hide();
  }

  // Check if window is visible
  Future<bool> isVisible() async {
    return await windowManager.isVisible();
  }

  // Draw attention to the window
  Future<void> drawAttention() async {
    await showWindow();

    // On Windows, we can try to flash the taskbar icon
    // This is a platform-specific feature that might require additional setup
    debugPrint('WindowService: Drawing attention');
  }

  // Toggle between show and hide
  Future<void> toggleVisibility() async {
    if (await isVisible()) {
      await hideToTray();
    } else {
      await showWindow();
    }
  }
}
