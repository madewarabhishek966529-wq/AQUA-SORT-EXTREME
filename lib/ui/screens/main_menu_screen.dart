import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../services/achievement_manager.dart';
import '../../services/save_repository.dart';
import '../../services/settings_service.dart';
import '../theme/game_theme.dart';
import 'achievements_screen.dart';
import 'daily_challenge_screen.dart';
import 'difficulty_screen.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'skins_screen.dart';
import 'statistics_screen.dart';

/// Main Menu Screen presenting all functional game hubs and progression.
class MainMenuScreen extends ConsumerStatefulWidget {
  final SaveRepository repository;
  final SettingsService settingsService;
  final AchievementManager achievementManager;

  const MainMenuScreen({
    super.key,
    required this.repository,
    required this.settingsService,
    required this.achievementManager,
  });

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  GameSnapshot? _savedSnapshot;
  PlayerProgress _progress = const PlayerProgress();
  List<LevelResult> _results = [];
  PlayerStats _stats = const PlayerStats();

  @override
  void initState() {
    super.initState();
    _loadPersistence();
  }

  Future<void> _loadPersistence() async {
    final snapshot = await widget.repository.loadSnapshot();
    final progress = await widget.repository.loadProgress();
    final results = await widget.repository.loadAllLevelResults();
    final stats = await widget.repository.loadStats();

    if (mounted) {
      setState(() {
        _savedSnapshot = snapshot;
        _progress = progress;
        _results = results;
        _stats = stats;
      });
    }
  }

  void _startPlayLevel(int levelNumber) {
    const generator = PuzzleGenerator();
    final tubeCount = levelNumber <= 12 ? 8 : (levelNumber <= 30 ? 14 : 20);
    final settings = GenerationSettings.forTubeCount(tubeCount);
    final level = generator.generate(700000 + levelNumber * 131, settings);

    ref.read(gameControllerProvider.notifier).loadLevel(levelNumber, level);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    ).then((_) => _loadPersistence());
  }

  void _continueSavedGame() {
    if (_savedSnapshot == null) return;

    final snapshot = _savedSnapshot!;
    final controller = ref.read(gameControllerProvider.notifier);

    // Restore exact state, history, moves, and timer
    const generator = PuzzleGenerator();
    final tubeCount = snapshot.currentState.tubeCount;
    final settings = GenerationSettings.forTubeCount(tubeCount);
    final level = generator.generate(700000 + snapshot.levelNumber * 131, settings);

    controller.loadLevel(snapshot.levelNumber, level);
    // Apply snapshot state over initial level
    controller.restoreSnapshot(snapshot);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    ).then((_) => _loadPersistence());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo & Title
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GameTheme.primaryCyan.withValues(alpha: 0.12),
                            border: Border.all(
                              color: GameTheme.primaryCyan.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: GameTheme.primaryCyan.withValues(alpha: 0.25),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.science_rounded,
                            size: 56,
                            color: GameTheme.primaryCyan,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'AQUA SORT',
                          style: TextStyle(
                            color: GameTheme.textBright,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.5,
                          ),
                        ),
                        const Text(
                          'EXTREME',
                          style: TextStyle(
                            color: GameTheme.accentGold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // PLAY Button (Starts current level)
                        _buildMenuButton(
                          title: 'PLAY (LEVEL ${_progress.highestUnlockedLevel})',
                          icon: Icons.play_arrow_rounded,
                          color: GameTheme.primaryCyan,
                          textColor: Colors.black,
                          onPressed: () => _startPlayLevel(_progress.highestUnlockedLevel),
                        ),
                        const SizedBox(height: 12),

                        // CONTINUE Button (Active when snapshot exists)
                        if (_savedSnapshot != null) ...[
                          _buildMenuButton(
                            title: 'CONTINUE (LEVEL ${_savedSnapshot!.levelNumber})',
                            icon: Icons.replay_rounded,
                            color: GameTheme.accentGold,
                            textColor: Colors.black,
                            onPressed: _continueSavedGame,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // SELECT LEVEL Button
                        _buildMenuButton(
                          title: 'SELECT LEVEL',
                          icon: Icons.grid_view_rounded,
                          color: GameTheme.surfaceElevated,
                          textColor: GameTheme.textBright,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LevelSelectScreen(
                                  progress: _progress,
                                  levelResults: _results,
                                ),
                              ),
                            ).then((_) => _loadPersistence());
                          },
                        ),
                        const SizedBox(height: 12),

                        // DIFFICULTY TIERS Button
                        _buildMenuButton(
                          title: 'DIFFICULTY TIERS',
                          icon: Icons.tune_rounded,
                          color: GameTheme.surfaceElevated,
                          textColor: GameTheme.textBright,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DifficultyScreen(),
                              ),
                            ).then((_) => _loadPersistence());
                          },
                        ),
                        const SizedBox(height: 12),

                        // DAILY CHALLENGE Button
                        _buildMenuButton(
                          title: 'DAILY CHALLENGE',
                          icon: Icons.event_available_rounded,
                          color: GameTheme.surfaceElevated,
                          textColor: GameTheme.textBright,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DailyChallengeScreen(),
                              ),
                            ).then((_) => _loadPersistence());
                          },
                        ),
                        const SizedBox(height: 12),

                        // Secondary Grid: Stats, Skins, Achievements, Settings
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallButton(
                                label: 'STATS',
                                icon: Icons.bar_chart_rounded,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StatisticsScreen(stats: _stats),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSmallButton(
                                label: 'SKINS',
                                icon: Icons.palette_outlined,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SkinsScreen(
                                        settingsService: widget.settingsService,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSmallButton(
                                label: 'TROPHIES',
                                icon: Icons.emoji_events_outlined,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AchievementsScreen(
                                        achievementManager: widget.achievementManager,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSmallButton(
                                label: 'SETTINGS',
                                icon: Icons.settings_outlined,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SettingsScreen(
                                        settingsService: widget.settingsService,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 22, color: textColor),
        label: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: color == GameTheme.surfaceElevated
                  ? GameTheme.glassBorder
                  : Colors.transparent,
            ),
          ),
          elevation: color == GameTheme.primaryCyan || color == GameTheme.accentGold ? 4 : 0,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSmallButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: GameTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GameTheme.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: GameTheme.primaryCyan),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: GameTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
