import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../theme/gradients.dart';
import '../../theme/theme_provider.dart';

/// Top bar displaying level title with gradient text, home, restart, undo, and hint buttons.
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
    final theme = ref.watch(activeThemePaletteProvider);
    final canUndo = gameState.history.isNotEmpty && !gameState.isInputLocked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(color: theme.glassBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Home / Menu Button
            IconButton(
              icon: Icon(Icons.home_rounded, color: theme.textBright),
              tooltip: 'Home',
              onPressed: onHomePressed ?? () => Navigator.of(context).maybePop(),
            ),

            // Level Info Title with rich GradientText
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradientText(
                    'LEVEL ${gameState.levelNumber}',
                    gradient: UIGradients.levelTitleGradient(theme),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${gameState.puzzleState.tubeCount} Bottles • ${gameState.currentLevel.settings.tier ?? "Standard"}',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Restart Button
            IconButton(
              key: const Key('restart_button'),
              icon: Icon(Icons.refresh_rounded, color: theme.textBright),
              tooltip: 'Restart Level',
              onPressed: gameState.isInputLocked ? null : () => controller.restart(),
            ),

            // Undo Button
            IconButton(
              key: const Key('undo_button'),
              icon: Icon(
                Icons.undo_rounded,
                color: canUndo ? theme.primaryAccent : theme.textMuted.withValues(alpha: 0.4),
              ),
              tooltip: 'Undo Move',
              onPressed: canUndo ? () => controller.undo() : null,
            ),

            // Hint Button
            IconButton(
              key: const Key('hint_button'),
              icon: gameState.isCalculatingHint
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.secondaryAccent),
                      ),
                    )
                  : Icon(
                      Icons.lightbulb_rounded,
                      color: gameState.hintMove != null
                          ? theme.secondaryAccent
                          : theme.textMuted,
                    ),
              tooltip: 'Get Hint',
              onPressed: gameState.isInputLocked ? null : () => controller.requestHint(),
            ),
          ],
        ),
      ),
    );
  }
}
