import 'package:flutter/material.dart';

/// Specification for tube visual style: glass tint, rim, reflections, shadows, and base cap.
class TubeSkin {
  final String id;
  final String name;
  final String description;
  final Color accentColor;
  final Color glassTint;
  final Color rimColor;
  final Color streakColor;
  final Color innerShadowColor;
  final Color dropShadowColor;
  final Color? baseCapColor;
  final double rimThickness;
  final double glassOpacity;
  final bool hasBaseCap;

  const TubeSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.accentColor,
    required this.glassTint,
    required this.rimColor,
    required this.streakColor,
    required this.innerShadowColor,
    required this.dropShadowColor,
    this.baseCapColor,
    this.rimThickness = 2.0,
    this.glassOpacity = 0.12,
    this.hasBaseCap = false,
  });
}

/// Registry of customizable tube skins selectable by the player.
class TubeSkinRegistry {
  static const classicGlass = TubeSkin(
    id: 'classic_glass',
    name: 'Classic Chemistry',
    description: 'Transparent borosilicate lab test tube with pure refractive glass gloss.',
    accentColor: Color(0xFF00E5FF),
    glassTint: Color(0x18FFFFFF),
    rimColor: Color(0x66FFFFFF),
    streakColor: Color(0x4DFFFFFF),
    innerShadowColor: Color(0x22000000),
    dropShadowColor: Color(0x40000000),
    rimThickness: 2.0,
    glassOpacity: 0.12,
  );

  static const neonCyber = TubeSkin(
    id: 'neon_cyber',
    name: 'Neon Cyberpunk',
    description: 'Reinforced polymer sleeve with luminescent purple edge rim and high gloss.',
    accentColor: Color(0xFFD500F9),
    glassTint: Color(0x22D500F9),
    rimColor: Color(0xFFE040FB),
    streakColor: Color(0x6600F5D4),
    innerShadowColor: Color(0x40000000),
    dropShadowColor: Color(0x507C3AED),
    rimThickness: 2.5,
    glassOpacity: 0.18,
  );

  static const frozenCrystal = TubeSkin(
    id: 'frozen_crystal',
    name: 'Frozen Crystal',
    description: 'Chilled frosted crystal glass with ice-edge highlights and diamond streaks.',
    accentColor: Color(0xFF00E5FF),
    glassTint: Color(0x26B8E6FC),
    rimColor: Color(0x99B8E6FC),
    streakColor: Color(0x80FFFFFF),
    innerShadowColor: Color(0x26002B49),
    dropShadowColor: Color(0x40002B49),
    rimThickness: 2.2,
    glassOpacity: 0.20,
  );

  static const obsidianVoid = TubeSkin(
    id: 'obsidian_void',
    name: 'Obsidian Void',
    description: 'Smoked obsidian tinted glass providing rich contrast for vibrant liquids.',
    accentColor: Color(0xFFFFD54F),
    glassTint: Color(0x35000000),
    rimColor: Color(0xFFFFD54F),
    streakColor: Color(0x44FFE082),
    innerShadowColor: Color(0x66000000),
    dropShadowColor: Color(0x60000000),
    rimThickness: 2.0,
    glassOpacity: 0.25,
  );

  static const steampunkCopper = TubeSkin(
    id: 'steampunk_copper',
    name: 'Steampunk Brass',
    description: 'Antiqued brass rim and metallic reinforced base cap with warm amber glass.',
    accentColor: Color(0xFFF59E0B),
    glassTint: Color(0x20F59E0B),
    rimColor: Color(0xFFD97706),
    streakColor: Color(0x66FDE68A),
    innerShadowColor: Color(0x33451A03),
    dropShadowColor: Color(0x50451A03),
    baseCapColor: Color(0xFFB45309),
    rimThickness: 2.8,
    glassOpacity: 0.18,
    hasBaseCap: true,
  );

  static const List<TubeSkin> allSkins = [
    classicGlass,
    neonCyber,
    frozenCrystal,
    obsidianVoid,
    steampunkCopper,
  ];

  static TubeSkin getSkin(String id) {
    return allSkins.firstWhere(
      (s) => s.id == id,
      orElse: () => classicGlass,
    );
  }
}

