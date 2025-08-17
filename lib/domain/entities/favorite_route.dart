import 'package:equatable/equatable.dart';

class RoutePoint extends Equatable {
  final double longitude;
  final double latitude;

  const RoutePoint({
    required this.longitude,
    required this.latitude,
  });

  @override
  List<Object> get props => [longitude, latitude];
}

class FavoriteRoute extends Equatable {
  final String name;
  final RoutePoint? startPoint;
  final RoutePoint? finishPoint;
  final List<RoutePoint?> stopovers;

  const FavoriteRoute({
    required this.name,
    required this.startPoint,
    required this.finishPoint,
    required this.stopovers,
  });

  @override
  List<Object?> get props => [name, startPoint, finishPoint, stopovers];
}