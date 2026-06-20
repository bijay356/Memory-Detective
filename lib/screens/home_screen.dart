import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/audio_manager.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/glass_panel.dart';
import '../widgets/premium_button.dart';
import '../widgets/ad_placeholder.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerStatsProvider);

    // Ensure home music plays when this screen is active
    AudioManager.playHomeMusic();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _PremiumDetectiveBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 820;
                final horizontalPadding =
                    isWide ? 36.0 : (constraints.maxWidth < 360 ? 14.0 : 20.0);

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    22,
                    horizontalPadding,
                    24,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 46,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeTopBar(level: stats.level),
                        SizedBox(height: isWide ? 28 : 22),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _HeroPanel(
                                  rank: stats.rank,
                                  accuracy: stats.accuracy,
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                flex: 4,
                                child: _StatsPanel(
                                  xp: stats.xp,
                                  casesSolved: stats.casesSolved,
                                  bestScore: stats.bestScore,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _HeroPanel(
                              rank: stats.rank, accuracy: stats.accuracy),
                          const SizedBox(height: 18),
                          _StatsPanel(
                            xp: stats.xp,
                            casesSolved: stats.casesSolved,
                            bestScore: stats.bestScore,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _PrimaryActions(isWide: isWide),
                        const SizedBox(height: 18),
                        _TrainingHub(isWide: isWide),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerPlaceholder(),
          BottomNavBar(
            currentIndex: 0,
            onTap: (index) {
              AudioManager.playClick();
              if (index == 1) context.push('/cases');
              if (index == 2) context.push('/achievements');
              if (index == 3) context.push('/profile');
            },
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final int level;

  const _HomeTopBar({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.travel_explore, color: AppTheme.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Memory Detective',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Agency training console',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _LevelChip(level: level),
      ],
    ).animate().fade(duration: 260.ms).slideY(begin: -0.16);
  }
}

class _LevelChip extends StatelessWidget {
  final int level;

  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, color: AppTheme.cyan, size: 17),
          const SizedBox(width: 7),
          Text(
            'LV $level',
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String rank;
  final double accuracy;

  const _HeroPanel({required this.rank, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final panelPadding = isCompact ? 20.0 : 26.0;
        final titleSize = constraints.maxWidth < 340
            ? 38.0
            : constraints.maxWidth < 430
                ? 44.0
                : 52.0;

        return GlassPanel(
          borderRadius: 28,
          padding: const EdgeInsets.all(0),
          color: const Color(0xFF0F1729).withValues(alpha: 0.78),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HeroPanelPainter(),
                  ),
                ),
                Positioned(
                  right: isCompact ? -44 : -28,
                  bottom: -18,
                  child: Icon(
                    Icons.fingerprint,
                    size: isCompact ? 190 : 260,
                    color: AppTheme.cyan.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(panelPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.cyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppTheme.cyan.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Text(
                          'NEURAL MEMORY UNIT',
                          style: GoogleFonts.inter(
                            color: AppTheme.cyan,
                            fontSize: isCompact ? 10 : 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: isCompact ? 1.1 : 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'MEMORY\nDETECTIVE',
                          style: GoogleFonts.outfit(
                            color: AppTheme.gold,
                            fontSize: titleSize,
                            height: 0.96,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: AppTheme.gold.withValues(alpha: 0.28),
                                blurRadius: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Train recall, sequence focus, visual pattern memory, and sound recognition in one elite detective lab.',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: isCompact ? 14 : 15,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _IntelPill(
                            icon: Icons.badge,
                            label: rank,
                            color: AppTheme.gold,
                          ),
                          _IntelPill(
                            icon: Icons.gps_fixed,
                            label: '${accuracy.toStringAsFixed(0)}% accuracy',
                            color: AppTheme.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 320.ms).slideY(begin: 0.08);
      },
    );
  }
}

class _IntelPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IntelPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final int xp;
  final int casesSolved;
  final int bestScore;

  const _StatsPanel({
    required this.xp,
    required this.casesSolved,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    final xpProgress = ((xp % 1000) / 1000).clamp(0.0, 1.0).toDouble();

    return GlassPanel(
      borderRadius: 28,
      padding: const EdgeInsets.all(22),
      color: Colors.white.withValues(alpha: 0.065),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.query_stats, color: AppTheme.cyan),
              const SizedBox(width: 10),
              Text(
                'Performance',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${xp % 1000}/1000 XP to next level',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'XP',
                  value: xp.toString(),
                  color: AppTheme.gold,
                  icon: Icons.bolt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Cases',
                  value: casesSolved.toString(),
                  color: AppTheme.green,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Best',
                  value: bestScore.toString(),
                  color: AppTheme.purple,
                  icon: Icons.military_tech,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 90.ms).fade(duration: 320.ms).slideY(begin: 0.08);
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingHub extends StatefulWidget {
  final bool isWide;

  const _TrainingHub({required this.isWide});

  @override
  State<_TrainingHub> createState() => _TrainingHubState();
}

class _TrainingHubState extends State<_TrainingHub> {
  final PageController _pageController = PageController();
  Timer? _storyTimer;
  int _currentStory = 0;

  static const List<_StorySlide> _slides = [
    _StorySlide(
      title: 'The City Forgets',
      body:
          'A witness remembers a face for one second. A clue appears in a room, then disappears into noise. Somewhere, one small detail decides whether the truth is found or lost forever.',
    ),
    _StorySlide(
      title: 'Your Mind Becomes The Case File',
      body:
          'Train until numbers stay sharp, sounds leave a trail, patterns become evidence, and every hidden detail has a place to live. A great detective is not born fearless. A great detective remembers.',
    ),
    _StorySlide(
      title: 'Play For The Moment That Matters',
      body:
          'When the final question comes, there is no luck, no shortcut, no second glance. There is only the memory you built. Step into training, sharpen the gift, and solve what others could not.',
    ),
    _StorySlide(
      title: 'The Last Detail Saves The Case',
      body:
          'A torn ticket. A voice in the hallway. A number seen for half a heartbeat. The world calls them small things, but a detective knows small things can bring someone home.',
    ),
    _StorySlide(
      title: 'Memory Is Your Evidence',
      body:
          'Every round is more than a game. It is practice for pressure, focus under darkness, and courage when the answer hides behind fear. Train until your mind becomes the light.',
    ),
    _StorySlide(
      title: 'Someone Is Waiting For The Truth',
      body:
          'Behind every mystery is a person who needs the truth to be found. Remember better, look closer, listen deeper. The next case may depend on the strength you build today.',
    ),
    _StorySlide(
      title: 'Become The Detective They Need',
      body:
          'The city does not need a perfect mind. It needs a mind that refuses to quit. Miss a clue, train again. Forget a pattern, return sharper. Every attempt makes you harder to fool.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _storyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentStory + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.all(0),
      color: Colors.black.withValues(alpha: 0.22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 380;
          final height = widget.isWide
              ? 176.0
              : isCompact
                  ? 276.0
                  : 232.0;

          return SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _StoryPanelPainter()),
                ),
                PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentStory = index),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                          isCompact ? 16 : 20, 18, isCompact ? 16 : 20, 18),
                      child: _StorySlideView(
                        slide: _slides[index],
                        isWide: widget.isWide,
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 18,
                  bottom: 16,
                  child: Row(
                    children: List.generate(_slides.length, (index) {
                      final active = index == _currentStory;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: active ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.gold
                              : Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate(delay: 210.ms).fade(duration: 320.ms).slideY(begin: 0.08);
  }
}

class _StorySlideView extends StatelessWidget {
  final _StorySlide slide;
  final bool isWide;

  const _StorySlideView({required this.slide, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 350;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isCompact ? 44 : 54,
              height: isCompact ? 44 : 54,
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(isCompact ? 15 : 18),
                border:
                    Border.all(color: AppTheme.green.withValues(alpha: 0.26)),
              ),
              child: const Icon(Icons.psychology_alt, color: AppTheme.green),
            ),
            SizedBox(width: isCompact ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: isCompact ? 19 : 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    slide.body,
                    maxLines: isWide
                        ? 4
                        : isCompact
                            ? 8
                            : 7,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD8E2F1),
                      fontSize: isWide ? 16 : 14,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StorySlide {
  final String title;
  final String body;

  const _StorySlide({required this.title, required this.body});
}

class _StoryPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppTheme.green.withValues(alpha: 0.16),
          AppTheme.cyan.withValues(alpha: 0.07),
          AppTheme.purple.withValues(alpha: 0.12),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (double x = 24; x < size.width; x += 68) {
      canvas.drawLine(Offset(x, 0), Offset(x + 80, size.height), linePaint);
    }

    final pulsePaint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final center = Offset(size.width * 0.9, size.height * 0.08);
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(center, 60.0 + i * 32, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StoryPanelPainter oldDelegate) => false;
}

class _PrimaryActions extends StatelessWidget {
  final bool isWide;

  const _PrimaryActions({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final startButton = PremiumButton(
      text: 'PLAY',
      icon: Icons.play_arrow_rounded,
      onPressed: () {
        AudioManager.playClick();
        context.push('/choose-mode');
      },
    );
    final trainingButton = PremiumButton(
      text: 'TRAINING',
      icon: Icons.psychology_alt,
      backgroundColor: AppTheme.green,
      textColor: Colors.white,
      onPressed: () {
        AudioManager.playClick();
        context.push('/training-mode');
      },
    );
    final dailyButton = PremiumButton(
      text: 'DAILY',
      icon: Icons.calendar_month,
      backgroundColor: AppTheme.purple,
      textColor: Colors.white,
      onPressed: () {
        AudioManager.playClick();
        context.push('/daily-challenge');
      },
    );

    return isWide
        ? Row(
            children: [
              Expanded(flex: 2, child: startButton),
              const SizedBox(width: 14),
              Expanded(child: trainingButton),
              const SizedBox(width: 14),
              Expanded(child: dailyButton),
            ],
          ).animate(delay: 140.ms).fade(duration: 320.ms).slideY(begin: 0.08)
        : Column(
            children: [
              startButton,
              const SizedBox(height: 14),
              trainingButton,
              const SizedBox(height: 14),
              dailyButton,
            ],
          ).animate(delay: 140.ms).fade(duration: 320.ms).slideY(begin: 0.08);
  }
}

class _PremiumDetectiveBackdrop extends StatelessWidget {
  const _PremiumDetectiveBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PremiumBackdropPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _PremiumBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF070C17),
          Color(0xFF0B1427),
          Color(0xFF060912),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    _drawGlow(canvas, size, Offset(size.width * 0.16, size.height * 0.12),
        AppTheme.gold, 0.18, size.shortestSide * 0.48);
    _drawGlow(canvas, size, Offset(size.width * 0.82, size.height * 0.18),
        AppTheme.cyan, 0.12, size.shortestSide * 0.42);
    _drawGlow(canvas, size, Offset(size.width * 0.7, size.height * 0.78),
        AppTheme.purple, 0.12, size.shortestSide * 0.48);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final silhouettePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;
    final center = Offset(size.width * 0.88, size.height * 0.46);
    canvas.drawCircle(center.translate(0, -90), 58, silhouettePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, 45),
          width: 220,
          height: 170,
        ),
        const Radius.circular(80),
      ),
      silhouettePaint,
    );

    final ringPaint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.87, size.height * 0.36),
        82.0 + (i * 34),
        ringPaint,
      );
    }

    final scanPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    final start = Offset(size.width * 0.63, size.height * 0.18);
    for (int i = 0; i < 6; i++) {
      final end = Offset(
        size.width * (0.72 + i * 0.035),
        size.height * (0.36 + math.sin(i) * 0.035),
      );
      canvas.drawLine(start, end, scanPaint);
    }
  }

  void _drawGlow(
    Canvas canvas,
    Size size,
    Offset center,
    Color color,
    double alpha,
    double radius,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PremiumBackdropPainter oldDelegate) => false;
}

class _HeroPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.gold.withValues(alpha: 0.18),
          AppTheme.cyan.withValues(alpha: 0.05),
          AppTheme.purple.withValues(alpha: 0.12),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.2;
    for (double y = 32; y < size.height; y += 34) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + math.sin(y) * 8),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPanelPainter oldDelegate) => false;
}
