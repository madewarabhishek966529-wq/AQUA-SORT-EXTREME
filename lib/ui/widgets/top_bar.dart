import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../theme/game_theme.dart';

/// Top bar displaying level title, home, undo, restart, and hint buttons.
class TopBar extends ConsumerWidget {
  final VoidCallback? onHomePressed;
  final VoidCallback? onSettingsPressed;

  const TopBar({
    super.key,
    this.onHomePressed,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final canUndo = gameState.history.isNotEmpty && !gameState.isInputLocked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GameTheme.surfaceDark.withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: GameTheme.glassBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Home / Menu Button
            IconButton(
              icon: const Icon(Icons.home_rounded, color: GameTheme.textBright),
              tooltip: 'Home',
              onPressed: onHomePressed,
            ),

            // Level Info Title
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LEVEL ${gameState.levelNumber}',
                    style: const TextStyle(
                      color: GameTheme.textBright,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${gameState.puzzleState.tubeCount} Bottles • ${gameState.currentLevel.settings.tier ?? "Standard"}',
                    style: const TextStyle(
                      color: GameTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Restart Button
            IconButton(
              key: const Key('restart_button'),
              icon: const Icon(Icons.refresh_rounded, color: GameTheme.textBright),
              tooltip: 'Restart Level',
              onPressed: gameState.isInputLocked ? null : () => controller.restart(),
            ),

            // Undo Button
            IconButton(
              key: const Key('undo_button'),
              icon: Icon(
                Icons.undo_rounded,
                color: canUndo ? GameTheme.primaryCyan : GameTheme.textMuted.withValues(alpha: 0.4),
              ),
              tooltip: 'Undo Move',
              onPressed: canUndo ? () => controller.undo() : null,
            ),

            // Hint Button
            IconButton(
              key: const Key('hint_button'),
              icon: gameState.isCalculatingHint
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(GameTheme.accentGold),
                      ),
                    )
                  : Icon(
                      Icons.lightbulb_rounded,
                      color: gameState.hintMove != null
                          ? GameTheme.accentGold
                          : (gameState.isInputLocked || gameState.isWon
                              ? GameTheme.textMuted.withValues(alpha: 0.3)
                              : GameTheme.accentGold.withValues(alpha: 0.9)),
                    ),
              tooltip: 'Hint',
              onPressed: (gameState.isInputLocked || gameState.isWon || gameState.isCalculatingHint)
                  ? null
                  : () => controller.requestHint(),
            ),
          ],
        ),
      ),
    );
  }
}
