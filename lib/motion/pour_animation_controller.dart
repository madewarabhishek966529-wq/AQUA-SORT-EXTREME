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
      duration: MotionTokens.pourStream,
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
      _controller.value = 1.0;
      onComplete?.call();
      notifyListeners();
      return;
    }

    // Base duration scales with unit count: 320ms base + 40ms per unit above 1 (max 380ms)
    final baseDurationMs = (320 + (event.count - 1) * 30).clamp(280, 380);
    final speedMultiplier = isUndo ? (1.0 / 1.5) : 1.0; // 1.5x speed on undo

    final effectiveMs = (baseDurationMs * intensity * speedMultiplier).round();
    _controller.duration = Duration(milliseconds: max(80, effectiveMs));

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
    if (v < 0.18) {
      _phase = PourPhase.lift;
    } else if (v < 0.42) {
      _phase = PourPhase.tilt;
    } else if (v < 0.82) {
      _phase = PourPhase.stream;
    } else {
      _phase = PourPhase.settle;
    }
    notifyListeners();
  }

  /// Current lift offset in pixels for the pouring source tube.
  double get liftOffset {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;

    if (v < 0.20) {
      // Lift with spring ease
      final t = v / 0.20;
      return -22.0 * MotionTokens.springEase.transform(t);
    } else if (v < 0.80) {
      // Maintained elevated height during pour
      return -22.0;
    } else {
      // Settle back down with bounce
      final t = (v - 0.80) / 0.20;
      return -22.0 * (1.0 - MotionTokens.springEase.transform(t));
    }
  }

  /// Current tilt angle in radians for the pouring source tube.
  double get tiltAngle {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    final direction = _activeEvent!.to > _activeEvent!.from ? 1.0 : -1.0;
    const maxTilt = 0.52; // ~30 degrees

    if (v < 0.18) {
      return 0.0;
    } else if (v < 0.42) {
      // Tilt with overshoot
      final t = (v - 0.18) / 0.24;
      return direction * maxTilt * MotionTokens.easeOutBack.transform(t);
    } else if (v < 0.80) {
      return direction * maxTilt;
    } else {
      // Return with smooth settle
      final t = (v - 0.80) / 0.20;
      return direction * maxTilt * (1.0 - MotionTokens.springEase.transform(t));
    }
  }

  /// Progress (0.0 to 1.0) of liquid drain from the source tube.
  double get drainProgress {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    if (v < 0.40) return 0.0;
    if (v >= 0.80) return 1.0;
    return (v - 0.40) / 0.40;
  }

  /// Progress (0.0 to 1.0) of liquid fill in the target tube.
  double get fillProgress {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    // Slight fluid travel delay between drain and fill
    if (v < 0.45) return 0.0;
    if (v >= 0.82) return 1.0;
    return (v - 0.45) / 0.37;
  }

  /// Progress of the connecting fluid stream (0.0 to 1.0).
  double get streamProgress {
    if (!isAnimating || _activeEvent == null) return 0.0;
    final v = _controller.value;
    if (v < 0.38) return 0.0;
    if (v > 0.82) return 0.0; // Stream snaps off before settle

    if (v < 0.45) {
      // Stream extending
      return (v - 0.38) / 0.07;
    } else if (v < 0.76) {
      return 1.0;
    } else {
      // Stream cutting off
      return 1.0 - ((v - 0.76) / 0.06);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }
}
