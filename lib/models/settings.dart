import 'package:hive/hive.dart';

class Settings {
  bool soundEnabled;
  bool musicEnabled;
  bool vibrationEnabled;
  String detectiveName;

  Settings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.detectiveName = 'Detective',
  });
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 3;

  @override
  Settings read(BinaryReader reader) {
    bool sound = reader.readBool();
    bool music = reader.readBool();
    bool vibration = reader.readBool();
    String name = 'Detective';
    try {
      name = reader.readString();
    } catch (_) {}

    return Settings(
      soundEnabled: sound,
      musicEnabled: music,
      vibrationEnabled: vibration,
      detectiveName: name,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer.writeBool(obj.soundEnabled);
    writer.writeBool(obj.musicEnabled);
    writer.writeBool(obj.vibrationEnabled);
    writer.writeString(obj.detectiveName);
  }
}
