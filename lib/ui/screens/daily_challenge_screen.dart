import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/game_controller.dart';
import '../../services/daily_challenge_service.dart';
import '../theme/game_theme.dart';
import 'game_screen.dart';

/// Screen presenting the deterministic daily puzzle challenge.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const dailyService = DailyChallengeService();
    final today = DateTime.now().toUtc();
    final level = dailyService.getDailyLevel(today);
    final constraints = dailyService.getConstraints(level);

    final weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = weekdayNames[today.weekday - 1];
    final dateFormatted =
        '$dayName, ${monthNames[today.month - 1]} ${today.day}, ${today.year} (UTC)';

    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('DAILY CHALLENGE'),
        backgroundColor: GameTheme.surfaceDark,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: constraints.isBossLevel
                      ? GameTheme.accentRed.withValues(alpha: 0.15)
                      : GameTheme.primaryCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  constraints.isBossLevel
                      ? Icons.local_fire_department_rounded
                      : Icons.calendar_month_rounded,
                  size: 64,
                  color: constraints.isBossLevel
                      ? GameTheme.accentRed
                      : GameTheme.primaryCyan,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                constraints.isBossLevel
                    ? 'WEEKEND BOSS CHALLENGE'
                    : 'DAILY SORT CHALLENGE',
                style: TextStyle(
                  color: constraints.isBossLevel
                      ? GameTheme.accentRed
                      : GameTheme.primaryCyan,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                dateFormatted,
                style: const TextStyle(
                  color: GameTheme.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Constraints Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: GameTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GameTheme.glassBorder),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      'Tubes to Sort',
                      '${level.initial.tubeCount} Bottles',
                      Icons.science_rounded,
                    ),
                    const Divider(color: GameTheme.glassBorder, height: 24),
                    _buildRow(
                      'Colors',
                      '${level.settings.numColors} Colors',
                      Icons.palette_rounded,
                    ),
                    const Divider(color: GameTheme.glassBorder, height: 24),
                    _buildRow(
                      'Target Moves',
                      '≤ ${constraints.maxMoves} Moves',
                      Icons.alt_route_rounded,
                    ),
                    const Divider(color: GameTheme.glassBorder, height: 24),
                    _buildRow(
                      'Allowed Undos',
                      '${constraints.maxUndos} Undos max',
                      Icons.undo_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Start Challenge Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text(
                    'START CHALLENGE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: constraints.isBossLevel
                        ? GameTheme.accentRed
                        : GameTheme.primaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    final controller = ref.read(gameControllerProvider.notifier);
                    controller.loadLevel(0, level); // 0 indicates Daily Challenge

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: GameTheme.primaryCyan),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: GameTheme.textMuted,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: GameTheme.textBright,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
