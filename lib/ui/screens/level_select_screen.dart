import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../services/save_repository.dart';
import '../theme/game_theme.dart';
import 'game_screen.dart';

/// Screen displaying grid of levels with lock status, stars, and tier filtering.
class LevelSelectScreen extends ConsumerStatefulWidget {
  final PlayerProgress progress;
  final List<LevelResult> levelResults;

  const LevelSelectScreen({
    super.key,
    required this.progress,
    required this.levelResults,
  });

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const tiers = [
    'Beginner',
    'Intermediate',
    'Hard',
    'Expert',
    'Nightmare',
    'Impossible',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tiers.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTubesForLevel(int level) {
    if (level <= 50) return 8 + ((level - 1) * 4 ~/ 49);
    if (level <= 100) return 14 + ((level - 51) * 6 ~/ 49);
    if (level <= 150) return 22 + ((level - 101) * 8 ~/ 49);
    if (level <= 200) return 32 + ((level - 151) * 8 ~/ 49);
    if (level <= 250) return 42 + ((level - 201) * 8 ~/ 49);
    return 52 + ((level - 251) * 8 ~/ 49);
  }

  @override
  Widget build(BuildContext context) {
    final highestUnlocked = widget.progress.highestUnlockedLevel;
    final resultsMap = {
      for (final r in widget.levelResults) r.levelNumber: r,
    };

    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('SELECT LEVEL'),
        backgroundColor: GameTheme.surfaceDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: GameTheme.primaryCyan,
          labelColor: GameTheme.primaryCyan,
          unselectedLabelColor: GameTheme.textMuted,
          tabs: tiers.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(tiers.length, (tierIdx) {
          final startLevel = tierIdx * 50 + 1;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: 50,
            itemBuilder: (context, index) {
              final levelNum = startLevel + index;
              final isUnlocked = levelNum <= highestUnlocked;
              final result = resultsMap[levelNum];

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isUnlocked
                    ? () {
                        // Generate level on demand
                        const generator = PuzzleGenerator();
                        final tubes = _getTubesForLevel(levelNum);
                        final settings = GenerationSettings.forTubeCount(tubes);
                        final level = generator.generate(
                          700000 + levelNum * 131,
                          settings,
                        );

                        ref.read(gameControllerProvider.notifier).loadLevel(
                              levelNum,
                              level,
                            );

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GameScreen()),
                        );
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? GameTheme.surfaceElevated
                        : GameTheme.surfaceDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUnlocked
                          ? GameTheme.primaryCyan.withValues(alpha: 0.4)
                          : GameTheme.glassBorder.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isUnlocked) ...[
                        Text(
                          '$levelNum',
                          style: const TextStyle(
                            color: GameTheme.textBright,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (starIdx) {
                            final hasStar =
                                result != null && result.stars > starIdx;
                            return Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: hasStar
                                  ? GameTheme.accentGold
                                  : GameTheme.textMuted.withValues(alpha: 0.25),
                            );
                          }),
                        ),
                      ] else ...[
                        Icon(
                          Icons.lock_rounded,
                          color: GameTheme.textMuted.withValues(alpha: 0.4),
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$levelNum',
                          style: TextStyle(
                            color: GameTheme.textMuted.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
