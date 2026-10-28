import 'dart:math';
import 'package:flutter/material.dart';

import 'aqua_palette.dart';

/// CustomPainter rendering a slow animated gradient mesh of 2-3 drifting soft color blobs
/// over a deep base color, creating an immersive, alive background.
class MeshGradientPainter extends CustomPainter {
  final ThemePalette theme;
  final double animationProgress; // 0.0 to 1.0 looping
  final bool isStatic; // When reduced motion or animation is Off

  MeshGradientPainter({
    required this.theme,
    required this.animationProgress,
    this.isStatic = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw solid deep base background
    final basePaint = Paint()..color = theme.backgroundBase;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), basePaint);

    if (w <= 0 || h <= 0) return;

    // If static, draw resting blobs at fixed aesthetic positions
    final t = isStatic ? 0.0 : animationProgress * 2 * pi;

    final blobs = theme.meshBlobColors;
    if (blobs.isEmpty) return;

    // Blob 1: Gentle circular drift (top-left to center-left)
    final blob1Pos = Offset(
      w * (0.28 + (isStatic ? 0.0 : 0.14 * sin(t))),
      h * (0.30 + (isStatic ? 0.0 : 0.12 * cos(t))),
    );
    final blob1Radius = max(w, h) * 0.55;
    final blob1Paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          blobs[0].withValues(alpha: 0.38),
          blobs[0].withValues(alpha: 0.12),
          blobs[0].withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: blob1Pos, radius: blob1Radius));
    canvas.drawCircle(blob1Pos, blob1Radius, blob1Paint);

    // Blob 2: Figure-eight drift (bottom-right to center-right)
    if (blobs.length > 1) {
      final blob2Pos = Offset(
        w * (0.72 + (isStatic ? 0.0 : 0.15 * cos(t * 0.7))),
        h * (0.68 + (isStatic ? 0.0 : 0.13 * sin(t * 1.4))),
      );
      final blob2Radius = max(w, h) * 0.60;
      final blob2Paint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.5,
          colors: [
            blobs[1].withValues(alpha: 0.32),
            blobs[1].withValues(alpha: 0.10),
            blobs[1].withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(Rect.fromCircle(center: blob2Pos, radius: blob2Radius));
      canvas.drawCircle(blob2Pos, blob2Radius, blob2Paint);
    }

    // Blob 3: Floating subtle center-top highlight
    if (blobs.length > 2) {
      final blob3Pos = Offset(
        w * (0.50 + (isStatic ? 0.0 : 0.18 * sin(t * 0.5 + 1.2))),
        h * (0.18 + (isStatic ? 0.0 : 0.10 * cos(t * 0.9))),
      );
      final blob3Radius = max(w, h) * 0.45;
      final blob3Paint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.5,
          colors: [
            blobs[2].withValues(alpha: 0.28),
            blobs[2].withValues(alpha: 0.08),
            blobs[2].withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: blob3Pos, radius: blob3Radius));
      canvas.drawCircle(blob3Pos, blob3Radius, blob3Paint);
    }

    // Boss level ominous ambient vignette
    if (theme.isBoss) {
      final borderVignette = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Colors.transparent,
            theme.primaryAccent.withValues(alpha: isStatic ? 0.25 : (0.2 + 0.12 * sin(t * 2))),
          ],
          stops: const [0.65, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), borderVignette);
    }
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter oldDelegate) {
    if (isStatic && oldDelegate.isStatic) {
      return oldDelegate.theme.id != theme.id;
    }
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.theme.id != theme.id ||
        oldDelegate.isStatic != isStatic;
  }
}

/// Helper building gradients for liquid, UI buttons, cards, and text.
class UIGradients {
  /// Button gradient with glowing primary-to-secondary slant
  static LinearGradient buttonGradient(ThemePalette theme, {bool isHovered = false}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        isHovered
            ? theme.primaryAccent.withValues(alpha: 0.95)
            : theme.primaryAccent.withValues(alpha: 0.80),
        isHovered
            ? theme.secondaryAccent.withValues(alpha: 0.85)
            : theme.secondaryAccent.withValues(alpha: 0.65),
      ],
    );
  }

  /// Glass container gradient fill
  static LinearGradient glassCardGradient(ThemePalette theme) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.surfaceElevated.withValues(alpha: 0.85),
        theme.surface.withValues(alpha: 0.70),
      ],
    );
  }

  /// Win title gradient (radiant gold to cyan)
  static const LinearGradient victoryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD54F),
      Color(0xFF00E5FF),
      Color(0xFF00E676),
    ],
  );

  /// Level title gradient
  static LinearGradient levelTitleGradient(ThemePalette theme) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        theme.primaryAccent,
        theme.textBright,
        theme.secondaryAccent,
      ],
    );
  }
}

/// Rich gradient text widget using [ShaderMask] for level headers, win screens, etc.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// WCAG 2.1 Contrast Checker computing relative luminance and contrast ratios.
class WcagContrast {
  /// Computes relative luminance according to WCAG 2.1 formula.
  static double relativeLuminance(Color color) {
    double transformComponent(double c) {
      return (c <= 0.04045)
          ? (c / 12.92)
          : pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transformComponent(color.red / 255.0);
    final g = transformComponent(color.green / 255.0);
    final b = transformComponent(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Computes contrast ratio between [foreground] and [background].
  /// Value is always >= 1.0 and <= 21.0.
  static double contrastRatio(Color foreground, Color background) {
    final l1 = relativeLuminance(foreground);
    final l2 = relativeLuminance(background);

    final lighter = max(l1, l2);
    final darker = min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Checks if [foreground] over [background] satisfies WCAG AA.
  /// Standard text requires ratio >= 4.5:1.
  /// Large text (>= 18pt or >= 14pt bold) requires ratio >= 3.0:1.
  static bool meetsAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = contrastRatio(foreground, background);
    return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
  }
}
