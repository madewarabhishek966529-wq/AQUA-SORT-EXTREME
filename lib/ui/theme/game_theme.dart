import 'package:flutter/material.dart';

import '../../theme/aqua_palette.dart';

export '../../theme/aqua_palette.dart';
export '../../theme/gradients.dart';
export '../../theme/theme_provider.dart';
export '../../theme/tube_skins.dart';

/// Design tokens, liquid color palette, and styling for Aqua Sort: Extreme.
class GameTheme {
  // Deep navy and dark charcoal backgrounds per UI/UX spec
  static const Color backgroundDark = Color(0xFF091122);
  static const Color surfaceDark = Color(0xFF111D35);
  static const Color surfaceElevated = Color(0xFF192A4D);
  static const Color glassBorder = Color(0x38FFFFFF);
  static const Color glassHighlight = Color(0x73FFFFFF);

  // Accent & Action colors
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color accentGold = Color(0xFFFFD54F);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color textMuted = Color(0xFF8DA4C4);
  static const Color textBright = Color(0xFFF0F6FC);

  /// Retrieves liquid color from default palette (Ocean theme)
  static Color getLiquidColor(int colorId, {bool colorblind = false}) {
    return AquaPalette.ocean.getLiquidColor(colorId, colorblind: colorblind).base;
  }

  /// Shaded 4-channel liquid color (base, light, dark, glow)
  static LiquidColor getShadedLiquidColor(int colorId, {bool colorblind = false, String themeId = 'ocean'}) {
    final theme = AquaPalette.getTheme(themeId);
    return theme.getLiquidColor(colorId, colorblind: colorblind);
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
