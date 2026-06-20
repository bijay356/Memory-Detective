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

class SequenceMemoryGameScreen extends ConsumerStatefulWidget {
  final int level;
  final int length;
  final int maxLevel;
  final String mode;
  final int dailyRewardXp;

  const SequenceMemoryGameScreen({
    Key? key,
    required this.level,
    required this.length,
    this.maxLevel = 1000,
    this.mode = 'play',
    this.dailyRewardXp = 0,
  }) : super(key: key);

  @override
  ConsumerState<SequenceMemoryGameScreen> createState() =>
      _SequenceMemoryGameScreenState();
}

class _SequenceMemoryGameScreenState
    extends ConsumerState<SequenceMemoryGameScreen>
    with SingleTickerProviderStateMixin {
  String phase = 'watch'; // 'watch', 'repeat', 'result'
  List<int> sequence = [];
  int userProgressIndex = 0;
  int? activeIndex;
  bool isSuccess = false;
  int _roundId = 0;
  bool get _isTrainingRun => widget.mode == 'training';
  bool get _isDailyRun => widget.mode == 'daily';
  late AnimationController _hintAnimationController;

  @override
  void initState() {
    super.initState();
    _hintAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _generateSequence();
    // small delay before starting
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _playSequence();
    });
  }

  void _generateSequence() {
    _roundId++;
    final rand = Random();
    sequence.clear();
    // Grid is 3x3, indices 0-8
    int lastAdded = -1;
    for (int i = 0; i < widget.length; i++) {
      int next;
      do {
        next = rand.nextInt(9);
      } while (next ==
          lastAdded); // Avoid same tile flashing twice in a row to make it distinct
      sequence.add(next);
      lastAdded = next;
    }
  }

  void _playSequence() async {
    final roundId = _roundId;
    for (int i = 0; i < sequence.length; i++) {
      if (!mounted || roundId != _roundId) return;
      AudioManager.playClick();
      setState(() {
        activeIndex = sequence[i];
      });
      // Flash duration
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted || roundId != _roundId) return;
      setState(() {
        activeIndex = null;
      });
      // Gap between flashes
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted || roundId != _roundId) return;
    setState(() {
      phase = 'repeat';
      userProgressIndex = 0;
    });
    if (_isTrainingRun) {
      _hintAnimationController.forward(from: 0.0);
      _hintAnimationController.repeat();
    }
  }

  void _onTileTap(int index) async {
    if (phase != 'repeat') return;
    AudioManager.playClick();

    // Flash the tile that was tapped
    setState(() {
      activeIndex = index;
    });

    // Check correctness
    if (sequence[userProgressIndex] == index) {
      // Correct tap
      userProgressIndex++;
      AudioManager.selectionHaptic();

      // Flash off quickly
      final roundId = _roundId;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && roundId == _roundId) {
          setState(() {
            activeIndex = null;
          });
        }
      });

      if (userProgressIndex >= sequence.length) {
        if (_isTrainingRun) {
          _hintAnimationController.stop();
        }
        AudioManager.lightHaptic();
        // Successfully completed sequence
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            phase = 'result';
            isSuccess = true;
          });
          _saveProgress();
        }
      } else {
        if (_isTrainingRun) {
          _hintAnimationController.forward(from: 0.0);
          _hintAnimationController.repeat();
        }
      }
    } else {
      // Wrong tap
      AudioManager.heavyHaptic();
      if (_isTrainingRun) {
        _hintAnimationController.stop();
      }
      setState(() {
        phase = 'result';
        isSuccess = false;
      });
    }
  }

  @override
  void dispose() {
    _hintAnimationController.dispose();
    _roundId++;
    super.dispose();
  }

  void _saveProgress() {
    if (_isTrainingRun) return;
    if (_isDailyRun) {
      ref
          .read(playerStatsProvider.notifier)
          .completeDailyChallenge(widget.dailyRewardXp);
      return;
    }

    final currentId = 'seq_case_${widget.level}';
    var currentProgress = LocalStorage.casesBox.get(currentId) ??
        CaseProgress(caseId: currentId, isUnlocked: true);
    final isFirstCompletion = !currentProgress.isCompleted;
    currentProgress.isCompleted = true;
    LocalStorage.casesBox.put(currentId, currentProgress);

    if (isFirstCompletion) {
      ref.read(playerStatsProvider.notifier).addXp(widget.length * 15);
    }

    // Unlock next
    if (widget.level < widget.maxLevel) {
      final nextId = 'seq_case_${widget.level + 1}';
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildHeader(),
            if (phase == 'repeat') _buildProgressTrail(),
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
          color: phase == 'watch'
              ? AppTheme.surfaceLight
              : AppTheme.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: phase == 'watch' ? Colors.transparent : AppTheme.green),
        ),
        child: Text(
          phase == 'watch' ? 'WATCH SEQUENCE' : 'YOUR TURN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: phase == 'watch' ? AppTheme.gold : AppTheme.green,
          ),
        ),
      ),
    )
        .animate()
        .fade(duration: 220.ms)
        .slideY(begin: -0.12, curve: Curves.easeOut);
  }

  Widget _buildProgressTrail() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List.generate(sequence.length, (index) {
          final completed = index < userProgressIndex;
          final current = index == userProgressIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: current ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: completed
                  ? AppTheme.green
                  : current
                      ? AppTheme.gold
                      : Colors.white24,
              borderRadius: BorderRadius.circular(99),
              boxShadow: current
                  ? [
                      BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.45),
                          blurRadius: 10)
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final isActive = activeIndex == index;
                  return GestureDetector(
                    onTap: () => _onTileTap(index),
                    child: AnimatedScale(
                      scale: isActive ? 1.08 : 1,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutBack,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color:
                              isActive ? Colors.white : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      blurRadius: 20,
                                      spreadRadius: 5)
                                ]
                              : [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4))
                                ],
                          border: Border.all(
                              color: isActive ? Colors.white : Colors.white10),
                        ),
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: isActive ? 1 : 0.16,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(Icons.fiber_manual_record,
                                color: isActive
                                    ? AppTheme.background
                                    : Colors.white,
                                size: 18),
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(delay: (index * 25).ms)
                      .fade(duration: 220.ms)
                      .scale(begin: const Offset(0.9, 0.9));
                },
              ),
            ),
            if (_isTrainingRun && phase == 'repeat')
              AnimatedBuilder(
                animation: _hintAnimationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _SequenceHintPainter(
                      sequence: sequence,
                      userProgressIndex: userProgressIndex,
                      progress: _hintAnimationController.value,
                    ),
                  );
                },
              ),
          ],
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
          isSuccess ? 'Sequence Mastered!' : 'Sequence Broken!',
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
                      final nextLength = _isTrainingRun
                          ? widget.length + 1
                          : 3 + (nextLevel / 3).floor();
                      context.pushReplacement('/sequence-game', extra: {
                        'level': nextLevel,
                        'length': nextLength,
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
                      _generateSequence();
                      phase = 'watch';
                    });
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) _playSequence();
                    });
                  },
                ),
        ),
      ],
    );
  }
}

