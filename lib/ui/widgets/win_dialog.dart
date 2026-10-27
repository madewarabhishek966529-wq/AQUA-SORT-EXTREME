import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../theme/game_theme.dart';

/// Modal dialog shown upon completing a puzzle.
class WinDialog extends ConsumerWidget {
  final VoidCallback? onNextLevel;

  const WinDialog({super.key, this.onNextLevel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    final minutes = gameState.elapsedSeconds ~/ 60;
    final seconds = gameState.elapsedSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: GameTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GameTheme.accentGold.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: GameTheme.accentGold.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 4,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Victory Trophy Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameTheme.accentGold.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 56,
                  color: GameTheme.accentGold,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'LEVEL COMPLETE!',
                style: TextStyle(
                  color: GameTheme.accentGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'All bottles sorted successfully!',
                style: TextStyle(
                  color: GameTheme.textBright.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('MOVES', '${gameState.moves}'),
                  Container(width: 1, height: 32, color: GameTheme.glassBorder),
                  _buildStat('TIME', timeStr),
                ],
              ),
              const SizedBox(height: 28),

              // Next Level and Replay Buttons
              Row(
                children: [
                  // Replay Button
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('win_replay_button'),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('REPLAY'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GameTheme.textBright,
                        side: const BorderSide(color: GameTheme.glassBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => controller.restart(),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Next Level Button
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('win_next_button'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('NEXT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.primaryCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (onNextLevel != null) {
                          onNextLevel!();
                        } else {
                          // Advance to next level deterministically
                          const generator = PuzzleGenerator();
                          final nextLevelNumber = gameState.levelNumber + 1;
                          final tubeCount = nextLevelNumber <= 5 ? 8 : (nextLevelNumber <= 10 ? 12 : 16);
                          final settings = GenerationSettings.forTubeCount(tubeCount);
                          final nextLevel = generator.generate(1000 + nextLevelNumber, settings);
                          controller.loadLevel(nextLevelNumber, nextLevel);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GameTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: GameTheme.textBright,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
