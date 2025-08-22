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
  final String? favIdx;  // 관리용 인덱스 (서버에서 제공)
  final String name;
  final RoutePoint? startPoint;
  final RoutePoint? finishPoint;
  final List<RoutePoint?> stopovers;

  const FavoriteRoute({
    this.favIdx,
    required this.name,
    required this.startPoint,
    required this.finishPoint,
    required this.stopovers,
  });

  @override
  List<Object?> get props => [favIdx, name, startPoint, finishPoint, stopovers];
}