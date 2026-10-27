import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/game_screen.dart';
import 'ui/theme/game_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AquaSortApp(),
    ),
  );
}

/// Root widget for Aqua Sort: Extreme application.
class AquaSortApp extends StatelessWidget {
  const AquaSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqua Sort: Extreme',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.darkTheme,
      home: const GameScreen(),
    );
  }
}
