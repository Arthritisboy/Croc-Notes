import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:modular_journal/core/navigation.dart'; // Add this import
import 'package:modular_journal/data/services/timer_service.dart';
import 'package:modular_journal/features/notes/models/note.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/exit_options_dialog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'features/notes/viewmodels/notes_viewmodel.dart';
import 'features/notes/views/desktop_main_view.dart';
import 'features/notes/widgets/dialogs/timer_complete_dialog.dart'; // Add this import

// Global instance of timer service for use throughout the app
final timerService = TimerService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('\n=== CROC NOTES START ===');
  debugPrint('Current working directory: ${Directory.current.path}');
  debugPrint('Platform: ${Platform.operatingSystem}');

  // Initialize window manager
  debugPrint('\n1. Initializing window manager...');
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  debugPrint('   ✓ Window manager initialized');

  if (Platform.isWindows) {
    debugPrint('   Setting up sqflite FFI...');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('   ✓ sqflite FFI initialized');
  }

  // Initialize timer service
  debugPrint('\n2. Initializing timer service...');
  await timerService.initialize();

  // Set the callback to show window when timer completes
  timerService.onShowWindow = () async {
    debugPrint('⏰ TimerService: Showing window from callback');

    try {
      if (await windowManager.isMinimized()) {
        await windowManager.restore();
        debugPrint('   Window restored from minimized');
      }

      if (!await windowManager.isVisible()) {
        await windowManager.show();
        debugPrint('   Window shown');
      }

      await windowManager.focus();
      debugPrint('   Window focused');
    } catch (e) {
      debugPrint('❌ Error showing window: $e');
    }
  };

  // Set the callback for timer completion
  timerService.onTimerComplete = (String itemId, String itemTitle) {
    debugPrint('⏰ TimerService: Timer completed for $itemTitle');

    Future.delayed(const Duration(milliseconds: 300), () {
      if (navigatorKey.currentContext != null) {
        navigatorKey.currentState?.push(
          DialogRoute(
            context: navigatorKey.currentContext!,
            builder: (context) => TimerCompleteDialog(
              itemId: itemId,
              itemTitle: itemTitle,
              onStopAlarm: () {
                debugPrint('Stopping alarm for item $itemId');
                timerService.stopAlarm(itemId);
              },
              onDismiss: () {
                debugPrint('Timer dialog dismissed for $itemTitle');
                // Find the ViewModel and update the note
                try {
                  final viewModel = Provider.of<NotesViewModel>(
                    navigatorKey.currentContext!,
                    listen: false,
                  );
                  viewModel.resetTimerItem(itemId);

                  // Also ensure checkbox is set to unchecked
                  viewModel.updateTimerItemCheckbox(
                    itemId,
                    CheckboxState.unchecked,
                  );
                } catch (e) {
                  debugPrint('Error updating note: $e');
                }
              },
            ),
          ),
        );
      } else {
        debugPrint('❌ navigatorKey.currentContext is null');
      }
    });
  };

  debugPrint('   ✓ Timer service initialized with window callback');

  // Set up tray with extensive debugging (BEFORE window)
  await _setupTrayMenu();

  // Set window options
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  debugPrint('\n3. Setting up window...');
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    windowManager.addListener(_WindowListener());
    await windowManager.show();
    await windowManager.focus();
    await Window.setEffect(effect: WindowEffect.acrylic, dark: false);
    debugPrint('   ✓ Window shown and focused');
  });

  debugPrint('\n4. Starting Flutter app...');
  runApp(const MyApp());
}

