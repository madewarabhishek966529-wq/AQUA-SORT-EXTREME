import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/pour_event.dart';
import '../painters/liquid_stream_painter.dart';
import '../painters/tube_painter.dart';
import '../painters/win_particle_painter.dart';
import '../theme/game_theme.dart';

/// Central game board displaying test tubes, handling player gestures,
/// and coordinating pour, shake, and win animations.
class GameBoard extends ConsumerStatefulWidget {
  const GameBoard({super.key});

  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard>
    with TickerProviderStateMixin {
  late final AnimationController _pourAnimController;
  late final AnimationController _shakeAnimController;
  late final AnimationController _winAnimController;

  final Map<int, GlobalKey> _tubeKeys = {};
  PourEvent? _currentAnimatingPour;
  List<Particle>? _winParticles;

  @override
  void initState() {
    super.initState();

    // Pour animation controller: 400ms total
    _pourAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pourAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishPourAnimation();
      }
    });

    // Invalid shake animation: 250ms
    _shakeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _shakeAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(gameControllerProvider.notifier).clearShaking();
        _shakeAnimController.reset();
      }
    });

    // Victory celebration animation: 1800ms
    _winAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _pourAnimController.dispose();
    _shakeAnimController.dispose();
    _winAnimController.dispose();
    super.dispose();
  }

  void _finishPourAnimation() {
    _pourAnimController.reset();
    _currentAnimatingPour = null;
    ref.read(gameControllerProvider.notifier).unlockInput();
  }

  /// Skipping animation on tap
  void _skipAnimation() {
    if (_pourAnimController.isAnimating) {
      _pourAnimController.stop();
      _finishPourAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    // Trigger pour animation if new pour event emitted
    if (gameState.activePourEvent != null &&
        gameState.activePourEvent != _currentAnimatingPour) {
      _currentAnimatingPour = gameState.activePourEvent;
      _pourAnimController.forward(from: 0.0);
    }

    // Trigger shake animation if shakingTubeIndex is set
    if (gameState.shakingTubeIndex != null && !_shakeAnimController.isAnimating) {
      _shakeAnimController.forward(from: 0.0);
    }

    // Trigger win animation when won
    if (gameState.isWon && !_winAnimController.isAnimating && _winParticles == null) {
      final size = MediaQuery.of(context).size;
      _winParticles = WinParticlePainter.createExplosion(size, count: 90);
      _winAnimController.repeat();
    } else if (!gameState.isWon && _winParticles != null) {
      _winParticles = null;
      _winAnimController.stop();
    }

    final puzzleState = gameState.puzzleState;
    final tubeCount = puzzleState.tubeCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Tapping while pouring skips animation immediately
        if (gameState.isInputLocked) {
          _skipAnimation();
        }
      },
      child: Stack(
        children: [
          // Background subtle ambient radial glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF162238),
                    GameTheme.backgroundDark,
                  ],
                ),
              ),
            ),
          ),

          // Tubes Grid
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: AnimatedBuilder(
                animation: Listenable.merge([_pourAnimController, _shakeAnimController]),
                builder: (context, _) {
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16.0,
                    runSpacing: 24.0,
                    children: List.generate(tubeCount, (index) {
                      _tubeKeys.putIfAbsent(index, GlobalKey.new);
                      final tube = puzzleState.tubes[index];
                      final isSelected = gameState.selectedTubeIndex == index;
                      final isShaking = gameState.shakingTubeIndex == index;
                      final isHintFrom = gameState.hintMove?.from == index;
                      final isHintTo = gameState.hintMove?.to == index;

                      Color? glowColor;
                      if (isSelected) {
                        glowColor = GameTheme.primaryCyan;
                      } else if (isHintFrom) {
                        glowColor = GameTheme.accentGold;
                      } else if (isHintTo) {
                        glowColor = GameTheme.accentGreen;
                      }

                      // Calculate shake horizontal offset
                      var shakeOffset = 0.0;
                      if (isShaking && _shakeAnimController.isAnimating) {
                        shakeOffset = sin(_shakeAnimController.value * pi * 4) * 8.0;
                      }

                      // Calculate pour animation properties
                      var liftOffset = 0.0;
                      var tiltAngle = 0.0;

                      if (isSelected || isHintFrom) {
                        liftOffset = -18.0; // Selected or hint lift
                      } else if (_currentAnimatingPour != null &&
                          _currentAnimatingPour!.from == index) {
                        final animVal = _pourAnimController.value;
                        // Lift and tilt curve
                        liftOffset = -22.0 * sin(animVal * pi);
                        final tiltDir = _currentAnimatingPour!.to > _currentAnimatingPour!.from ? 1.0 : -1.0;
                        tiltAngle = 0.45 * sin(animVal * pi) * tiltDir;
                      }

                      return Transform.translate(
                        offset: Offset(shakeOffset, liftOffset),
                        child: RepaintBoundary(
                          key: Key('tube_boundary_$index'),
                          child: GestureDetector(
                            key: Key('tube_$index'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (gameState.isInputLocked) {
                                _skipAnimation();
                              } else {
                                controller.selectTube(index);
                              }
                            },
                            child: SizedBox(
                              key: _tubeKeys[index],
                              width: 52,
                              height: 148,
                              child: CustomPaint(
                                painter: TubePainter(
                                  tube: tube,
                                  isSelected: isSelected || isHintFrom || isHintTo,
                                  glowColor: glowColor,
                                  shakeOffset: shakeOffset,
                                  tiltAngle: tiltAngle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),

          // Liquid Pouring Stream Overlay
          if (_currentAnimatingPour != null && _pourAnimController.isAnimating)
            AnimatedBuilder(
              animation: _pourAnimController,
              builder: (context, _) {
                final fromKey = _tubeKeys[_currentAnimatingPour!.from];
                final toKey = _tubeKeys[_currentAnimatingPour!.to];

                if (fromKey?.currentContext == null || toKey?.currentContext == null) {
                  return const SizedBox.shrink();
                }

                final renderBoxBoard = context.findRenderObject() as RenderBox?;
                final fromBox = fromKey!.currentContext!.findRenderObject() as RenderBox?;
                final toBox = toKey!.currentContext!.findRenderObject() as RenderBox?;

                if (renderBoxBoard == null || fromBox == null || toBox == null) {
                  return const SizedBox.shrink();
                }

                final fromOrigin = renderBoxBoard.globalToLocal(fromBox.localToGlobal(Offset.zero));
                final toOrigin = renderBoxBoard.globalToLocal(toBox.localToGlobal(Offset.zero));

                final startOffset = Offset(
                  fromOrigin.dx + (fromBox.size.width / 2) + (_currentAnimatingPour!.to > _currentAnimatingPour!.from ? 18 : -18),
                  fromOrigin.dy + 8,
                );
                final endOffset = Offset(
                  toOrigin.dx + (toBox.size.width / 2),
                  toOrigin.dy + 12,
                );

                return CustomPaint(
                  size: Size.infinite,
                  painter: LiquidStreamPainter(
                    startOffset: startOffset,
                    endOffset: endOffset,
                    colorId: _currentAnimatingPour!.color,
                    progress: sin(_pourAnimController.value * pi),
                  ),
                );
              },
            ),

          // Victory Confetti & Particle Layer
          if (gameState.isWon && _winParticles != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _winAnimController,
                  builder: (context, _) {
                    // Update particle physics
                    for (final p in _winParticles!) {
                      p.x += p.vx;
                      p.y += p.vy;
                      p.vy += 0.25; // gravity
                      p.rotation += p.rotationSpeed;
                    }

                    return CustomPaint(
                      size: Size.infinite,
                      painter: WinParticlePainter(
                        particles: _winParticles!,
                        animationProgress: _winAnimController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
