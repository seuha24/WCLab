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
  final List<RoutePoint?> points;

  const FavoriteRoute({
    required this.name,
    required this.points,
  });

  @override
  List<Object?> get props => [name, points];
}