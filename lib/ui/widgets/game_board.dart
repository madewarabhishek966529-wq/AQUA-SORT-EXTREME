import 'dart:math';
import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/pour_event.dart';
import '../../motion/effects_layer.dart';
import '../../motion/motion_budget_service.dart';
import '../../motion/motion_tokens.dart';
import '../../motion/particle_system.dart';
import '../../motion/pour_animation_controller.dart';
import '../../services/audio_service.dart';
import '../../services/settings_service.dart';
import '../../theme/aqua_palette.dart';
import '../../theme/gradients.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tube_skins.dart';
import '../painters/tube_painter.dart';

/// Central game board displaying test tubes with layered animations,
/// ambient mesh gradients, smart motion budgeting, pooled particles,
/// and accessible visual cues.
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
  late final PourAnimationController _pourController;
  late final AnimationController _shakeAnimController;
  late final AnimationController _ambientLoopController;
  late final AnimationController _entranceAnimController;
  late final TransformationController _transformController;
  late final FocusNode _focusNode;

  late final ParticlePool _particlePool;
  late final MotionBudgetService _budgetService;

  final Map<int, GlobalKey> _tubeKeys = {};
  final Set<int> _completedTubes = {};
  final Map<int, double> _completionSweepProgress = {};

  PourEvent? _lastHandledPourEvent;
  int _focusedIndex = 0;
  bool _hasKeyboardFocus = false;
  int _prevMoves = 0;
  TimingsCallback? _timingsCallback;

  @override
  void initState() {
    super.initState();

    _transformController = TransformationController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _hasKeyboardFocus = _focusNode.hasFocus);
      }
    });

    _particlePool = ParticlePool(maxCapacity: 160);
    _budgetService = MotionBudgetService();

    // Pour sequence controller
    _pourController = PourAnimationController(vsync: this);
    _pourController.addListener(() {
      if (mounted) setState(() {});
    });

    // Invalid shake animation: 250ms
    _shakeAnimController = AnimationController(
      vsync: this,
      duration: MotionTokens.invalidShake,
    );
    _shakeAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(gameControllerProvider.notifier).clearShaking();
        _shakeAnimController.reset();
      }
    });

    // Ambient loop: 14 seconds looping for drifting mesh, surface waves, particle updates
    _ambientLoopController = AnimationController(
      vsync: this,
      duration: MotionTokens.meshDriftPeriod,
    );
    _ambientLoopController.addListener(_onAmbientTick);

    // Staggered entrance cascade controller
    _entranceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Register real frame timing monitoring from Flutter engine
    _timingsCallback = (List<FrameTiming> timings) {
      if (!mounted) return;
      for (final timing in timings) {
        final frameMs = timing.totalSpan.inMicroseconds / 1000.0;
        _budgetService.recordFrameTime(frameMs);
      }
    };
    SchedulerBinding.instance.addTimingsCallback(_timingsCallback!);

    // Start controllers if motion is active
    if (!widget.reducedMotion) {
      _ambientLoopController.repeat();
      _entranceAnimController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _ambientLoopController.stop();
        _particlePool.clear();
      } else {
        _ambientLoopController.repeat();
      }
    }
  }

  @override
  void dispose() {
    if (_timingsCallback != null) {
      SchedulerBinding.instance.removeTimingsCallback(_timingsCallback!);
    }
    _pourController.dispose();
    _shakeAnimController.dispose();
    _ambientLoopController.dispose();
    _entranceAnimController.dispose();
    _transformController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onAmbientTick() {
    if (!mounted) return;
    if (_particlePool.activeCount > 0) {
      _particlePool.update(0.016); // ~60fps simulation delta
      setState(() {});
    }
  }

  void _skipAnimation() {
    if (_pourController.isAnimating) {
      _pourController.fastForward();
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
      setState(() => _focusedIndex = (_focusedIndex + 1) % tubeCount);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() => _focusedIndex = (_focusedIndex - 1 + tubeCount) % tubeCount);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final cols = _calculateColumnCount(tubeCount);
      setState(() => _focusedIndex = (_focusedIndex + cols) % tubeCount);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final cols = _calculateColumnCount(tubeCount);
      setState(() => _focusedIndex = (_focusedIndex - cols + tubeCount) % tubeCount);
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

    setState(() => _focusedIndex = index);

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

  void _checkTubeCompletions(PuzzleState puzzleState, ThemePalette theme, MotionQualityProfile profile) {
    for (var i = 0; i < puzzleState.tubeCount; i++) {
      final tube = puzzleState.tubes[i];
      final isComplete = tube.isComplete;

      if (isComplete && !_completedTubes.contains(i)) {
        _completedTubes.add(i);
        // Trigger completion sparkle burst and lock sweep if motion enabled
        if (!profile.isStatic && profile.maxParticles > 0) {
          final tubeKey = _tubeKeys[i];
          final context = tubeKey?.currentContext;
          if (context != null) {
            final box = context.findRenderObject() as RenderBox?;
            final boardBox = this.context.findRenderObject() as RenderBox?;
            if (box != null && boardBox != null) {
              final lipPos = boardBox.globalToLocal(
                box.localToGlobal(Offset(box.size.width / 2, 0)),
              );
              final color = theme.getLiquidColor(tube.units.first).base;
              _particlePool.emitTubeCompletionBurst(lipPos, color, min(14, profile.maxParticles ~/ 4));
            }
          }
        }
      } else if (!isComplete && _completedTubes.contains(i)) {
        _completedTubes.remove(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final settingsService = ref.watch(settingsServiceProvider);
    final settings = settingsService.settings;
    final theme = ref.watch(activeThemePaletteProvider);
    final skin = ref.watch(activeTubeSkinProvider);

    final puzzleState = gameState.puzzleState;
    final tubeCount = puzzleState.tubeCount;

    // Evaluate dynamic motion quality budget
    final motionProfile = _budgetService.evaluate(
      tubeCount: tubeCount,
      animationIntensity: settings.animationIntensity,
      reducedMotion: settings.reducedMotion,
    );

    // Stop ambient controller if static mode requested
    if (motionProfile.isStatic && _ambientLoopController.isAnimating) {
      _ambientLoopController.stop();
      _particlePool.clear();
    } else if (!motionProfile.isStatic && !_ambientLoopController.isAnimating) {
      _ambientLoopController.repeat();
    }

    // Handle incoming PourEvent via PourAnimationController
    if (gameState.activePourEvent != null &&
        gameState.activePourEvent != _lastHandledPourEvent) {
      final event = gameState.activePourEvent!;
      _lastHandledPourEvent = event;
      final isUndo = gameState.moves < _prevMoves;
      _prevMoves = gameState.moves;

      // Start pour sequence
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pourController.startPour(
          event,
          intensity: settings.animationIntensity,
          reducedMotion: settings.reducedMotion,
          isUndo: isUndo,
          onComplete: () {
            ref.read(gameControllerProvider.notifier).unlockInput();
          },
        );

        // Spawn splash droplets at destination lip if motion enabled
        if (!motionProfile.isStatic && motionProfile.maxParticles > 0) {
          final toKey = _tubeKeys[event.to];
          final box = toKey?.currentContext?.findRenderObject() as RenderBox?;
          final boardBox = context.findRenderObject() as RenderBox?;
          if (box != null && boardBox != null) {
            final toLip = boardBox.globalToLocal(
              box.localToGlobal(Offset(box.size.width / 2, 0)),
            );
            final color = theme.getLiquidColor(event.color).base;
            _particlePool.emitPourSplash(toLip, color, min(8, motionProfile.maxParticles ~/ 6));
          }
        }
      });
    }

    // Trigger shake animation if shakingTubeIndex is set
    if (gameState.shakingTubeIndex != null && !_shakeAnimController.isAnimating) {
      _shakeAnimController.forward(from: 0.0);
    }

    // Trigger win celebratory confetti
    if (gameState.isWon && _particlePool.activeCount == 0 && !motionProfile.isStatic) {
      widget.audioService.playVictory();
      final size = MediaQuery.of(context).size;
      final colors = theme.standardLiquidColors.map((c) => c.base).toList();
      _particlePool.emitWinConfetti(size, colors, min(75, motionProfile.maxParticles));
    }

    // Check newly completed tubes
    _checkTubeCompletions(puzzleState, theme, motionProfile);

    // Calculate valid destination tubes
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
          if (move != null) validDestinations.add(i);
        }
      }
    }

    final (tubeWidth, tubeHeight) = _getTubeDimensions(tubeCount);
    final tubeSpacing = tubeCount > 24 ? 10.0 : 16.0;
    final tubeRunSpacing = tubeCount > 24 ? 16.0 : 24.0;

    // Stream coordinates for EffectsLayer
    Offset? streamStart;
    Offset? streamEnd;
    int? streamColorId;

    if (_pourController.isAnimating && _pourController.activeEvent != null) {
      final event = _pourController.activeEvent!;
      streamColorId = event.color;
      final fromKey = _tubeKeys[event.from];
      final toKey = _tubeKeys[event.to];

      final boardBox = context.findRenderObject() as RenderBox?;
      final fromBox = fromKey?.currentContext?.findRenderObject() as RenderBox?;
      final toBox = toKey?.currentContext?.findRenderObject() as RenderBox?;

      if (boardBox != null && fromBox != null && toBox != null) {
        streamStart = boardBox.globalToLocal(
          fromBox.localToGlobal(Offset(fromBox.size.width / 2, 0)),
        );
        streamEnd = boardBox.globalToLocal(
          toBox.localToGlobal(Offset(toBox.size.width / 2, 0)),
        );
      }
    }

    // Hint path coordinates
    Offset? hintSourcePos;
    Offset? hintTargetPos;
    if (gameState.hintMove != null) {
      final fromKey = _tubeKeys[gameState.hintMove!.from];
      final toKey = _tubeKeys[gameState.hintMove!.to];
      final boardBox = context.findRenderObject() as RenderBox?;
      final fromBox = fromKey?.currentContext?.findRenderObject() as RenderBox?;
      final toBox = toKey?.currentContext?.findRenderObject() as RenderBox?;

      if (boardBox != null && fromBox != null && toBox != null) {
        hintSourcePos = boardBox.globalToLocal(
          fromBox.localToGlobal(Offset(fromBox.size.width / 2, 0)),
        );
        hintTargetPos = boardBox.globalToLocal(
          toBox.localToGlobal(Offset(toBox.size.width / 2, 0)),
        );
      }
    }

    final ambientProgress = _ambientLoopController.value;
    final wavePhase = ambientProgress * 2 * pi * 4;
    final bubbleTime = ambientProgress * 14.0;
    final entranceVal = motionProfile.isStatic ? 1.0 : _entranceAnimController.value;

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
            // 1. Slow animated drifting background gradient mesh
            Positioned.fill(
              child: CustomPaint(
                painter: MeshGradientPainter(
                  theme: theme,
                  animationProgress: ambientProgress,
                  isStatic: motionProfile.isStatic || !motionProfile.ambientBackgroundEnabled,
                ),
              ),
            ),

            // 2. Pan & Zoomable Tubes Board
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
                      _pourController,
                      _shakeAnimController,
                      _ambientLoopController,
                      _entranceAnimController,
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
                            glowColor = theme.primaryAccent;
                          } else if (isHintFrom) {
                            glowColor = theme.secondaryAccent;
                          } else if (isHintTo) {
                            glowColor = const Color(0xFF00E676);
                          }

                          // Calculate shake offset
                          var shakeOffset = 0.0;
                          if (isShaking && _shakeAnimController.isAnimating) {
                            shakeOffset = sin(_shakeAnimController.value * pi * 4) * 8.0;
                          }

                          // Calculate lift & tilt from PourAnimationController
                          var liftOffset = 0.0;
                          var tiltAngle = 0.0;

                          if (isSelected || isHintFrom) {
                            liftOffset = -18.0;
                          } else if (_pourController.isAnimating &&
                              _pourController.activeEvent?.from == index) {
                            liftOffset = _pourController.liftOffset;
                            tiltAngle = _pourController.tiltAngle;
                          }

                          // Staggered cascade entrance delay per tube
                          var entranceY = 0.0;
                          var entranceOpacity = 1.0;
                          if (!motionProfile.isStatic && entranceVal < 1.0) {
                            final delay = (index * 0.015).clamp(0.0, 0.60);
                            final t = ((entranceVal - delay) / (1.0 - delay)).clamp(0.0, 1.0);
                            entranceY = (1.0 - MotionTokens.springEase.transform(t)) * 40.0;
                            entranceOpacity = t;
                          }

                          // Subtle idle tube breathing (0.5% scale oscillation)
                          var scale = 1.0;
                          if (!motionProfile.isStatic &&
                              !isSelected &&
                              !_pourController.isAnimating &&
                              tubeCount <= 30) {
                            scale = 1.0 + 0.005 * sin(ambientProgress * 2 * pi + index * 0.4);
                          }

                          return Transform.translate(
                            offset: Offset(shakeOffset, liftOffset + entranceY),
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: entranceOpacity,
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
                                          shakeOffset: shakeOffset,
                                          tiltAngle: tiltAngle,
                                          glowColor: glowColor,
                                          theme: theme,
                                          skin: skin,
                                          wavePhase: wavePhase,
                                          waveAmplitude: motionProfile.waveAnimationEnabled ? 1.4 : 0.0,
                                          enableBubbles: motionProfile.bubblesEnabled,
                                          bubbleTime: bubbleTime,
                                        ),
                                      ),
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

            // 3. Effects Layer (Fluid Stream, Droplets, Splashes, Confetti, Hint Path)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _pourController,
                  _ambientLoopController,
                ]),
                builder: (context, _) {
                  return EffectsLayer(
                    particlePool: _particlePool,
                    pourController: _pourController,
                    sourceLipPosition: streamStart,
                    targetLipPosition: streamEnd,
                    streamColorId: streamColorId,
                    theme: theme,
                    hintSourcePos: hintSourcePos,
                    hintTargetPos: hintTargetPos,
                    hintPulseProgress: (ambientProgress * 3.5) % 1.0,
                  );
                },
              ),
            ),

            // 4. Floating Zoom & Pan Controls
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  gradient: UIGradients.glassCardGradient(theme),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.glassBorder),
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
                      icon: Icon(Icons.remove_rounded, color: theme.textBright, size: 18),
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
                          color: theme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '100%',
                          style: TextStyle(
                            color: theme.primaryAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('zoom_in_button'),
                      icon: Icon(Icons.add_rounded, color: theme.textBright, size: 18),
                      tooltip: 'Zoom In',
                      onPressed: () => _zoom(1.18),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),

            // 5. Debug Motion Budget Overlay (when enabled in settings)
            if (settings.showMotionDebugOverlay)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.primaryAccent, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MOTION BUDGET',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            motionProfile.quality.name.toUpperCase(),
                            style: TextStyle(
                              color: theme.primaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avg Frametime: ${_budgetService.averageFrameTimeMs.toStringAsFixed(1)} ms',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      Text(
                        'Tubes: $tubeCount | Max Particles: ${motionProfile.maxParticles}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      Text(
                        'Bubbles: ${motionProfile.bubblesEnabled} | Waves: ${motionProfile.waveAnimationEnabled}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      Text(
                        'Ambient: ${motionProfile.ambientBackgroundEnabled} | Static: ${motionProfile.isStatic}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
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