Future<void> _setupTrayMenu() async {
  debugPrint('\n=== TRAY INITIALIZATION DEBUG ===');

  try {
    final menu = Menu(
      items: [
        MenuItem(key: 'croc_show', label: 'Show Window'),
        MenuItem(key: 'croc_hide', label: 'Hide Window'),
        MenuItem.separator(),
        MenuItem(key: 'croc_about', label: 'About Croc Notes'),
        MenuItem.separator(),
        MenuItem(key: 'croc_quit', label: 'Exit Completely'),
      ],
    );

    await trayManager.setContextMenu(menu);
    await trayManager.setToolTip('Croc Notes');

    // Try multiple icon paths
    final exeDir = Directory(Platform.resolvedExecutable).parent;
    final possiblePaths = [
      '${exeDir.path}\\data\\flutter_assets\\assets\\icon\\app_icon.ico',
      '${Directory.current.path}\\assets\\icon\\app_icon.ico',
    ];

    bool iconSet = false;
    for (final path in possiblePaths) {
      final iconFile = File(path);
      if (await iconFile.exists()) {
        await trayManager.setIcon(path);
        debugPrint('✓ Icon set from: $path');
        iconSet = true;
        break;
      }
    }

    if (!iconSet) {
      debugPrint(
        '⚠ No icon file found - tray will be invisible but functional',
      );
    }

    trayManager.addListener(_TrayListener());
    debugPrint('✓ Tray initialized successfully');
  } catch (e) {
    debugPrint('❌ Tray initialization error: $e');
  }
}

class _WindowListener implements WindowListener {
  @override
  void onWindowClose() async {
    debugPrint('Window close event intercepted - showing exit options');
    await windowManager.hide(); // Hide for now
  }

  @override
  void onWindowFocus() => debugPrint('Window focused');
  @override
  void onWindowBlur() => debugPrint('Window blurred');
  @override
  void onWindowMinimize() => debugPrint('Window minimized');
  @override
  void onWindowMaximize() => debugPrint('Window maximized');
  @override
  void onWindowUnmaximize() => debugPrint('Window unmaximized');
  @override
  void onWindowRestore() => debugPrint('Window restored');
  @override
  void onWindowResize() => debugPrint('Window resize started');
  @override
  void onWindowResized() => debugPrint('Window resized');
  @override
  void onWindowMove() => debugPrint('Window move started');
  @override
  void onWindowMoved() => debugPrint('Window moved');
  @override
  void onWindowEnterFullScreen() => debugPrint('Enter full screen');
  @override
  void onWindowLeaveFullScreen() => debugPrint('Leave full screen');
  @override
  void onWindowDocked() => debugPrint('Window docked');
  @override
  void onWindowUndocked() => debugPrint('Window undocked');
  @override
  void onWindowEvent(String eventName) =>
      debugPrint('Window event: $eventName');
}

class _TrayListener implements TrayListener {
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    debugPrint('Tray menu clicked: ${menuItem.key}');
    switch (menuItem.key) {
      case 'show':
        _showWindow();
        break;
      case 'hide':
        windowManager.hide();
        break;
      case 'about':
        _showAboutDialog();
        break;
      case 'quit':
        _showExitDialog();
        break;
    }
  }

  @override
  void onTrayIconMouseDown() {
    debugPrint('Tray icon clicked - showing window');
    _showWindow();
  }

  @override
  void onTrayIconMouseUp() => debugPrint('Tray icon mouse up');

  @override
  void onTrayIconRightMouseDown() {
    debugPrint('Tray icon right mouse down - showing context menu');
    // Small delay to ensure the menu appears
    Future.delayed(const Duration(milliseconds: 10), () {
      trayManager.popUpContextMenu();
    });
  }

  @override
  void onTrayIconRightMouseUp() => debugPrint('Tray icon right mouse up');

  void _showWindow() async {
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  }

  void _showAboutDialog() {
    _showWindow();
    // Show about dialog using navigatorKey
    navigatorKey.currentState?.push(
      DialogRoute(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text('About Croc Notes'),
          content: const Text(
            'A modular journaling app with timers and rich text editing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    _showWindow();
    // Show exit options dialog using navigatorKey
    navigatorKey.currentState?.push(
      DialogRoute(
        context: navigatorKey.currentContext!,
        builder: (context) => ExitOptionsDialog(timerService: timerService),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesViewModel()),
        Provider<TimerService>.value(value: timerService),
      ],
      child: MaterialApp(
        title: 'Croc Notes',
        navigatorKey: navigatorKey, // Add navigator key
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const DesktopMainView(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
