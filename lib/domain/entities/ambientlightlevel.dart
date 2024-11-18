part of object;

class AmbientLightLevel extends Equatable {
  final double? ambientLightLevel;

  const AmbientLightLevel({
    required this.ambientLightLevel,
  });

  @override
  List<Object?> get props => [];

  @override
  String toString() {
    return '{ambientLightLevel : $ambientLightLevel}';
  }
}
