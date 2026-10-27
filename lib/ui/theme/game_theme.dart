import 'package:flutter/material.dart';

/// Design tokens, liquid color palette, and styling for Aqua Sort: Extreme.
class GameTheme {
  // Deep navy and dark charcoal backgrounds per UI/UX spec
  static const Color backgroundDark = Color(0xFF0D131F);
  static const Color surfaceDark = Color(0xFF141E30);
  static const Color surfaceElevated = Color(0xFF1B283F);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x66FFFFFF);

  // Accent & Action colors
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color accentGold = Color(0xFFFFD54F);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color textMuted = Color(0xFF8A99AD);
  static const Color textBright = Color(0xFFF0F4F8);

  /// 20 vibrant, distinct liquid base colors with smooth pairing.
  /// Generates additional deterministic colors if colorId > 20.
  static Color getLiquidColor(int colorId) {
    const palette = <Color>[
      Color(0xFF00E5FF), // 1: Vibrant Cyan
      Color(0xFFFF1744), // 2: Crimson Red
      Color(0xFFFFD600), // 3: Bright Gold / Yellow
      Color(0xFF00E676), // 4: Neon Emerald Green
      Color(0xFFD500F9), // 5: Radiant Magenta / Orchid
      Color(0xFFFF6D00), // 6: Sunset Orange
      Color(0xFF2979FF), // 7: Royal Blue
      Color(0xFF76FF03), // 8: Lime Green
      Color(0xFFFF4081), // 9: Hot Pink
      Color(0xFF651FFF), // 10: Deep Indigo / Violet
      Color(0xFF00B0FF), // 11: Sky Blue
      Color(0xFF1DE9B6), // 12: Aquamarine / Teal
      Color(0xFFFF9100), // 13: Amber
      Color(0xFFAEEA00), // 14: Chartreuse
      Color(0xFFE040FB), // 15: Neon Purple
      Color(0xFFFF5252), // 16: Coral
      Color(0xFF00BFA5), // 17: Dark Teal
      Color(0xFF7C4DFF), // 18: Lavender / Purple
      Color(0xFFFFAB00), // 19: Deep Gold
      Color(0xFF00E5FF), // 20: Electric Blue
    ];

    if (colorId >= 1 && colorId <= palette.length) {
      return palette[colorId - 1];
    }

    // Deterministic HSL generation for larger color counts (up to 60+ bottles)
    final hue = ((colorId * 137.508) % 360).toDouble(); // Golden ratio hue spread
    return HSLColor.fromAHSL(1.0, hue, 0.85, 0.55).toColor();
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'Segoe UI',
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentGold,
        surface: surfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
