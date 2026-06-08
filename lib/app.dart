import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/main_shell.dart';

/// Root widget. Provides [AppState] to the tree and builds the MaterialApp.
class AmxControlApp extends StatelessWidget {
  const AmxControlApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'AMX CE Control',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.comfortable,
        ),
        home: const MainShell(),
      ),
    );
  }
}
