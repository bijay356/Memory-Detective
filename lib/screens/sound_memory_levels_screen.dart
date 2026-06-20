import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/audio_manager.dart';
import '../data/local_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/detective_card.dart';
import '../widgets/map_node.dart';

class SoundMemoryLevelsScreen extends StatefulWidget {
  final bool isTraining;

  const SoundMemoryLevelsScreen({Key? key, this.isTraining = false})
      : super(key: key);

  static const List<int> _trainingLengths = [3, 4, 5, 6];

  @override
  State<SoundMemoryLevelsScreen> createState() =>
      _SoundMemoryLevelsScreenState();
}

class _SoundMemoryLevelsScreenState extends State<SoundMemoryLevelsScreen> {
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
      final levelId = 'snd_case_$i';
      final progress = LocalStorage.casesBox.get(levelId);
      if (progress != null && progress.isUnlocked) {
        maxLevel = i;
      }
    }
    setState(() {
      maxUnlockedLevel = maxLevel;
    });
  }

  void _showLevelDialog(int level, int sequenceLength, int instrumentCount) {
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
              border: Border.all(color: AppTheme.purple.withOpacity(0.5)),
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
                    color: AppTheme.purple,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sound Memory',
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
                    'Mission Objective:\nListen to the audio sequence of $sequenceLength signals across $instrumentCount distinct frequencies. Repeat the pattern perfectly to decrypt the file.',
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
                      context.push('/sound-game', extra: {
                        'level': level,
                        'length': sequenceLength,
                        'instrumentCount': instrumentCount,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple,
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
        title: Text(widget.isTraining ? 'SOUND TRAINING' : 'SOUND MEMORY',
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
                      pathColor: AppTheme.purple,
                    ),
                  ),
                Align(
                  alignment: Alignment(alignX, 0),
                  child: MapNode(
                    level: level,
                    status: status,
                    onTap: () {
                      AudioManager.playClick();
                      final sequenceLength = 3 + (level / 2).floor();
                      var instrumentCount = 4 + (level / 15).floor();
                      if (instrumentCount > 9) instrumentCount = 9;
                      _showLevelDialog(level, sequenceLength, instrumentCount);
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
              '''\u2022 The Rule: Listen to the sequence of instrument sounds and tap the pads in the exact same order.
\u2022 The Easy Way (Mapping): Assign a short word to each sound (e.g., "Kick, Snare, High, Low"). When the sequence plays, chant the words in your head.''',
          color: AppTheme.purple,
          icon: Icons.volume_up,
        ),
        const SizedBox(height: 16),
        ...List.generate(SoundMemoryLevelsScreen._trainingLengths.length,
            (index) {
          final length = SoundMemoryLevelsScreen._trainingLengths[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DetectiveCard(
              title: 'MISSION ${index + 1}',
              subtitle: '$length sounds - repeat the signal chain',
              icon:
                  const Icon(Icons.volume_up, color: AppTheme.purple, size: 32),
              actionWidget: ElevatedButton(
                onPressed: () {
                  AudioManager.playClick();
                  AudioManager.playBackground();
                  context.push('/sound-game', extra: {
                    'level': index + 1,
                    'length': length,
                    'instrumentCount': 4,
                    'maxLevel': 4,
                    'mode': 'training',
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Play'),
              ),
              onTap: () {
                AudioManager.playClick();
                AudioManager.playBackground();
                context.push('/sound-game', extra: {
                  'level': index + 1,
                  'length': length,
                  'instrumentCount': 4,
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
