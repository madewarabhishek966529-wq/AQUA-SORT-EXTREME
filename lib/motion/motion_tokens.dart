import 'package:flutter/animation.dart';

/// Centralized motion design tokens: durations, easing curves, and scaling utilities.
class MotionTokens {
  // Base Durations
  static const Duration pourSelect = Duration(milliseconds: 160);
  static const Duration pourTilt = Duration(milliseconds: 220);
  static const Duration pourStream = Duration(milliseconds: 360);
  static const Duration pourReturn = Duration(milliseconds: 200);
  static const Duration invalidShake = Duration(milliseconds: 250);
  static const Duration tubeCompletion = Duration(milliseconds: 550);
  static const Duration levelWinCelebration = Duration(milliseconds: 1800);
  static const Duration staggeredDropDelay = Duration(milliseconds: 35);
  static const Duration ambientBreathPeriod = Duration(milliseconds: 3200);
  static const Duration meshDriftPeriod = Duration(milliseconds: 14000);
  static const Duration screenTransition = Duration(milliseconds: 280);

  // Curves
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve springEase = Curves.easeOutCubic;
  static const Curve bounceSettle = Curves.bounceOut;
  static const Curve fluidStream = Curves.easeInOutQuad;

  /// Scales a [base] duration according to [intensity] factor and [reducedMotion].
  /// Returns [Duration.zero] if reducedMotion is active or intensity is <= 0.05 (Off).
  static Duration scaleDuration(
    Duration base, {
    double intensity = 1.0,
    bool reducedMotion = false,
  }) {
    if (reducedMotion || intensity <= 0.05) {
      return Duration.zero;
    }
    final us = (base.inMicroseconds * intensity).round();
    return Duration(microseconds: us);
  }
}
