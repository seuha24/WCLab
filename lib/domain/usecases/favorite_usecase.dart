import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/domain/entities/favorite_point.dart';
import 'package:safelight/domain/entities/favorite_route.dart';
import 'package:safelight/domain/repositories/favorite_repository.dart';

class GetFavoritePointsParams extends Equatable {
  final String loginMethod;
  final String userId;

  const GetFavoritePointsParams({
    required this.loginMethod,
    required this.userId,
  });

  @override
  List<Object> get props => [loginMethod, userId];
}

class GetFavoritePoints extends UseCase<List<FavoritePoint>, GetFavoritePointsParams> {
  final FavoriteRepository repository;

  GetFavoritePoints(this.repository);

  @override
  Future<Either<Failure, List<FavoritePoint>>> call(GetFavoritePointsParams params) async {
    return await repository.getFavoritePoints(
      loginMethod: params.loginMethod,
      userId: params.userId,
    );
  }
}

class GetFavoriteRoutesParams extends Equatable {
  final String loginMethod;
  final String userId;

  const GetFavoriteRoutesParams({
    required this.loginMethod,
    required this.userId,
  });

  @override
  List<Object> get props => [loginMethod, userId];
}

class GetFavoriteRoutes extends UseCase<List<FavoriteRoute>, GetFavoriteRoutesParams> {
  final FavoriteRepository repository;

  GetFavoriteRoutes(this.repository);

  @override
  Future<Either<Failure, List<FavoriteRoute>>> call(GetFavoriteRoutesParams params) async {
    return await repository.getFavoriteRoutes(
      loginMethod: params.loginMethod,
      userId: params.userId,
    );
  }
}

class AddFavoritePointParams extends Equatable {
  final String loginMethod;
  final String userId;
  final String name;
  final double longitude;
  final double latitude;

  const AddFavoritePointParams({
    required this.loginMethod,
    required this.userId,
    required this.name,
    required this.longitude,
    required this.latitude,
  });

  @override
  List<Object> get props => [loginMethod, userId, name, longitude, latitude];
}

class AddFavoritePoint extends UseCase<FavoritePoint, AddFavoritePointParams> {
  final FavoriteRepository repository;

  AddFavoritePoint(this.repository);

  @override
  Future<Either<Failure, FavoritePoint>> call(AddFavoritePointParams params) async {
    return await repository.addFavoritePoint(
      loginMethod: params.loginMethod,
      userId: params.userId,
      name: params.name,
      longitude: params.longitude,
      latitude: params.latitude,
    );
  }
}

class AddFavoriteRouteParams extends Equatable {
  final String loginMethod;
  final String userId;
  final String name;
  final RoutePoint? startPoint;
  final RoutePoint? finishPoint;
  final List<RoutePoint?> stopovers;

  const AddFavoriteRouteParams({
    required this.loginMethod,
    required this.userId,
    required this.name,
    required this.startPoint,
    required this.finishPoint,
    required this.stopovers,
  });

  @override
  List<Object?> get props => [loginMethod, userId, name, startPoint, finishPoint, stopovers];
}

class AddFavoriteRoute extends UseCase<bool, AddFavoriteRouteParams> {
  final FavoriteRepository repository;

  AddFavoriteRoute(this.repository);

  @override
  Future<Either<Failure, bool>> call(AddFavoriteRouteParams params) async {
    return await repository.addFavoriteRoute(
      loginMethod: params.loginMethod,
      userId: params.userId,
      name: params.name,
      startPoint: params.startPoint,
      finishPoint: params.finishPoint,
      stopovers: params.stopovers,
    );
  }
}