class _SequenceHintPainter extends CustomPainter {
  final List<int> sequence;
  final int userProgressIndex;
  final double progress;

  _SequenceHintPainter({
    required this.sequence,
    required this.userProgressIndex,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sequence.isEmpty || progress <= 0) return;

    int startIndex = userProgressIndex > 0 ? userProgressIndex - 1 : 0;
    int remainingNodes = sequence.length - startIndex;
    if (remainingNodes <= 1) return;

    final paint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.6)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cellSize = (size.width - 2 * 16) / 3;

    Offset getCenter(int index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(
        col * (cellSize + 16) + cellSize / 2,
        row * (cellSize + 16) + cellSize / 2,
      );
    }

    final path = Path();

    int numSegments = remainingNodes - 1;
    double segmentProgress = progress * numSegments;
    int currentSegment = segmentProgress.floor();
    if (currentSegment >= numSegments) {
      currentSegment = numSegments - 1;
      segmentProgress = numSegments.toDouble();
    }

    path.moveTo(
        getCenter(sequence[startIndex]).dx, getCenter(sequence[startIndex]).dy);

    for (int i = 0; i < currentSegment; i++) {
      path.lineTo(getCenter(sequence[startIndex + i + 1]).dx,
          getCenter(sequence[startIndex + i + 1]).dy);
    }

    double t = segmentProgress - currentSegment;
    Offset start = getCenter(sequence[startIndex + currentSegment]);
    Offset end = getCenter(sequence[startIndex + currentSegment + 1]);
    Offset currentPos = Offset(
      start.dx + (end.dx - start.dx) * t,
      start.dy + (end.dy - start.dy) * t,
    );
    path.lineTo(currentPos.dx, currentPos.dy);

    canvas.drawPath(path, paint);

    // Glowing dot at the leading edge
    final dotPaint = Paint()
      ..color = AppTheme.gold
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(currentPos, 10, dotPaint);
    canvas.drawCircle(currentPos, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SequenceHintPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.userProgressIndex != userProgressIndex;
  }
}
