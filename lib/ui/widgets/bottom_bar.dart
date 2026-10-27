import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../theme/game_theme.dart';

/// Bottom bar displaying move counter, elapsed time, and difficulty metrics.
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: GameTheme.surfaceDark.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: GameTheme.glassBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Moves Counter
            _buildStatItem(
              icon: Icons.alt_route_rounded,
              label: 'MOVES',
              value: '${gameState.moves}',
              keyString: 'moves_counter',
            ),

            // Vertical divider
            Container(width: 1, height: 28, color: GameTheme.glassBorder),

            // Elapsed Timer
            _buildStatItem(
              icon: Icons.timer_outlined,
              label: 'TIME',
              value: _formatTime(gameState.elapsedSeconds),
              keyString: 'timer_display',
            ),

            // Vertical divider
            Container(width: 1, height: 28, color: GameTheme.glassBorder),

            // Solved Tubes Progress
            _buildStatItem(
              icon: Icons.check_circle_outline_rounded,
              label: 'SORTED',
              value: '${gameState.puzzleState.filledColorTubeCount}/${gameState.currentLevel.settings.numColors}',
              keyString: 'progress_display',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
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
            Icon(icon, size: 16, color: GameTheme.primaryCyan),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: GameTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          key: Key(keyString),
          style: const TextStyle(
            color: GameTheme.textBright,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
