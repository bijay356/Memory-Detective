import 'package:hive/hive.dart';

class CaseProgress {
  String caseId;
  int stars;
  bool isUnlocked;
  bool isCompleted;
  int bestScore;

  CaseProgress({
    required this.caseId,
    this.stars = 0,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.bestScore = 0,
  });
}

class CaseProgressAdapter extends TypeAdapter<CaseProgress> {
  @override
  final int typeId = 1;

  @override
  CaseProgress read(BinaryReader reader) {
    return CaseProgress(
      caseId: reader.readString(),
      stars: reader.readInt(),
      isUnlocked: reader.readBool(),
      isCompleted: reader.readBool(),
      bestScore: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, CaseProgress obj) {
    writer.writeString(obj.caseId);
    writer.writeInt(obj.stars);
    writer.writeBool(obj.isUnlocked);
    writer.writeBool(obj.isCompleted);
    writer.writeInt(obj.bestScore);
  }
}
