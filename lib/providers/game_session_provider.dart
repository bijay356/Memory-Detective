import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/scene_data.dart';

class GameSessionState {
  final StoryCase? currentCase;
  final int timeElapsedSeconds;
  final bool isFinished;
  final bool isSuccess;
  final bool isTraining;

  GameSessionState({
    this.currentCase,
    this.timeElapsedSeconds = 0,
    this.isFinished = false,
    this.isSuccess = false,
    this.isTraining = false,
  });

  GameSessionState copyWith({
    StoryCase? currentCase,
    int? timeElapsedSeconds,
    bool? isFinished,
    bool? isSuccess,
    bool? isTraining,
  }) {
    return GameSessionState(
      currentCase: currentCase ?? this.currentCase,
      timeElapsedSeconds: timeElapsedSeconds ?? this.timeElapsedSeconds,
      isFinished: isFinished ?? this.isFinished,
      isSuccess: isSuccess ?? this.isSuccess,
      isTraining: isTraining ?? this.isTraining,
    );
  }
}

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSessionState>((ref) {
  return GameSessionNotifier();
});

class GameSessionNotifier extends StateNotifier<GameSessionState> {
  GameSessionNotifier() : super(GameSessionState());

  void startGame(String caseId, {bool isTraining = false}) {
    final storyCase = SceneDatabase.cases.firstWhere((s) => s.id == caseId);
    state = GameSessionState(currentCase: storyCase, isTraining: isTraining);
  }

  void finishGame(bool success) {
    state = state.copyWith(isFinished: true, isSuccess: success);
  }
}
