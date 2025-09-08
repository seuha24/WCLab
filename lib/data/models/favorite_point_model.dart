import 'package:safelight/domain/entities/favorite_point.dart';

class FavoritePointModel extends FavoritePoint {
  const FavoritePointModel({
    super.favIdx,
    required super.name,
    required super.longitude,
    required super.latitude,
    super.entranceLongitude,
    super.entranceLatitude,
  });

  factory FavoritePointModel.fromJson(Map<String, dynamic> json) {
    return FavoritePointModel(
      favIdx: json['fav_idx']?.toString(),
      name: json['name'],
      longitude: (json['lon'] as num).toDouble(),
      latitude: (json['lat'] as num).toDouble(),
      entranceLongitude: json['entrance_lon'] != null 
          ? (json['entrance_lon'] as num).toDouble() 
          : null,
      entranceLatitude: json['entrance_lat'] != null 
          ? (json['entrance_lat'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lon': longitude,
      'lat': latitude,
    };
  }

  FavoritePoint toEntity() {
    return FavoritePoint(
      favIdx: favIdx,
      name: name,
      longitude: longitude,
      latitude: latitude,
      entranceLongitude: entranceLongitude,
      entranceLatitude: entranceLatitude,
    );
  }
}