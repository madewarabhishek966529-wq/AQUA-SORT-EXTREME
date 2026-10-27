import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double alpha;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.alpha = 1.0,
    this.rotation = 0.0,
    required this.rotationSpeed,
  });
}

/// Paints joyful confetti and sparkling bubbles upon winning a level.
class WinParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationProgress;

  WinParticlePainter({
    required this.particles,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentAlpha = (p.alpha * (1.0 - animationProgress * 0.7)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: currentAlpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      // Mix of circles and confetti ribbons
      if (p.size > 8) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.4),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant WinParticlePainter oldDelegate) => true;

  /// Helper factory to generate a fresh cloud of celebration particles
  static List<Particle> createExplosion(Size canvasSize, {int count = 75}) {
    final rng = Random();
    final particles = <Particle>[];
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;

    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 3.0 + rng.nextDouble() * 7.0;
      final colorId = 1 + rng.nextInt(10);

      particles.add(
        Particle(
          x: centerX + (rng.nextDouble() - 0.5) * 100,
          y: centerY + (rng.nextDouble() - 0.5) * 80,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 2.0, // slight upward bias
          size: 6.0 + rng.nextDouble() * 8.0,
          color: GameTheme.getLiquidColor(colorId),
          rotationSpeed: (rng.nextDouble() - 0.5) * 0.2,
        ),
      );
    }
    return particles;
  }
}
