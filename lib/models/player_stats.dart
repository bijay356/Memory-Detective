import 'package:hive/hive.dart';

class PlayerStats {
  int level;
  int xp;
  int totalScore;
  int casesSolved;
  int bestScore;
  int totalCorrectAnswers;
  int totalQuestionsAnswered;
  int totalTimePlayedSeconds;
  int currentStreak;
  String lastPlayedDate;

  PlayerStats({
    this.level = 1,
    this.xp = 0,
    this.totalScore = 0,
    this.casesSolved = 0,
    this.bestScore = 0,
    this.totalCorrectAnswers = 0,
    this.totalQuestionsAnswered = 0,
    this.totalTimePlayedSeconds = 0,
    this.currentStreak = 0,
    this.lastPlayedDate = '',
  });

  double get accuracy {
    if (totalQuestionsAnswered == 0) return 0;
    return (totalCorrectAnswers / totalQuestionsAnswered) * 100;
  }

  String get rank {
    if (casesSolved < 5) return 'Rookie Detective';
    if (casesSolved < 15) return 'Junior Investigator';
    if (casesSolved < 30) return 'Investigator';
    if (casesSolved < 50) return 'Senior Detective';
    if (casesSolved < 70) return 'Detective Inspector';
    if (casesSolved < 85) return 'Chief Detective';
    if (casesSolved < 99) return 'Master Detective';
    return 'Legendary Detective';
  }
}

class PlayerStatsAdapter extends TypeAdapter<PlayerStats> {
  @override
  final int typeId = 0;

  @override
  PlayerStats read(BinaryReader reader) {
    return PlayerStats(
      level: reader.readInt(),
      xp: reader.readInt(),
      totalScore: reader.readInt(),
      casesSolved: reader.readInt(),
      bestScore: reader.readInt(),
      totalCorrectAnswers: reader.readInt(),
      totalQuestionsAnswered: reader.readInt(),
      totalTimePlayedSeconds: reader.readInt(),
      currentStreak: reader.readInt(),
      lastPlayedDate: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStats obj) {
    writer.writeInt(obj.level);
    writer.writeInt(obj.xp);
    writer.writeInt(obj.totalScore);
    writer.writeInt(obj.casesSolved);
    writer.writeInt(obj.bestScore);
    writer.writeInt(obj.totalCorrectAnswers);
    writer.writeInt(obj.totalQuestionsAnswered);
    writer.writeInt(obj.totalTimePlayedSeconds);
    writer.writeInt(obj.currentStreak);
    writer.writeString(obj.lastPlayedDate);
  }
}
