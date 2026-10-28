import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';
import 'aqua_palette.dart';
import 'tube_skins.dart';

/// Provides current active ThemePalette reacting to player settings.
final activeThemePaletteProvider = Provider<ThemePalette>((ref) {
  final settings = ref.watch(settingsServiceProvider).settings;
  return AquaPalette.getTheme(settings.selectedTheme);
});

/// Provides current active TubeSkin reacting to player settings.
final activeTubeSkinProvider = Provider<TubeSkin>((ref) {
  final settings = ref.watch(settingsServiceProvider).settings;
  return TubeSkinRegistry.getSkin(settings.selectedSkin);
});
