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

class NumberMemoryGameScreen extends ConsumerStatefulWidget {
  final int level;
  final int digits;
  final int maxLevel;
  final String mode;
  final int dailyRewardXp;

  const NumberMemoryGameScreen({
    Key? key,
    required this.level,
    required this.digits,
    this.maxLevel = 1000,
    this.mode = 'play',
    this.dailyRewardXp = 0,
  }) : super(key: key);

  @override
  ConsumerState<NumberMemoryGameScreen> createState() =>
      _NumberMemoryGameScreenState();
}

class _NumberMemoryGameScreenState
    extends ConsumerState<NumberMemoryGameScreen> {
  String phase = 'memorize'; // 'memorize', 'recall', 'result'
  late String targetNumber;
  String enteredNumber = '';
  double progress = 1.0;
  Timer? timer;
  int memorizeTimeMs = 0;
  bool isSuccess = false;
  int _roundId = 0;
  bool get _isTrainingRun => widget.mode == 'training';
  bool get _isDailyRun => widget.mode == 'daily';

  @override
  void initState() {
    super.initState();
    _generateNumber();
    _startMemorizePhase();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _generateNumber() {
    final rand = Random();
    String numStr = '';
    // Generate first digit 1-9 so it doesn't start with 0 (which looks weird)
    numStr += (rand.nextInt(9) + 1).toString();
    for (int i = 1; i < widget.digits; i++) {
      numStr += rand.nextInt(10).toString();
    }
    targetNumber = numStr;
    // Base 2 seconds + 0.5s per digit
    memorizeTimeMs = 2000 + (widget.digits * 500);
  }

  void _startMemorizePhase() {
    timer?.cancel();
    final roundId = ++_roundId;
    int elapsed = 0;
    const interval = 50;
    timer = Timer.periodic(const Duration(milliseconds: interval), (t) {
      if (roundId != _roundId || !mounted) {
        t.cancel();
        return;
      }
      elapsed += interval;
      setState(() {
        progress =
            (1.0 - (elapsed / memorizeTimeMs)).clamp(0.0, 1.0).toDouble();
      });
      if (elapsed >= memorizeTimeMs) {
        t.cancel();
        setState(() => phase = 'recall');
      }
    });
  }

  void _onKeyPress(String val) {
    if (phase != 'recall') return;
    AudioManager.playClick();
    AudioManager.selectionHaptic();
    if (enteredNumber.length < widget.digits) {
      setState(() {
        enteredNumber += val;
      });
    }
  }

  void _onDelete() {
    if (phase != 'recall' || enteredNumber.isEmpty) return;
    AudioManager.playClick();
    AudioManager.selectionHaptic();
    setState(() {
      enteredNumber = enteredNumber.substring(0, enteredNumber.length - 1);
    });
  }

  void _onSubmit() {
    if (enteredNumber.length != widget.digits) return;
    AudioManager.playClick();
    final bool success = enteredNumber == targetNumber;
    if (success) {
      AudioManager.lightHaptic();
    } else {
      AudioManager.heavyHaptic();
    }
    setState(() {
      phase = 'result';
      isSuccess = success;
    });

    if (isSuccess) {
      _saveProgress();
    }
  }

  void _saveProgress() {
    if (_isTrainingRun) return;
    if (_isDailyRun) {
      ref
          .read(playerStatsProvider.notifier)
          .completeDailyChallenge(widget.dailyRewardXp);
      return;
    }

    final currentId = 'num_case_${widget.level}';
    var currentProgress = LocalStorage.casesBox.get(currentId) ??
        CaseProgress(caseId: currentId, isUnlocked: true);
    final isFirstCompletion = !currentProgress.isCompleted;
    currentProgress.isCompleted = true;
    LocalStorage.casesBox.put(currentId, currentProgress);

    if (isFirstCompletion) {
      ref.read(playerStatsProvider.notifier).addXp(widget.digits * 10);
    }

    // Unlock next
    if (widget.level < widget.maxLevel) {
      final nextId = 'num_case_${widget.level + 1}';
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
            if (phase == 'memorize') _buildProgressBar(),
            Expanded(
              child: Center(
                child: _buildMainContent(),
              ),
            ),
            if (phase == 'recall') _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.surfaceLight,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 8,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: _buildPhaseContent(),
    );
  }

  Widget _buildPhaseContent() {
    if (phase == 'memorize') {
      return Padding(
        key: const ValueKey('memorize'),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            targetNumber,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.blue, blurRadius: 24),
              ],
            ),
          ),
        )
            .animate()
            .fade(duration: 220.ms)
            .scale(begin: const Offset(0.92, 0.92)),
      );
    }

    if (phase == 'recall') {
      return SingleChildScrollView(
        child: Column(
          key: const ValueKey('recall'),
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'What was the number?',
              style: TextStyle(fontSize: 20, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  enteredNumber.isEmpty ? '?' : enteredNumber,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color:
                        enteredNumber.isEmpty ? Colors.white24 : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${enteredNumber.length}/${widget.digits}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('result'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSuccess ? Icons.check_circle : Icons.cancel,
          size: 100,
          color: isSuccess ? AppTheme.green : Colors.red,
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          isSuccess ? 'Number Remembered!' : 'Number Forgotten!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isSuccess ? AppTheme.green : Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        if (!isSuccess) ...[
          const Text('Correct Number was:',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(targetNumber,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
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
                  backgroundColor: Colors.blue,
                  onPressed: () {
                    AudioManager.playClick();
                    if (widget.level < widget.maxLevel) {
                      final nextLevel = widget.level + 1;
                      final nextDigits = _isTrainingRun
                          ? widget.digits + 1
                          : 3 + (nextLevel / 2).floor();
                      context.pushReplacement('/number-game', extra: {
                        'level': nextLevel,
                        'digits': nextDigits,
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
                      enteredNumber = '';
                      isSuccess = false;
                      _generateNumber();
                      phase = 'memorize';
                      progress = 1.0;
                    });
                    _startMemorizePhase();
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSubmitKey() {
    final canSubmit = enteredNumber.length == widget.digits;
    return Opacity(
      opacity: canSubmit ? 1 : 0.35,
      child: _buildActionKey(Icons.check, AppTheme.green, _onSubmit),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionKey(Icons.backspace, Colors.red, _onDelete),
              _buildKey('0'),
              _buildSubmitKey(),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.18, duration: 260.ms, curve: Curves.easeOut)
        .fade();
  }

  Widget _buildKey(String val) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(40),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 70,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surface,
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
                color: Colors.blue.withValues(alpha: 0.08), blurRadius: 14)
          ],
        ),
        child: Text(
          val,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surface,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
