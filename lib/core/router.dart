import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/choose_mode_screen.dart';
import '../screens/training_mode_screen.dart';
import '../screens/cases_screen.dart';
import '../screens/case_intro_screen.dart';
import '../screens/evidence_board_screen.dart';
import '../screens/question_screen.dart';
import '../screens/result_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/number_memory_levels_screen.dart';
import '../screens/number_memory_game_screen.dart';
import '../screens/sequence_memory_levels_screen.dart';
import '../screens/sequence_memory_game_screen.dart';
import '../screens/visual_memory_levels_screen.dart';
import '../screens/visual_memory_game_screen.dart';
import '../screens/sound_memory_levels_screen.dart';
import '../screens/sound_memory_game_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/choose-mode',
      builder: (context, state) => const ChooseModeScreen(),
    ),
    GoRoute(
      path: '/training-mode',
      builder: (context, state) => const TrainingModeScreen(),
    ),
    GoRoute(
      path: '/cases',
      builder: (context, state) => const CasesScreen(),
    ),
    GoRoute(
      path: '/training-cases',
      builder: (context, state) => const CasesScreen(isTraining: true),
    ),
    GoRoute(
      path: '/case-intro',
      builder: (context, state) => const CaseIntroScreen(),
    ),
    GoRoute(
      path: '/evidence-board',
      builder: (context, state) => const EvidenceBoardScreen(),
    ),
    GoRoute(
      path: '/question',
      builder: (context, state) => const QuestionScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
    GoRoute(
      path: '/daily-challenge',
      builder: (context, state) => const DailyChallengeScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/number-levels',
      builder: (context, state) => const NumberMemoryLevelsScreen(),
    ),
    GoRoute(
      path: '/training-number-levels',
      builder: (context, state) =>
          const NumberMemoryLevelsScreen(isTraining: true),
    ),
    GoRoute(
      path: '/number-game',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final level = extra?['level'] as int? ?? 1;
        final digits = extra?['digits'] as int? ?? 3;
        final maxLevel = extra?['maxLevel'] as int? ?? 1000;
        final mode = extra?['mode'] as String? ?? 'play';
        final dailyRewardXp = extra?['dailyRewardXp'] as int? ?? 0;
        return NumberMemoryGameScreen(
            level: level,
            digits: digits,
            maxLevel: maxLevel,
            mode: mode,
            dailyRewardXp: dailyRewardXp);
      },
    ),
    GoRoute(
      path: '/sequence-levels',
      builder: (context, state) => const SequenceMemoryLevelsScreen(),
    ),
    GoRoute(
      path: '/training-sequence-levels',
      builder: (context, state) =>
          const SequenceMemoryLevelsScreen(isTraining: true),
    ),
    GoRoute(
      path: '/sequence-game',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final level = extra?['level'] as int? ?? 1;
        final length = extra?['length'] as int? ?? 3;
        final maxLevel = extra?['maxLevel'] as int? ?? 1000;
        final mode = extra?['mode'] as String? ?? 'play';
        final dailyRewardXp = extra?['dailyRewardXp'] as int? ?? 0;
        return SequenceMemoryGameScreen(
            level: level,
            length: length,
            maxLevel: maxLevel,
            mode: mode,
            dailyRewardXp: dailyRewardXp);
      },
    ),
    GoRoute(
      path: '/visual-levels',
      builder: (context, state) => const VisualMemoryLevelsScreen(),
    ),
    GoRoute(
      path: '/training-visual-levels',
      builder: (context, state) =>
          const VisualMemoryLevelsScreen(isTraining: true),
    ),
    GoRoute(
      path: '/visual-game',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final level = extra?['level'] as int? ?? 1;
        final gridSize = extra?['gridSize'] as int? ?? 3;
        final activeTiles = extra?['activeTiles'] as int? ?? 3;
        final maxLevel = extra?['maxLevel'] as int? ?? 1000;
        final mode = extra?['mode'] as String? ?? 'play';
        final dailyRewardXp = extra?['dailyRewardXp'] as int? ?? 0;
        return VisualMemoryGameScreen(
            level: level,
            gridSize: gridSize,
            activeTiles: activeTiles,
            maxLevel: maxLevel,
            mode: mode,
            dailyRewardXp: dailyRewardXp);
      },
    ),
    GoRoute(
      path: '/sound-levels',
      builder: (context, state) => const SoundMemoryLevelsScreen(),
    ),
    GoRoute(
      path: '/training-sound-levels',
      builder: (context, state) =>
          const SoundMemoryLevelsScreen(isTraining: true),
    ),
    GoRoute(
      path: '/sound-game',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final level = extra?['level'] as int? ?? 1;
        final length = extra?['length'] as int? ?? 3;
        final instrumentCount = extra?['instrumentCount'] as int? ?? 4;
        final maxLevel = extra?['maxLevel'] as int? ?? 1000;
        final mode = extra?['mode'] as String? ?? 'play';
        final dailyRewardXp = extra?['dailyRewardXp'] as int? ?? 0;
        return SoundMemoryGameScreen(
            level: level,
            length: length,
            instrumentCount: instrumentCount,
            maxLevel: maxLevel,
            mode: mode,
            dailyRewardXp: dailyRewardXp);
      },
    ),
  ],
);
