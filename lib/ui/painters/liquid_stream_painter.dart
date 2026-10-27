import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Paints the liquid stream connecting the pouring tube to the destination tube.
class LiquidStreamPainter extends CustomPainter {
  final Offset startOffset;
  final Offset endOffset;
  final int colorId;
  final double streamWidth;
  final double progress; // 0.0 to 1.0

  LiquidStreamPainter({
    required this.startOffset,
    required this.endOffset,
    required this.colorId,
    this.streamWidth = 6.0,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final color = GameTheme.getLiquidColor(colorId);

    // Control points for a natural fluid gravity parabola
    final midX = (startOffset.dx + endOffset.dx) / 2;
    final peakY = (startOffset.dy < endOffset.dy ? startOffset.dy : endOffset.dy) - 30;

    final path = Path()
      ..moveTo(startOffset.dx, startOffset.dy)
      ..quadraticBezierTo(midX, peakY, endOffset.dx, endOffset.dy);

    // Stream glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = streamWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    // Core stream
    final streamPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = streamWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, streamPaint);

    // Highlight center
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = streamWidth * 0.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);

    // Splash droplet at destination mouth
    final splashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endOffset, streamWidth * 0.8, splashPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidStreamPainter oldDelegate) {
    return oldDelegate.startOffset != startOffset ||
        oldDelegate.endOffset != endOffset ||
        oldDelegate.colorId != colorId ||
        oldDelegate.progress != progress;
  }
}
