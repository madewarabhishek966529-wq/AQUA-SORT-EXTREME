import 'package:flutter/foundation.dart';
import 'save_repository.dart';

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String iconName;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
  });
}

/// Event-driven manager for unlocking and tracking achievements.
class AchievementManager extends ChangeNotifier {
  final SaveRepository repository;
  final Set<String> _unlockedIds = {};

  static const List<AchievementDef> allAchievements = [
    AchievementDef(
      id: 'first_pour',
      title: 'First Drop',
      description: 'Make your very first liquid pour.',
      iconName: 'water_drop',
    ),
    AchievementDef(
      id: 'level_1_complete',
      title: 'Color Novice',
      description: 'Successfully complete Level 1.',
      iconName: 'star_rounded',
    ),
    AchievementDef(
      id: 'reach_10_levels',
      title: 'Tube Apprentice',
      description: 'Complete 10 levels in your sorting journey.',
      iconName: 'military_tech',
    ),
    AchievementDef(
      id: 'expert_complete',
      title: 'Master Sorter',
      description: 'Conquer an Expert or higher tier puzzle.',
      iconName: 'workspace_premium',
    ),
    AchievementDef(
      id: 'no_undo_win',
      title: 'Flawless Mind',
      description: 'Solve a puzzle without using Undo once.',
      iconName: 'psychology',
    ),
    AchievementDef(
      id: 'speed_demon',
      title: 'Speed Sorter',
      description: 'Solve a puzzle in under 45 seconds.',
      iconName: 'bolt',
    ),
    AchievementDef(
      id: 'daily_streak',
      title: 'Daily Dedication',
      description: 'Complete a Daily Challenge puzzle.',
      iconName: 'event_available',
    ),
  ];

  AchievementManager({required this.repository});

  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);

  Future<void> init() async {
    final ids = await repository.loadAchievements();
    _unlockedIds.addAll(ids);
    notifyListeners();
  }

  bool isUnlocked(String id) => _unlockedIds.contains(id);

  Future<bool> unlock(String id) async {
    if (_unlockedIds.contains(id)) return false;

    _unlockedIds.add(id);
    notifyListeners();
    await repository.saveAchievements([id]);
    return true;
  }

  /// Event hook: on any player pour
  Future<void> onPour() async {
    await unlock('first_pour');
  }

  /// Event hook: on winning a level
  Future<void> onLevelWon({
    required int levelNumber,
    required int moves,
    required int timeSeconds,
    required bool usedUndo,
    required String tier,
  }) async {
    if (levelNumber == 1) {
      await unlock('level_1_complete');
    }
    if (levelNumber >= 10) {
      await unlock('reach_10_levels');
    }
    if (tier == 'Expert' || tier == 'Nightmare' || tier == 'Impossible') {
      await unlock('expert_complete');
    }
    if (!usedUndo) {
      await unlock('no_undo_win');
    }
    if (timeSeconds < 45 && moves >= 5) {
      await unlock('speed_demon');
    }
  }

  /// Event hook: on completing a daily challenge
  Future<void> onDailyWon() async {
    await unlock('daily_streak');
  }
}
