import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_mode_card.dart';

class TrainingModeScreen extends StatelessWidget {
  const TrainingModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TRAINING',
            style:
                TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? constraints.maxWidth * 0.1 : 20,
              vertical: 24,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.green.withValues(alpha: 0.32)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.school, color: AppTheme.green, size: 34),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Practice room',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 6),
                                Text(
                                  'Each training category has 4 guided missions. Learn the rule, build confidence, then use the skill in full play mode.',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 1200
                        ? 4
                        : (constraints.maxWidth > 800 ? 3 : 2),
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildListDelegate([
                    PremiumModeCard(
                      title: 'DETECTIVE TRAINING',
                      subtitle: '4 cases - learn evidence analysis',
                      imagePath: 'assets/images/mode_detective.png',
                      icon: Icons.search,
                      color: AppTheme.gold,
                      route: '/training-cases',
                      delay: 0,
                    ),
                    PremiumModeCard(
                      title: 'NUMBER TRAINING',
                      subtitle: '4 missions - learn digit recall',
                      imagePath: 'assets/images/mode_number.png',
                      icon: Icons.numbers,
                      color: Colors.blueAccent,
                      route: '/training-number-levels',
                      delay: 100,
                    ),
                    PremiumModeCard(
                      title: 'SEQUENCE TRAINING',
                      subtitle: '4 missions - learn flashing paths',
                      imagePath: 'assets/images/mode_sequence.png',
                      icon: Icons.linear_scale,
                      color: Colors.greenAccent,
                      route: '/training-sequence-levels',
                      delay: 200,
                    ),
                    PremiumModeCard(
                      title: 'VISUAL TRAINING',
                      subtitle: '4 missions - learn tile patterns',
                      imagePath: 'assets/images/mode_visual.png',
                      icon: Icons.image,
                      color: Colors.orangeAccent,
                      route: '/training-visual-levels',
                      delay: 300,
                    ),
                    PremiumModeCard(
                      title: 'SOUND TRAINING',
                      subtitle: '4 missions - learn audio order',
                      imagePath: 'assets/images/mode_sound.png',
                      icon: Icons.volume_up,
                      color: AppTheme.purple,
                      route: '/training-sound-levels',
                      delay: 400,
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
