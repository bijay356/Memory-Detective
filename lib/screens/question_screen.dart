import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/game_session_provider.dart';
import '../providers/game_providers.dart';
import '../core/audio_manager.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  int? _hoveredIndex;

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
          // Background Gradient matching Case Intro
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF1B2333), Color(0xFF0F131D)],
                center: Alignment.bottomCenter,
                radius: 1.2,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HUD Elements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DEDUCTION PHASE',
                        style: TextStyle(
                            color: AppTheme.cyan,
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Icon(Icons.radar,
                          color: AppTheme.cyan.withValues(alpha: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // High-tech Terminal Log
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.cyan.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.cyan.withValues(alpha: 0.05),
                            blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('> SYSTEM LOG: EVIDENCE VERIFIED',
                            style: TextStyle(
                                color: AppTheme.green,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                fontFamily: 'monospace')),
                        const SizedBox(height: 8),
                        _buildTerminalText('> String connections confirmed.'),
                        _buildTerminalText('> Neural reconstruction complete.'),
                        _buildTerminalText('> Awaiting final deduction...'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // The Question
                  Text(
                    currentCase.question.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Options
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: currentCase.options.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final option = currentCase.options[index];
                        final isHovered = _hoveredIndex == index;

                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _hoveredIndex = index),
                            onTapCancel: () =>
                                setState(() => _hoveredIndex = null),
                            onTapUp: (_) {
                              AudioManager.playClick();
                              setState(() => _hoveredIndex = null);
                              bool isCorrect =
                                  (index == currentCase.correctIndex);
                              ref
                                  .read(playerStatsProvider.notifier)
                                  .recordAnswer(isCorrect);
                              ref
                                  .read(gameSessionProvider.notifier)
                                  .finishGame(isCorrect);
                              context.pushReplacement('/result');
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 24),
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? AppTheme.cyan.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isHovered
                                      ? AppTheme.cyan
                                      : Colors.white24,
                                  width: isHovered ? 2 : 1,
                                ),
                                boxShadow: isHovered
                                    ? [
                                        BoxShadow(
                                            color: AppTheme.cyan
                                                .withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            spreadRadius: -2)
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '0${index + 1}',
                                    style: TextStyle(
                                      color: isHovered
                                          ? AppTheme.cyan
                                          : Colors.white38,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: isHovered
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (isHovered)
                                    const Icon(Icons.arrow_forward_ios,
                                        color: AppTheme.cyan, size: 16),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildTerminalText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
            fontFamily: 'monospace'),
      ),
    );
  }
}
