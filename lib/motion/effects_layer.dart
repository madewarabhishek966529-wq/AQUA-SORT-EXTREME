import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/aqua_palette.dart';
import 'particle_system.dart';
import 'pour_animation_controller.dart';

/// Non-interactive visual overlay rendering the curved fluid stream,
/// splash droplets, win confetti, tube completion sparkle bursts, and hint paths.
class EffectsLayer extends StatelessWidget {
  final ParticlePool particlePool;
  final PourAnimationController? pourController;
  final Offset? sourceLipPosition;
  final Offset? targetLipPosition;
  final int? streamColorId;
  final ThemePalette theme;
  final Offset? hintSourcePos;
  final Offset? hintTargetPos;
  final double hintPulseProgress;

  const EffectsLayer({
    super.key,
    required this.particlePool,
    this.pourController,
    this.sourceLipPosition,
    this.targetLipPosition,
    this.streamColorId,
    required this.theme,
    this.hintSourcePos,
    this.hintTargetPos,
    this.hintPulseProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _EffectsOverlayPainter(
          particlePool: particlePool,
          pourController: pourController,
          sourceLip: sourceLipPosition,
          targetLip: targetLipPosition,
          streamColorId: streamColorId,
          theme: theme,
          hintSourcePos: hintSourcePos,
          hintTargetPos: hintTargetPos,
          hintPulseProgress: hintPulseProgress,
        ),
      ),
    );
  }
}

class _EffectsOverlayPainter extends CustomPainter {
  final ParticlePool particlePool;
  final PourAnimationController? pourController;
  final Offset? sourceLip;
  final Offset? targetLip;
  final int? streamColorId;
  final ThemePalette theme;
  final Offset? hintSourcePos;
  final Offset? hintTargetPos;
  final double hintPulseProgress;

  final Paint _sharedPaint = Paint();

  static final Paint _baseGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  static final Paint _dashPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  static final Paint _headPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _headGlow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _shinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.55);

  static final Paint _ripplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  _EffectsOverlayPainter({
    required this.particlePool,
    this.pourController,
    this.sourceLip,
    this.targetLip,
    this.streamColorId,
    required this.theme,
    this.hintSourcePos,
    this.hintTargetPos,
    required this.hintPulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Hint Path (animated traveling glowing dotted curve)
    if (hintSourcePos != null && hintTargetPos != null) {
      _drawHintPath(canvas);
    }

    // 2. Draw Curved Pouring Liquid Stream
    if (pourController != null &&
        pourController!.isAnimating &&
        sourceLip != null &&
        targetLip != null &&
        streamColorId != null) {
      _drawPourStream(canvas);
    }

    // 3. Draw Active Particles (Confetti, Splashes, Completion Sparkles)
    particlePool.draw(canvas, _sharedPaint);
  }

  void _drawHintPath(Canvas canvas) {
    final start = hintSourcePos!;
    final end = hintTargetPos!;
    final midX = (start.dx + end.dx) / 2;
    final peakY = min(start.dy, end.dy) - 45;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(midX, peakY, end.dx, end.dy);

    // Glowing base line
    _baseGlowPaint.color = theme.primaryAccent.withValues(alpha: 0.30);
    _baseGlowPaint.strokeWidth = 3.5;
    canvas.drawPath(path, _baseGlowPaint);

    // Animated traveling pulse indicator
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final totalLen = metric.length;
      if (totalLen <= 0) continue;

      // Draw dotted dash
      const dashWidth = 8.0;
      const dashSpace = 8.0;
      var distance = (hintPulseProgress * (dashWidth + dashSpace)) % (dashWidth + dashSpace);

      _dashPaint.color = theme.secondaryAccent.withValues(alpha: 0.85);

      while (distance < totalLen) {
        final extract = metric.extractPath(distance, min(distance + dashWidth, totalLen));
        canvas.drawPath(extract, _dashPaint);
        distance += dashWidth + dashSpace;
      }

      // Leading traveling comet dot
      final headPos = (hintPulseProgress * totalLen) % totalLen;
      final tangent = metric.getTangentForOffset(headPos);
      if (tangent != null) {
        _headPaint.color = Colors.white;
        canvas.drawCircle(tangent.position, 4.0, _headPaint);

        _headGlow.color = theme.secondaryAccent.withValues(alpha: 0.8);
        canvas.drawCircle(tangent.position, 6.0, _headGlow);
      }
    }
  }

  void _drawPourStream(Canvas canvas) {
    final streamProgress = pourController!.streamProgress;
    if (streamProgress <= 0.0) return;

    final color = theme.getLiquidColor(streamColorId!).base;
    final start = sourceLip!;
    final end = targetLip!;

    // Gravity arching curve
    final midX = (start.dx + end.dx) / 2;
    final peakY = min(start.dy, end.dy) - 25.0;

    final fullPath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(midX, peakY, end.dx, end.dy);

    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLen = metrics.first.length;
    final drawnLen = totalLen * streamProgress.clamp(0.0, 1.0);
    final activePath = metrics.first.extractPath(0.0, drawnLen);

    // Dynamic stream width tapering from mouth (7px) to destination (4.5px)
    const baseWidth = 6.5;

    // 1. Soft stream outer glow
    _glowPaint.color = color.withValues(alpha: 0.45);
    _glowPaint.strokeWidth = baseWidth + 5.0;
    canvas.drawPath(activePath, _glowPaint);

    // 2. High-vibrancy fluid core gradient
    final streamRect = Rect.fromPoints(start, end);
    _corePaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.getLiquidColor(streamColorId!).light,
        color,
        theme.getLiquidColor(streamColorId!).dark,
      ],
    ).createShader(streamRect);
    _corePaint.strokeWidth = baseWidth;
    canvas.drawPath(activePath, _corePaint);

    // 3. Central specular highlight line
    _shinePaint.strokeWidth = baseWidth * 0.35;
    canvas.drawPath(activePath, _shinePaint);

    // 4. Landing splash ripple when liquid reaches destination
    if (streamProgress >= 0.8) {
      final rippleRadius = 5.0 + 3.0 * sin(streamProgress * pi * 4);
      _ripplePaint.color = color.withValues(alpha: 0.7);
      canvas.drawCircle(end, rippleRadius, _ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EffectsOverlayPainter oldDelegate) {
    if (particlePool.activeCount > 0) return true;
    if (pourController != null && pourController!.isAnimating) return true;
    if (hintSourcePos != null && hintTargetPos != null) return true;
    return oldDelegate.streamColorId != streamColorId ||
        oldDelegate.sourceLip != sourceLip ||
        oldDelegate.targetLip != targetLip ||
        oldDelegate.theme.id != theme.id;
  }
}
