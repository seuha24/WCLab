import 'package:dartz/dartz.dart';
import 'package:safelight/data/sources/favorite_remote_data_source.dart';
import 'package:safelight/domain/entities/favorite_point.dart';
import 'package:safelight/domain/entities/favorite_route.dart';
import 'package:safelight/domain/repositories/favorite_repository.dart';
import 'package:safelight/framework/core.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteRemoteDataSource remoteDataSource;

  FavoriteRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<FavoritePoint>>> getFavoritePoints({
    required String loginMethod,
    required String userId,
  }) async {
    try {
      final favoritePoints = await remoteDataSource.getFavoritePoints(
        loginMethod: loginMethod,
        userId: userId,
      );
      return Right(favoritePoints.map((model) => model.toEntity()).toList());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<FavoriteRoute>>> getFavoriteRoutes({
    required String loginMethod,
    required String userId,
  }) async {
    try {
      final favoriteRoutes = await remoteDataSource.getFavoriteRoutes(
        loginMethod: loginMethod,
        userId: userId,
      );
      return Right(favoriteRoutes.map((model) => model.toEntity()).toList());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, FavoritePoint>> addFavoritePoint({
    required String loginMethod,
    required String userId,
    required String name,
    required double longitude,
    required double latitude,
  }) async {
    try {
      final favoritePoint = await remoteDataSource.addFavoritePoint(
        loginMethod: loginMethod,
        userId: userId,
        name: name,
        longitude: longitude,
        latitude: latitude,
      );
      return Right(favoritePoint.toEntity());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> addFavoriteRoute({
    required String loginMethod,
    required String userId,
    required String name,
    required RoutePoint? startPoint,
    required RoutePoint? finishPoint,
    required List<RoutePoint?> stopovers,
  }) async {
    try {
      final result = await remoteDataSource.addFavoriteRoute(
        loginMethod: loginMethod,
        userId: userId,
        name: name,
        startPoint: startPoint,
        finishPoint: finishPoint,
        stopovers: stopovers,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteFavoritePoint({
    required String loginMethod,
    required String userId,
    required String favIdx,
  }) async {
    try {
      final result = await remoteDataSource.deleteFavoritePoint(
        loginMethod: loginMethod,
        userId: userId,
        favIdx: favIdx,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteFavoriteRoute({
    required String loginMethod,
    required String userId,
    required String favIdx,
  }) async {
    try {
      final result = await remoteDataSource.deleteFavoriteRoute(
        loginMethod: loginMethod,
        userId: userId,
        favIdx: favIdx,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> updateFavoritePoint({
    required String loginMethod,
    required String userId,
    required String favIdx,
    required String name,
    required double longitude,
    required double latitude,
  }) async {
    try {
      final result = await remoteDataSource.updateFavoritePoint(
        loginMethod: loginMethod,
        userId: userId,
        favIdx: favIdx,
        name: name,
        longitude: longitude,
        latitude: latitude,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> updateFavoriteRoute({
    required String loginMethod,
    required String userId,
    required String favIdx,
    required String name,
    required RoutePoint? startPoint,
    required RoutePoint? finishPoint,
    required List<RoutePoint?> stopovers,
  }) async {
    try {
      final result = await remoteDataSource.updateFavoriteRoute(
        loginMethod: loginMethod,
        userId: userId,
        favIdx: favIdx,
        name: name,
        startPoint: startPoint,
        finishPoint: finishPoint,
        stopovers: stopovers,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}