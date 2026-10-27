import 'package:flutter/material.dart';

import '../../services/achievement_manager.dart';
import '../theme/game_theme.dart';

/// Screen displaying achievements, trophies, and milestones.
class AchievementsScreen extends StatelessWidget {
  final AchievementManager achievementManager;

  const AchievementsScreen({super.key, required this.achievementManager});

  IconData _getIconData(String name) {
    return switch (name) {
      'water_drop' => Icons.water_drop_rounded,
      'star_rounded' => Icons.star_rounded,
      'military_tech' => Icons.military_tech_rounded,
      'workspace_premium' => Icons.workspace_premium_rounded,
      'psychology' => Icons.psychology_rounded,
      'bolt' => Icons.bolt_rounded,
      'event_available' => Icons.event_available_rounded,
      _ => Icons.emoji_events_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = achievementManager.unlockedIds;
    final total = AchievementManager.allAchievements.length;

    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('ACHIEVEMENTS'),
        backgroundColor: GameTheme.surfaceDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header summary banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            color: GameTheme.surfaceElevated,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trophy Progress',
                      style: TextStyle(
                        color: GameTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${unlocked.length} of $total Unlocked',
                      style: const TextStyle(
                        color: GameTheme.accentGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.emoji_events_rounded,
                  color: GameTheme.accentGold.withValues(alpha: 0.8),
                  size: 36,
                ),
              ],
            ),
          ),

          // Achievements List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: AchievementManager.allAchievements.length,
              itemBuilder: (context, index) {
                final def = AchievementManager.allAchievements[index];
                final isUnlocked = unlocked.contains(def.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GameTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked
                          ? GameTheme.accentGold.withValues(alpha: 0.6)
                          : GameTheme.glassBorder,
                      width: isUnlocked ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? GameTheme.accentGold.withValues(alpha: 0.2)
                              : GameTheme.surfaceDark,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconData(def.iconName),
                          color: isUnlocked
                              ? GameTheme.accentGold
                              : GameTheme.textMuted.withValues(alpha: 0.4),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.title,
                              style: TextStyle(
                                color: isUnlocked
                                    ? GameTheme.textBright
                                    : GameTheme.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              def.description,
                              style: TextStyle(
                                color: GameTheme.textMuted.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: GameTheme.accentGreen,
                          size: 22,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
