import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:memory_detective/data/local_storage.dart';
import 'package:memory_detective/models/achievement.dart';
import 'package:memory_detective/models/case_progress.dart';
import 'package:memory_detective/models/player_stats.dart';
import 'package:memory_detective/models/settings.dart';
import 'package:memory_detective/screens/choose_mode_screen.dart';
import 'package:memory_detective/screens/daily_challenge_screen.dart';
import 'package:memory_detective/screens/home_screen.dart';
import 'package:memory_detective/screens/training_mode_screen.dart';
import 'package:memory_detective/screens/result_screen.dart';
import 'package:memory_detective/providers/game_session_provider.dart';
import 'package:memory_detective/providers/game_providers.dart';
import 'package:memory_detective/widgets/premium_button.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp(
      'memory_detective_test',
    );
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlayerStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CaseProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AchievementAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SettingsAdapter());
    }

    await Hive.openBox<PlayerStats>(LocalStorage.statsBoxName);
    await Hive.openBox<CaseProgress>(LocalStorage.casesBoxName);
    await Hive.openBox<Achievement>(LocalStorage.achievementsBoxName);
    await Hive.openBox<Settings>(LocalStorage.settingsBoxName);
    await LocalStorage.statsBox.put('main', PlayerStats());
    await LocalStorage.settingsBox.put('main', Settings());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('PremiumButton invokes its callback',
      (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PremiumButton(
            text: 'PLAY',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('PLAY'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('HomeScreen renders premium dashboard body',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('MEMORY\nDETECTIVE'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('The City Forgets'), findsOneWidget);
  });

  testWidgets('Core screens adapt across common device sizes',
      (WidgetTester tester) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1366, 768),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull,
          reason: 'HomeScreen overflowed at ${size.width}x${size.height}');

      await tester.pumpWidget(
        const MaterialApp(
          home: ChooseModeScreen(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason:
              'ChooseModeScreen overflowed at ${size.width}x${size.height}');

      await tester.pumpWidget(
        const MaterialApp(
          home: TrainingModeScreen(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason:
              'TrainingModeScreen overflowed at ${size.width}x${size.height}');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DailyChallengeScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason:
              'DailyChallengeScreen overflowed at ${size.width}x${size.height}');
    }

    // Dispose periodic animations and countdowns before the test binding
    // verifies that no timers remain.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  test('Daily challenge XP can only be claimed once per day', () async {
    await LocalStorage.statsBox.put('main', PlayerStats());
    final notifier = PlayerStatsNotifier();

    notifier.completeDailyChallenge(120);
    notifier.completeDailyChallenge(120);

    expect(notifier.state.xp, 120);
    expect(notifier.state.currentStreak, 1);
    expect(notifier.state.lastPlayedDate, isNotEmpty);
  });

  testWidgets('Story result fits a compact Android screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = GameSessionNotifier()
      ..startGame('case_1', isTraining: true)
      ..finishGame(true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSessionProvider.overrideWith((ref) => session),
        ],
        child: const MaterialApp(home: ResultScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.takeException(), isNull);
    expect(find.text('CASE SOLVED'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
