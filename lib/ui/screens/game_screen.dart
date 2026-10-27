import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../services/audio_service.dart';
import '../../services/settings_service.dart';
import '../theme/game_theme.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/game_board.dart';
import '../widgets/top_bar.dart';
import '../widgets/win_dialog.dart';

/// Main gameplay screen for Aqua Sort: Extreme.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    // 1-second gameplay timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(gameControllerProvider.notifier).tickTimer();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final settingsService = ref.watch(settingsServiceProvider);
    final settings = settingsService.settings;

    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      body: Stack(
        children: [
          // Main layout: Top Bar, Board, Bottom Bar
          Column(
            children: [
              const TopBar(),
              Expanded(
                child: GameBoard(
                  showColorblindCues: settings.colorblindPalette,
                  colorblindPalette: settings.colorblindPalette,
                  reducedMotion: settings.reducedMotion,
                  audioService: AudioService(settingsService: settingsService),
                ),
              ),
              const BottomBar(),
            ],
          ),

          // Win Dialog Modal
          if (gameState.isWon)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const WinDialog(),
              ),
            ),
        ],
      ),
    );
  }
}
