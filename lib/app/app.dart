import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/notes/viewmodels/notes_viewmodel.dart';
import '../features/notes/views/desktop_main_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => NotesViewModel())],
      child: MaterialApp(
        title: 'Modular Journal',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: const DesktopMainView(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
