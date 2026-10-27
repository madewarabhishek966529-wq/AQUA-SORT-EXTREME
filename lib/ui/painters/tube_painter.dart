import 'dart:math';
import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// CustomPainter rendering a glass test tube with liquid layers, glass rim,
/// highlights, fluid meniscus, and accessible colorblind cues.
class TubePainter extends CustomPainter {
  final TubeState tube;
  final bool isSelected;
  final bool isFocused;
  final bool isValidDestination;
  final bool showColorblindCues;
  final bool colorblindPalette;
  final double shakeOffset;
  final double tiltAngle; // in radians, for pouring animation
  final Color? glowColor;

  TubePainter({
    required this.tube,
    this.isSelected = false,
    this.isFocused = false,
    this.isValidDestination = false,
    this.showColorblindCues = false,
    this.colorblindPalette = false,
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

    // 1. Draw Glows (Selection, Valid Destination, Keyboard Focus)
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
    } else if (isValidDestination) {
      // Valid pour destination glow
      final validPaint = Paint()
        ..color = GameTheme.accentGreen.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final validRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(-3, 0, w + 6, h + 3),
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius + 3),
        bottomRight: Radius.circular(radius + 3),
      );
      canvas.drawRRect(validRect, validPaint);
    } else if (isFocused) {
      // Keyboard navigation focus ring
      final focusPaint = Paint()
        ..color = GameTheme.accentGold.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final focusRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(-3, 0, w + 6, h + 3),
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius + 3),
        bottomRight: Radius.circular(radius + 3),
      );
      canvas.drawRRect(focusRect, focusPaint);
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
        final liquidColor = GameTheme.getLiquidColor(
          colorId,
          colorblind: colorblindPalette,
        );

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

        // Accessible non-color cues: symbol glyph per color ID
        if (showColorblindCues) {
          final glyphCenter = Offset(w / 2, layerTop + unitHeight / 2);
          final glyphSize = min(w * 0.35, unitHeight * 0.45);
          _drawColorblindGlyph(canvas, colorId, glyphCenter, glyphSize);
        }

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
        oldDelegate.isFocused != isFocused ||
        oldDelegate.isValidDestination != isValidDestination ||
        oldDelegate.showColorblindCues != showColorblindCues ||
        oldDelegate.colorblindPalette != colorblindPalette ||
        oldDelegate.shakeOffset != shakeOffset ||
        oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.glowColor != glowColor;
  }

  /// Renders a crisp mathematical geometric glyph for colorblind accessibility.
  void _drawColorblindGlyph(
      Canvas canvas, int colorId, Offset center, double size) {
    final glyphPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final half = size / 2;
    final r = half * 0.85;

    switch ((colorId - 1) % 12) {
      case 0: // Circle
        canvas.drawCircle(center, r, glyphPaint);
        break;
      case 1: // Square
        canvas.drawRect(
          Rect.fromCenter(
              center: center, width: size * 0.8, height: size * 0.8),
          glyphPaint,
        );
        break;
      case 2: // Triangle Up
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy + r)
          ..lineTo(center.dx - r, center.dy + r)
          ..close();
        canvas.drawPath(path, glyphPaint);
        break;
      case 3: // Diamond
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r, center.dy)
          ..close();
        canvas.drawPath(path, glyphPaint);
        break;
      case 4: // Plus (+)
        canvas.drawLine(Offset(center.dx - r, center.dy),
            Offset(center.dx + r, center.dy), glyphPaint);
        canvas.drawLine(Offset(center.dx, center.dy - r),
            Offset(center.dx, center.dy + r), glyphPaint);
        break;
      case 5: // X / Saltire
        final d = r * 0.707;
        canvas.drawLine(Offset(center.dx - d, center.dy - d),
            Offset(center.dx + d, center.dy + d), glyphPaint);
        canvas.drawLine(Offset(center.dx + d, center.dy - d),
            Offset(center.dx - d, center.dy + d), glyphPaint);
        break;
      case 6: // Triangle Down
        final path = Path()
          ..moveTo(center.dx, center.dy + r)
          ..lineTo(center.dx + r, center.dy - r)
          ..lineTo(center.dx - r, center.dy - r)
          ..close();
        canvas.drawPath(path, glyphPaint);
        break;
      case 7: // Hexagon
        final path = Path();
        for (var k = 0; k < 6; k++) {
          final angle = k * pi / 3;
          final x = center.dx + r * cos(angle);
          final y = center.dy + r * sin(angle);
          if (k == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, glyphPaint);
        break;
      case 8: // Star / Asterisk (6 points)
        for (var k = 0; k < 3; k++) {
          final angle = k * pi / 3;
          final dx = r * cos(angle);
          final dy = r * sin(angle);
          canvas.drawLine(Offset(center.dx - dx, center.dy - dy),
              Offset(center.dx + dx, center.dy + dy), glyphPaint);
        }
        break;
      case 9: // Horizontal double bars
        canvas.drawLine(Offset(center.dx - r, center.dy - 3),
            Offset(center.dx + r, center.dy - 3), glyphPaint);
        canvas.drawLine(Offset(center.dx - r, center.dy + 3),
            Offset(center.dx + r, center.dy + 3), glyphPaint);
        break;
      case 10: // Solid filled dot
        glyphPaint.style = PaintingStyle.fill;
        canvas.drawCircle(center, r * 0.5, glyphPaint);
        break;
      case 11: // Bullseye ring + center dot
        canvas.drawCircle(center, r, glyphPaint);
        glyphPaint.style = PaintingStyle.fill;
        canvas.drawCircle(center, r * 0.35, glyphPaint);
        break;
    }
  }
}
