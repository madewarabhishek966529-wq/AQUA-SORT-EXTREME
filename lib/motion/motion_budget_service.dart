import 'dart:math';

/// Discrete quality tier for adaptive motion scaling.
enum MotionQualityLevel {
  low,
  medium,
  high,
}

/// Profile representing the active visual budget decisions.
class MotionQualityProfile {
  final MotionQualityLevel quality;
  final int maxParticles;
  final bool bubblesEnabled;
  final bool shaderEnabled;
  final bool ambientBackgroundEnabled;
  final bool waveAnimationEnabled;
  final double particleMultiplier;
  final bool isStatic;

  const MotionQualityProfile({
    required this.quality,
    required this.maxParticles,
    required this.bubblesEnabled,
    required this.shaderEnabled,
    required this.ambientBackgroundEnabled,
    required this.waveAnimationEnabled,
    required this.particleMultiplier,
    this.isStatic = false,
  });

  /// Static, instant profile used when reduced motion is requested or animation is Off.
  static const off = MotionQualityProfile(
    quality: MotionQualityLevel.low,
    maxParticles: 0,
    bubblesEnabled: false,
    shaderEnabled: false,
    ambientBackgroundEnabled: false,
    waveAnimationEnabled: false,
    particleMultiplier: 0.0,
    isStatic: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionQualityProfile &&
          runtimeType == other.runtimeType &&
          quality == other.quality &&
          maxParticles == other.maxParticles &&
          bubblesEnabled == other.bubblesEnabled &&
          shaderEnabled == other.shaderEnabled &&
          ambientBackgroundEnabled == other.ambientBackgroundEnabled &&
          waveAnimationEnabled == other.waveAnimationEnabled &&
          particleMultiplier == other.particleMultiplier &&
          isStatic == other.isStatic;

  @override
  int get hashCode => Object.hash(
        quality,
        maxParticles,
        bubblesEnabled,
        shaderEnabled,
        ambientBackgroundEnabled,
        waveAnimationEnabled,
        particleMultiplier,
        isStatic,
      );
}

/// Service monitoring frame rates and tube counts to enforce adaptive visual budgets.
class MotionBudgetService {
  final int rollingWindowSize;
  final double targetFps;
  final List<double> _frameTimesMs = [];
  MotionQualityLevel _dynamicQuality = MotionQualityLevel.high;
  int _stableFramesCount = 0;
  int _unstableFramesCount = 0;
  final List<String> _decisionLogs = [];

  MotionBudgetService({
    this.rollingWindowSize = 30,
    this.targetFps = 60.0,
  });

  /// Factory for 120 FPS high-refresh-rate configuration (8.33 ms budget)
  factory MotionBudgetService.target120Fps({int rollingWindowSize = 30}) {
    return MotionBudgetService(
      rollingWindowSize: rollingWindowSize,
      targetFps: 120.0,
    );
  }

  MotionQualityLevel get dynamicQuality => _dynamicQuality;
  List<String> get decisionLogs => List.unmodifiable(_decisionLogs);

  /// Target frame time budget in milliseconds (8.33ms at 120 FPS, 16.67ms at 60 FPS).
  double get targetBudgetMs => 1000.0 / targetFps;

  /// Threshold for stepping down quality tier.
  double get stepDownThresholdMs => targetBudgetMs;

  /// Threshold for recovering to a higher quality tier.
  double get stepUpThresholdMs => targetBudgetMs * 0.78;

  /// Computes average frame duration across recent rolling window.
  double get averageFrameTimeMs {
    if (_frameTimesMs.isEmpty) return 16.0;
    final sum = _frameTimesMs.reduce((a, b) => a + b);
    return sum / _frameTimesMs.length;
  }

