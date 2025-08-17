import 'package:dartz/dartz.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/domain/entities/favorite_point.dart';
import 'package:safelight/domain/entities/favorite_route.dart';

abstract class FavoriteRepository {
  Future<Either<Failure, List<FavoritePoint>>> getFavoritePoints({
    required String loginMethod,
    required String userId,
  });

  Future<Either<Failure, List<FavoriteRoute>>> getFavoriteRoutes({
    required String loginMethod,
    required String userId,
  });

  Future<Either<Failure, FavoritePoint>> addFavoritePoint({
    required String loginMethod,
    required String userId,
    required String name,
    required double longitude,
    required double latitude,
  });

  Future<Either<Failure, bool>> addFavoriteRoute({
    required String loginMethod,
    required String userId,
    required String name,
    required List<RoutePoint?> points,
  });
}