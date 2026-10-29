import 'dart:math';
import 'package:flutter/material.dart';

/// Particle classification for visual rendering behavior.
enum ParticleType {
  confetti,
  sparkle,
  droplet,
  bubble,
}

/// A single particle representation reused inside [ParticlePool].
class Particle {
  double x = 0.0;
  double y = 0.0;
  double vx = 0.0;
  double vy = 0.0;
  double ax = 0.0;
  double ay = 0.0;
  double life = 0.0; // 1.0 -> 0.0
  double maxLife = 1.0;
  double size = 4.0;
  Color color = Colors.white;
  ParticleType type = ParticleType.sparkle;
  double rotation = 0.0;
  double vRot = 0.0;
  bool active = false;

  void reset() {
    x = 0.0;
    y = 0.0;
    vx = 0.0;
    vy = 0.0;
    ax = 0.0;
    ay = 0.0;
    life = 0.0;
    maxLife = 1.0;
    size = 4.0;
    color = Colors.white;
    type = ParticleType.sparkle;
    rotation = 0.0;
    vRot = 0.0;
    active = false;
  }
}

/// High-performance zero-allocation particle pool managing up to [maxCapacity] particles.
class ParticlePool {
  final int maxCapacity;
  late final List<Particle> _pool;
  final Random _rng = Random(42);

  ParticlePool({this.maxCapacity = 160}) {
    _pool = List.generate(maxCapacity, (_) => Particle(), growable: false);
  }

  /// Current count of actively simulated and rendered particles.
  int get activeCount {
    var count = 0;
    for (var i = 0; i < maxCapacity; i++) {
      if (_pool[i].active) count++;
    }
    return count;
  }

  /// Spawns a particle from the recycled pool if available.
  Particle? spawn({
    required double x,
    required double y,
    required double vx,
    required double vy,
    double ax = 0.0,
    double ay = 0.0,
    required double maxLife,
    required double size,
    required Color color,
    required ParticleType type,
    double rotation = 0.0,
    double vRot = 0.0,
  }) {
    for (var i = 0; i < maxCapacity; i++) {
      final p = _pool[i];
      if (!p.active) {
        p.active = true;
        p.x = x;
        p.y = y;
        p.vx = vx;
        p.vy = vy;
        p.ax = ax;
        p.ay = ay;
        p.life = 1.0;
        p.maxLife = maxLife > 0 ? maxLife : 0.01;
        p.size = size;
        p.color = color;
        p.type = type;
        p.rotation = rotation;
        p.vRot = vRot;
        return p;
      }
    }
    return null; // Pool exhausted, no new allocation churn
  }

  /// Advances physics simulation for all active particles by [dt] seconds.
  void update(double dt) {
    if (dt <= 0.0) return;

    for (var i = 0; i < maxCapacity; i++) {
      final p = _pool[i];
      if (!p.active) continue;

      p.life -= dt / p.maxLife;
      if (p.life <= 0.0) {
        p.active = false;
        continue;
      }

      p.vx += p.ax * dt;
      p.vy += p.ay * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.vRot * dt;
    }
  }

  /// Renders all active particles onto the canvas without object allocations.
  void draw(Canvas canvas, Paint sharedPaint) {
    for (var i = 0; i < maxCapacity; i++) {
      final p = _pool[i];
      if (!p.active) continue;

      final alpha = (p.life * 255).clamp(0, 255).toInt();
      if (alpha <= 0) continue;

      sharedPaint.color = p.color.withAlpha(alpha);

      switch (p.type) {
        case ParticleType.confetti:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rotation);
          sharedPaint.style = PaintingStyle.fill;
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size * 1.6, height: p.size * 0.9),
            sharedPaint,
          );
          canvas.restore();
          break;

        case ParticleType.sparkle:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rotation);
          sharedPaint.style = PaintingStyle.fill;
          final path = Path()
            ..moveTo(0, -p.size)
            ..lineTo(p.size * 0.25, -p.size * 0.25)
            ..lineTo(p.size, 0)
            ..lineTo(p.size * 0.25, p.size * 0.25)
            ..lineTo(0, p.size)
            ..lineTo(-p.size * 0.25, p.size * 0.25)
            ..lineTo(-p.size, 0)
            ..lineTo(-p.size * 0.25, -p.size * 0.25)
            ..close();
          canvas.drawPath(path, sharedPaint);
          canvas.restore();
          break;

        case ParticleType.droplet:
          sharedPaint.style = PaintingStyle.fill;
          canvas.drawCircle(Offset(p.x, p.y), p.size * 0.5, sharedPaint);
          break;

        case ParticleType.bubble:
          sharedPaint.style = PaintingStyle.stroke;
          sharedPaint.strokeWidth = 1.0;
          canvas.drawCircle(Offset(p.x, p.y), p.size, sharedPaint);
          break;
      }
    }
  }

  /// Clears and deactivates all active particles.
  void clear() {
    for (var i = 0; i < maxCapacity; i++) {
      _pool[i].active = false;
    }
  }

  // --- Emitter Helpers ---

  /// Emits celebratory confetti burst across [bounds].
  void emitWinConfetti(Size bounds, List<Color> colors, int count) {
    if (colors.isEmpty || count <= 0) return;

    for (var i = 0; i < count; i++) {
      final x = _rng.nextDouble() * bounds.width;
      final y = -20.0 - (_rng.nextDouble() * 80.0);
      final vx = (_rng.nextDouble() - 0.5) * 120.0;
      final vy = 80.0 + _rng.nextDouble() * 160.0;
      final color = colors[_rng.nextInt(colors.length)];

      spawn(
        x: x,
        y: y,
        vx: vx,
        vy: vy,
        ay: 90.0, // gravity
        maxLife: 2.2 + _rng.nextDouble() * 1.2,
        size: 5.0 + _rng.nextDouble() * 4.0,
        color: color,
        type: _rng.nextBool() ? ParticleType.confetti : ParticleType.sparkle,
        rotation: _rng.nextDouble() * 2 * pi,
        vRot: (_rng.nextDouble() - 0.5) * 8.0,
      );
    }
  }

  /// Emits a localized sparkle burst when a tube completes.
  void emitTubeCompletionBurst(Offset center, Color color, int count) {
    if (count <= 0) return;

    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 40.0 + _rng.nextDouble() * 90.0;
      final vx = cos(angle) * speed;
      final vy = sin(angle) * speed;

      spawn(
        x: center.dx,
        y: center.dy,
        vx: vx,
        vy: vy,
        ay: 30.0,
        maxLife: 0.55 + _rng.nextDouble() * 0.35,
        size: 3.5 + _rng.nextDouble() * 3.0,
        color: color,
        type: ParticleType.sparkle,
        rotation: _rng.nextDouble() * 2 * pi,
        vRot: (_rng.nextDouble() - 0.5) * 6.0,
      );
    }
  }

  /// Emits a small splash and droplet spray at the pour destination lip.
  void emitPourSplash(Offset mouthPos, Color color, int count) {
    if (count <= 0) return;

    for (var i = 0; i < count; i++) {
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * 1.2;
      final speed = 25.0 + _rng.nextDouble() * 45.0;

      spawn(
        x: mouthPos.dx + (_rng.nextDouble() - 0.5) * 6,
        y: mouthPos.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        ay: 120.0,
        maxLife: 0.30 + _rng.nextDouble() * 0.20,
        size: 2.0 + _rng.nextDouble() * 2.0,
        color: color,
        type: ParticleType.droplet,
      );
    }
  }
}

