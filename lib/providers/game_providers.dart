import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_storage.dart';
import '../models/player_stats.dart';
import '../models/settings.dart';

final playerStatsProvider =
    StateNotifierProvider<PlayerStatsNotifier, PlayerStats>((ref) {
  return PlayerStatsNotifier();
});

class PlayerStatsNotifier extends StateNotifier<PlayerStats> {
  PlayerStatsNotifier()
      : super(LocalStorage.statsBox.get('main') ?? PlayerStats());

  void updateStats(PlayerStats newStats) {
    state = newStats;
    LocalStorage.statsBox.put('main', state);
  }

  void addXp(int xpToAdd) {
    final newXp = state.xp + xpToAdd;
    final newLevel = (newXp / 1000).floor() + 1;

    state = PlayerStats(
      level: newLevel,
      xp: newXp,
      totalScore: state.totalScore,
      casesSolved: state.casesSolved,
      bestScore: state.bestScore,
      totalCorrectAnswers: state.totalCorrectAnswers,
      totalQuestionsAnswered: state.totalQuestionsAnswered,
      totalTimePlayedSeconds: state.totalTimePlayedSeconds,
      currentStreak: state.currentStreak,
      lastPlayedDate: state.lastPlayedDate,
    );
    LocalStorage.statsBox.put('main', state);
  }

  void incrementCasesSolved(int detectivePoints) {
    state = PlayerStats(
      level: state.level,
      xp: state.xp,
      totalScore: state.totalScore + detectivePoints,
      casesSolved: state.casesSolved + 1,
      bestScore:
          detectivePoints > state.bestScore ? detectivePoints : state.bestScore,
      totalCorrectAnswers: state.totalCorrectAnswers,
      totalQuestionsAnswered: state.totalQuestionsAnswered,
      totalTimePlayedSeconds: state.totalTimePlayedSeconds,
      currentStreak: state.currentStreak,
      lastPlayedDate: state.lastPlayedDate,
    );
    LocalStorage.statsBox.put('main', state);
  }

  void recordAnswer(bool isCorrect) {
    state = PlayerStats(
      level: state.level,
      xp: state.xp,
      totalScore: state.totalScore,
      casesSolved: state.casesSolved,
      bestScore: state.bestScore,
      totalCorrectAnswers: state.totalCorrectAnswers + (isCorrect ? 1 : 0),
      totalQuestionsAnswered: state.totalQuestionsAnswered + 1,
      totalTimePlayedSeconds: state.totalTimePlayedSeconds,
      currentStreak: state.currentStreak,
      lastPlayedDate: state.lastPlayedDate,
    );
    LocalStorage.statsBox.put('main', state);
  }

  /// Awards a daily challenge once per local calendar day and maintains the
  /// streak. Reopening or replaying today's challenge cannot farm XP.
  void completeDailyChallenge(int xpReward) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dateKey(today);
    if (state.lastPlayedDate == todayKey) return;

    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
    final newXp = state.xp + xpReward;
    state = PlayerStats(
      level: (newXp / 1000).floor() + 1,
      xp: newXp,
      totalScore: state.totalScore,
      casesSolved: state.casesSolved,
      bestScore: state.bestScore,
      totalCorrectAnswers: state.totalCorrectAnswers,
      totalQuestionsAnswered: state.totalQuestionsAnswered,
      totalTimePlayedSeconds: state.totalTimePlayedSeconds,
      currentStreak:
          state.lastPlayedDate == yesterdayKey ? state.currentStreak + 1 : 1,
      lastPlayedDate: todayKey,
    );
    LocalStorage.statsBox.put('main', state);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier()
      : super(LocalStorage.settingsBox.get('main') ?? Settings());

  void toggleSound() {
    state = Settings(
      soundEnabled: !state.soundEnabled,
      musicEnabled: state.musicEnabled,
      vibrationEnabled: state.vibrationEnabled,
      detectiveName: state.detectiveName,
    );
    LocalStorage.settingsBox.put('main', state);
  }

  void toggleMusic() {
    state = Settings(
      soundEnabled: state.soundEnabled,
      musicEnabled: !state.musicEnabled,
      vibrationEnabled: state.vibrationEnabled,
      detectiveName: state.detectiveName,
    );
    LocalStorage.settingsBox.put('main', state);
  }

  void toggleVibration() {
    state = Settings(
      soundEnabled: state.soundEnabled,
      musicEnabled: state.musicEnabled,
      vibrationEnabled: !state.vibrationEnabled,
      detectiveName: state.detectiveName,
    );
    LocalStorage.settingsBox.put('main', state);
  }

  void setDetectiveName(String name) {
    state = Settings(
      soundEnabled: state.soundEnabled,
      musicEnabled: state.musicEnabled,
      vibrationEnabled: state.vibrationEnabled,
      detectiveName: name,
    );
    LocalStorage.settingsBox.put('main', state);
  }
}
