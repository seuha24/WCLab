part of '../../framework/repository.dart';

/// IntersectionRepository 구현체
///
/// CSV 데이터를 로컬에서 로드하여 반경 내 교차로를 필터링한다.
class IntersectionRepositoryImpl implements IntersectionRepository {
  final IntersectionLocalDataSource localDataSource;

  IntersectionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Intersection>>> getNearbyIntersections({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  }) async {
    try {
      final intersections = await localDataSource.getIntersectionsWithinRadius(
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );
      return Right(intersections);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '캐시 오류'));
    } catch (e) {
      return Left(CacheFailure('교차로 조회 실패: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Intersection>>> loadAllIntersections() async {
    try {
      final intersections = await localDataSource.loadAllIntersections();
      return Right(intersections);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '캐시 오류'));
    } catch (e) {
      return Left(CacheFailure('교차로 데이터 로드 실패: $e'));
    }
  }
}
