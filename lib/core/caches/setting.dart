part of core;

@HiveType(typeId: 0)
class Setting {
  static const String db = 'setting';

  @HiveField(0)
  ColorMode colorMode;

  @HiveField(1)
  bool tts;

  @HiveField(2)
  FlashMode flashMode;

  Setting({
    this.colorMode = ColorMode.SYSTEM,
    this.tts = true,
    this.flashMode = FlashMode.WITH_WEATHER,
  });

  @override
  String toString() {
    return '{colorMode : $colorMode, tts : $tts, flashMode : $flashMode}';
  }
}

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingAdapter extends TypeAdapter<Setting> {
  @override
  final int typeId = 0;

  @override
  Setting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Setting(
      colorMode: fields[0] as ColorMode,
      tts: fields[1] as bool,
      flashMode: fields[2] as FlashMode,
    );
  }

  @override
  void write(BinaryWriter writer, Setting obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.colorMode)
      ..writeByte(1)
      ..write(obj.tts)
      ..writeByte(2)
      ..write(obj.flashMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
