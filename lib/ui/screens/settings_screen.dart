import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../theme/aqua_palette.dart';
import '../theme/game_theme.dart';

/// Interactive Settings screen for audio, visual themes, animation intensity,
/// accessibility, and gameplay controls.
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
    final activeTheme = AquaPalette.getTheme(_settings.selectedTheme);

    return Scaffold(
      backgroundColor: activeTheme.backgroundBase,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        backgroundColor: activeTheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 1. THEMES
          _buildSectionHeader(activeTheme, 'VISUAL THEME'),
          _buildThemeSelector(activeTheme),
          const SizedBox(height: 24),

          // 2. ANIMATION INTENSITY
          _buildSectionHeader(activeTheme, 'ANIMATION INTENSITY'),
          _buildIntensitySelector(activeTheme),
          const SizedBox(height: 24),

          // 3. ACCESSIBILITY & MOTION
          _buildSectionHeader(activeTheme, 'ACCESSIBILITY & MOTION'),
          _buildSwitchTile(
            theme: activeTheme,
            title: 'Reduced Motion',
            subtitle: 'Instant animations, static background, and no particle bursts',
            value: _settings.reducedMotion,
            icon: Icons.motion_photos_off_rounded,
            onChanged: (v) => _update(_settings.copyWith(reducedMotion: v)),
          ),
          _buildSwitchTile(
            theme: activeTheme,
            title: 'Colorblind Assist & Glyphs',
            subtitle: 'Enhances separation and displays accessible geometric symbol overlays',
            value: _settings.colorblindPalette,
            icon: Icons.visibility_rounded,
            onChanged: (v) => _update(_settings.copyWith(colorblindPalette: v)),
          ),
          _buildSwitchTile(
            theme: activeTheme,
            title: 'Motion Budget Debug Overlay',
            subtitle: 'Display live frametime measurements and smart motion tier decisions',
            value: _settings.showMotionDebugOverlay,
            icon: Icons.developer_mode_rounded,
            onChanged: (v) => _update(_settings.copyWith(showMotionDebugOverlay: v)),
          ),
          const SizedBox(height: 24),

          // 4. AUDIO
          _buildSectionHeader(activeTheme, 'AUDIO'),
          _buildSwitchTile(
            theme: activeTheme,
            title: 'Sound Effects',
            subtitle: 'Play liquid pour, selection, and victory sounds',
            value: _settings.soundEnabled,
            icon: Icons.volume_up_rounded,
            onChanged: (v) => _update(_settings.copyWith(soundEnabled: v)),
          ),
          _buildSwitchTile(
            theme: activeTheme,
            title: 'Ambient Music',
            subtitle: 'Atmospheric background puzzle music',
            value: _settings.musicEnabled,
            icon: Icons.music_note_rounded,
            onChanged: (v) => _update(_settings.copyWith(musicEnabled: v)),
          ),
          const SizedBox(height: 24),

          // 5. GAMEPLAY
          _buildSectionHeader(activeTheme, 'GAMEPLAY'),
          _buildSwitchTile(
            theme: activeTheme,
            title: 'Auto-Pour',
            subtitle: 'Automatically transfer liquid when only one valid move exists',
            value: _settings.autoPour,
            icon: Icons.water_drop_rounded,
            onChanged: (v) => _update(_settings.copyWith(autoPour: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemePalette activeTheme) {
    final themeList = AquaPalette.allThemes.values.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: themeList.map((t) {
              final isSelected = _settings.selectedTheme == t.id;
              return GestureDetector(
                onTap: () => _update(_settings.copyWith(selectedTheme: t.id)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.primaryAccent.withValues(alpha: 0.25)
                        : activeTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? t.primaryAccent : activeTheme.glassBorder,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.name,
                        style: TextStyle(
                          color: isSelected ? activeTheme.textBright : activeTheme.textMuted,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            activeTheme.description,
            style: TextStyle(color: activeTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySelector(ThemePalette theme) {
    const options = [
      ('Off', 0.0),
      ('Low', 0.5),
      ('Medium', 1.0),
      ('High', 1.5),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Animation Speed & Particles',
                style: TextStyle(
                  color: theme.textBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _settings.intensityLevel.name.toUpperCase(),
                style: TextStyle(
                  color: theme.primaryAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: options.map((opt) {
              final isSelected = (_settings.animationIntensity - opt.$2).abs() < 0.2;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? theme.primaryAccent
                          : theme.surface,
                      foregroundColor: isSelected ? Colors.black : theme.textBright,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: isSelected ? 3 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? theme.primaryAccent : theme.glassBorder,
                        ),
                      ),
                    ),
                    onPressed: () => _update(_settings.copyWith(animationIntensity: opt.$2)),
                    child: Text(
                      opt.$1,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            _settings.intensityLevel == AnimationIntensityLevel.off
                ? 'Instant transitions: all particles and looping ambient motion disabled.'
                : 'Scales pour duration, surface waves, and particle counts.',
            style: TextStyle(color: theme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemePalette theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: theme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required ThemePalette theme,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.glassBorder),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.primaryAccent, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textBright,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 12,
          ),
        ),
        value: value,
        activeThumbColor: theme.primaryAccent,
        onChanged: onChanged,
      ),
    );
  }
}
