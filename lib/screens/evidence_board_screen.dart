import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/game_session_provider.dart';
import '../core/audio_manager.dart';

class EvidenceBoardScreen extends ConsumerStatefulWidget {
  const EvidenceBoardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EvidenceBoardScreen> createState() =>
      _EvidenceBoardScreenState();
}

class _EvidenceBoardScreenState extends ConsumerState<EvidenceBoardScreen> {
  final Random _rand = Random();

  List<Offset> _nodePositions = [];
  List<IconData> _nodeIcons = [];
  Set<String> _targetStrings = {}; // "index1_index2"
  final Set<String> _drawnStrings = {};

  int? _selectedNodeIndex;

  bool _isMemorizing = true;
  bool _isDemoing = false;
  int _memorizeTimeLeft = 10;
  Timer? _timer;
  int _strikes = 3;

  final List<IconData> _evidenceIcons = [
    Icons.person,
    Icons.directions_walk,
    Icons.videocam,
    Icons.search,
    Icons.description,
    Icons.badge,
    Icons.key,
    Icons.folder_special,
    Icons.camera_alt,
    Icons.watch,
    Icons.local_police,
    Icons.fingerprint
  ];

  // Random rotation for each polaroid
  final List<double> _nodeRotations = [];

  @override
  void initState() {
    super.initState();
    // We defer initialization until we have the constraints via LayoutBuilder or after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBoard(context.size ?? const Size(400, 600));
    });
  }

  void _initBoard(Size size) {
    final currentCase = ref.read(gameSessionProvider).currentCase;
    if (currentCase == null) return;

    int numNodes = currentCase.nodeCount;
    int numStrings = currentCase.stringCount;

    // Generate random node positions within bounds
    _nodePositions = [];
    _nodeIcons = [];
    _nodeRotations.clear();
    // Pick icons
    List<IconData> availableIcons = List.from(_evidenceIcons)..shuffle(_rand);

    for (int i = 0; i < numNodes; i++) {
      // Try to find a position not too close to others
      Offset pos;
      bool valid;
      int attempts = 0;
      final double paddingX = 40;
      final double paddingY = 50;
      final double playHeight = size.height - 180; // Adjust for AppBar and HUD

      do {
        valid = true;
        pos = Offset(
          paddingX + _rand.nextDouble() * (size.width - paddingX * 2),
          paddingY + _rand.nextDouble() * (playHeight - paddingY * 2),
        );
        for (var existing in _nodePositions) {
          if ((existing - pos).distance < 80) {
            valid = false;
            break;
          }
        }
        attempts++;
      } while (!valid && attempts < 50);

      _nodePositions.add(pos);
      _nodeIcons.add(availableIcons[i % availableIcons.length]);
      _nodeRotations.add((_rand.nextDouble() - 0.5) *
          0.4); // Random rotation between -0.2 and 0.2 rads
    }

    // Generate random strings connecting pairs
    _targetStrings = {};
    while (_targetStrings.length < numStrings) {
      int idx1 = _rand.nextInt(numNodes);
      int idx2 = _rand.nextInt(numNodes);
      if (idx1 != idx2) {
        String key = _makeKey(idx1, idx2);
        _targetStrings.add(key);
      }
    }

    _startTimer();
    setState(() {});
  }

  String _makeKey(int a, int b) {
    return a < b ? '${a}_$b' : '${b}_$a';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_memorizeTimeLeft > 1) {
          _memorizeTimeLeft--;
        } else {
          final isTraining = ref.read(gameSessionProvider).isTraining;
          if (isTraining) {
            _startDemoSequence();
          } else {
            _isMemorizing = false;
          }
          timer.cancel();
        }
      });
    });
  }

  void _startDemoSequence() async {
    setState(() {
      _isMemorizing = false;
      _isDemoing = true;
    });

    for (String target in _targetStrings) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      AudioManager.playClick();
      AudioManager.lightHaptic();
      setState(() {
        _drawnStrings.add(target);
      });
    }

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    setState(() {
      _drawnStrings.clear();
      _isDemoing = false;
    });
  }

  void _onNodeTap(int index) {
    if (_isMemorizing || _isDemoing) return;
    AudioManager.playClick();
    AudioManager.selectionHaptic();

    setState(() {
      if (_selectedNodeIndex == null) {
        // Select first node
        _selectedNodeIndex = index;
      } else if (_selectedNodeIndex == index) {
        // Deselect
        _selectedNodeIndex = null;
      } else {
        // Draw string between _selectedNodeIndex and index
        String key = _makeKey(_selectedNodeIndex!, index);

        if (_drawnStrings.contains(key)) {
          // Already drawn, do nothing
          _selectedNodeIndex = null;
        } else if (_targetStrings.contains(key)) {
          // Correct string
          AudioManager.lightHaptic();
          _drawnStrings.add(key);
          _selectedNodeIndex = null;
          _checkWinCondition();
        } else {
          // Incorrect string
          AudioManager.heavyHaptic();
          _strikes--;
          _selectedNodeIndex = null;
          if (_strikes <= 0) {
            // Fail case
            ref.read(gameSessionProvider.notifier).finishGame(false);
            context.pushReplacement('/result');
          }
        }
      }
    });
  }

  void _checkWinCondition() {
    if (_drawnStrings.length == _targetStrings.length) {
      // Won!
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pushReplacement('/question');
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCase = ref.watch(gameSessionProvider).currentCase;
    if (currentCase == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF2C2214), // Corkboard brown-ish
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isMemorizing
              ? 'MEMORIZE STRINGS: $_memorizeTimeLeft'
              : _isDemoing
                  ? 'DEMO: WATCH CAREFULLY'
                  : 'RECONNECT STRINGS',
          style: const TextStyle(
              color: AppTheme.gold,
              letterSpacing: 2,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Background texture effect
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(painter: CorkTexturePainter()),
                    ),
                  ),

                  // Strings
                  CustomPaint(
                    size: Size.infinite,
                    painter: StringPainter(
                      positions: _nodePositions,
                      targetStrings: _isMemorizing ? _targetStrings : null,
                      drawnStrings: _drawnStrings,
                    ),
                  ),

                  // Selected node glow
                  if (_selectedNodeIndex != null && _nodePositions.isNotEmpty)
                    Positioned(
                      left: _nodePositions[_selectedNodeIndex!].dx - 30,
                      top: _nodePositions[_selectedNodeIndex!].dy - 30,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.gold, width: 4),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.gold.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ],
                        ),
                      ),
                    ),

                  // Nodes
                  ..._nodePositions.asMap().entries.map((entry) {
                    int idx = entry.key;
                    Offset pos = entry.value;
                    bool isSelected = _selectedNodeIndex == idx;
                    return Positioned(
                      left: pos.dx - 35, // center (70 width)
                      top: pos.dy - 40, // center (80 height)
                      child: GestureDetector(
                        onTap: () => _onNodeTap(idx),
                        child: Transform.rotate(
                          angle: isSelected ? 0 : _nodeRotations[idx],
                          child: AnimatedScale(
                            scale: isSelected ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 70,
                              height: 80,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF0F0F0), // Polaroid white
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      offset: const Offset(3, 4)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(
                                            0xFF1E1E1E), // Dark photo bg
                                        border:
                                            Border.all(color: Colors.black12),
                                      ),
                                      child: Center(
                                        child: Icon(_nodeIcons[idx],
                                            color: AppTheme.cyan, size: 28),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 12), // Polaroid bottom gap
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            // Bottom HUD
            if (!_isMemorizing)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Strike counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: List.generate(
                            3,
                            (index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    index < (3 - _strikes)
                                        ? Icons.close
                                        : Icons.favorite,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                )),
                      ),
                    ),
                    // Progress
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.green),
                      ),
                      child: Text(
                        '${_drawnStrings.length} / ${_targetStrings.length} FOUND',
                        style: const TextStyle(
                            color: AppTheme.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CorkTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);
    final lightPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);

    for (double y = 0; y < size.height; y += 12) {
      for (double x = 0; x < size.width; x += 12) {
        final paint = ((x + y) ~/ 12).isEven ? lightPaint : darkPaint;
        canvas.drawCircle(Offset(x + 3, y + 5), 1.3, paint);
        canvas.drawCircle(Offset(x + 9, y + 2), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CorkTexturePainter oldDelegate) => false;
}

class StringPainter extends CustomPainter {
  final List<Offset> positions;
  final Set<String>? targetStrings;
  final Set<String> drawnStrings;

  StringPainter({
    required this.positions,
    this.targetStrings,
    required this.drawnStrings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    final Paint paintRedGlow = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.5)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final Paint paintRed = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint paintGreenGlow = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.6)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final Paint paintGreen = Paint()
      ..color = AppTheme.cyan
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw targets if we are in memorize phase
    if (targetStrings != null) {
      for (String key in targetStrings!) {
        var parts = key.split('_');
        int a = int.parse(parts[0]);
        int b = int.parse(parts[1]);
        canvas.drawLine(positions[a], positions[b], paintRedGlow);
        canvas.drawLine(positions[a], positions[b], paintRed);
      }
    }

    // Draw user found strings (in cyan or solid red)
    for (String key in drawnStrings) {
      var parts = key.split('_');
      int a = int.parse(parts[0]);
      int b = int.parse(parts[1]);
      canvas.drawLine(positions[a], positions[b], paintGreenGlow);
      canvas.drawLine(positions[a], positions[b], paintGreen);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
