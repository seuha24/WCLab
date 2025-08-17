import 'package:safelight/domain/entities/favorite_route.dart';

class RoutePointModel extends RoutePoint {
  const RoutePointModel({
    required double longitude,
    required double latitude,
  }) : super(
          longitude: longitude,
          latitude: latitude,
        );

  factory RoutePointModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('RoutePointModel.fromJson: json is null');
    }
    return RoutePointModel(
      longitude: (json['lon'] as num).toDouble(),
      latitude: (json['lat'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lon': longitude,
      'lat': latitude,
    };
  }
}

class FavoriteRouteModel extends FavoriteRoute {
  const FavoriteRouteModel({
    required String name,
    required List<RoutePoint?> points,
  }) : super(
          name: name,
          points: points,
        );

  factory FavoriteRouteModel.fromJson(Map<String, dynamic> json) {
    final pointsList = json['points'] as List;
    final points = pointsList.map((point) {
      if (point == null) return null;
      return RoutePointModel.fromJson(point);
    }).toList();

    return FavoriteRouteModel(
      name: json['name'],
      points: points,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'points': points.map((point) {
        if (point == null) return null;
        return {
          'lon': point.longitude,
          'lat': point.latitude,
        };
      }).toList(),
    };
  }

  FavoriteRoute toEntity() {
    return FavoriteRoute(
      name: name,
      points: points,
    );
  }
}