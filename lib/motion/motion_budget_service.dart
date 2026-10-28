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
  final List<double> _frameTimesMs = [];
  MotionQualityLevel _dynamicQuality = MotionQualityLevel.high;
  int _stableFramesCount = 0;
  final List<String> _decisionLogs = [];

  MotionBudgetService({this.rollingWindowSize = 30});

  MotionQualityLevel get dynamicQuality => _dynamicQuality;
  List<String> get decisionLogs => List.unmodifiable(_decisionLogs);

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

    // Frame dropped below ~60fps target threshold (16.6ms)
    if (avg > 16.6) {
      _stableFramesCount = 0;
      if (_dynamicQuality == MotionQualityLevel.high) {
        _dynamicQuality = MotionQualityLevel.medium;
        _log('Frametime high (${avg.toStringAsFixed(1)}ms): Stepped down to MEDIUM quality.');
      } else if (_dynamicQuality == MotionQualityLevel.medium) {
        _dynamicQuality = MotionQualityLevel.low;
        _log('Frametime critical (${avg.toStringAsFixed(1)}ms): Stepped down to LOW quality.');
      }
    } else if (avg < 13.0) {
      // Stable and smooth performance
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
    );
  }

  /// Deterministic profile calculator given strict inputs.
  static MotionQualityProfile calculateProfile({
    required int tubeCount,
    required double animationIntensity,
    required bool reducedMotion,
    MotionQualityLevel quality = MotionQualityLevel.high,
    double? averageFrameTimeMs,
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

    switch (effectiveQuality) {
      case MotionQualityLevel.low:
        return MotionQualityProfile(
          quality: MotionQualityLevel.low,
          maxParticles: (30 * animationIntensity).round(),
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
          maxParticles: (70 * animationIntensity).round(),
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
          maxParticles: (130 * animationIntensity).round(),
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
