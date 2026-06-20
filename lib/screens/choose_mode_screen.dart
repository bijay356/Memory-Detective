import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_mode_card.dart';

class ChooseModeScreen extends StatelessWidget {
  const ChooseModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('CHOOSE MODE',
            style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        centerTitle: true,
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
                    child: _buildHeader(),
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
                      title: 'MEMORY DETECTIVE',
                      subtitle:
                          'Story cases - inspect evidence and solve mysteries',
                      imagePath: 'assets/images/mode_detective.png',
                      icon: Icons.search,
                      color: AppTheme.gold,
                      route: '/cases',
                      delay: 0,
                    ),
                    PremiumModeCard(
                      title: 'NUMBER MEMORY',
                      subtitle:
                          '1000 levels - remember codes and exact digit order',
                      imagePath: 'assets/images/mode_number.png',
                      icon: Icons.numbers,
                      color: Colors.blueAccent,
                      route: '/number-levels',
                      delay: 100,
                    ),
                    PremiumModeCard(
                      title: 'SEQUENCE MEMORY',
                      subtitle: '1000 levels - watch and repeat flashing paths',
                      imagePath: 'assets/images/mode_sequence.png',
                      icon: Icons.linear_scale,
                      color: Colors.greenAccent,
                      route: '/sequence-levels',
                      delay: 200,
                    ),
                    PremiumModeCard(
                      title: 'VISUAL MEMORY',
                      subtitle: '1000 levels - memorize hidden tile patterns',
                      imagePath: 'assets/images/mode_visual.png',
                      icon: Icons.image,
                      color: Colors.orangeAccent,
                      route: '/visual-levels',
                      delay: 300,
                    ),
                    PremiumModeCard(
                      title: 'SOUND MEMORY',
                      subtitle: '1000 levels - replay the audio evidence order',
                      imagePath: 'assets/images/mode_sound.png',
                      icon: Icons.volume_up,
                      color: AppTheme.purple,
                      route: '/sound-levels',
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.green.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.explore, color: AppTheme.green, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose your path',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                SizedBox(height: 8),
                Text(
                  'Select a training module below to begin your 1000-level neural mapping sequence.',
                  style: TextStyle(
                      color: AppTheme.textSecondary, height: 1.4, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1);
  }
}
