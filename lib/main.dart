import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:modular_journal/core/navigation.dart';
import 'package:modular_journal/data/services/timer_service.dart';
import 'package:modular_journal/features/notes/models/note.dart';
import 'package:modular_journal/features/notes/views/mobile_main_view.dart';
import 'package:modular_journal/features/notes/views/mobile_settings_view.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/exit_options_dialog.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/mobile/mobile_timer_complete_dialog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'features/notes/viewmodels/notes_viewmodel.dart';
import 'features/notes/views/desktop_main_view.dart';
import 'features/notes/widgets/dialogs/timer_complete_dialog.dart';

// Global instances
final timerService = TimerService();
late String cachedImagesDirectory;
final bool isDesktop =
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;
final bool isMobile = Platform.isAndroid || Platform.isIOS;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('\n=== CROC NOTES START ===');
  debugPrint('Current working directory: ${Directory.current.path}');
  debugPrint('Platform: ${Platform.operatingSystem}');

  // ✅ Platform-specific initialization
  if (isDesktop) {
    // Initialize desktop-only plugins
    debugPrint('\n1. Initializing window manager...');
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    debugPrint('   ✓ Window manager initialized');

    // sqflite FFI is Windows-only, macOS uses different setup
    if (Platform.isWindows) {
      debugPrint('   Setting up sqflite FFI...');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      debugPrint('   ✓ sqflite FFI initialized');
    }
    // macOS uses regular sqflite, no FFI needed
  }

  // Initialize timer service (works on all platforms)
  debugPrint('\n2. Initializing timer service...');
  await timerService.initialize();

  // Platform-specific image directory caching
  if (isDesktop) {
    if (Platform.isWindows) {
      cachedImagesDirectory = DatabaseService.getImagesDirectorySync();
      debugPrint(
        '📁 [Windows] Cached images directory: $cachedImagesDirectory',
      );
    } else if (Platform.isMacOS) {
      // macOS uses async method like Android
      cachedImagesDirectory = await DatabaseService.getImagesDirectoryAsync();
      debugPrint('📁 [macOS] Cached images directory: $cachedImagesDirectory');
    }
    await Directory(cachedImagesDirectory).create(recursive: true);
  } else {
    // Mobile (Android/iOS)
    cachedImagesDirectory = await DatabaseService.getImagesDirectoryAsync();
    debugPrint('📁 [Mobile] Cached images directory: $cachedImagesDirectory');
  }

  // ✅ Desktop-only callbacks and setup
  if (isDesktop) {
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
          final isMobile =
              MediaQuery.of(navigatorKey.currentContext!).size.width < 600;

          navigatorKey.currentState?.push(
            DialogRoute(
              context: navigatorKey.currentContext!,
              builder: (context) => isMobile
                  ? MobileTimerCompleteDialog(
                      itemTitle: itemTitle,
                      onStopAlarm: () {
                        debugPrint(
                          '👆 USER PRESSED OK - stopping alarm for item $itemId',
                        );
                        timerService.stopAlarm(itemId);
                      },
                      onDismiss: () {
                        debugPrint('👆 Dismissing dialog for $itemTitle');
                        try {
                          final viewModel = Provider.of<NotesViewModel>(
                            navigatorKey.currentContext!,
                            listen: false,
                          );
                          viewModel.resetTimerItem(itemId);
                          viewModel.updateTimerItemCheckbox(
                            itemId,
                            CheckboxState.unchecked,
                          );
                        } catch (e) {
                          debugPrint('Error updating note: $e');
                        }
                      },
                    )
                  : TimerCompleteDialog(
                      itemId: itemId,
                      itemTitle: itemTitle,
                      onStopAlarm: () {
                        debugPrint(
                          '👆 USER PRESSED OK - stopping alarm for item $itemId',
                        );
                        timerService.stopAlarm(itemId);
                      },
                      onDismiss: () {
                        debugPrint('👆 Dismissing dialog for $itemTitle');
                        try {
                          final viewModel = Provider.of<NotesViewModel>(
                            navigatorKey.currentContext!,
                            listen: false,
                          );
                          viewModel.resetTimerItem(itemId);
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
        }
      });
    };

    debugPrint('   ✓ Timer service initialized with window callback');

    // Set up tray menu (Windows and macOS)
    if (Platform.isWindows || Platform.isMacOS) {
      await _setupTrayMenu();
    }

    // Set window options (Windows and macOS)
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

      // Acrylic effect is Windows-only
      if (Platform.isWindows) {
        await Window.setEffect(effect: WindowEffect.acrylic, dark: false);
      }
      // macOS uses vibrancy effect
      else if (Platform.isMacOS) {
        // Optional: Add macOS vibrancy if supported
        // await Window.setEffect(effect: WindowEffect.vibrancy, dark: false);
      }

      debugPrint('   ✓ Window shown and focused');
    });
  }

  debugPrint('\n4. Starting Flutter app...');
  runApp(const MyApp());
}

