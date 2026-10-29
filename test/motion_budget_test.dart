import 'package:aqua_sort_extreme/motion/motion_budget_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MotionBudgetService Unit Tests', () {
    late MotionBudgetService service;

    setUp(() {
      service = MotionBudgetService(rollingWindowSize: 20);
    });

    test('Deterministic evaluation for identical inputs', () {
      final p1 = MotionBudgetService.calculateProfile(
        tubeCount: 8,
        animationIntensity: 1.0,
        reducedMotion: false,
        quality: MotionQualityLevel.high,
      );
      final p2 = MotionBudgetService.calculateProfile(
        tubeCount: 8,
        animationIntensity: 1.0,
        reducedMotion: false,
        quality: MotionQualityLevel.high,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1.bubblesEnabled, isTrue);
      expect(p1.ambientBackgroundEnabled, isTrue);
      expect(p1.maxParticles, equals(130));
    });

    test('Off intensity or reducedMotion returns static profile with 0 particles', () {
      final offProfile = service.evaluate(
        tubeCount: 8,
        animationIntensity: 0.0,
        reducedMotion: false,
      );
      expect(offProfile.isStatic, isTrue);
      expect(offProfile.maxParticles, equals(0));
      expect(offProfile.bubblesEnabled, isFalse);
      expect(offProfile.ambientBackgroundEnabled, isFalse);

      final reducedProfile = service.evaluate(
        tubeCount: 8,
        animationIntensity: 1.0,
        reducedMotion: true,
      );
      expect(reducedProfile.isStatic, isTrue);
      expect(reducedProfile.maxParticles, equals(0));
      expect(reducedProfile.bubblesEnabled, isFalse);
    });

    test('Boards with 40+ tubes automatically drop bubbles, ambient background, and shader', () {
      final profile40 = service.evaluate(
        tubeCount: 40,
        animationIntensity: 1.0,
        reducedMotion: false,
      );

      expect(profile40.bubblesEnabled, isFalse, reason: '40+ tubes must drop bubbles');
      expect(profile40.ambientBackgroundEnabled, isFalse, reason: '40+ tubes must drop ambient mesh');
      expect(profile40.shaderEnabled, isFalse, reason: '40+ tubes must drop shader');
      expect(profile40.maxParticles, lessThanOrEqualTo(24));

      final profile60 = service.evaluate(
        tubeCount: 60,
        animationIntensity: 1.0,
        reducedMotion: false,
      );

      expect(profile60.bubblesEnabled, isFalse);
      expect(profile60.ambientBackgroundEnabled, isFalse);
      expect(profile60.shaderEnabled, isFalse);
      expect(profile60.maxParticles, lessThanOrEqualTo(16));
    });

    test('Degrades quality when rolling average frametime exceeds 16.6ms', () {
      expect(service.dynamicQuality, equals(MotionQualityLevel.high));

      // Feed frames taking 22ms (> 16.6ms threshold)
      for (var i = 0; i < 25; i++) {
        service.recordFrameTime(22.0);
      }

      expect(service.dynamicQuality, equals(MotionQualityLevel.medium));
      expect(service.decisionLogs, isNotEmpty);
      expect(service.decisionLogs.last, contains('Stepped down to MEDIUM'));

      // Continue feeding high frame times to drop to LOW
      for (var i = 0; i < 25; i++) {
        service.recordFrameTime(24.0);
      }

      expect(service.dynamicQuality, equals(MotionQualityLevel.low));
      expect(service.decisionLogs.last, contains('Stepped down to LOW'));
    });

    test('Recovers quality when rolling frametimes stay smooth under 13.0ms', () {
      // Force step down to LOW
      for (var i = 0; i < 45; i++) {
        service.recordFrameTime(25.0);
      }
      expect(service.dynamicQuality, equals(MotionQualityLevel.low));

      // Feed smooth 10ms frames: first flush slow frames from window, then accumulate stable window
      for (var i = 0; i < 45; i++) {
        service.recordFrameTime(10.0);
      }
      expect(service.dynamicQuality, equals(MotionQualityLevel.medium));

      // Feed another window of 10ms frames
      for (var i = 0; i < 25; i++) {
        service.recordFrameTime(10.0);
      }
      expect(service.dynamicQuality, equals(MotionQualityLevel.high));
      expect(service.decisionLogs.last, contains('Recovered to HIGH'));
    });
  });
}
