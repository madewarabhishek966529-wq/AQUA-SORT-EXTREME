import 'package:flutter/material.dart';

/// Represents a 4-channel shaded liquid color unit:
/// [base] is the core color,
/// [light] is the lighter top gradient/highlight,
/// [dark] is the richer deeper bottom gradient,
/// [glow] is the soft ambient glow tint.
class LiquidColor {
  final Color base;
  final Color light;
  final Color dark;
  final Color glow;

  const LiquidColor({
    required this.base,
    required this.light,
    required this.dark,
    required this.glow,
  });

  /// Factory constructing a shaded [LiquidColor] from a single base color.
  factory LiquidColor.fromBase(Color base) {
    final hsl = HSLColor.fromColor(base);
    final lightHsl = hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 0.95));
    final darkHsl = hsl.withLightness((hsl.lightness - 0.20).clamp(0.05, 1.0));
    final glowColor = base.withValues(alpha: 0.5);

    return LiquidColor(
      base: base,
      light: lightHsl.toColor(),
      dark: darkHsl.toColor(),
      glow: glowColor,
    );
  }
}

/// Pattern types used for non-color accessibility cues.
enum ColorblindPattern {
  dots,
  stripes,
  waves,
  checks,
  diamonds,
  rings,
  crosses,
  stars,
  triangles,
  chevrons,
  grid,
  zigzag,
  hexagons,
  plus,
  spirals,
  shield,
}

/// Theme palette definition providing background mesh colors, liquid sets,
/// UI token colors, and accessible contrast palettes.
class ThemePalette {
  final String id;
  final String name;
  final String description;
  final Color backgroundBase;
  final List<Color> meshBlobColors; // 2 to 3 drifting soft color blobs
  final Color surface;
  final Color surfaceElevated;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color textBright;
  final Color textMuted;
  final Color glassBorder;
  final Color glassHighlight;
  final List<LiquidColor> standardLiquidColors;
  final List<LiquidColor> colorblindLiquidColors;
  final bool isBoss;

  const ThemePalette({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundBase,
    required this.meshBlobColors,
    required this.surface,
    required this.surfaceElevated,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.textBright,
    required this.textMuted,
    required this.glassBorder,
    required this.glassHighlight,
    required this.standardLiquidColors,
    required this.colorblindLiquidColors,
    this.isBoss = false,
  });

  /// Retrieves the shaded [LiquidColor] for [colorId] (1-indexed).
  /// Falls back to deterministic HSL calculation if colorId exceeds preconfigured palette.
  LiquidColor getLiquidColor(int colorId, {bool colorblind = false}) {
    final list = colorblind ? colorblindLiquidColors : standardLiquidColors;
    if (colorId >= 1 && colorId <= list.length) {
      return list[colorId - 1];
    }

    // Deterministic golden ratio hue generation for extreme boards (up to 60+ bottles)
    final hue = ((colorId * 137.508) % 360).toDouble();
    final baseColor = HSLColor.fromAHSL(1.0, hue, 0.85, 0.55).toColor();
    return LiquidColor.fromBase(baseColor);
  }

  /// Returns the accessible pattern glyph assigned to [colorId].
  static ColorblindPattern getPattern(int colorId) {
    const patterns = ColorblindPattern.values;
    final index = (colorId - 1).clamp(0, patterns.length - 1);
    return patterns[index % patterns.length];
  }
}