  /// Records a frame timing sample in milliseconds.
  void recordFrameTime(double frameTimeMs) {
    _frameTimesMs.add(frameTimeMs);
    if (_frameTimesMs.length > rollingWindowSize) {
      _frameTimesMs.removeAt(0);
    }

    final avg = averageFrameTimeMs;
    final stepDown = stepDownThresholdMs;
    final stepUp = stepUpThresholdMs;

    // Frame dropped below target threshold (e.g. 8.33ms at 120fps or 16.6ms at 60fps)
    if (avg > stepDown) {
      _stableFramesCount = 0;
      _unstableFramesCount++;
      if (_unstableFramesCount >= rollingWindowSize) {
        _unstableFramesCount = 0;
        if (_dynamicQuality == MotionQualityLevel.high) {
          _dynamicQuality = MotionQualityLevel.medium;
          _log('Frametime high (${avg.toStringAsFixed(1)}ms): Stepped down to MEDIUM quality.');
        } else if (_dynamicQuality == MotionQualityLevel.medium) {
          _dynamicQuality = MotionQualityLevel.low;
          _log('Frametime critical (${avg.toStringAsFixed(1)}ms): Stepped down to LOW quality.');
        }
      }
    } else if (avg < stepUp) {
      // Stable and smooth performance
      _unstableFramesCount = 0;
      _stableFramesCount++;
      if (_stableFramesCount >= rollingWindowSize) {
        _stableFramesCount = 0;
        if (_dynamicQuality == MotionQualityLevel.low) {
          _dynamicQuality = MotionQualityLevel.medium;
          _log('Frametime stable (${avg.toStringAsFixed(1)}ms): Recovered to MEDIUM quality.');
        } else if (_dynamicQuality == MotionQualityLevel.medium) {
          _dynamicQuality = MotionQualityLevel.high;
          _log('Frametime smooth (${avg.toStringAsFixed(1)}ms): Recovered to HIGH quality.');
        }
      }
    } else {
      _unstableFramesCount = 0;
      _stableFramesCount = 0;
    }
  }

  void _log(String message) {
    _decisionLogs.add(message);
    if (_decisionLogs.length > 20) {
      _decisionLogs.removeAt(0);
    }
  }

  /// Evaluates active settings and environmental constraints to compute [MotionQualityProfile].
  MotionQualityProfile evaluate({
    required int tubeCount,
    required double animationIntensity,
    required bool reducedMotion,
  }) {
    return calculateProfile(
      tubeCount: tubeCount,
      animationIntensity: animationIntensity,
      reducedMotion: reducedMotion,
      quality: _dynamicQuality,
      averageFrameTimeMs: averageFrameTimeMs,
      targetFps: targetFps,
    );
  }

  /// Deterministic profile calculator given strict inputs.
  static MotionQualityProfile calculateProfile({
    required int tubeCount,
    required double animationIntensity,
    required bool reducedMotion,
    MotionQualityLevel quality = MotionQualityLevel.high,
    double? averageFrameTimeMs,
    double targetFps = 60.0,
  }) {
    // Rule 1: Reduced motion or Animation Off = completely static & no particles
    if (reducedMotion || animationIntensity <= 0.05) {
      return MotionQualityProfile.off;
    }

    // Rule 2: Large boards (40+ tubes) automatically drop ambient, bubbles, and shader
    if (tubeCount >= 40) {
      final effectiveQuality = quality == MotionQualityLevel.high
          ? MotionQualityLevel.medium
          : quality;

      final particleCap = tubeCount >= 55 ? 16 : 24;

      return MotionQualityProfile(
        quality: effectiveQuality,
        maxParticles: (particleCap * min(1.0, animationIntensity)).round(),
        bubblesEnabled: false, // strictly dropped on 40+ tubes
        shaderEnabled: false,  // strictly dropped on 40+ tubes
        ambientBackgroundEnabled: false, // strictly dropped on 40+ tubes
        waveAnimationEnabled: false,
        particleMultiplier: 0.25,
        isStatic: false,
      );
    }

    // Rule 3: Boards with < 40 tubes scale by user intensity and dynamic frame quality
    var effectiveQuality = quality;
    if (animationIntensity <= 0.6) {
      effectiveQuality = MotionQualityLevel.low;
    }

    final isHighRefresh = targetFps >= 115.0;

    switch (effectiveQuality) {
      case MotionQualityLevel.low:
        return MotionQualityProfile(
          quality: MotionQualityLevel.low,
          maxParticles: ((isHighRefresh ? 20 : 30) * animationIntensity).round(),
          bubblesEnabled: false,
          shaderEnabled: false,
          ambientBackgroundEnabled: false,
          waveAnimationEnabled: false,
          particleMultiplier: 0.35,
          isStatic: false,
        );

      case MotionQualityLevel.medium:
        return MotionQualityProfile(
          quality: MotionQualityLevel.medium,
          maxParticles: ((isHighRefresh ? 45 : 70) * animationIntensity).round(),
          bubblesEnabled: false,
          shaderEnabled: false,
          ambientBackgroundEnabled: true,
          waveAnimationEnabled: true,
          particleMultiplier: 0.65,
          isStatic: false,
        );

      case MotionQualityLevel.high:
        return MotionQualityProfile(
          quality: MotionQualityLevel.high,
          maxParticles: ((isHighRefresh ? 75 : 130) * animationIntensity).round(),
          bubblesEnabled: true,
          shaderEnabled: true,
          ambientBackgroundEnabled: true,
          waveAnimationEnabled: true,
          particleMultiplier: 1.0,
          isStatic: false,
        );
    }
  }
}
