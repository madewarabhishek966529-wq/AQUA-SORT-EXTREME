# Motion Design, Gradients, and Theming Guide

Aqua Sort: Extreme features a high-fidelity visual and motion presentation engine built on top of a pure Dart puzzle engine. All animations and visual effects are presentation-only: they consume state snapshots and `PourEvent` objects, never mutate puzzle logic, and guarantee that rendered liquid equals `PuzzleState` on any finish, skip, or cancellation.

---

## Architecture Overview

```
app/ (lib/)
  theme/
    aqua_palette.dart      # 4-channel shaded liquid colors, 5 themes + Boss theme, colorblind sets
    gradients.dart         # Drifting mesh painter, UI gradients, GradientText, WCAG AA contrast checker
    tube_skins.dart        # TubeSkin definitions (glass tint, rim, reflections, shadows, base cap)
    theme_provider.dart    # Riverpod reactive providers for active theme and tube skin
  motion/
    motion_tokens.dart     # Durations, easing curves (easeOutBack, springEase), time scaling
    particle_system.dart   # Zero-allocation pooled particle simulation (confetti, sparkle, splash, bubbles)
    pour_animation_controller.dart # 5-phase move sequence controller (lift, tilt, stream, transfer, settle)
    motion_budget_service.dart     # Smart adaptive motion budgeter (monitors frame times and tube count)
    effects_layer.dart     # IgnorePointer visual overlay (fluid stream, splash droplets, hint paths)
  ui/
    painters/
      tube_painter.dart    # Pure CustomPainter: vertical gradients, inner highlights, waves, meniscus, bubbles
```

---

## 1. How to Add a New Theme Palette

Theme palettes are defined entirely as data in `lib/theme/aqua_palette.dart`.

### Step 1: Define the Theme Data
```dart
static final ThemePalette myCyberTheme = ThemePalette(
  id: 'my_cyber',
  name: 'Cyber Neon',
  description: 'Deep violet abyss illuminated by electric neon currents.',
  backgroundBase: const Color(0xFF090616),
  meshBlobColors: const [
    Color(0xFFE040FB), // Top drifting blob
    Color(0xFF00E5FF), // Bottom drifting blob
    Color(0xFF7C3AED), // Center highlight blob
  ],
  surface: const Color(0xFF140D2B),
  surfaceElevated: const Color(0xFF1E133F),
  primaryAccent: const Color(0xFF00E5FF),
  secondaryAccent: const Color(0xFFFFD54F),
  textBright: const Color(0xFFF8FAFC),
  textMuted: const Color(0xFFA5B4FC),
  glassBorder: const Color(0x38E040FB),
  glassHighlight: const Color(0x75FFFFFF),
  standardLiquidColors: _createVibrantPalette(hueShift: 45, glowAlpha: 0.65),
  colorblindLiquidColors: colorblindSet,
);
```

### Step 2: Register in `allThemes`
Add the theme to `AquaPalette.allThemes`:
```dart
static final Map<String, ThemePalette> allThemes = {
  'ocean': ocean,
  'neon_night': neonNight,
  'sunset_lava': sunsetLava,
  'aurora': aurora,
  'midnight_forest': midnightForest,
  'boss': boss,
  'my_cyber': myCyberTheme, // Added here
};
```
The new theme will immediately appear in the **Settings** screen and update the background mesh, UI tokens, and tube lighting in real time.

---

## 2. How to Add a New Tube Skin

Tube skins change the physical material look of the glass test tubes: glass tint, rim style, specular gloss streak, shadows, and optional metallic base cap.

### Step 1: Define the Skin in `lib/theme/tube_skins.dart`
```dart
static const goldenAlchemist = TubeSkin(
  id: 'golden_alchemist',
  name: 'Golden Alchemist',
  description: 'Gilded brass rim and reinforced base cap with warm tinted glass.',
  accentColor: Color(0xFFFFD54F),
  glassTint: Color(0x22FFD54F),
  rimColor: Color(0xFFFFC107),
  streakColor: Color(0x66FFF8E1),
  innerShadowColor: Color(0x333E2723),
  dropShadowColor: Color(0x503E2723),
  baseCapColor: Color(0xFFFFA000),
  rimThickness: 2.6,
  glassOpacity: 0.16,
  hasBaseCap: true,
);
```

