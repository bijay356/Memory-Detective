import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/glass_panel.dart';
import '../providers/game_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerStatsProvider);
    final settings = ref.watch(settingsProvider);
    const xpPerLevel = 1000;
    final currentLevelXp = stats.xp % xpPerLevel;
    final progress = currentLevelXp / xpPerLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DETECTIVE HQ',
            style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.surfaceLight,
                child: Icon(Icons.person, size: 40, color: AppTheme.gold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settings.detectiveName.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gold)),
                    Row(
                      children: [
                        const Icon(Icons.shield,
                            color: AppTheme.purple, size: 14),
                        const SizedBox(width: 4),
                        Text(stats.rank,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, color: AppTheme.gold, size: 14),
                        const SizedBox(width: 4),
                        Text('Level ${stats.level}',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      color: AppTheme.gold,
                    ),
                    const SizedBox(height: 4),
                    Text('$currentLevelXp / $xpPerLevel XP',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('STATISTICS',
              style:
                  TextStyle(color: AppTheme.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Cases Solved', '${stats.casesSolved}',
                  Icons.cases_outlined, Colors.blue),
              _buildStatCard(
                  'Total XP', '${stats.xp}', Icons.stars, AppTheme.gold),
              _buildStatCard('Detective Points', '${stats.totalScore}',
                  Icons.shield, AppTheme.purple),
              _buildStatCard(
                  'Accuracy',
                  '${stats.accuracy.toStringAsFixed(1)}%',
                  Icons.check_circle_outline,
                  Colors.green),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/cases');
          if (index == 2) context.go('/achievements');
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return GlassPanel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
