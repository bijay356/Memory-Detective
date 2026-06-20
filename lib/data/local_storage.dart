import 'package:hive_flutter/hive_flutter.dart';
import '../models/player_stats.dart';
import '../models/case_progress.dart';
import '../models/achievement.dart';
import '../models/settings.dart';

class LocalStorage {
  static const String statsBoxName = 'statsBox';
  static const String casesBoxName = 'casesBox';
  static const String achievementsBoxName = 'achievementsBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(PlayerStatsAdapter());
    Hive.registerAdapter(CaseProgressAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(SettingsAdapter());

    await Hive.openBox<PlayerStats>(statsBoxName);
    await Hive.openBox<CaseProgress>(casesBoxName);
    await Hive.openBox<Achievement>(achievementsBoxName);
    await Hive.openBox<Settings>(settingsBoxName);

    // Initialize defaults if empty
    final statsBox = Hive.box<PlayerStats>(statsBoxName);
    if (statsBox.isEmpty) {
      await statsBox.put('main', PlayerStats());
    }

    final settingsBox = Hive.box<Settings>(settingsBoxName);
    if (settingsBox.isEmpty) {
      await settingsBox.put('main', Settings());
    }
  }

  static Box<PlayerStats> get statsBox => Hive.box<PlayerStats>(statsBoxName);
  static Box<CaseProgress> get casesBox => Hive.box<CaseProgress>(casesBoxName);
  static Box<Achievement> get achievementsBox =>
      Hive.box<Achievement>(achievementsBoxName);
  static Box<Settings> get settingsBox => Hive.box<Settings>(settingsBoxName);
}
