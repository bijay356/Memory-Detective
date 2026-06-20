import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/audio_manager.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/premium_button.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({Key? key}) : super(key: key);

  static const List<_DailyChallenge> _challenges = [
    _DailyChallenge(
      title: 'Witness Number',
      subtitle: 'A witness whispers one code before disappearing.',
      howToPlay:
          'Memorize the number, then enter it exactly. One wrong digit can change the whole case.',
      icon: Icons.pin,
      color: Colors.blueAccent,
      route: '/number-game',
      extra: {
        'level': 3,
        'digits': 5,
        'maxLevel': 3,
        'mode': 'daily',
        'dailyRewardXp': 120,
      },
      reward: '+120 XP',
    ),
    _DailyChallenge(
      title: 'Signal Trail',
      subtitle: 'The suspect leaves a path of flashing evidence.',
      howToPlay:
          'Watch the tile sequence. Repeat the same route after the lights stop.',
      icon: Icons.grid_view,
      color: AppTheme.green,
      route: '/sequence-game',
      extra: {
        'level': 3,
        'length': 5,
        'maxLevel': 3,
        'mode': 'daily',
        'dailyRewardXp': 140,
      },
      reward: '+140 XP',
    ),
    _DailyChallenge(
      title: 'Hidden Scene',
      subtitle: 'The crime scene appears for only a few seconds.',
      howToPlay:
          'Remember the glowing tiles. Tap only the places you saw and protect your lives.',
      icon: Icons.visibility,
      color: Colors.orangeAccent,
      route: '/visual-game',
      extra: {
        'level': 3,
        'gridSize': 4,
        'activeTiles': 5,
        'maxLevel': 3,
        'mode': 'daily',
        'dailyRewardXp': 150,
      },
      reward: '+150 XP',
    ),
    _DailyChallenge(
      title: 'Audio Evidence',
      subtitle: 'Four strange sounds hide the order of events.',
      howToPlay:
          'Listen carefully, then replay the sound chain in the same order.',
      icon: Icons.graphic_eq,
      color: AppTheme.purple,
      route: '/sound-game',
      extra: {
        'level': 3,
        'length': 5,
        'instrumentCount': 4,
        'maxLevel': 3,
        'mode': 'daily',
        'dailyRewardXp': 140,
      },
      reward: '+140 XP',
    ),
  ];

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final challenge = DailyChallengeScreen._challenges[
        now.difference(DateTime(now.year)).inDays %
            DailyChallengeScreen._challenges.length];
    final stats = ref.watch(playerStatsProvider);
    final todayKey = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final isCompletedToday = stats.lastPlayedDate == todayKey;
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final remaining = tomorrow.difference(now);
    final resetText =
        '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DAILY CHALLENGE',
            style:
                TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        children: [
          Text('Resets in $resetText',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 22),
          GlassPanel(
            borderRadius: 28,
            padding: EdgeInsets.all(isCompact ? 18 : 24),
            color: challenge.color.withValues(alpha: 0.1),
            child: Column(
              children: [
                Container(
                  width: isCompact ? 78 : 92,
                  height: isCompact ? 78 : 92,
                  decoration: BoxDecoration(
                    color: challenge.color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: challenge.color.withValues(alpha: 0.42),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: challenge.color.withValues(alpha: 0.28),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Icon(challenge.icon,
                      color: challenge.color, size: isCompact ? 38 : 44),
                ),
                SizedBox(height: isCompact ? 18 : 24),
                const Text("TODAY'S CASE",
                    style: TextStyle(
                        color: AppTheme.textSecondary, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  challenge.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: isCompact ? 26 : 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  challenge.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                _HowToPlayCard(
                    text: challenge.howToPlay, color: challenge.color),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _RewardTile(
                        icon: Icons.star,
                        label: challenge.reward,
                        color: AppTheme.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RewardTile(
                        icon: Icons.local_fire_department,
                        label: '${stats.currentStreak} day streak',
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PremiumButton(
            text: isCompletedToday ? 'PLAY AGAIN' : 'START DAILY CASE',
            icon: Icons.play_arrow_rounded,
            backgroundColor: challenge.color,
            textColor: Colors.white,
            onPressed: () {
              AudioManager.playClick();
              AudioManager.playBackground();
              context.push(challenge.route, extra: challenge.extra);
            },
          ),
        ],
      ),
    );
  }
}

class _HowToPlayCard extends StatelessWidget {
  final String text;
  final Color color;

  const _HowToPlayCard({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white, height: 1.4, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DailyChallenge {
  final String title;
  final String subtitle;
  final String howToPlay;
  final IconData icon;
  final Color color;
  final String route;
  final Map<String, dynamic> extra;
  final String reward;

  const _DailyChallenge({
    required this.title,
    required this.subtitle,
    required this.howToPlay,
    required this.icon,
    required this.color,
    required this.route,
    required this.extra,
    required this.reward,
  });
}
