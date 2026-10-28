import 'dart:math';
import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';

import '../../theme/aqua_palette.dart';
import '../../theme/tube_skins.dart';

/// Upgraded CustomPainter rendering a high-fidelity glass test tube with:
/// - Translucent glass fill, rim highlight, side reflection streaks, inner and drop shadows.
/// - Liquid units with vertical gradients (lighter top, richer bottom), inner highlights, and ambient glow.
/// - Layer boundary blending between stacked colors (soft gradient seam).
/// - Dynamic animated surface wave and bright meniscus line.
/// - Tiny rising ambient bubbles (capped by motion budget).
/// - Tube skins (changing glass tint, rim, and base cap).
/// - Per-color pattern glyphs for accessibility.
/// - Completion lock shine sweep.
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
  final ThemePalette theme;
  final TubeSkin skin;
  final double wavePhase;
  final double waveAmplitude;
  final bool enableBubbles;
  final double bubbleTime;
  final double completionProgress; // 0.0 to 1.0 for cap shine sweep
  final double liquidLevelMultiplier; // for drain/fill scaling

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
    ThemePalette? theme,
    TubeSkin? skin,
    this.wavePhase = 0.0,
    this.waveAmplitude = 1.2,
    this.enableBubbles = false,
    this.bubbleTime = 0.0,
    this.completionProgress = 0.0,
    this.liquidLevelMultiplier = 1.0,
  })  : theme = theme ?? AquaPalette.ocean,
        skin = skin ?? TubeSkinRegistry.classicGlass;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 1. Horizontal shake offset for invalid move feedback
    if (shakeOffset != 0.0) {
      canvas.translate(shakeOffset, 0);
    }

    // 2. Tilt for pouring (rotates around top lip)
    if (tiltAngle != 0.0) {
      canvas.translate(size.width / 2, 0);
      canvas.rotate(tiltAngle);
      canvas.translate(-size.width / 2, 0);
    }

    final w = size.width;
    final h = size.height;
    const rimHeight = 8.0;
    const rimOverflow = 4.0;
    const bodyTop = rimHeight;
    final bodyHeight = h - bodyTop;
    final radius = w / 2;

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

    // 3. Drop Shadow
    final dropShadowPaint = Paint()
      ..color = skin.dropShadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(bodyPath.shift(const Offset(0, 3)), dropShadowPaint);

    // 4. Glows (Selection, Valid Destination, Keyboard Focus)
    if (isSelected) {
      final activeGlow = glowColor ?? theme.primaryAccent;
      final glowPaint = Paint()
        ..color = activeGlow.withValues(alpha: 0.45)
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
      final validPaint = Paint()
        ..color = theme.secondaryAccent.withValues(alpha: 0.38)
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
      final focusPaint = Paint()
        ..color = theme.primaryAccent.withValues(alpha: 0.40)
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

    // 5. Translucent Glass Body Fill
    final glassBgPaint = Paint()
      ..color = skin.glassTint.withValues(alpha: skin.glassOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, glassBgPaint);

    // 6. Subtle Inner Shadow along glass edges
    final innerShadowPaint = Paint()
      ..color = skin.innerShadowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(bodyPath, innerShadowPaint);

    // 7. Render Liquid Layers
    if (tube.units.isNotEmpty && liquidLevelMultiplier > 0.0) {
      canvas.save();
      // Clip strictly inside the tube body
      canvas.clipPath(bodyPath);

      final capacity = tube.capacity;
      final unitHeight = (bodyHeight - radius * 0.2) / capacity;

      for (var i = 0; i < tube.units.length; i++) {
        final colorId = tube.units[i];
        final liquidColor = theme.getLiquidColor(
          colorId,
          colorblind: colorblindPalette,
        );

        // Compute layer vertical bounds
        final layerBottom = h - (i * unitHeight);
        var layerTop = layerBottom - unitHeight;

        // Apply scale if dynamic drain/fill
        if (i == tube.units.length - 1 && liquidLevelMultiplier < 1.0) {
          layerTop = layerBottom - (unitHeight * liquidLevelMultiplier);
        }

        final liquidRect = Rect.fromLTRB(0, layerTop, w, layerBottom);

        // A. Vertical liquid gradient (lighter top, richer bottom)
        final liquidPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              liquidColor.light,
              liquidColor.base,
              liquidColor.dark,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(liquidRect);

        canvas.drawRect(liquidRect, liquidPaint);

        // B. Thin Inner Highlight along left curve
        final innerHighlightPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.25, 0.50],
          ).createShader(liquidRect);
        canvas.drawRect(liquidRect, innerHighlightPaint);

        // C. Layer boundary blending: soft gradient seam between stacked colors
        if (i > 0) {
          final seamRect = Rect.fromLTRB(0, layerBottom - 1.5, w, layerBottom + 1.5);
          final prevColor = theme.getLiquidColor(tube.units[i - 1], colorblind: colorblindPalette);
          final seamPaint = Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                liquidColor.dark.withValues(alpha: 0.6),
                prevColor.light.withValues(alpha: 0.6),
              ],
            ).createShader(seamRect);
          canvas.drawRect(seamRect, seamPaint);
        }

        // D. Accessible non-color cues: symbol glyph per color ID
        if (showColorblindCues) {
          final glyphCenter = Offset(w / 2, (layerTop + layerBottom) / 2);
          final glyphSize = min(w * 0.36, unitHeight * 0.48);
          _drawColorblindGlyph(canvas, colorId, glyphCenter, glyphSize);
        }

        // E. Top surface meniscus & animated wave (only on highest layer)
        if (i == tube.units.length - 1) {
          _drawSurfaceWave(
            canvas,
            w: w,
            layerTop: layerTop,
            liquidColor: liquidColor,
          );
        }
      }

      // F. Tiny rising bubbles in liquid (when enabled by motion budget)
      if (enableBubbles) {
        _drawRisingBubbles(canvas, w: w, h: h, unitHeight: unitHeight);
      }

      // G. Tube Completion shine sweep
      if (completionProgress > 0.0 && completionProgress <= 1.0) {
        _drawCompletionSweep(canvas, w: w, h: h);
      }

      canvas.restore();
    }

    // 8. Base Cap (e.g. Steampunk / Brass skin)
    if (skin.hasBaseCap && skin.baseCapColor != null) {
      final capPath = Path()
        ..moveTo(0, h - radius * 0.9)
        ..arcToPoint(
          Offset(w, h - radius * 0.9),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..close();

      final capPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            skin.baseCapColor!.withValues(alpha: 0.9),
            skin.baseCapColor!,
            skin.baseCapColor!.withValues(alpha: 0.7),
          ],
        ).createShader(Rect.fromLTWH(0, h - radius, w, radius))
        ..style = PaintingStyle.fill;
      canvas.drawPath(capPath, capPaint);
    }

    // 9. Side Specular Reflection Streak
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          skin.streakColor.withValues(alpha: 0.55),
          skin.streakColor.withValues(alpha: 0.15),
          skin.streakColor.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromLTWH(3, bodyTop + 4, 4, bodyHeight - radius));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3.5, bodyTop + 5, 3.0, bodyHeight - radius - 10),
        const Radius.circular(2),
      ),
      glossPaint,
    );

    // 10. Outer Glass Rim & Border Stroke
    final glassStrokePaint = Paint()
      ..color = isSelected
          ? (glowColor ?? theme.primaryAccent)
          : skin.rimColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? skin.rimThickness + 0.8 : skin.rimThickness;

    canvas.drawPath(bodyPath, glassStrokePaint);

    // 11. Top Glass Rim Lip
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
      ..color = skin.rimColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rimRect, rimFillPaint);

    final rimStrokePaint = Paint()
      ..color = isSelected
          ? (glowColor ?? theme.primaryAccent)
          : skin.rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.4;
    canvas.drawRRect(rimRect, rimStrokePaint);

    canvas.restore();
  }

  void _drawSurfaceWave({
    required Canvas canvas,
    required double w,
    required double layerTop,
    required LiquidColor liquidColor,
  }) {
    final wavePath = Path()..moveTo(0, layerTop);
    const steps = 12;
    final amp = waveAmplitude;

    for (var s = 0; s <= steps; s++) {
      final x = (w / steps) * s;
      final wave = amp * sin(2 * pi * (s / steps) + wavePhase);
      final meniscus = 2.0 * sin((s / steps) * pi); // Natural meniscus dip
      wavePath.lineTo(x, layerTop + wave + meniscus);
    }
    wavePath.lineTo(w, layerTop + 10);
    wavePath.lineTo(0, layerTop + 10);
    wavePath.close();

    final capFill = Paint()..color = liquidColor.light.withValues(alpha: 0.85);
    canvas.drawPath(wavePath, capFill);

    // Bright meniscus highlight line
    final surfaceLine = Path()..moveTo(1, layerTop);
    for (var s = 0; s <= steps; s++) {
      final x = (w / steps) * s;
      final wave = amp * sin(2 * pi * (s / steps) + wavePhase);
      final meniscus = 2.0 * sin((s / steps) * pi);
      surfaceLine.lineTo(x, layerTop + wave + meniscus);
    }

    final surfacePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(surfaceLine, surfacePaint);
  }

  void _drawRisingBubbles(
    Canvas canvas, {
    required double w,
    required double h,
    required double unitHeight,
  }) {
    final totalLiquidHeight = tube.units.length * unitHeight;
    final liquidTop = h - totalLiquidHeight;
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Up to 3 deterministic rising bubbles
    for (var b = 0; b < min(3, tube.units.length); b++) {
      final xOffset = w * (0.35 + 0.15 * b);
      final speed = 25.0 + 10.0 * b;
      final cycleY = totalLiquidHeight > 0
          ? (bubbleTime * speed + b * 20) % totalLiquidHeight
          : 0.0;
      final bubbleY = h - cycleY;

      if (bubbleY > liquidTop + 4 && bubbleY < h - 4) {
        canvas.drawCircle(Offset(xOffset, bubbleY), 1.2 + 0.3 * b, bubblePaint);
      }
    }
  }

  void _drawCompletionSweep(Canvas canvas, {required double w, required double h}) {
    final sweepY = h * completionProgress;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, sweepY - 15, w, 30));

    canvas.drawRect(Rect.fromLTWH(0, sweepY - 15, w, 30), sweepPaint);
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
        oldDelegate.glowColor != glowColor ||
        oldDelegate.theme.id != theme.id ||
        oldDelegate.skin.id != skin.id ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.enableBubbles != enableBubbles ||
        oldDelegate.bubbleTime != bubbleTime ||
        oldDelegate.completionProgress != completionProgress ||
        oldDelegate.liquidLevelMultiplier != liquidLevelMultiplier;
  }

  /// Crisp mathematical geometric glyphs for accessibility
  void _drawColorblindGlyph(
      Canvas canvas, int colorId, Offset center, double size) {
    final glyphPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final half = size / 2;
    final r = half * 0.85;

    switch ((colorId - 1) % 16) {
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
      case 8: // Asterisk
        for (var k = 0; k < 3; k++) {
          final angle = k * pi / 3;
          final dx = r * cos(angle);
          final dy = r * sin(angle);
          canvas.drawLine(Offset(center.dx - dx, center.dy - dy),
              Offset(center.dx + dx, center.dy + dy), glyphPaint);
        }
        break;
      case 9: // Double Bars
        canvas.drawLine(Offset(center.dx - r, center.dy - 3),
            Offset(center.dx + r, center.dy - 3), glyphPaint);
        canvas.drawLine(Offset(center.dx - r, center.dy + 3),
            Offset(center.dx + r, center.dy + 3), glyphPaint);
        break;
      case 10: // Solid Dot
        glyphPaint.style = PaintingStyle.fill;
        canvas.drawCircle(center, r * 0.5, glyphPaint);
        break;
      case 11: // Bullseye
        canvas.drawCircle(center, r, glyphPaint);
        glyphPaint.style = PaintingStyle.fill;
        canvas.drawCircle(center, r * 0.35, glyphPaint);
        break;
      case 12: // Waves
        final wavePath = Path()
          ..moveTo(center.dx - r, center.dy)
          ..quadraticBezierTo(center.dx - r / 2, center.dy - 4, center.dx, center.dy)
          ..quadraticBezierTo(center.dx + r / 2, center.dy + 4, center.dx + r, center.dy);
        canvas.drawPath(wavePath, glyphPaint);
        break;
      case 13: // Checks / Grid
        canvas.drawRect(Rect.fromCenter(center: center, width: r * 1.2, height: r * 1.2), glyphPaint);
        canvas.drawLine(Offset(center.dx, center.dy - r * 0.6), Offset(center.dx, center.dy + r * 0.6), glyphPaint);
        canvas.drawLine(Offset(center.dx - r * 0.6, center.dy), Offset(center.dx + r * 0.6, center.dy), glyphPaint);
        break;
      case 14: // Chevron
        final chevPath = Path()
          ..moveTo(center.dx - r, center.dy + 3)
          ..lineTo(center.dx, center.dy - 4)
          ..lineTo(center.dx + r, center.dy + 3);
        canvas.drawPath(chevPath, glyphPaint);
        break;
      case 15: // Shield
      default:
        final shieldPath = Path()
          ..moveTo(center.dx - r, center.dy - r)
          ..lineTo(center.dx + r, center.dy - r)
          ..lineTo(center.dx + r * 0.8, center.dy + 2)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r * 0.8, center.dy + 2)
          ..close();
        canvas.drawPath(shieldPath, glyphPaint);
        break;
    }
  }
}
