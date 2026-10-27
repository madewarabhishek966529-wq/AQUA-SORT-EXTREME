import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/achievement_manager.dart';
import 'services/save_repository.dart';
import 'services/settings_service.dart';
import 'services/sqlite_save_repository.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/theme/game_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = SqliteSaveRepository();
  await repository.init();

  final settingsService = await SettingsService.create();

  final achievementManager = AchievementManager(repository: repository);
  await achievementManager.init();

  runApp(
    ProviderScope(
      child: AquaSortApp(
        repository: repository,
        settingsService: settingsService,
        achievementManager: achievementManager,
      ),
    ),
  );
}

/// Root widget for Aqua Sort: Extreme application.
class AquaSortApp extends StatelessWidget {
  final SaveRepository repository;
  final SettingsService settingsService;
  final AchievementManager achievementManager;

  const AquaSortApp({
    super.key,
    required this.repository,
    required this.settingsService,
    required this.achievementManager,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqua Sort: Extreme',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.darkTheme,
      home: MainMenuScreen(
        repository: repository,
        settingsService: settingsService,
        achievementManager: achievementManager,
      ),
    );
  }
}
