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

class SoundMemoryGameScreen extends ConsumerStatefulWidget {
  final int level;
  final int length;
  final int instrumentCount;
  final int maxLevel;
  final String mode;
  final int dailyRewardXp;

  const SoundMemoryGameScreen({
    Key? key,
    required this.level,
    required this.length,
    this.instrumentCount = 4,
    this.maxLevel = 1000,
    this.mode = 'play',
    this.dailyRewardXp = 0,
  }) : super(key: key);

  @override
  ConsumerState<SoundMemoryGameScreen> createState() =>
      _SoundMemoryGameScreenState();
}

class _SoundMemoryGameScreenState extends ConsumerState<SoundMemoryGameScreen> {
  String phase = 'watch'; // 'watch', 'repeat', 'result'
  List<int> sequence = [];
  int userProgressIndex = 0;
  int? activeIndex;
  bool isSuccess = false;
  int _roundId = 0;
  bool get _isTrainingRun => widget.mode == 'training';
  bool get _isDailyRun => widget.mode == 'daily';

  late final List<Map<String, dynamic>> instruments;

  void _setupInstruments() {
    final allIcons = [
      Icons.music_note,
      Icons.graphic_eq,
      Icons.radar,
      Icons.memory,
      Icons.mic,
      Icons.headphones,
      Icons.speaker,
      Icons.piano,
      Icons.stream
    ];
    final allColors = [
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.yellowAccent,
      Colors.purpleAccent,
      Colors.lightBlueAccent,
      Colors.redAccent,
      Colors.tealAccent
    ];

    instruments = List.generate(
        widget.instrumentCount,
        (i) => {
              'icon': allIcons[i % allIcons.length],
              'color': allColors[i % allColors.length],
            });
  }

  @override
  void initState() {
    super.initState();
    _setupInstruments();
    _generateSequence();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _playSequence();
    });
  }

  void _generateSequence() {
    _roundId++;
    final rand = Random();
    sequence.clear();
    int lastAdded = -1;
    for (int i = 0; i < widget.length; i++) {
      int next;
      do {
        next = rand.nextInt(instruments.length);
      } while (next == lastAdded);
      sequence.add(next);
      lastAdded = next;
    }
  }

  void _playSequence() async {
    final roundId = _roundId;
    for (int i = 0; i < sequence.length; i++) {
      if (!mounted || roundId != _roundId) return;
      setState(() {
        activeIndex = sequence[i];
      });
      AudioManager.playInstrument(sequence[i]);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || roundId != _roundId) return;
      setState(() {
        activeIndex = null;
      });
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted || roundId != _roundId) return;
    setState(() {
      phase = 'repeat';
      userProgressIndex = 0;
    });
  }

  void _onInstrumentTap(int index) async {
    if (phase != 'repeat') return;

    // Flash the instrument
    AudioManager.playInstrument(index);
    setState(() {
      activeIndex = index;
    });

    // Check correctness
    if (sequence[userProgressIndex] == index) {
      userProgressIndex++;
      AudioManager.selectionHaptic();

      final roundId = _roundId;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && roundId == _roundId) {
          setState(() {
            activeIndex = null;
          });
        }
      });

      if (userProgressIndex >= sequence.length) {
        AudioManager.lightHaptic();
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          setState(() {
            phase = 'result';
            isSuccess = true;
          });
          _saveProgress();
        }
      }
    } else {
      // Wrong tap
      AudioManager.heavyHaptic();
      setState(() {
        phase = 'result';
        isSuccess = false;
      });
    }
  }

  @override
  void dispose() {
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

    final currentId = 'snd_case_${widget.level}';
    var currentProgress = LocalStorage.casesBox.get(currentId) ??
        CaseProgress(caseId: currentId, isUnlocked: true);
    final isFirstCompletion = !currentProgress.isCompleted;
    currentProgress.isCompleted = true;
    LocalStorage.casesBox.put(currentId, currentProgress);

    if (isFirstCompletion) {
      ref.read(playerStatsProvider.notifier).addXp(widget.length * 15);
    }

    if (widget.level < widget.maxLevel) {
      final nextId = 'snd_case_${widget.level + 1}';
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
                  child: phase == 'result'
                      ? _buildResult()
                      : _buildInstrumentGrid(),
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
              : AppTheme.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: phase == 'watch'
                  ? AppTheme.textSecondary.withValues(alpha: 0.3)
                  : AppTheme.purple,
              width: 2),
          boxShadow: phase == 'repeat'
              ? [
                  BoxShadow(
                      color: AppTheme.purple.withValues(alpha: 0.3),
                      blurRadius: 20)
                ]
              : [],
        ),
        child: Text(
          phase == 'watch'
              ? 'ANALYZING AUDIO SIGNAL...'
              : 'INPUT DECRYPTION SEQUENCE',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Courier',
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: phase == 'watch' ? AppTheme.textSecondary : AppTheme.purple,
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
                  ? AppTheme.purple
                  : current
                      ? AppTheme.cyan
                      : Colors.white24,
              borderRadius: BorderRadius.circular(99),
              boxShadow: current
                  ? [
                      BoxShadow(
                          color: AppTheme.cyan.withValues(alpha: 0.45),
                          blurRadius: 10)
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInstrumentGrid() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: RepaintBoundary(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: instruments.length > 4 ? 3 : 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: instruments.length,
            itemBuilder: (context, index) {
              final isActive = activeIndex == index;
              final item = instruments[index];
              final color = item['color'] as Color;

              return GestureDetector(
                onTap: () => _onInstrumentTap(index),
                child: AnimatedScale(
                  scale: isActive ? 1.07 : 1,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withValues(alpha: 0.2)
                          : AppTheme.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 25,
                                  spreadRadius: 5)
                            ]
                          : [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ],
                      border: Border.all(
                          color: isActive
                              ? color
                              : AppTheme.textSecondary.withValues(alpha: 0.2),
                          width: isActive ? 3 : 1),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isActive) _buildSignalBars(color),
                        Icon(
                          item['icon'] as IconData,
                          size: isActive ? 64 : 48,
                          color: isActive
                              ? color
                              : AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate(delay: (index * 45).ms)
                  .fade(duration: 220.ms)
                  .scale(begin: const Offset(0.9, 0.9));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSignalBars(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return Container(
          width: 5,
          height: 24.0 + ((i.isEven ? 12 : 0)),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
                begin: const Offset(1, 0.45),
                end: const Offset(1, 1.25),
                duration: (260 + i * 60).ms,
                curve: Curves.easeInOut);
      }),
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
          isSuccess ? 'Perfect Pitch!' : 'Wrong Note!',
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
                  backgroundColor: AppTheme.purple,
                  onPressed: () {
                    AudioManager.playClick();
                    if (widget.level < widget.maxLevel) {
                      final nextLevel = widget.level + 1;
                      final nextLength = _isTrainingRun
                          ? widget.length + 1
                          : 3 + (nextLevel / 2).floor();
                      var nextInstrumentCount = widget.instrumentCount;
                      if (!_isTrainingRun) {
                        nextInstrumentCount = 4 + (nextLevel / 15).floor();
                        if (nextInstrumentCount > 9) nextInstrumentCount = 9;
                      }
                      context.pushReplacement('/sound-game', extra: {
                        'level': nextLevel,
                        'length': nextLength,
                        'instrumentCount': nextInstrumentCount,
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
                  text: 'REBOOT SYSTEM',
                  backgroundColor: Colors.redAccent,
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
