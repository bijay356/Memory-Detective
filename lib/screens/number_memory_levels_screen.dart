import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/audio_manager.dart';
import '../data/local_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/detective_card.dart';
import '../widgets/map_node.dart';

class NumberMemoryLevelsScreen extends StatefulWidget {
  final bool isTraining;

  const NumberMemoryLevelsScreen({Key? key, this.isTraining = false})
      : super(key: key);

  static const List<int> _trainingDigits = [3, 4, 5, 6];

  @override
  State<NumberMemoryLevelsScreen> createState() =>
      _NumberMemoryLevelsScreenState();
}

class _NumberMemoryLevelsScreenState extends State<NumberMemoryLevelsScreen> {
  int maxUnlockedLevel = 1;
  final int totalLevels = 1000;

  @override
  void initState() {
    super.initState();
    if (!widget.isTraining) {
      _calculateProgress();
    }
  }

  void _calculateProgress() {
    int maxLevel = 1;
    for (int i = 1; i <= totalLevels; i++) {
      final levelId = 'num_case_$i';
      final progress = LocalStorage.casesBox.get(levelId);
      if (progress != null && progress.isUnlocked) {
        maxLevel = i;
      }
    }
    setState(() {
      maxUnlockedLevel = maxLevel;
    });
  }

  void _showLevelDialog(int level, int digitCount) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEVEL $level',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Memory Sequence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    'Mission Objective:\nMemorize $digitCount digits in exact order before they disappear. Do you have what it takes?',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AudioManager.playClick();
                      AudioManager.playBackground();
                      context.pop(); // Close dialog
                      context.push('/number-game',
                          extra: {'level': level, 'digits': digitCount});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'START LEVEL',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTraining ? 'NUMBER TRAINING' : 'NUMBER MEMORY',
            style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: widget.isTraining
          ? _buildTrainingList(context)
          : _buildFullLevelList(),
    );
  }

  Widget _buildFullLevelList() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      return ListView.builder(
        reverse: true, // Bottom-to-Top scrolling
        padding: const EdgeInsets.symmetric(vertical: 40),
        itemCount: totalLevels,
        itemBuilder: (context, index) {
          final level = index + 1;

          NodeStatus status;
          if (level < maxUnlockedLevel) {
            status = NodeStatus.completed;
          } else if (level == maxUnlockedLevel) {
            status = NodeStatus.current;
          } else {
            status = NodeStatus.locked;
          }

          final alignX = sin(index * 0.6) * 0.6;
          final nextAlignX =
              index < totalLevels - 1 ? sin((index + 1) * 0.6) * 0.6 : alignX;

          return SizedBox(
            height: 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (index < totalLevels - 1)
                  CustomPaint(
                    size: Size(width, 120),
                    painter: _MapPathPainter(
                      startX: (alignX + 1) / 2,
                      endX: (nextAlignX + 1) / 2,
                      isCompleted: level < maxUnlockedLevel,
                      pathColor: Colors.blue,
                    ),
                  ),
                Align(
                  alignment: Alignment(alignX, 0),
                  child: MapNode(
                    level: level,
                    status: status,
                    onTap: () {
                      AudioManager.playClick();
                      final digitCount = 3 + (level / 2).floor();
                      _showLevelDialog(level, digitCount);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildTrainingList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _TrainingGuide(
          title: 'How to play',
          steps:
              '''\u2022 The Rule: Memorize the exact digit sequence before it vanishes.
\u2022 The Easy Way (Chunking): Don't read it as individual numbers (e.g., "4, 1, 9, 7"). Group them into pairs or recognizable years (e.g., "41 - 97"). Speak them out loud in your head.''',
          color: Colors.blue,
          icon: Icons.numbers,
        ),
        const SizedBox(height: 16),
        ...List.generate(NumberMemoryLevelsScreen._trainingDigits.length,
            (index) {
          final digitCount = NumberMemoryLevelsScreen._trainingDigits[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DetectiveCard(
              title: 'MISSION ${index + 1}',
              subtitle: '$digitCount digits - learn exact order',
              icon: const Icon(Icons.numbers, color: Colors.blue, size: 32),
              actionWidget: ElevatedButton(
                onPressed: () {
                  AudioManager.playClick();
                  AudioManager.playBackground();
                  context.push('/number-game', extra: {
                    'level': index + 1,
                    'digits': digitCount,
                    'maxLevel': 4,
                    'mode': 'training',
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Play'),
              ),
              onTap: () {
                AudioManager.playClick();
                AudioManager.playBackground();
                context.push('/number-game', extra: {
                  'level': index + 1,
                  'digits': digitCount,
                  'maxLevel': 4,
                  'mode': 'training',
                });
              },
            ),
          );
        }),
      ],
    );
  }
}

class _MapPathPainter extends CustomPainter {
  final double startX;
  final double endX;
  final bool isCompleted;
  final Color pathColor;

  _MapPathPainter({
    required this.startX,
    required this.endX,
    required this.isCompleted,
    required this.pathColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted ? pathColor : Colors.white12
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startPoint = Offset(size.width * startX, size.height / 2);
    final endPoint = Offset(size.width * endX, -size.height / 2);

    double dashWidth = 8;
    double dashSpace = 8;

    var path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..lineTo(endPoint.dx, endPoint.dy);

    PathMetrics pathMetrics = path.computeMetrics();
    Path dashedPath = Path();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _MapPathPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.endX != endX ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.pathColor != pathColor;
  }
}

class _TrainingGuide extends StatelessWidget {
  final String title;
  final String steps;
  final Color color;
  final IconData icon;

  const _TrainingGuide({
    required this.title,
    required this.steps,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(steps,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
