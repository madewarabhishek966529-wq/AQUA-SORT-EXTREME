import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../theme/game_theme.dart';

/// Interactive Settings screen for audio, animations, accessibility, and gameplay controls.
class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsScreen({super.key, required this.settingsService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsService.settings;
  }

  void _update(GameSettings next) {
    setState(() => _settings = next);
    widget.settingsService.update(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        backgroundColor: GameTheme.surfaceDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildSectionHeader('AUDIO'),
          _buildSwitchTile(
            title: 'Sound Effects',
            subtitle: 'Play liquid pour, selection, and victory sounds',
            value: _settings.soundEnabled,
            icon: Icons.volume_up_rounded,
            onChanged: (v) => _update(_settings.copyWith(soundEnabled: v)),
          ),
          _buildSwitchTile(
            title: 'Ambient Music',
            subtitle: 'Atmospheric background puzzle music',
            value: _settings.musicEnabled,
            icon: Icons.music_note_rounded,
            onChanged: (v) => _update(_settings.copyWith(musicEnabled: v)),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('GAMEPLAY & ACCESSIBILITY'),
          _buildSwitchTile(
            title: 'Auto-Pour',
            subtitle: 'Automatically transfer liquid when only one valid move exists',
            value: _settings.autoPour,
            icon: Icons.water_drop_rounded,
            onChanged: (v) => _update(_settings.copyWith(autoPour: v)),
          ),
          _buildSwitchTile(
            title: 'Colorblind Assist',
            subtitle: 'Enhances color contrast and distinct color mapping',
            value: _settings.colorblindPalette,
            icon: Icons.visibility_rounded,
            onChanged: (v) => _update(_settings.copyWith(colorblindPalette: v)),
          ),
          _buildSwitchTile(
            title: 'Reduced Motion',
            subtitle: 'Disable particle bursts and simplify animations',
            value: _settings.reducedMotion,
            icon: Icons.motion_photos_off_rounded,
            onChanged: (v) => _update(_settings.copyWith(reducedMotion: v)),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('ANIMATION SPEED'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GameTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GameTheme.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pour Speed',
                      style: TextStyle(
                        color: GameTheme.textBright,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_settings.animationIntensity.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        color: GameTheme.primaryCyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _settings.animationIntensity,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  activeColor: GameTheme.primaryCyan,
                  inactiveColor: GameTheme.surfaceDark,
                  onChanged: (v) => _update(_settings.copyWith(animationIntensity: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: GameTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GameTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameTheme.glassBorder),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GameTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: GameTheme.primaryCyan, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: GameTheme.textBright,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: GameTheme.textMuted,
            fontSize: 12,
          ),
        ),
        value: value,
        activeThumbColor: GameTheme.primaryCyan,
        onChanged: onChanged,
      ),
    );
  }
}
