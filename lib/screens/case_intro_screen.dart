import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/game_session_provider.dart';
import '../widgets/premium_button.dart';
import '../core/audio_manager.dart';

class CaseIntroScreen extends ConsumerStatefulWidget {
  const CaseIntroScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CaseIntroScreen> createState() => _CaseIntroScreenState();
}

class _CaseIntroScreenState extends ConsumerState<CaseIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _stampController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _stampScale = Tween<double>(begin: 3.0, end: 1.0).animate(
        CurvedAnimation(parent: _stampController, curve: Curves.easeInCubic));
    _stampOpacity = Tween<double>(begin: 0.0, end: 0.8).animate(
        CurvedAnimation(parent: _stampController, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _stampController.forward();
    });
  }

  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(gameSessionProvider);
    final currentCase = sessionState.currentCase;

    if (currentCase == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF1E2638), Color(0xFF0F131D)],
                center: Alignment.topRight,
                radius: 1.5,
              ),
            ),
          ),

          // Abstract Cyber Lines
          const Positioned(
            top: -100,
            right: -50,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.fingerprint, size: 400, color: AppTheme.cyan),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white70),
                        onPressed: () => context.pop(),
                      ),
                      const Text(
                        'AGENCY DATABASE',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            letterSpacing: 4,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Main Content Glass Panel
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppTheme.cyan.withValues(alpha: 0.3),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.cyan.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: -5),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            padding: const EdgeInsets.all(24),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'CASE FILE #${currentCase.difficulty.toString().padLeft(3, '0')}',
                                          style: const TextStyle(
                                              color: AppTheme.gold,
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Icon(Icons.shield,
                                            color: AppTheme.gold
                                                .withValues(alpha: 0.8),
                                            size: 24),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      currentCase.title.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cyan
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppTheme.cyan
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        'THREAT LEVEL: ${currentCase.difficulty}',
                                        style: const TextStyle(
                                            color: AppTheme.cyan,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    const Text(
                                      '/// INCIDENT REPORT ///',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          letterSpacing: 3,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Text(
                                          currentCase.description,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                            height: 1.8,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Animated Classified Stamp
                                Positioned(
                                  bottom: 40,
                                  right: 0,
                                  child: AnimatedBuilder(
                                    animation: _stampController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _stampScale.value,
                                        child: Transform.rotate(
                                          angle: -0.2,
                                          child: Opacity(
                                            opacity: _stampOpacity.value,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.redAccent,
                                                    width: 3),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'CLASSIFIED',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Start Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: PremiumButton(
                    text: 'INITIALIZE INVESTIGATION',
                    backgroundColor: AppTheme.cyan,
                    onPressed: () {
                      AudioManager.playClick();
                      context.pushReplacement('/evidence-board');
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
