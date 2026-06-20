import 'package:hive/hive.dart';

class Achievement {
  String id;
  String title;
  String description;
  int currentProgress;
  int maxProgress;
  bool isUnlocked;
  String iconName; // We'll map this to a font awesome icon locally

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.maxProgress,
    this.currentProgress = 0,
    this.isUnlocked = false,
    required this.iconName,
  });
}

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 2;

  @override
  Achievement read(BinaryReader reader) {
    return Achievement(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      maxProgress: reader.readInt(),
      currentProgress: reader.readInt(),
      isUnlocked: reader.readBool(),
      iconName: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeInt(obj.maxProgress);
    writer.writeInt(obj.currentProgress);
    writer.writeBool(obj.isUnlocked);
    writer.writeString(obj.iconName);
  }
}
