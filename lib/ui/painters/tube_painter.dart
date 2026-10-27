import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// CustomPainter rendering a glass test tube with liquid layers, glass rim,
/// highlights, and fluid meniscus.
class TubePainter extends CustomPainter {
  final TubeState tube;
  final bool isSelected;
  final double shakeOffset;
  final double tiltAngle; // in radians, for pouring animation
  final Color? glowColor;

  TubePainter({
    required this.tube,
    this.isSelected = false,
    this.shakeOffset = 0.0,
    this.tiltAngle = 0.0,
    this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Horizontal shake offset for invalid move feedback
    if (shakeOffset != 0.0) {
      canvas.translate(shakeOffset, 0);
    }

    // Tilt for pouring
    if (tiltAngle != 0.0) {
      // Rotate around the top rim
      canvas.translate(size.width / 2, 0);
      canvas.rotate(tiltAngle);
      canvas.translate(-size.width / 2, 0);
    }

    final w = size.width;
    final h = size.height;
    final rimHeight = 8.0;
    final rimOverflow = 4.0;
    final bodyTop = rimHeight;
    final bodyHeight = h - bodyTop;
    final radius = w / 2;

    // 1. Draw Selection Glow if selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = (glowColor ?? GameTheme.primaryCyan).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      final glowRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(-4, 0, w + 8, h + 4),
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius + 4),
        bottomRight: Radius.circular(radius + 4),
      );
      canvas.drawRRect(glowRect, glowPaint);
    }

    // Tube body outer path (cylindrical with hemispherical rounded bottom)
    final bodyPath = Path()
      ..moveTo(0, bodyTop)
      ..lineTo(0, h - radius)
      ..arcToPoint(
        Offset(w, h - radius),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(w, bodyTop)
      ..close();

    // 2. Translucent Glass Body Background
    final glassBgPaint = Paint()
      ..color = const Color(0x18FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, glassBgPaint);

    // 3. Render Liquid Layers
    if (tube.units.isNotEmpty) {
      canvas.save();
      // Clip to interior of tube body
      canvas.clipPath(bodyPath);

      final capacity = tube.capacity;
      final unitHeight = (bodyHeight - radius * 0.2) / capacity;

      for (var i = 0; i < tube.units.length; i++) {
        final colorId = tube.units[i];
        final liquidColor = GameTheme.getLiquidColor(colorId);

        // Layer bottom to top (i = 0 is bottom)
        final layerBottom = h - (i * unitHeight);
        final layerTop = layerBottom - unitHeight;

        final liquidRect = Rect.fromLTRB(0, layerTop, w, layerBottom);

        final liquidPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              liquidColor.withValues(alpha: 0.85),
              liquidColor,
              liquidColor.withValues(alpha: 0.9),
            ],
          ).createShader(liquidRect);

        canvas.drawRect(liquidRect, liquidPaint);

        // Meniscus / surface curve at the top of the highest liquid layer
        if (i == tube.units.length - 1) {
          final surfacePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          final surfacePath = Path()
            ..moveTo(2, layerTop)
            ..quadraticBezierTo(w / 2, layerTop + 3, w - 2, layerTop);
          canvas.drawPath(surfacePath, surfacePaint);
        }

        // Subtle divider line between layers
        if (i > 0) {
          final dividerPaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.15)
            ..strokeWidth = 1.0;
          canvas.drawLine(Offset(0, layerBottom), Offset(w, layerBottom), dividerPaint);
        }
      }

      canvas.restore();
    }

    // 4. Glass Highlights & Specular Reflections
    // Vertical specular gloss stripe on left side
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromLTWH(3, bodyTop + 4, 4, bodyHeight - radius));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, bodyTop + 6, 3, bodyHeight - radius - 10),
        const Radius.circular(2),
      ),
      glossPaint,
    );

    // 5. Outer Glass Stroke
    final glassStrokePaint = Paint()
      ..color = isSelected
          ? (glowColor ?? GameTheme.primaryCyan)
          : GameTheme.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 2.0;

    canvas.drawPath(bodyPath, glassStrokePaint);

    // 6. Glass Rim at the top
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -rimOverflow / 2,
        0,
        w + rimOverflow,
        rimHeight,
      ),
      const Radius.circular(4),
    );

    final rimFillPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rimRect, rimFillPaint);

    final rimStrokePaint = Paint()
      ..color = isSelected
          ? (glowColor ?? GameTheme.primaryCyan)
          : GameTheme.glassHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rimRect, rimStrokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TubePainter oldDelegate) {
    return oldDelegate.tube != tube ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.shakeOffset != shakeOffset ||
        oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.glowColor != glowColor;
  }
}