// ✅ Make these functions conditional or only used on Windows
Future<void> _setupTrayMenu() async {
  if (!(Platform.isWindows || Platform.isMacOS)) return;

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
    debugPrint('✓ Menu created with ${menu.items?.length} items');

    await trayManager.setContextMenu(menu);
    debugPrint('✓ Context menu set');

    await trayManager.setToolTip('Croc Notes');
    debugPrint('✓ Tooltip set');

    // Platform-specific icon paths
    final exeDir = Directory(Platform.resolvedExecutable).parent;
    final List<String> possiblePaths = [];

    if (Platform.isWindows) {
      possiblePaths.addAll([
        '${exeDir.path}\\data\\flutter_assets\\assets\\icon\\app_icon.ico',
        '${Directory.current.path}\\assets\\icon\\app_icon.ico',
        '${exeDir.path}\\app_icon.ico',
      ]);
    } else if (Platform.isMacOS) {
      // On macOS, use the app bundle's icon from Assets.xcassets
      // The icon is built into the app, so we can use a special path or just skip icon setting
      debugPrint('macOS: Using app icon from Assets.xcassets');

      // You can either:
      // 1. Not set an icon (uses default app icon)
      // 2. Try to use the icon from the bundle
      final bundleIconPath = '${exeDir.path}/../Resources/AppIcon.icns';
      possiblePaths.add(bundleIconPath);
    }

    bool iconSet = false;
    for (final path in possiblePaths) {
      debugPrint('Trying icon path: $path');
      final iconFile = File(path);
      if (await iconFile.exists()) {
        debugPrint('✓ Icon file found at: $path');
        await trayManager.setIcon(path);
        debugPrint('✓ Icon set successfully');
        iconSet = true;
        break;
      } else {
        debugPrint('✗ Icon file not found at: $path');
      }
    }

    if (!iconSet && Platform.isMacOS) {
      debugPrint('ℹ️ No explicit icon set - using default app icon');
      // On macOS, the tray will use the app icon by default
    }

    trayManager.addListener(_TrayListener());
    debugPrint('✓ Tray listener added');
    debugPrint('✓ Tray initialized successfully');
  } catch (e) {
    debugPrint('❌ Tray initialization error: $e');
  }
}

// ✅ Add platform checks to listeners
class _WindowListener implements WindowListener {
  @override
  void onWindowClose() async {
    if (!(Platform.isWindows || Platform.isMacOS)) return;
    debugPrint('Window close event intercepted - showing exit options');
    await windowManager.hide();
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
    if (!(Platform.isWindows || Platform.isMacOS)) return;
    debugPrint(
      'Tray menu clicked: ${menuItem.key} on ${Platform.operatingSystem}',
    );
    switch (menuItem.key) {
      case 'croc_show':
        _showWindow();
        break;
      case 'croc_hide':
        windowManager.hide();
        break;
      case 'croc_about':
        _showAboutDialog();
        break;
      case 'croc_quit':
        _showExitDialog();
        break;
    }
  }

  @override
  void onTrayIconMouseDown() {
    if (!(Platform.isWindows || Platform.isMacOS)) return;
    debugPrint('Tray icon clicked on ${Platform.operatingSystem}');

    if (Platform.isMacOS) {
      // On macOS, left click shows the menu
      debugPrint('  macOS: showing menu on left click');
      trayManager.popUpContextMenu();
    } else {
      // On Windows, left click shows the window
      debugPrint('  Windows: showing window on left click');
      _showWindow();
    }
  }

  @override
  void onTrayIconMouseUp() => debugPrint('Tray icon mouse up');

  @override
  void onTrayIconRightMouseDown() {
    if (!(Platform.isWindows || Platform.isMacOS)) return;
    debugPrint('Tray icon right mouse down on ${Platform.operatingSystem}');

    if (Platform.isWindows) {
      // On Windows, right click shows the menu
      debugPrint('  Windows: showing menu on right click');
      Future.delayed(const Duration(milliseconds: 10), () {
        trayManager.popUpContextMenu();
      });
    }
    // On macOS, right click might do nothing or we can ignore it
  }

  @override
  void onTrayIconRightMouseUp() => debugPrint('Tray icon right mouse up');

  void _showWindow() async {
    if (!(Platform.isWindows || Platform.isMacOS)) return;
    debugPrint('Showing window on ${Platform.operatingSystem}');

    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  }

  void _showAboutDialog() {
    if (!(Platform.isWindows || Platform.isMacOS)) return;
    _showWindow();
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
    if (!(Platform.isWindows || Platform.isMacOS)) return;
    _showWindow();
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
    // Create a pleasant dark theme with purple seed
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesViewModel()),
        Provider<TimerService>.value(value: timerService),
      ],
      child: MaterialApp(
        title: 'Croc Notes',
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        home: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return const DesktopMainView();
            } else {
              return const MobileMainView();
            }
          },
        ),
        routes: {'/settings': (context) => const MobileSettingsView()},
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
