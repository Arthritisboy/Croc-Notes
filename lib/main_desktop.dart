import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Add this import
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this import
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Set up main window
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await Window.setEffect(effect: WindowEffect.acrylic, dark: false);
  });

  // Initialize system tray
  await trayManager.setContextMenu(
    Menu(
      items: [
        MenuItem(key: 'show', label: 'Show'),
        MenuItem(key: 'hide', label: 'Hide'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    ),
  );

  runApp(const MyApp());
}
