import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Add this import
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this import
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'features/notes/viewmodels/notes_viewmodel.dart';
import 'features/notes/views/desktop_main_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Windows (does nothing on Android)
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => NotesViewModel())],
      child: MaterialApp(
        title: 'Modular Journal',
        // Add localizations delegates for FlutterQuill
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate, // Add this line
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          // Add more locales as needed
        ],
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
