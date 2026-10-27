import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../theme/game_theme.dart';
import 'game_screen.dart';

class TierCardDef {
  final String name;
  final String tubeRange;
  final String description;
  final Color accentColor;
  final int startingLevel;

  const TierCardDef({
    required this.name,
    required this.tubeRange,
    required this.description,
    required this.accentColor,
    required this.startingLevel,
  });
}

/// Screen letting players select difficulty tiers from Beginner to Impossible.
class DifficultyScreen extends ConsumerWidget {
  const DifficultyScreen({super.key});

  static const List<TierCardDef> tiers = [
    TierCardDef(
      name: 'Beginner',
      tubeRange: '8 – 12 Bottles',
      description: 'Introductory boards with low fragmentation and generous empty tubes.',
      accentColor: GameTheme.accentGreen,
      startingLevel: 1,
    ),
    TierCardDef(
      name: 'Intermediate',
      tubeRange: '14 – 20 Bottles',
      description: 'Moderate branching requiring 25–40 strategic move lookaheads.',
      accentColor: GameTheme.primaryCyan,
      startingLevel: 51,
    ),
    TierCardDef(
      name: 'Hard',
      tubeRange: '22 – 30 Bottles',
      description: 'High color interleaving and deep buried units. Strict move economy.',
      accentColor: GameTheme.accentGold,
      startingLevel: 101,
    ),
    TierCardDef(
      name: 'Expert',
      tubeRange: '32 – 40 Bottles',
      description: 'Large boards with 60–80 move solutions. Complex bottleneck management.',
      accentColor: Color(0xFFFF6D00),
      startingLevel: 151,
    ),
    TierCardDef(
      name: 'Nightmare',
      tubeRange: '42 – 50 Bottles',
      description: 'Extreme state-space depth with treacherous dead ends and single empty buffers.',
      accentColor: Color(0xFFD500F9),
      startingLevel: 201,
    ),
    TierCardDef(
      name: 'Impossible',
      tubeRange: '52 – 60+ Bottles',
      description: 'The ultimate color-sorting summit. 100+ steps with near-zero tolerance for error.',
      accentColor: GameTheme.accentRed,
      startingLevel: 251,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('DIFFICULTY TIERS'),
        backgroundColor: GameTheme.surfaceDark,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: tiers.length,
        itemBuilder: (context, index) {
          final tier = tiers[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GameTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tier.accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tier.name.toUpperCase(),
                      style: TextStyle(
                        color: tier.accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tier.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tier.tubeRange,
                        style: TextStyle(
                          color: tier.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tier.description,
                  style: const TextStyle(
                    color: GameTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Levels ${tier.startingLevel} – ${tier.startingLevel + 49}',
                      style: const TextStyle(
                        color: GameTheme.textBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tier.accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        // Generate tier starting level
                        const generator = PuzzleGenerator();
                        final tubeCount = int.parse(tier.tubeRange.split(' ')[0]);
                        final settings = GenerationSettings.forTubeCount(tubeCount);
                        final level = generator.generate(
                          700000 + tier.startingLevel * 131,
                          settings,
                        );

                        ref.read(gameControllerProvider.notifier).loadLevel(
                              tier.startingLevel,
                              level,
                            );

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GameScreen()),
                        );
                      },
                      child: const Text(
                        'PLAY TIER',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