/// Palette repository containing all 5 themes + Boss theme and colorblind variants.
class AquaPalette {
  // Shared universal high-separation accessible Okabe-Ito / Tol liquid color palette
  static final List<LiquidColor> colorblindSet = [
    LiquidColor(
      base: const Color(0xFF0072B2),
      light: const Color(0xFF3399D4),
      dark: const Color(0xFF004D7A),
      glow: const Color(0x660072B2),
    ), // 1: Blue
    LiquidColor(
      base: const Color(0xFFE69F00),
      light: const Color(0xFFFFBF33),
      dark: const Color(0xFFB37B00),
      glow: const Color(0x66E69F00),
    ), // 2: Amber Orange
    LiquidColor(
      base: const Color(0xFF56B4E9),
      light: const Color(0xFF8AD1F7),
      dark: const Color(0xFF268CBD),
      glow: const Color(0x6656B4E9),
    ), // 3: Sky Blue
    LiquidColor(
      base: const Color(0xFF009E73),
      light: const Color(0xFF26C697),
      dark: const Color(0xFF006B4E),
      glow: const Color(0x66009E73),
    ), // 4: Bluish Green
    LiquidColor(
      base: const Color(0xFFF0E442),
      light: const Color(0xFFFFF275),
      dark: const Color(0xFFC7BC1A),
      glow: const Color(0x66F0E442),
    ), // 5: Pale Yellow
    LiquidColor(
      base: const Color(0xFFD55E00),
      light: const Color(0xFFFF8533),
      dark: const Color(0xFF9E4500),
      glow: const Color(0x66D55E00),
    ), // 6: Vermilion Red
    LiquidColor(
      base: const Color(0xFFCC79A7),
      light: const Color(0xFFE5A3C7),
      dark: const Color(0xFF9E4778),
      glow: const Color(0x66CC79A7),
    ), // 7: Reddish Purple
    LiquidColor(
      base: const Color(0xFF332288),
      light: const Color(0xFF5945B0),
      dark: const Color(0xFF1E1452),
      glow: const Color(0x66332288),
    ), // 8: Indigo
    LiquidColor(
      base: const Color(0xFF117733),
      light: const Color(0xFF22AA55),
      dark: const Color(0xFF08481E),
      glow: const Color(0x66117733),
    ), // 9: Forest Green
    LiquidColor(
      base: const Color(0xFF44AA99),
      light: const Color(0xFF6ED0BF),
      dark: const Color(0xFF267366),
      glow: const Color(0x6644AA99),
    ), // 10: Teal
    LiquidColor(
      base: const Color(0xFF88CCEE),
      light: const Color(0xFFB8E6FC),
      dark: const Color(0xFF539DBE),
      glow: const Color(0x6688CCEE),
    ), // 11: Light Cyan
    LiquidColor(
      base: const Color(0xFFDDCC77),
      light: const Color(0xFFF5E6A3),
      dark: const Color(0xFFA69647),
      glow: const Color(0x66DDCC77),
    ), // 12: Sand
    LiquidColor(
      base: const Color(0xFFCC6677),
      light: const Color(0xFFE893A0),
      dark: const Color(0xFF993B4A),
      glow: const Color(0x66CC6677),
    ), // 13: Rose
    LiquidColor(
      base: const Color(0xFFAA4499),
      light: const Color(0xFFCC72BC),
      dark: const Color(0xFF78236A),
      glow: const Color(0x66AA4499),
    ), // 14: Orchid Purple
    LiquidColor(
      base: const Color(0xFF882255),
      light: const Color(0xFFB5457C),
      dark: const Color(0xFF520E30),
      glow: const Color(0x66882255),
    ), // 15: Wine
    LiquidColor(
      base: const Color(0xFF999933),
      light: const Color(0xFFC7C75C),
      dark: const Color(0xFF666614),
      glow: const Color(0x66999933),
    ), // 16: Olive
  ];

  // 1. Theme: Ocean
  static final ThemePalette ocean = ThemePalette(
    id: 'ocean',
    name: 'Ocean Deep',
    description: 'Deep oceanic abyss with luminescent cyan and azure fluid currents.',
    backgroundBase: const Color(0xFF091122),
    meshBlobColors: const [
      Color(0xFF00E5FF), // Cyan
      Color(0xFF1E3A8A), // Deep Royal Navy
      Color(0xFF0D9488), // Oceanic Teal
    ],
    surface: const Color(0xFF111D35),
    surfaceElevated: const Color(0xFF192A4D),
    primaryAccent: const Color(0xFF00E5FF),
    secondaryAccent: const Color(0xFFFFD54F),
    textBright: const Color(0xFFF0F6FC),
    textMuted: const Color(0xFF8DA4C4),
    glassBorder: const Color(0x38FFFFFF),
    glassHighlight: const Color(0x73FFFFFF),
    standardLiquidColors: _createVibrantPalette(
      hueShift: 0,
      glowAlpha: 0.55,
    ),
    colorblindLiquidColors: colorblindSet,
  );

