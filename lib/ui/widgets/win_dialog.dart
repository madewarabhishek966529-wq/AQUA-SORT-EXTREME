import 'dart:math';
import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../motion/motion_tokens.dart';
import '../../services/settings_service.dart';
import '../../theme/aqua_palette.dart';
import '../../theme/gradients.dart';
import '../../theme/theme_provider.dart';

/// Upgraded modal dialog shown upon completing a puzzle with:
/// - Gradient title text
/// - Animated 3-star count-up
/// - Animated coin reward counter
/// - Soft glowing gradient buttons
/// - Skippable on tap / reduced motion
class WinDialog extends ConsumerStatefulWidget {
  final VoidCallback? onNextLevel;

  const WinDialog({super.key, this.onNextLevel});

  @override
  ConsumerState<WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends ConsumerState<WinDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _starsAnimation;
  late final Animation<int> _coinsAnimation;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsServiceProvider).settings;
    final isStatic = settings.reducedMotion || settings.animationIntensity <= 0.05;

    _animController = AnimationController(
      vsync: this,
      duration: isStatic ? Duration.zero : MotionTokens.levelWinCelebration,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack),
    );

    _starsAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.30, 0.75, curve: Curves.easeOutCubic),
    );

    _coinsAnimation = IntTween(begin: 0, end: 50).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.50, 0.95, curve: Curves.easeOut),
      ),
    );

    if (isStatic) {
      _animController.value = 1.0;
    } else {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _skipAnimation() {
    if (_animController.isAnimating) {
      _animController.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final theme = ref.watch(activeThemePaletteProvider);

    final minutes = gameState.elapsedSeconds ~/ 60;
    final seconds = gameState.elapsedSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipAnimation,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final scale = _scaleAnimation.value.clamp(0.0, 1.0);
                final starsProgress = _starsAnimation.value;
                final earnedCoins = _coinsAnimation.value;

                return Transform.scale(
                  scale: scale <= 0.01 ? 1.0 : scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: UIGradients.glassCardGradient(theme),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.secondaryAccent.withValues(alpha: 0.7),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.secondaryAccent.withValues(alpha: 0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                        const BoxShadow(
                          color: Colors.black87,
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy with glowing aura
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.secondaryAccent.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 54,
                          color: theme.secondaryAccent,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Gradient Victory Title
                      const GradientText(
                        'LEVEL COMPLETE!',
                        gradient: UIGradients.victoryGradient,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Animated 3 Stars Count-Up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (starIdx) {
                          final starThreshold = (starIdx + 1) / 3.0;
                          final isStarActive = starsProgress >= starThreshold;
                          final starScale = isStarActive
                              ? (1.0 + 0.2 * sin((starsProgress - starThreshold) * pi * 4).clamp(0.0, 1.0))
                              : 0.8;

                          return Transform.scale(
                            scale: starScale,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                isStarActive ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: isStarActive ? theme.secondaryAccent : Colors.white24,
                                size: 36,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Stats Row + Animated Coin Roll
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.glassBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(theme, 'MOVES', '${gameState.moves}'),
                            Container(width: 1, height: 30, color: theme.glassBorder),
                            _buildStat(theme, 'TIME', timeStr),
                            Container(width: 1, height: 30, color: theme.glassBorder),
                            Column(
                              children: [
                                Text(
                                  'COINS',
                                  style: TextStyle(
                                    color: theme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.monetization_on_rounded,
                                        color: theme.secondaryAccent, size: 16),
                                    const SizedBox(width: 3),
                                    Text(
                                      '+$earnedCoins',
                                      style: TextStyle(
                                        color: theme.secondaryAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Replay & Next Buttons
                      Row(
                        children: [
                          // Replay
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('win_replay_button'),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('REPLAY'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.textBright,
                                side: BorderSide(color: theme.glassBorder),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => controller.restart(),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Next Level
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: UIGradients.buttonGradient(theme),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryAccent.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                key: const Key('win_next_button'),
                                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                                label: const Text(
                                  'NEXT',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  if (widget.onNextLevel != null) {
                                    widget.onNextLevel!();
                                  } else {
                                    const generator = PuzzleGenerator();
                                    final nextLevelNumber = gameState.levelNumber + 1;
                                    final tubeCount = nextLevelNumber <= 5
                                        ? 8
                                        : (nextLevelNumber <= 10 ? 12 : 16);
                                    final settings = GenerationSettings.forTubeCount(tubeCount);
                                    final nextLevel =
                                        generator.generate(1000 + nextLevelNumber, settings);
                                    controller.loadLevel(nextLevelNumber, nextLevel);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStat(ThemePalette theme, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.textBright,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
