import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../theme/aqua_palette.dart';
import '../../theme/gradients.dart';
import '../../theme/tube_skins.dart';
import '../painters/tube_painter.dart';

/// Screen allowing players to choose and equip visual tube skins with live rendered previews.
class SkinsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SkinsScreen({super.key, required this.settingsService});

  @override
  State<SkinsScreen> createState() => _SkinsScreenState();
}

class _SkinsScreenState extends State<SkinsScreen> {
  late String _selectedSkin;

  // Preview sample tube state: 3 units filled with distinct colors
  final TubeState _previewTube = TubeState([1, 2, 4], capacity: 4);

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
    final activeTheme = AquaPalette.getTheme(widget.settingsService.settings.selectedTheme);
    final skins = TubeSkinRegistry.allSkins;

    return Scaffold(
      backgroundColor: activeTheme.backgroundBase,
      appBar: AppBar(
        title: const Text('BOTTLE SKINS'),
        backgroundColor: activeTheme.surface,
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
              gradient: UIGradients.glassCardGradient(activeTheme),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEquipped ? skin.accentColor : activeTheme.glassBorder,
                width: isEquipped ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (isEquipped)
                  BoxShadow(
                    color: skin.accentColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                // Live Rendered Sample Tube Preview
                SizedBox(
                  width: 46,
                  height: 120,
                  child: CustomPaint(
                    painter: TubePainter(
                      tube: _previewTube,
                      isSelected: isEquipped,
                      glowColor: skin.accentColor,
                      theme: activeTheme,
                      skin: skin,
                      enableBubbles: false,
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Skin Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            skin.name,
                            style: TextStyle(
                              color: activeTheme.textBright,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isEquipped) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: skin.accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: skin.accentColor, width: 1),
                              ),
                              child: Text(
                                'EQUIPPED',
                                style: TextStyle(
                                  color: skin.accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        skin.description,
                        style: TextStyle(
                          color: activeTheme.textMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Equip Action Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          key: Key('equip_skin_${skin.id}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEquipped
                                ? activeTheme.surface
                                : skin.accentColor,
                            foregroundColor: isEquipped
                                ? activeTheme.textMuted
                                : Colors.black,
                            elevation: isEquipped ? 0 : 2,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isEquipped ? activeTheme.glassBorder : skin.accentColor,
                              ),
                            ),
                          ),
                          onPressed: isEquipped ? null : () => _selectSkin(skin.id),
                          child: Text(
                            isEquipped ? 'IN USE' : 'EQUIP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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
