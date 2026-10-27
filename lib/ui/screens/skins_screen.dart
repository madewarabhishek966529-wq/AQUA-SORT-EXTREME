import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../painters/tube_painter.dart';
import '../theme/game_theme.dart';

class SkinDef {
  final String id;
  final String name;
  final String description;
  final Color accentColor;

  const SkinDef({
    required this.id,
    required this.name,
    required this.description,
    required this.accentColor,
  });
}

/// Screen allowing players to choose visual bottle themes and liquid palettes.
class SkinsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SkinsScreen({super.key, required this.settingsService});

  @override
  State<SkinsScreen> createState() => _SkinsScreenState();
}

class _SkinsScreenState extends State<SkinsScreen> {
  late String _selectedSkin;

  static const List<SkinDef> skins = [
    SkinDef(
      id: 'classic_glass',
      name: 'Classic Chemistry',
      description: 'Transparent borosilicate lab test tubes with refractive gloss.',
      accentColor: GameTheme.primaryCyan,
    ),
    SkinDef(
      id: 'neon_cyber',
      name: 'Neon Cyberpunk',
      description: 'Luminescent edge glow with intense neon liquid luminescence.',
      accentColor: Color(0xFFD500F9),
    ),
    SkinDef(
      id: 'frozen_crystal',
      name: 'Frozen Crystal',
      description: 'Chilled frosted crystal glass with ice-edge reflections.',
      accentColor: Color(0xFF00E5FF),
    ),
    SkinDef(
      id: 'obsidian_void',
      name: 'Obsidian Void',
      description: 'Deep smoked obsidian glass with vivid liquid contrast.',
      accentColor: GameTheme.accentGold,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSkin = widget.settingsService.settings.selectedSkin;
  }

  void _selectSkin(String id) {
    setState(() => _selectedSkin = id);
    widget.settingsService.update(
      widget.settingsService.settings.copyWith(selectedSkin: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('BOTTLE SKINS'),
        backgroundColor: GameTheme.surfaceDark,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: skins.length,
        itemBuilder: (context, index) {
          final skin = skins[index];
          final isEquipped = _selectedSkin == skin.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: GameTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEquipped ? skin.accentColor : GameTheme.glassBorder,
                width: isEquipped ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Mini preview of tube
                SizedBox(
                  width: 36,
                  height: 90,
                  child: CustomPaint(
                    painter: TubePainter(
                      tube: TubeState([1, 2, 3]),
                      isSelected: isEquipped,
                      glowColor: skin.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.name,
                        style: const TextStyle(
                          color: GameTheme.textBright,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        skin.description,
                        style: const TextStyle(
                          color: GameTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: isEquipped ? null : () => _selectSkin(skin.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isEquipped ? GameTheme.surfaceDark : skin.accentColor,
                          foregroundColor: isEquipped ? GameTheme.textMuted : Colors.black,
                          elevation: isEquipped ? 0 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          isEquipped ? 'EQUIPPED' : 'EQUIP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
