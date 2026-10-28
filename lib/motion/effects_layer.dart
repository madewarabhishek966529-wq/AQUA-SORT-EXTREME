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
    final baseGlowPaint = Paint()
      ..color = theme.primaryAccent.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, baseGlowPaint);

    // Animated traveling pulse indicator
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final totalLen = metric.length;
      if (totalLen <= 0) continue;

      // Draw dotted dash
      const dashWidth = 8.0;
      const dashSpace = 8.0;
      var distance = (hintPulseProgress * (dashWidth + dashSpace)) % (dashWidth + dashSpace);

      final dashPaint = Paint()
        ..color = theme.secondaryAccent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      while (distance < totalLen) {
        final extract = metric.extractPath(distance, min(distance + dashWidth, totalLen));
        canvas.drawPath(extract, dashPaint);
        distance += dashWidth + dashSpace;
      }

      // Leading traveling comet dot
      final headPos = (hintPulseProgress * totalLen) % totalLen;
      final tangent = metric.getTangentForOffset(headPos);
      if (tangent != null) {
        final headPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(tangent.position, 4.0, headPaint);

        final headGlow = Paint()
          ..color = theme.secondaryAccent.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(tangent.position, 6.0, headGlow);
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
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth + 5.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(activePath, glowPaint);

    // 2. Core liquid stream with gradient
    final streamRect = Rect.fromPoints(start, end);
    final corePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.getLiquidColor(streamColorId!).light,
          color,
          theme.getLiquidColor(streamColorId!).dark,
        ],
      ).createShader(streamRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(activePath, corePaint);

    // 3. Central specular highlight line
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth * 0.35
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(activePath, shinePaint);

    // 4. Landing splash ripple when liquid reaches destination
    if (streamProgress >= 0.8) {
      final rippleRadius = 5.0 + 3.0 * sin(streamProgress * pi * 4);
      final ripplePaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(end, rippleRadius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EffectsOverlayPainter oldDelegate) {
    return true; // Continuously updated during active particle/stream animations
  }
}
