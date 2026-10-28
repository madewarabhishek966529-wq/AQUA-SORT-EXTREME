import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../services/achievement_manager.dart';
import '../../services/save_repository.dart';
import '../../services/settings_service.dart';
import '../../theme/aqua_palette.dart';
import '../../theme/gradients.dart';
import '../../theme/theme_provider.dart';
import 'achievements_screen.dart';
import 'daily_challenge_screen.dart';
import 'difficulty_screen.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'skins_screen.dart';
import 'statistics_screen.dart';

/// Main Menu Screen presenting all functional game hubs and progression
/// against an animated ambient gradient mesh background with theme support.
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

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  GameSnapshot? _savedSnapshot;
  PlayerProgress _progress = const PlayerProgress();
  List<LevelResult> _results = [];
  PlayerStats _stats = const PlayerStats();
  late final AnimationController _ambientController;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    final isStatic = widget.settingsService.settings.reducedMotion ||
        widget.settingsService.settings.animationIntensity <= 0.05 ||
        _isTest;
    if (!isStatic) {
      _ambientController.repeat();
    }

    _loadPersistence();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
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

    const generator = PuzzleGenerator();
    final tubeCount = snapshot.currentState.tubeCount;
    final settings = GenerationSettings.forTubeCount(tubeCount);
    final level = generator.generate(700000 + snapshot.levelNumber * 131, settings);

    controller.loadLevel(snapshot.levelNumber, level);
    controller.restoreSnapshot(snapshot);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    ).then((_) => _loadPersistence());
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(activeThemePaletteProvider);
    final isStatic = widget.settingsService.settings.reducedMotion ||
        widget.settingsService.settings.animationIntensity <= 0.05;

    return Scaffold(
      backgroundColor: theme.backgroundBase,
      body: Stack(
        children: [
          // Slow drifting ambient mesh gradient
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return CustomPaint(
                  painter: MeshGradientPainter(
                    theme: theme,
                    animationProgress: _ambientController.value,
                    isStatic: isStatic,
                  ),
                );
              },
            ),
          ),

          // Menu Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo & Glow
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.primaryAccent.withValues(alpha: 0.12),
                          border: Border.all(
                            color: theme.primaryAccent.withValues(alpha: 0.45),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryAccent.withValues(alpha: 0.28),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.science_rounded,
                          size: 56,
                          color: theme.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gradient Title
                      GradientText(
                        'AQUA SORT',
                        gradient: UIGradients.levelTitleGradient(theme),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.5,
                        ),
                      ),
                      Text(
                        'EXTREME',
                        style: TextStyle(
                          color: theme.secondaryAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // PLAY Button
                      _buildMenuButton(
                        theme: theme,
                        title: 'PLAY (LEVEL ${_progress.highestUnlockedLevel})',
                        icon: Icons.play_arrow_rounded,
                        color: theme.primaryAccent,
                        textColor: Colors.black,
                        isPrimary: true,
                        onPressed: () => _startPlayLevel(_progress.highestUnlockedLevel),
                      ),
                      const SizedBox(height: 12),

                      // CONTINUE Button (Active when snapshot exists)
                      if (_savedSnapshot != null) ...[
                        _buildMenuButton(
                          theme: theme,
                          title: 'CONTINUE (LEVEL ${_savedSnapshot!.levelNumber})',
                          icon: Icons.replay_rounded,
                          color: theme.secondaryAccent,
                          textColor: Colors.black,
                          onPressed: _continueSavedGame,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // SELECT LEVEL Button
                      _buildMenuButton(
                        theme: theme,
                        title: 'SELECT LEVEL',
                        icon: Icons.grid_view_rounded,
                        color: theme.surfaceElevated,
                        textColor: theme.textBright,
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
                        theme: theme,
                        title: 'DIFFICULTY TIERS',
                        icon: Icons.tune_rounded,
                        color: theme.surfaceElevated,
                        textColor: theme.textBright,
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
                        theme: theme,
                        title: 'DAILY CHALLENGE',
                        icon: Icons.event_available_rounded,
                        color: theme.surfaceElevated,
                        textColor: theme.textBright,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyChallengeScreen(),
                            ),
                          ).then((_) => _loadPersistence());
                        },
                      ),
                      const SizedBox(height: 16),

                      // Secondary Hubs: Stats, Skins, Trophies, Settings
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallButton(
                              theme: theme,
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
                              theme: theme,
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
                              theme: theme,
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
                              theme: theme,
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
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required ThemePalette theme,
    required String title,
    required IconData icon,
    required Color color,
    required Color textColor,
    bool isPrimary = false,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isPrimary ? UIGradients.buttonGradient(theme) : null,
        color: isPrimary ? null : color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: theme.primaryAccent.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
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
          backgroundColor: isPrimary ? Colors.transparent : color,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPrimary ? Colors.transparent : theme.glassBorder,
            ),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSmallButton({
    required ThemePalette theme,
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
          color: theme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.primaryAccent),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.textMuted,
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
