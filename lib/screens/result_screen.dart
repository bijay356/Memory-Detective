import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/game_session_provider.dart';
import '../providers/game_providers.dart';
import '../data/local_storage.dart';
import '../models/case_progress.dart';
import '../widgets/premium_button.dart';
import '../core/audio_manager.dart';
import '../ads/ad_service.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _stampController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _stampScale = Tween<double>(begin: 4.0, end: 1.0).animate(
        CurvedAnimation(parent: _stampController, curve: Curves.bounceOut));
    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _stampController, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 300), () {
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
    final isSuccess = sessionState.isSuccess;
    final isTraining = sessionState.isTraining;

    if (currentCase == null) return const Scaffold();

    if (isSuccess && !isTraining) {
      // Save completion
      var currentProgress = LocalStorage.casesBox.get(currentCase.id) ??
          CaseProgress(caseId: currentCase.id, isUnlocked: true);
      if (!currentProgress.isCompleted) {
        currentProgress.isCompleted = true;
        LocalStorage.casesBox.put(currentCase.id, currentProgress);

        // Add massive XP for solving case
        Future.microtask(() => ref
            .read(playerStatsProvider.notifier)
            .addXp(currentCase.difficulty * 50));
        Future.microtask(() => ref
            .read(playerStatsProvider.notifier)
            .incrementCasesSolved(currentCase.difficulty * 10));

        // Unlock next
        if (currentCase.difficulty < 1000) {
          final nextId = 'case_${currentCase.difficulty + 1}';
          var nextProgress =
              LocalStorage.casesBox.get(nextId) ?? CaseProgress(caseId: nextId);
          nextProgress.isUnlocked = true;
          LocalStorage.casesBox.put(nextId, nextProgress);
        }
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: isSuccess
                    ? [
                        AppTheme.green.withValues(alpha: 0.2),
                        const Color(0xFF0F131D)
                      ]
                    : [
                        Colors.red.withValues(alpha: 0.2),
                        const Color(0xFF0F131D)
                      ],
                center: Alignment.center,
                radius: 1.0,
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),

                        // Animated Stamp
                        Center(
                          child: AnimatedBuilder(
                            animation: _stampController,
                            builder: (context, child) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width - 48,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Transform.scale(
                                    scale: _stampScale.value,
                                    child: Opacity(
                                      opacity: _stampOpacity.value,
                                      child: Transform.rotate(
                                        angle: isSuccess ? -0.1 : 0.1,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isSuccess
                                                  ? AppTheme.gold
                                                  : Colors.red,
                                              width: 8,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isSuccess
                                                        ? AppTheme.gold
                                                        : Colors.red)
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 30,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            isSuccess
                                                ? 'CASE SOLVED'
                                                : 'CASE REOPENED',
                                            style: TextStyle(
                                              color: isSuccess
                                                  ? AppTheme.gold
                                                  : Colors.red,
                                              fontSize: 40,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 4,
                                              shadows: [
                                                Shadow(
                                                  color: isSuccess
                                                      ? AppTheme.gold
                                                      : Colors.red,
                                                  blurRadius: 20,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Message
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            isSuccess
                                ? 'Excellent deduction, Detective! The culprit has been apprehended and the stolen property recovered.'
                                : 'Your deduction was incorrect. The culprit slipped away. Review the evidence and try again.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.6,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        if (isSuccess && !isTraining) ...[
                          const SizedBox(height: 32),
                          // Rewards HUD
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: AppTheme.cyan.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        AppTheme.cyan.withValues(alpha: 0.05),
                                    blurRadius: 20)
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text('/// REWARDS ACQUIRED ///',
                                    style: TextStyle(
                                        color: AppTheme.cyan,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2)),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildReward(Icons.star, AppTheme.purple,
                                        '+${currentCase.difficulty * 50} XP'),
                                    _buildReward(Icons.shield, AppTheme.gold,
                                        '+${currentCase.difficulty * 10} DP'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Action Button
                        PremiumButton(
                          text: isSuccess
                              ? (isTraining && currentCase.difficulty >= 4
                                  ? 'TRAINING COMPLETE'
                                  : 'NEXT CASE')
                              : 'RETRY INVESTIGATION',
                          backgroundColor:
                              isSuccess ? AppTheme.cyan : Colors.redAccent,
                          onPressed: () {
                            AudioManager.playClick();
                            void continueNavigation() {
                              if (!mounted) return;
                              if (isSuccess) {
                                final nextDifficulty =
                                    currentCase.difficulty + 1;
                                final lastDifficulty = isTraining ? 4 : 1000;
                                if (nextDifficulty <= lastDifficulty) {
                                  AudioManager
                                      .playBackground(); // Ensure music plays
                                  ref
                                      .read(gameSessionProvider.notifier)
                                      .startGame(
                                        'case_$nextDifficulty',
                                        isTraining: isTraining,
                                      );
                                  context.pushReplacement('/case-intro');
                                } else {
                                  if (isTraining) {
                                    context.pop();
                                  } else {
                                    AudioManager.stopBackground();
                                    context.go('/home');
                                  }
                                }
                              } else {
                                AudioManager
                                    .playBackground(); // Ensure music plays
                                context.pushReplacement('/case-intro');
                              }
                            }

                            if (isSuccess && !isTraining) {
                              AdService.showAfterSolvedCase(
                                onComplete: continueNavigation,
                              );
                            } else {
                              continueNavigation();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReward(IconData icon, Color color, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15)
            ],
          ),
          child: Icon(icon, color: color, size: 36),
        ),
        const SizedBox(height: 12),
        Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1)),
      ],
    );
  }
}
