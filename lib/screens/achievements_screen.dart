import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/glass_panel.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerStatsProvider);
    final accuracyAchievement =
        stats.totalQuestionsAnswered > 0 && stats.accuracy >= 90 ? 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ACHIEVEMENTS',
            style:
                TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAchievementCard('Sharp Eyes', 'Solve 100 cases',
              stats.casesSolved.clamp(0, 100), 100, Icons.visibility),
          const SizedBox(height: 12),
          _buildAchievementCard(
              'Memory Master',
              'Maintain at least 90% accuracy',
              accuracyAchievement,
              1,
              Icons.psychology,
              color: AppTheme.purple),
          const SizedBox(height: 12),
          _buildAchievementCard('Daily Player', 'Play 7 days in a row',
              stats.currentStreak.clamp(0, 7), 7, Icons.calendar_today,
              color: AppTheme.gold),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/cases');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildAchievementCard(
      String title, String subtitle, int current, int max, IconData icon,
      {Color color = AppTheme.gold}) {
    final bool isCompleted = current >= max;
    return GlassPanel(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: current / max,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: isCompleted ? AppTheme.green : color,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppTheme.green)
          else
            Text('$current/$max',
                style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
