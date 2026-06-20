import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../data/local_storage.dart';
import '../models/case_progress.dart';
import '../providers/game_providers.dart';
import '../widgets/premium_button.dart';
import '../core/audio_manager.dart';

class VisualMemoryGameScreen extends ConsumerStatefulWidget {
  final int level;
  final int gridSize;
  final int activeTiles;
  final int maxLevel;
  final String mode;
  final int dailyRewardXp;

  const VisualMemoryGameScreen({
    Key? key,
    required this.level,
    required this.gridSize,
    required this.activeTiles,
    this.maxLevel = 1000,
    this.mode = 'play',
    this.dailyRewardXp = 0,
  }) : super(key: key);

  @override
  ConsumerState<VisualMemoryGameScreen> createState() =>
      _VisualMemoryGameScreenState();
}

class _VisualMemoryGameScreenState
    extends ConsumerState<VisualMemoryGameScreen> {
  String phase = 'memorize'; // 'memorize', 'recall', 'result'
  Set<int> targetIndices = {};
  Set<int> foundIndices = {};
  Set<int> wrongIndices = {};
  int lives = 3;
  bool isSuccess = false;
  int _roundId = 0;
  bool get _isTrainingRun => widget.mode == 'training';
  bool get _isDailyRun => widget.mode == 'daily';

  @override
  void initState() {
    super.initState();
    _generatePattern();
    _startMemorizePhase();
  }

  void _generatePattern() {
    final rand = Random();
    targetIndices.clear();
    foundIndices.clear();
    wrongIndices.clear();
    int totalTiles = widget.gridSize * widget.gridSize;
    final tilesToActivate = min(widget.activeTiles, totalTiles);

    while (targetIndices.length < tilesToActivate) {
      targetIndices.add(rand.nextInt(totalTiles));
    }
  }

  void _startMemorizePhase() {
    final roundId = ++_roundId;
    // Show pattern for 2-3 seconds depending on activeTiles
    int duration = 1500 + (widget.activeTiles * 100);
    Future.delayed(Duration(milliseconds: duration), () {
      if (mounted && roundId == _roundId) {
        setState(() {
          phase = 'recall';
        });
      }
    });
  }

  @override
  void dispose() {
    _roundId++;
    super.dispose();
  }

  void _onTileTap(int index) {
    if (phase != 'recall') return;
    if (foundIndices.contains(index) || wrongIndices.contains(index)) return;

    AudioManager.playClick();

    setState(() {
      if (targetIndices.contains(index)) {
        foundIndices.add(index);
        AudioManager.selectionHaptic();
        if (foundIndices.length == targetIndices.length) {
          AudioManager.lightHaptic();
          phase = 'result';
          isSuccess = true;
          _saveProgress();
        }
      } else {
        AudioManager.heavyHaptic();
        wrongIndices.add(index);
        lives--;
        if (lives <= 0) {
          phase = 'result';
          isSuccess = false;
        }
      }
    });
  }

  void _saveProgress() {
    if (_isTrainingRun) return;
    if (_isDailyRun) {
      ref
          .read(playerStatsProvider.notifier)
          .completeDailyChallenge(widget.dailyRewardXp);
      return;
    }

    final currentId = 'vis_case_${widget.level}';
    var currentProgress = LocalStorage.casesBox.get(currentId) ??
        CaseProgress(caseId: currentId, isUnlocked: true);
    final isFirstCompletion = !currentProgress.isCompleted;
    currentProgress.isCompleted = true;
    LocalStorage.casesBox.put(currentId, currentProgress);

    if (isFirstCompletion) {
      ref
          .read(playerStatsProvider.notifier)
          .addXp(widget.activeTiles * 10 + (lives * 5));
    }

    // Unlock next
    if (widget.level < widget.maxLevel) {
      final nextId = 'vis_case_${widget.level + 1}';
      var nextProgress =
          LocalStorage.casesBox.get(nextId) ?? CaseProgress(caseId: nextId);
      nextProgress.isUnlocked = true;
      LocalStorage.casesBox.put(nextId, nextProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('LEVEL ${widget.level}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (phase != 'result')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: List.generate(3, (index) {
                  return Icon(
                    index < lives ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 20,
                  );
                }),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildHeader(),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: phase == 'result' ? _buildResult() : _buildGrid(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (phase == 'result') return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        decoration: BoxDecoration(
          color: phase == 'memorize'
              ? AppTheme.surfaceLight
              : Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: phase == 'memorize' ? Colors.transparent : Colors.orange),
        ),
        child: Text(
          phase == 'memorize' ? 'MEMORIZE TILES' : 'RECALL TILES',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: phase == 'memorize' ? Colors.white : Colors.orange,
          ),
        ),
      ),
    )
        .animate()
        .fade(duration: 220.ms)
        .slideY(begin: -0.12, curve: Curves.easeOut);
  }

  Widget _buildGrid() {
    int totalTiles = widget.gridSize * widget.gridSize;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: RepaintBoundary(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.gridSize,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: totalTiles,
            itemBuilder: (context, index) {
              bool isTarget = targetIndices.contains(index);
              bool isFound = foundIndices.contains(index);
              bool isWrong = wrongIndices.contains(index);

              Color tileColor = AppTheme.surfaceLight;
              if (phase == 'memorize') {
                if (isTarget) tileColor = Colors.white;
              } else if (phase == 'recall') {
                if (isFound) tileColor = Colors.white;
                if (isWrong) tileColor = Colors.red;
              }

              return GestureDetector(
                onTap: () => _onTileTap(index),
                child: AnimatedScale(
                  scale:
                      ((isTarget && phase == 'memorize') || isFound) ? 1.06 : 1,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: tileColor == Colors.white
                          ? [
                              BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2)
                            ]
                          : isWrong
                              ? [
                                  BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      spreadRadius: 1)
                                ]
                              : [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4))
                                ],
                      border: Border.all(
                          color: tileColor == AppTheme.surfaceLight
                              ? Colors.white10
                              : Colors.transparent),
                    ),
                    child: AnimatedOpacity(
                      opacity: isFound || isWrong ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        isWrong ? Icons.close : Icons.check,
                        color: isWrong ? Colors.white : AppTheme.background,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              )
                  .animate(delay: (index * 12).ms)
                  .fade(duration: 180.ms)
                  .scale(begin: const Offset(0.94, 0.94));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSuccess ? Icons.check_circle : Icons.cancel,
          size: 100,
          color: isSuccess ? AppTheme.green : Colors.red,
        ).animate().scale(duration: 320.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          isSuccess ? 'Pattern Remembered!' : 'Pattern Lost!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isSuccess ? AppTheme.green : Colors.red,
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: isSuccess
              ? PremiumButton(
                  text: widget.level < widget.maxLevel
                      ? (_isTrainingRun ? 'NEXT MISSION' : 'NEXT LEVEL')
                      : (_isTrainingRun
                          ? 'TRAINING COMPLETE'
                          : _isDailyRun
                              ? 'DAILY COMPLETE'
                              : 'FINISHED'),
                  backgroundColor: AppTheme.green,
                  onPressed: () {
                    AudioManager.playClick();
                    if (widget.level < widget.maxLevel) {
                      final nextLevel = widget.level + 1;
                      int newGridSize;
                      int newActiveTiles;

                      if (_isTrainingRun) {
                        newGridSize = nextLevel <= 2 ? 3 : 4;
                        newActiveTiles = nextLevel + 2;
                      } else {
                        newGridSize = 3 + (nextLevel / 10).floor();
                        if (newGridSize > 6) newGridSize = 6;
                        newActiveTiles = 3 + (nextLevel / 2).floor();
                        final maxActiveTiles = (newGridSize * newGridSize) ~/ 2;
                        if (newActiveTiles > maxActiveTiles) {
                          newActiveTiles = maxActiveTiles;
                        }
                      }

                      context.pushReplacement('/visual-game', extra: {
                        'level': nextLevel,
                        'gridSize': newGridSize,
                        'activeTiles': newActiveTiles,
                        'maxLevel': widget.maxLevel,
                        'mode': widget.mode,
                        'dailyRewardXp': widget.dailyRewardXp,
                      });
                    } else {
                      context.pop();
                    }
                  },
                )
              : PremiumButton(
                  text: 'TRY AGAIN',
                  backgroundColor: Colors.red,
                  onPressed: () {
                    AudioManager.playClick();
                    setState(() {
                      isSuccess = false;
                      lives = 3;
                      _generatePattern();
                      phase = 'memorize';
                    });
                    _startMemorizePhase();
                  },
                ),
        ),
      ],
    );
  }
}