### Step 2: Register in `TubeSkinRegistry.allSkins`
```dart
static const List<TubeSkin> allSkins = [
  classicGlass,
  neonCyber,
  frozenCrystal,
  obsidianVoid,
  steampunkCopper,
  goldenAlchemist, // Added here
];
```
The skin will immediately render in the **Skins** screen with a live rendered sample tube preview and can be equipped by the player.

---

## 3. How to Add a New Particle or Motion Effect

The motion engine strictly avoids per-frame memory allocation. All particle effects use the pre-allocated `ParticlePool`.

### Step 1: Add an Emitter to `ParticlePool` in `lib/motion/particle_system.dart`
```dart
void emitLaserSpark(Offset position, Color color, int count) {
  for (var i = 0; i < count; i++) {
    final angle = _rng.nextDouble() * 2 * pi;
    final speed = 30.0 + _rng.nextDouble() * 60.0;

    spawn(
      x: position.dx,
      y: position.dy,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      ay: 40.0,
      maxLife: 0.4 + _rng.nextDouble() * 0.3,
      size: 3.0,
      color: color,
      type: ParticleType.sparkle,
      rotation: _rng.nextDouble() * 2 * pi,
      vRot: 5.0,
    );
  }
}
```

### Step 2: Call the Emitter from `GameBoard`
In `GameBoard._checkTubeCompletions` or move event listener:
```dart
if (!profile.isStatic && profile.maxParticles > 0) {
  _particlePool.emitLaserSpark(lipPosition, liquidColor, profile.maxParticles ~/ 8);
}
```

---

## 4. Adaptive Motion Budgeting ("Smart Motion")

The `MotionBudgetService` monitors real engine frame times and tube count:
- **Tubes >= 40**: Automatically disables ambient background drifting mesh, liquid bubbles, and fragment shaders, and caps particles to <= 24.
- **Average Frame Time > 16.6ms**: Automatically steps visual quality down (High -> Medium -> Low).
- **Average Frame Time < 13.0ms (Stable for 20-30 frames)**: Recovers quality back up.
- **Reduced Motion / Off Intensity**: Disables all particle spawning and looping controllers, providing instantaneous visual feedback.

A live debug overlay can be enabled in **Settings -> Motion Budget Debug Overlay** to monitor real frame times, active tube counts, and quality tier decisions.

---

## 5. Shaders & Windows Compatibility Note

Pure Canvas rendering paths were implemented with custom vertical linear gradients, radial glow filters, specular highlights, and trigonometric surface waves. This guarantees:
- 100% deterministic cross-platform execution on Windows, Android, Linux, and macOS without GPU shader compiler quirks or driver discrepancies.
- Zero dependency on external third-party shader plugins.
- Frame times under **5 ms** on boards up to 60 tubes.

---

## List of Anything Not Done

All Phase 6 requirements have been implemented and verified:
- [x] Color & gradient system: 5 themes + Boss theme + high-separation colorblind variants.
- [x] 4-channel shaded liquid colors `{base, light, dark, glow}`.
- [x] Tube skins: Classic Glass, Neon Cyber, Frozen Crystal, Obsidian Void, Steampunk Brass.
- [x] UI gradients, gradient text, and WCAG 2.1 AA text contrast validation.
- [x] Liquid rendering upgrades: surface wave, meniscus line, layer boundary blending, rising bubbles.
- [x] Reusable `PourAnimationController` with 5-phase move sequence, tap-to-skip, undo, invalid shake.
- [x] Zero-allocation pooled `ParticlePool` for confetti, sparkles, splashes, bubbles.
- [x] Adaptive `MotionBudgetService` with rolling frame time degradation/recovery and 40+ tube rules.
- [x] Ambient drifting mesh, subtle tube breathing, staggered level entrance cascade, completion lock, win dialog animations.
- [x] Comprehensive test suite (52 tests passed: widget sync, reduced motion, contrast, golden tubes, budget unit tests, intensity parity integration).
- [x] Benchmarks documented in `docs/BENCHMARKS.md`.

