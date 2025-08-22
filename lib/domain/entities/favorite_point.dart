import 'package:equatable/equatable.dart';

class FavoritePoint extends Equatable {
  final String? favIdx;  // 관리용 인덱스 (서버에서 제공)
  final String name;
  final double longitude;
  final double latitude;
  final double? entranceLongitude;
  final double? entranceLatitude;

  const FavoritePoint({
    this.favIdx,
    required this.name,
    required this.longitude,
    required this.latitude,
    this.entranceLongitude,
    this.entranceLatitude,
  });

  @override
  List<Object?> get props => [
        favIdx,
        name,
        longitude,
        latitude,
        entranceLongitude,
        entranceLatitude,
      ];
}