  // 2. Theme: Neon Night
  static final ThemePalette neonNight = ThemePalette(
    id: 'neon_night',
    name: 'Neon Night',
    description: 'Cyberpunk midnight charcoal illuminated by electric magenta and synthwave cyan.',
    backgroundBase: const Color(0xFF0B0C12),
    meshBlobColors: const [
      Color(0xFFD500F9), // Electric Magenta
      Color(0xFF00F5D4), // Cyber Mint Cyan
      Color(0xFF3B0764), // Midnight Ultraviolet
    ],
    surface: const Color(0xFF141522),
    surfaceElevated: const Color(0xFF1E2033),
    primaryAccent: const Color(0xFFD500F9),
    secondaryAccent: const Color(0xFF00F5D4),
    textBright: const Color(0xFFFAF5FF),
    textMuted: const Color(0xFFA8A29E),
    glassBorder: const Color(0x40E040FB),
    glassHighlight: const Color(0x80FFFFFF),
    standardLiquidColors: _createVibrantPalette(
      hueShift: 40,
      glowAlpha: 0.65,
    ),
    colorblindLiquidColors: colorblindSet,
  );

  // 3. Theme: Sunset Lava
  static final ThemePalette sunsetLava = ThemePalette(
    id: 'sunset_lava',
    name: 'Sunset Lava',
    description: 'Smoldering obsidian depths with molten amber and radiant crimson magma.',
    backgroundBase: const Color(0xFF160A0D),
    meshBlobColors: const [
      Color(0xFFDC2626), // Lava Crimson
      Color(0xFFEA580C), // Radiant Blaze Orange
      Color(0xFFD97706), // Molten Amber
    ],
    surface: const Color(0xFF221116),
    surfaceElevated: const Color(0xFF331A21),
    primaryAccent: const Color(0xFFFF5722),
    secondaryAccent: const Color(0xFFFFC107),
    textBright: const Color(0xFFFFF7ED),
    textMuted: const Color(0xFFC7A7A1),
    glassBorder: const Color(0x40FF7043),
    glassHighlight: const Color(0x80FFE0B2),
    standardLiquidColors: _createVibrantPalette(
      hueShift: 15,
      glowAlpha: 0.55,
    ),
    colorblindLiquidColors: colorblindSet,
  );

  // 4. Theme: Aurora
  static final ThemePalette aurora = ThemePalette(
    id: 'aurora',
    name: 'Aurora Borealis',
    description: 'Sub-zero arctic midnight kissed by drifting ribbons of emerald and cosmic violet.',
    backgroundBase: const Color(0xFF05131E),
    meshBlobColors: const [
      Color(0xFF10B981), // Boreal Emerald
      Color(0xFF06B6D4), // Arctic Cyan
      Color(0xFF8B5CF6), // Cosmic Violet
    ],
    surface: const Color(0xFF0B2133),
    surfaceElevated: const Color(0xFF13324C),
    primaryAccent: const Color(0xFF10B981),
    secondaryAccent: const Color(0xFFA78BFA),
    textBright: const Color(0xFFECFDF5),
    textMuted: const Color(0xFF8DB3A4),
    glassBorder: const Color(0x4034D399),
    glassHighlight: const Color(0x80A7F3D0),
    standardLiquidColors: _createVibrantPalette(
      hueShift: 90,
      glowAlpha: 0.6,
    ),
    colorblindLiquidColors: colorblindSet,
  );

