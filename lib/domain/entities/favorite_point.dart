import 'package:equatable/equatable.dart';

class FavoritePoint extends Equatable {
  final String name;
  final double longitude;
  final double latitude;
  final double? entranceLongitude;
  final double? entranceLatitude;

  const FavoritePoint({
    required this.name,
    required this.longitude,
    required this.latitude,
    this.entranceLongitude,
    this.entranceLatitude,
  });

  @override
  List<Object?> get props => [
        name,
        longitude,
        latitude,
        entranceLongitude,
        entranceLatitude,
      ];
}