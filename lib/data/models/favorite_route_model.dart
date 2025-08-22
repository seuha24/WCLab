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
    String? favIdx,
    required String name,
    required RoutePoint? startPoint,
    required RoutePoint? finishPoint,
    required List<RoutePoint?> stopovers,
  }) : super(
          favIdx: favIdx,
          name: name,
          startPoint: startPoint,
          finishPoint: finishPoint,
          stopovers: stopovers,
        );

  factory FavoriteRouteModel.fromJson(Map<String, dynamic> json) {
    final startPoint = json['start_point'] != null
        ? RoutePointModel.fromJson(json['start_point'])
        : null;
    
    final finishPoint = json['finish_point'] != null
        ? RoutePointModel.fromJson(json['finish_point'])
        : null;
    
    final stopoversList = json['stopovers'] as List? ?? [];
    final stopovers = stopoversList.map((point) {
      if (point == null) return null;
      return RoutePointModel.fromJson(point);
    }).toList();

    return FavoriteRouteModel(
      favIdx: json['fav_idx']?.toString(),
      name: json['name'],
      startPoint: startPoint,
      finishPoint: finishPoint,
      stopovers: stopovers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start_point': startPoint != null
          ? {
              'lon': startPoint!.longitude,
              'lat': startPoint!.latitude,
            }
          : null,
      'finish_point': finishPoint != null
          ? {
              'lon': finishPoint!.longitude,
              'lat': finishPoint!.latitude,
            }
          : null,
      'stopovers': stopovers.map((point) {
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
      favIdx: favIdx,
      name: name,
      startPoint: startPoint,
      finishPoint: finishPoint,
      stopovers: stopovers,
    );
  }
}