  // 5. Theme: Midnight Forest
  static final ThemePalette midnightForest = ThemePalette(
    id: 'midnight_forest',
    name: 'Midnight Forest',
    description: 'Enchanted moss twilight alive with bioluminescent flora and deep jade streams.',
    backgroundBase: const Color(0xFF07140E),
    meshBlobColors: const [
      Color(0xFF059669), // Mystic Jade
      Color(0xFF064E3B), // Deep Pine
      Color(0xFF34D399), // Mint Glow
    ],
    surface: const Color(0xFF0F261B),
    surfaceElevated: const Color(0xFF173828),
    primaryAccent: const Color(0xFF34D399),
    secondaryAccent: const Color(0xFFFBBF24),
    textBright: const Color(0xFFF0FDF4),
    textMuted: const Color(0xFF86A896),
    glassBorder: const Color(0x386EE7B7),
    glassHighlight: const Color(0x75A7F3D0),
    standardLiquidColors: _createVibrantPalette(
      hueShift: 120,
      glowAlpha: 0.55,
    ),
    colorblindLiquidColors: colorblindSet,
  );

  // 6. Boss Level Theme: Void Overlord
  static final ThemePalette boss = ThemePalette(
    id: 'boss',
    name: 'Abyssal Void',
    description: 'Ominous abyssal rift pulsating with dark energy and forbidden crimson flames.',
    backgroundBase: const Color(0xFF0A0413),
    meshBlobColors: const [
      Color(0xFF581C87), // Shadow Void Purple
      Color(0xFF7F1D1D), // Dark Blood Crimson
      Color(0xFF312E81), // Abyssal Indigo
    ],
    surface: const Color(0xFF160A26),
    surfaceElevated: const Color(0xFF24113E),
    primaryAccent: const Color(0xFFEF4444),
    secondaryAccent: const Color(0xFFA855F7),
    textBright: const Color(0xFFFAF5FF),
    textMuted: const Color(0xFFA899BA),
    glassBorder: const Color(0x50EF4444),
    glassHighlight: const Color(0x80C084FC),
    standardLiquidColors: _createVibrantPalette(
      hueShift: 270,
      glowAlpha: 0.7,
    ),
    colorblindLiquidColors: colorblindSet,
    isBoss: true,
  );

  /// Map of all available themes indexed by identifier.
  static final Map<String, ThemePalette> allThemes = {
    'ocean': ocean,
    'neon_night': neonNight,
    'sunset_lava': sunsetLava,
    'aurora': aurora,
    'midnight_forest': midnightForest,
    'boss': boss,
  };

  /// Retrieves theme by ID, falling back to [ocean].
  static ThemePalette getTheme(String id) {
    return allThemes[id] ?? ocean;
  }

  /// Internal helper generating 16 core distinct liquid colors.
  static List<LiquidColor> _createVibrantPalette({
    double hueShift = 0.0,
    double glowAlpha = 0.55,
  }) {
    const rawBases = <Color>[
      Color(0xFF00E5FF), // 1: Cyan
      Color(0xFFFF1744), // 2: Crimson
      Color(0xFFFFD600), // 3: Gold
      Color(0xFF00E676), // 4: Neon Green
      Color(0xFFD500F9), // 5: Radiant Magenta
      Color(0xFFFF6D00), // 6: Sunset Orange
      Color(0xFF2979FF), // 7: Royal Blue
      Color(0xFF76FF03), // 8: Lime Green
      Color(0xFFFF4081), // 9: Hot Pink
      Color(0xFF651FFF), // 10: Indigo
      Color(0xFF00B0FF), // 11: Sky Blue
      Color(0xFF1DE9B6), // 12: Aquamarine
      Color(0xFFFF9100), // 13: Amber
      Color(0xFFAEEA00), // 14: Chartreuse
      Color(0xFFE040FB), // 15: Neon Purple
      Color(0xFFFF5252), // 16: Coral
    ];

    return rawBases.map((base) {
      if (hueShift == 0.0) {
        return LiquidColor.fromBase(base);
      }
      final hsl = HSLColor.fromColor(base);
      final newHue = (hsl.hue + hueShift) % 360.0;
      final shifted = hsl.withHue(newHue).toColor();
      return LiquidColor.fromBase(shifted);
    }).toList();
  }
}
