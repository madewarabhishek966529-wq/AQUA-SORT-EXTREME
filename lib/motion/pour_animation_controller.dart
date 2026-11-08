import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../controllers/pour_event.dart';
import 'motion_tokens.dart';

/// Discrete phases of a single pour sequence.
enum PourPhase {
  idle,
  lift,
  tilt,
  stream,
  settle,
}

/// Reusable controller orchestrating the 5-phase pour animation sequence per move.
class PourAnimationController extends ChangeNotifier {
  final TickerProvider vsync;
  late final AnimationController _controller;

  PourEvent? _activeEvent;
  PourPhase _phase = PourPhase.idle;
  VoidCallback? _onCompleted;
  bool _isUndo = false;

  PourAnimationController({required this.vsync}) {
    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 650),
    );

    _controller.addListener(_onTick);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finish();
      }
    });
  }

  PourEvent? get activeEvent => _activeEvent;
  PourPhase get phase => _phase;
  bool get isAnimating => _controller.isAnimating;
  double get value => _controller.value;
  bool get isUndo => _isUndo;

  /// Starts a pour animation for [event].
  void startPour(
    PourEvent event, {
    double intensity = 1.0,
    bool reducedMotion = false,
    bool isUndo = false,
    VoidCallback? onComplete,
  }) {
    _activeEvent = event;
    _onCompleted = onComplete;
    _isUndo = isUndo;

    // Instant completion on reduced motion or Off intensity
    if (reducedMotion || intensity <= 0.05) {
      _phase = PourPhase.idle;
      _activeEvent = null;
      _isUndo = false;
      scheduleMicrotask(() {
        onComplete?.call();
      });
      return;
    }

    // Rich, readable base duration scaling with unit count:
    // 620ms base + 50ms per unit above 1 (max 770ms)
    final baseDurationMs = (620 + (event.count - 1) * 50).clamp(550, 800);
    final speedMultiplier = isUndo ? (1.0 / 1.5) : 1.0; // 1.5x speed on undo

    final effectiveMs = (baseDurationMs * intensity * speedMultiplier).round();
    _controller.duration = Duration(milliseconds: max(100, effectiveMs));

    _phase = PourPhase.lift;
    _controller.forward(from: 0.0);
    notifyListeners();
  }

  /// Fast-forwards the current animation instantly to its final state.
  void fastForward() {
    if (!isAnimating && _activeEvent == null) return;

    _controller.stop();
    _controller.value = 1.0;
    _finish();
  }

  void _finish() {
    _phase = PourPhase.idle;
    final callback = _onCompleted;
    _onCompleted = null;
    _activeEvent = null;
    _isUndo = false;
    _controller.reset();
    callback?.call();
    notifyListeners();
  }

  void _onTick() {
    final v = _controller.value;
    if (v < 0.28) {
      _phase = PourPhase.lift;
    } else if (v < 0.38) {
      _phase = PourPhase.tilt;
    } else if (v < 0.78) {
      _phase = PourPhase.stream;
    } else {
      _phase = PourPhase.settle;
    }
    notifyListeners();
  }

  /// Progress (0.0 to 1.0) of bottle flight from home slot to target hover slot.
  double get flightProgress {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    if (v < 0.32) {
      // Traveling from home to target hover slot
      final t = v / 0.32;
      return Curves.easeOutCubic.transform(t);
    } else if (v < 0.76) {
      // Hovering at target
      return 1.0;
    } else {
      // Returning home
      final t = (v - 0.76) / 0.24;
      return 1.0 - MotionTokens.springEase.transform(t);
    }
  }

  /// Arc height offset in pixels to give a natural curved flight arc over other tubes.
  double get flightArcY {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    if (v < 0.32) {
      final t = v / 0.32;
      return -sin(t * pi) * 26.0;
    } else if (v < 0.76) {
      return 0.0;
    } else {
      final t = (v - 0.76) / 0.24;
      return -sin(t * pi) * 16.0;
    }
  }

  /// Current lift offset in pixels for the pouring source tube (fallback / home lift).
  double get liftOffset {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;

    if (v < 0.24) {
      // Lift with spring ease
      final t = v / 0.24;
      return -24.0 * MotionTokens.springEase.transform(t);
    } else if (v < 0.76) {
      // Maintained elevated height during pour
      return -24.0;
    } else {
      // Settle back down with bounce
      final t = (v - 0.76) / 0.24;
      return -24.0 * (1.0 - MotionTokens.springEase.transform(t));
    }
  }

  /// Current tilt angle in radians for the pouring source tube (~62 degrees).
  double get tiltAngle {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final direction = _activeEvent!.to >= _activeEvent!.from ? 1.0 : -1.0;
    return getTiltAngleForDirection(direction);
  }

  /// Calculate tilt angle given a specific flight direction sign (+1.0 for right, -1.0 for left).
  double getTiltAngleForDirection(double direction) {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    const maxTilt = 1.08; // ~62 degrees for realistic fluid discharge

    if (v < 0.16) {
      return 0.0;
    } else if (v < 0.35) {
      // Tilt with juicy overshoot
      final t = (v - 0.16) / 0.19;
      return direction * maxTilt * MotionTokens.easeOutBack.transform(t);
    } else if (v < 0.75) {
      // Sustained tilt during stream with micro-fluid oscillation
      final tStream = (v - 0.35) / 0.40;
      final microWobble = sin(tStream * pi * 4) * 0.025;
      return direction * (maxTilt + microWobble);
    } else {
      // Return with smooth settle
      final t = (v - 0.75) / 0.25;
      return direction * maxTilt * (1.0 - MotionTokens.springEase.transform(t));
    }
  }

  /// Progress (0.0 to 1.0) of liquid drain from the source tube.
  double get drainProgress {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    if (v < 0.32) return 0.0;
    if (v >= 0.74) return 1.0;
    return Curves.easeInOutQuad.transform((v - 0.32) / 0.42);
  }

  /// Progress (0.0 to 1.0) of liquid fill in the target tube.
  double get fillProgress {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    // Slight fluid flight delay before fill begins
    if (v < 0.36) return 0.0;
    if (v >= 0.76) return 1.0;
    return Curves.easeInOutQuad.transform((v - 0.36) / 0.40);
  }

  /// Progress of the connecting fluid stream (0.0 to 1.0).
  double get streamProgress {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    if (v < 0.28) return 0.0;
    if (v > 0.78) return 0.0; // Stream snaps off before return

    if (v < 0.36) {
      // Stream extending to target
      return (v - 0.28) / 0.08;
    } else if (v < 0.70) {
      return 1.0;
    } else {
      // Stream thinning & cutting off
      return 1.0 - ((v - 0.70) / 0.08);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }
}
