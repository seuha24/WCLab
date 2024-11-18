// ignore_for_file: constant_identifier_names

part of core;

@HiveType(typeId: 1)
enum ColorMode {
  @HiveField(0)
  SYSTEM,

  @HiveField(1)
  LIGHT,

  @HiveField(2)
  DARK,
}

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ColorModeAdapter extends TypeAdapter<ColorMode> {
  @override
  final int typeId = 1;

  @override
  ColorMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ColorMode.SYSTEM;
      case 1:
        return ColorMode.LIGHT;
      case 2:
        return ColorMode.DARK;
      default:
        return ColorMode.SYSTEM;
    }
  }

  @override
  void write(BinaryWriter writer, ColorMode obj) {
    switch (obj) {
      case ColorMode.SYSTEM:
        writer.writeByte(0);
        break;
      case ColorMode.LIGHT:
        writer.writeByte(1);
        break;
      case ColorMode.DARK:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
