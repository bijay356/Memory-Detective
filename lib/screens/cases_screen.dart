import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../game/scene_data.dart';
import '../providers/game_session_provider.dart';
import '../data/local_storage.dart';
import '../core/audio_manager.dart';
import '../widgets/map_node.dart';

class CasesScreen extends ConsumerStatefulWidget {
  final bool isTraining;

  const CasesScreen({Key? key, this.isTraining = false}) : super(key: key);

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  int maxUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
  }

  void _calculateProgress() {
    int maxLevel = 1;
    final cases = SceneDatabase.cases;

    // Find the highest unlocked level
    for (int i = 0; i < cases.length; i++) {
      final progress = LocalStorage.casesBox.get(cases[i].id);
      if (progress != null && progress.isUnlocked) {
        maxLevel = i + 1;
      }
    }
    setState(() {
      maxUnlockedLevel = maxLevel;
    });
  }

  void _showCaseDialog(StoryCase gameCase) {
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
              border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
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
                  'LEVEL ${gameCase.difficulty}',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gameCase.title,
                  style: const TextStyle(
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
                    gameCase.description,
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
                      ref.read(gameSessionProvider.notifier).startGame(
                          gameCase.id,
                          isTraining: widget.isTraining);
                      context.pop(); // Close dialog
                      context.push('/case-intro');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'START INVESTIGATION',
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

  void _showLockedCasePreview(StoryCase gameCase) {
    final words = gameCase.description.split(RegExp(r'\s+'));
    final previewLength = (words.length / 2).ceil();
    final preview = '${words.take(previewLength).join(' ')}...';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.4)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppTheme.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'CLASSIFIED CASE #${gameCase.difficulty}',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gameCase.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                preview,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Text(
                  'Solve the previous case to decrypt the full briefing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cases = SceneDatabase.cases;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isTraining ? 'DETECTIVE TRAINING' : 'GLOBAL OUTBREAKS',
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
          ? _buildTrainingList(context, cases)
          : LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;

              return ListView.builder(
                reverse: true, // Bottom-to-Top scrolling like Candy Crush
                padding: const EdgeInsets.symmetric(vertical: 40),
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final gameCase = cases[index];
                  final level = index + 1;

                  NodeStatus status;
                  if (level < maxUnlockedLevel) {
                    status = NodeStatus.completed;
                  } else if (level == maxUnlockedLevel) {
                    status = NodeStatus.current;
                  } else {
                    status = NodeStatus.locked;
                  }

                  // Calculate sine wave alignment for this node
                  final alignX = sin(index * 0.6) * 0.6;

                  // Calculate alignment for the next node (which is visually ABOVE this node because of reverse: true)
                  // If this is the last node, just point straight up.
                  final nextAlignX = index < cases.length - 1
                      ? sin((index + 1) * 0.6) * 0.6
                      : alignX;

                  return SizedBox(
                    height: 120, // Height of each map row
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Draw the path to the next node
                        if (index < cases.length - 1)
                          CustomPaint(
                            size: Size(width, 120),
                            painter: _MapPathPainter(
                              startX: (alignX + 1) /
                                  2, // Convert from -1..1 to 0..1
                              endX: (nextAlignX + 1) / 2,
                              isCompleted: level < maxUnlockedLevel,
                            ),
                          ),
                        // Draw the node itself
                        Align(
                          alignment: Alignment(alignX, 0),
                          child: MapNode(
                            level: level,
                            status: status,
                            onTap: () {
                              AudioManager.playClick();
                              _showCaseDialog(gameCase);
                            },
                            onLockedTap: () {
                              AudioManager.playClick();
                              _showLockedCasePreview(gameCase);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
    );
  }

  Widget _buildTrainingList(BuildContext context, List<StoryCase> allCases) {
    // Show only the first 4 easiest cases
    final trainingCases = allCases.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _TrainingGuide(
          title: 'How to play',
          steps:
              '''\u2022 The Rule: Read the suspect statements carefully and spot the contradiction in the timeline.
\u2022 The Easy Way (Cross-Referencing): Don't try to memorize everything. Focus entirely on TIME. If suspect A says they arrived at 9:00, and suspect B says they saw suspect A arrive at 10:00, that is your lie.''',
          color: AppTheme.gold,
          icon: Icons.search,
        ),
        const SizedBox(height: 16),
        ...List.generate(trainingCases.length, (index) {
          final gameCase = trainingCases[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading:
                    const Icon(Icons.search, color: AppTheme.gold, size: 32),
                title: Text('CASE ${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                subtitle: Text(gameCase.title,
                    style: TextStyle(color: Colors.white.withOpacity(0.7))),
                trailing: ElevatedButton(
                  onPressed: () {
                    AudioManager.playClick();
                    AudioManager.playBackground();
                    ref
                        .read(gameSessionProvider.notifier)
                        .startGame(gameCase.id, isTraining: widget.isTraining);
                    context.push('/case-intro');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Play'),
                ),
              ),
            ),
          );
        }),
      ],
    );
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

class _MapPathPainter extends CustomPainter {
  final double startX;
  final double endX;
  final bool isCompleted;

  _MapPathPainter({
    required this.startX,
    required this.endX,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted ? AppTheme.green : Colors.white12
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startPoint = Offset(size.width * startX, size.height / 2);
    // End point is vertically centered in the cell ABOVE this one
    // Since we are painting inside this cell (height 120), the center of the next cell is at -size.height/2
    final endPoint = Offset(size.width * endX, -size.height / 2);

    // Draw dashed line
    double dashWidth = 8;
    double dashSpace = 8;

    var path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..lineTo(endPoint.dx, endPoint.dy);

    // To properly draw a dashed line, we have to extract metrics
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
        oldDelegate.isCompleted != isCompleted;
  }
}
