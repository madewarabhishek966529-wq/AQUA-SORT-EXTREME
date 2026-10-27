import 'package:flutter/services.dart';
import 'settings_service.dart';

/// Audio playback service handling sound effects and volume toggles.
/// Fully usable muted and respects [GameSettings.soundEnabled].
class AudioService {
  final SettingsService? settingsService;

  const AudioService({this.settingsService});

  bool get isSoundEnabled =>
      settingsService?.settings.soundEnabled ?? true;

  /// Plays select / tube tap sound
  void playSelect() {
    if (!isSoundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Plays pour sound
  void playPour() {
    if (!isSoundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Plays invalid move / shake alert sound
  void playInvalid() {
    if (!isSoundEnabled) return;
    SystemSound.play(SystemSoundType.alert);
  }

  /// Plays undo sound
  void playUndo() {
    if (!isSoundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Plays victory fanfare sound
  void playVictory() {
    if (!isSoundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Plays hint chime sound
  void playHint() {
    if (!isSoundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }
}
