import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/pour_event.dart';
import '../../services/audio_service.dart';
import '../painters/liquid_stream_painter.dart';
import '../painters/tube_painter.dart';
import '../painters/win_particle_painter.dart';
import '../theme/game_theme.dart';

/// Central game board displaying test tubes, handling player gestures,
/// coordinating pour/shake/win animations, keyboard navigation,
/// adaptive scaling, zoom controls, and accessibility cues.
class GameBoard extends ConsumerStatefulWidget {
  final bool showColorblindCues;
  final bool colorblindPalette;
  final bool reducedMotion;
  final AudioService audioService;

  const GameBoard({
    super.key,
    this.showColorblindCues = false,
    this.colorblindPalette = false,
    this.reducedMotion = false,
    this.audioService = const AudioService(),
  });

  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard>
    with TickerProviderStateMixin {
  late final AnimationController _pourAnimController;
  late final AnimationController _shakeAnimController;
  late final AnimationController _winAnimController;
  late final TransformationController _transformController;
  late final FocusNode _focusNode;

  final Map<int, GlobalKey> _tubeKeys = {};
  PourEvent? _currentAnimatingPour;
  List<Particle>? _winParticles;
  int _focusedIndex = 0;
  bool _hasKeyboardFocus = false;

  @override
  void initState() {
    super.initState();

    _transformController = TransformationController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _hasKeyboardFocus = _focusNode.hasFocus;
        });
      }
    });

    // Pour animation controller: 400ms total (or 200ms if reduced motion)
    final pourDuration = widget.reducedMotion
        ? const Duration(milliseconds: 150)
        : const Duration(milliseconds: 400);

    _pourAnimController = AnimationController(
      vsync: this,
      duration: pourDuration,
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
    _transformController.dispose();
    _focusNode.dispose();
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

  void _zoom(double factor) {
    final matrix = _transformController.value.clone();
    matrix.scaleByDouble(factor, factor, 1.0, 1.0);
    _transformController.value = matrix;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final gameState = ref.read(gameControllerProvider);
    final tubeCount = gameState.puzzleState.tubeCount;
    final controller = ref.read(gameControllerProvider.notifier);

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _focusedIndex = (_focusedIndex + 1) % tubeCount;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _focusedIndex = (_focusedIndex - 1 + tubeCount) % tubeCount;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final cols = _calculateColumnCount(tubeCount);
      setState(() {
        _focusedIndex = (_focusedIndex + cols) % tubeCount;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final cols = _calculateColumnCount(tubeCount);
      setState(() {
        _focusedIndex = (_focusedIndex - cols + tubeCount) % tubeCount;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _onTubeTapped(_focusedIndex);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyU ||
        (event.logicalKey == LogicalKeyboardKey.keyZ &&
            HardwareKeyboard.instance.isControlPressed)) {
      widget.audioService.playUndo();
      controller.undo();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
      widget.audioService.playSelect();
      controller.restart();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
      widget.audioService.playHint();
      controller.requestHint();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  int _calculateColumnCount(int tubeCount) {
    if (tubeCount <= 8) return 4;
    if (tubeCount <= 14) return 7;
    if (tubeCount <= 24) return 8;
    if (tubeCount <= 42) return 10;
    return 12;
  }

  void _onTubeTapped(int index) {
    final gameState = ref.read(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    setState(() {
      _focusedIndex = index;
    });

    if (gameState.isInputLocked) {
      _skipAnimation();
      return;
    }

    if (gameState.selectedTubeIndex == null) {
      if (gameState.puzzleState.tubes[index].isEmpty) {
        widget.audioService.playInvalid();
      } else {
        widget.audioService.playSelect();
      }
    } else if (gameState.selectedTubeIndex == index) {
      widget.audioService.playSelect();
    } else {
      // Pour attempt
      final move = controller.validator.calculateMove(
        gameState.puzzleState,
        gameState.selectedTubeIndex!,
        index,
      );
      if (move != null) {
        widget.audioService.playPour();
      } else {
        widget.audioService.playInvalid();
      }
    }

    controller.selectTube(index);
  }

  (double, double) _getTubeDimensions(int tubeCount) {
    if (tubeCount <= 12) return (52.0, 148.0);
    if (tubeCount <= 24) return (46.0, 134.0);
    if (tubeCount <= 42) return (40.0, 118.0);
    return (34.0, 102.0); // 50 to 60+ tubes
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final puzzleState = gameState.puzzleState;
    final tubeCount = puzzleState.tubeCount;

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
      widget.audioService.playVictory();
      if (!widget.reducedMotion) {
        final size = MediaQuery.of(context).size;
        _winParticles = WinParticlePainter.createExplosion(size, count: 90);
        _winAnimController.repeat();
      }
    } else if (!gameState.isWon && _winParticles != null) {
      _winParticles = null;
      _winAnimController.stop();
    }

    // Calculate valid destination tubes when a tube is currently selected
    final validDestinations = <int>{};
    if (gameState.selectedTubeIndex != null) {
      final controller = ref.read(gameControllerProvider.notifier);
      for (var i = 0; i < tubeCount; i++) {
        if (i != gameState.selectedTubeIndex) {
          final move = controller.validator.calculateMove(
            puzzleState,
            gameState.selectedTubeIndex!,
            i,
          );
          if (move != null) {
            validDestinations.add(i);
          }
        }
      }
    }

    final (tubeWidth, tubeHeight) = _getTubeDimensions(tubeCount);
    final tubeSpacing = tubeCount > 24 ? 10.0 : 16.0;
    final tubeRunSpacing = tubeCount > 24 ? 16.0 : 24.0;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focusNode.requestFocus();
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

            // Pan & Zoomable Tubes Board
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(120),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _pourAnimController,
                      _shakeAnimController,
                    ]),
                    builder: (context, _) {
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: tubeSpacing,
                        runSpacing: tubeRunSpacing,
                        children: List.generate(tubeCount, (index) {
                          _tubeKeys.putIfAbsent(index, GlobalKey.new);
                          final tube = puzzleState.tubes[index];
                          final isSelected = gameState.selectedTubeIndex == index;
                          final isShaking = gameState.shakingTubeIndex == index;
                          final isHintFrom = gameState.hintMove?.from == index;
                          final isHintTo = gameState.hintMove?.to == index;
                          final isValidDest = validDestinations.contains(index);
                          final isFocused = _hasKeyboardFocus && _focusedIndex == index;

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
                            liftOffset = -18.0;
                          } else if (_currentAnimatingPour != null &&
                              _currentAnimatingPour!.from == index) {
                            final animVal = _pourAnimController.value;
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
                                onTap: () => _onTubeTapped(index),
                                child: SizedBox(
                                  key: _tubeKeys[index],
                                  width: tubeWidth,
                                  height: tubeHeight,
                                  child: CustomPaint(
                                    painter: TubePainter(
                                      tube: tube,
                                      isSelected: isSelected || isHintFrom || isHintTo,
                                      isFocused: isFocused,
                                      isValidDestination: isValidDest,
                                      showColorblindCues: widget.showColorblindCues,
                                      colorblindPalette: widget.colorblindPalette,
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

                  final fromPos = renderBoxBoard.globalToLocal(
                    fromBox.localToGlobal(Offset(fromBox.size.width / 2, 0)),
                  );
                  final toPos = renderBoxBoard.globalToLocal(
                    toBox.localToGlobal(Offset(toBox.size.width / 2, 0)),
                  );

                  return CustomPaint(
                    size: Size.infinite,
                    painter: LiquidStreamPainter(
                      startOffset: fromPos,
                      endOffset: toPos,
                      colorId: _currentAnimatingPour!.color,
                      progress: _pourAnimController.value,
                    ),
                  );
                },
              ),

            // Victory Particles Overlay
            if (_winParticles != null && !widget.reducedMotion)
              AnimatedBuilder(
                animation: _winAnimController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: WinParticlePainter(
                      particles: _winParticles!,
                      animationProgress: _winAnimController.value,
                    ),
                  );
                },
              ),

            // Floating Zoom & Pan Controls
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: GameTheme.surfaceDark.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GameTheme.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('zoom_out_button'),
                      icon: const Icon(Icons.remove_rounded, color: GameTheme.textBright, size: 18),
                      tooltip: 'Zoom Out',
                      onPressed: () => _zoom(0.85),
                      visualDensity: VisualDensity.compact,
                    ),
                    GestureDetector(
                      key: const Key('zoom_reset_button'),
                      onTap: _resetZoom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: GameTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '100%',
                          style: TextStyle(
                            color: GameTheme.primaryCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('zoom_in_button'),
                      icon: const Icon(Icons.add_rounded, color: GameTheme.textBright, size: 18),
                      tooltip: 'Zoom In',
                      onPressed: () => _zoom(1.18),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
