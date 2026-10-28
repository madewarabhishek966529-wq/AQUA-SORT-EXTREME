import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../services/settings_service.dart';
import '../../theme/aqua_palette.dart';
import '../../theme/theme_provider.dart';

/// Bottom bar displaying move counter, elapsed timer, and sorted tubes progress
/// with rolling number animations.
class BottomBar extends ConsumerWidget {
  const BottomBar({super.key});

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final theme = ref.watch(activeThemePaletteProvider);
    final settings = ref.watch(settingsServiceProvider).settings;
    final isStatic = settings.reducedMotion || settings.animationIntensity <= 0.05;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: theme.glassBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Moves Counter
            _buildStatItem(
              theme: theme,
              isStatic: isStatic,
              icon: Icons.alt_route_rounded,
              label: 'MOVES',
              value: '${gameState.moves}',
              keyString: 'moves_counter',
            ),

            // Vertical divider
            Container(width: 1, height: 28, color: theme.glassBorder),

            // Elapsed Timer
            _buildStatItem(
              theme: theme,
              isStatic: isStatic,
              icon: Icons.timer_outlined,
              label: 'TIME',
              value: _formatTime(gameState.elapsedSeconds),
              keyString: 'timer_display',
            ),

            // Vertical divider
            Container(width: 1, height: 28, color: theme.glassBorder),

            // Solved Tubes Progress
            _buildStatItem(
              theme: theme,
              isStatic: isStatic,
              icon: Icons.check_circle_outline_rounded,
              label: 'SORTED',
              value:
                  '${gameState.puzzleState.filledColorTubeCount}/${gameState.currentLevel.settings.numColors}',
              keyString: 'progress_display',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required ThemePalette theme,
    required bool isStatic,
    required IconData icon,
    required String label,
    required String value,
    required String keyString,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.primaryAccent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: isStatic ? Duration.zero : const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            value,
            key: Key(keyString),
            style: TextStyle(
              color: theme.textBright,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
