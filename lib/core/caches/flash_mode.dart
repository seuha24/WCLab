// ignore_for_file: constant_identifier_names

part of core;

@HiveType(typeId: 2)
enum FlashMode {
  @HiveField(0)
  WITH_WEATHER,

  @HiveField(1)
  ALWAYS,

  @HiveField(2)
  NEVER_IN_USE,
}

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashModeAdapter extends TypeAdapter<FlashMode> {
  @override
  final int typeId = 2;

  @override
  FlashMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FlashMode.WITH_WEATHER;
      case 1:
        return FlashMode.ALWAYS;
      case 2:
        return FlashMode.NEVER_IN_USE;
      default:
        return FlashMode.ALWAYS;
    }
  }

  @override
  void write(BinaryWriter writer, FlashMode obj) {
    switch (obj) {
      case FlashMode.WITH_WEATHER:
        writer.writeByte(0);
        break;
      case FlashMode.ALWAYS:
        writer.writeByte(1);
        break;
      case FlashMode.NEVER_IN_USE:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
