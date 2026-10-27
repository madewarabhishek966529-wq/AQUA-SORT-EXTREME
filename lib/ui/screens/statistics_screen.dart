import 'package:flutter/material.dart';

import '../../services/save_repository.dart';
import '../theme/game_theme.dart';

/// Screen displaying player statistics and milestones.
class StatisticsScreen extends StatelessWidget {
  final PlayerStats stats;

  const StatisticsScreen({super.key, required this.stats});

  String _formatPlayTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${totalSeconds % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('STATISTICS'),
        backgroundColor: GameTheme.surfaceDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildStatCard(
            title: 'Puzzles Solved',
            value: '${stats.totalSolved}',
            subtitle: 'Levels conquered across all tiers',
            icon: Icons.check_circle_rounded,
            color: GameTheme.accentGreen,
          ),
          _buildStatCard(
            title: 'Total Moves Made',
            value: '${stats.totalMoves}',
            subtitle: 'Pours executed in your journey',
            icon: Icons.alt_route_rounded,
            color: GameTheme.primaryCyan,
          ),
          _buildStatCard(
            title: 'Total Playtime',
            value: _formatPlayTime(stats.totalPlayTimeSeconds),
            subtitle: 'Time spent mastering liquid sorting',
            icon: Icons.timer_rounded,
            color: GameTheme.accentGold,
          ),
          _buildStatCard(
            title: 'Hints Consulted',
            value: '${stats.hintsUsed}',
            subtitle: 'Tactical moves revealed by solver',
            icon: Icons.lightbulb_rounded,
            color: GameTheme.accentGold,
          ),
          _buildStatCard(
            title: 'Daily Challenges',
            value: '${stats.dailyCompleted}',
            subtitle: 'Global daily calendar challenges cleared',
            icon: Icons.event_available_rounded,
            color: const Color(0xFFD500F9),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameTheme.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: GameTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: GameTheme.textBright,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: GameTheme.textMuted.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
