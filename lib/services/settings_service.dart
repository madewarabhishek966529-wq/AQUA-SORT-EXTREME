import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Game configuration settings persisted via [SharedPreferences].
class GameSettings {
  final bool soundEnabled;
  final bool musicEnabled;
  final double animationIntensity; // 0.5 (fast) to 1.5 (slow)
  final bool reducedMotion;
  final bool colorblindPalette;
  final bool autoPour;
  final String selectedSkin;

  const GameSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.animationIntensity = 1.0,
    this.reducedMotion = false,
    this.colorblindPalette = false,
    this.autoPour = true,
    this.selectedSkin = 'classic_glass',
  });

  GameSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    double? animationIntensity,
    bool? reducedMotion,
    bool? colorblindPalette,
    bool? autoPour,
    String? selectedSkin,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      animationIntensity: animationIntensity ?? this.animationIntensity,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      colorblindPalette: colorblindPalette ?? this.colorblindPalette,
      autoPour: autoPour ?? this.autoPour,
      selectedSkin: selectedSkin ?? this.selectedSkin,
    );
  }
}

/// Service managing loading, updating, and persisting user settings.
class SettingsService extends ChangeNotifier {
  GameSettings _settings = const GameSettings();
  final SharedPreferences? _prefs;

  SettingsService([this._prefs]) {
    if (_prefs != null) {
      _load();
    }
  }

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  GameSettings get settings => _settings;

  void _load() {
    final prefs = _prefs;
    if (prefs == null) return;
    _settings = GameSettings(
      soundEnabled: prefs.getBool('sound_enabled') ?? true,
      musicEnabled: prefs.getBool('music_enabled') ?? true,
      animationIntensity: prefs.getDouble('anim_intensity') ?? 1.0,
      reducedMotion: prefs.getBool('reduced_motion') ?? false,
      colorblindPalette: prefs.getBool('colorblind') ?? false,
      autoPour: prefs.getBool('auto_pour') ?? true,
      selectedSkin: prefs.getString('selected_skin') ?? 'classic_glass',
    );
    notifyListeners();
  }

  Future<void> update(GameSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setBool('sound_enabled', newSettings.soundEnabled);
      await prefs.setBool('music_enabled', newSettings.musicEnabled);
      await prefs.setDouble('anim_intensity', newSettings.animationIntensity);
      await prefs.setBool('reduced_motion', newSettings.reducedMotion);
      await prefs.setBool('colorblind', newSettings.colorblindPalette);
      await prefs.setBool('auto_pour', newSettings.autoPour);
      await prefs.setString('selected_skin', newSettings.selectedSkin);
    }
  }
}

/// Riverpod provider for reactive settings service
final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  return SettingsService();
});
