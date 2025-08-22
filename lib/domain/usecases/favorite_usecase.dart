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

// 즐겨찾기 지점 삭제 UseCase
class DeleteFavoritePointParams extends Equatable {
  final String loginMethod;
  final String userId;
  final String favIdx;

  const DeleteFavoritePointParams({
    required this.loginMethod,
    required this.userId,
    required this.favIdx,
  });

  @override
  List<Object> get props => [loginMethod, userId, favIdx];
}

class DeleteFavoritePoint extends UseCase<bool, DeleteFavoritePointParams> {
  final FavoriteRepository repository;

  DeleteFavoritePoint(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteFavoritePointParams params) async {
    return await repository.deleteFavoritePoint(
      loginMethod: params.loginMethod,
      userId: params.userId,
      favIdx: params.favIdx,
    );
  }
}

// 즐겨찾기 경로 삭제 UseCase
class DeleteFavoriteRouteParams extends Equatable {
  final String loginMethod;
  final String userId;
  final String favIdx;

  const DeleteFavoriteRouteParams({
    required this.loginMethod,
    required this.userId,
    required this.favIdx,
  });

  @override
  List<Object> get props => [loginMethod, userId, favIdx];
}

class DeleteFavoriteRoute extends UseCase<bool, DeleteFavoriteRouteParams> {
  final FavoriteRepository repository;

  DeleteFavoriteRoute(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteFavoriteRouteParams params) async {
    return await repository.deleteFavoriteRoute(
      loginMethod: params.loginMethod,
      userId: params.userId,
      favIdx: params.favIdx,
    );
  }
}

// 즐겨찾기 지점 수정 UseCase
class UpdateFavoritePointParams extends Equatable {
  final String loginMethod;
  final String userId;
  final String favIdx;
  final String name;
  final double longitude;
  final double latitude;

  const UpdateFavoritePointParams({
    required this.loginMethod,
    required this.userId,
    required this.favIdx,
    required this.name,
    required this.longitude,
    required this.latitude,
  });

  @override
  List<Object> get props => [loginMethod, userId, favIdx, name, longitude, latitude];
}

class UpdateFavoritePoint extends UseCase<bool, UpdateFavoritePointParams> {
  final FavoriteRepository repository;

  UpdateFavoritePoint(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateFavoritePointParams params) async {
    return await repository.updateFavoritePoint(
      loginMethod: params.loginMethod,
      userId: params.userId,
      favIdx: params.favIdx,
      name: params.name,
      longitude: params.longitude,
      latitude: params.latitude,
    );
  }
}

// 즐겨찾기 경로 수정 UseCase
class UpdateFavoriteRouteParams extends Equatable {
  final String loginMethod;
  final String userId;
  final String favIdx;
  final String name;
  final RoutePoint? startPoint;
  final RoutePoint? finishPoint;
  final List<RoutePoint?> stopovers;

  const UpdateFavoriteRouteParams({
    required this.loginMethod,
    required this.userId,
    required this.favIdx,
    required this.name,
    required this.startPoint,
    required this.finishPoint,
    required this.stopovers,
  });

  @override
  List<Object?> get props => [loginMethod, userId, favIdx, name, startPoint, finishPoint, stopovers];
}

class UpdateFavoriteRoute extends UseCase<bool, UpdateFavoriteRouteParams> {
  final FavoriteRepository repository;

  UpdateFavoriteRoute(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateFavoriteRouteParams params) async {
    return await repository.updateFavoriteRoute(
      loginMethod: params.loginMethod,
      userId: params.userId,
      favIdx: params.favIdx,
      name: params.name,
      startPoint: params.startPoint,
      finishPoint: params.finishPoint,
      stopovers: params.stopovers,
    );
  }
}