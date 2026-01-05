part of '../../framework/repository.dart';

/// 서울시 공공데이터 교차로 Repository 인터페이스
///
/// GPS 위치 기반으로 주변 교차로를 조회하는 기능을 제공한다.
/// CSV 데이터를 로컬에서 로드하여 반경 내 교차로를 필터링한다.
abstract class IntersectionRepository {
  /// 현재 위치 기준 반경 내 교차로 목록 조회
  ///
  /// [latitude], [longitude]: 현재 위치 좌표
  /// [radiusInMeters]: 검색 반경 (기본값: 1000m)
  ///
  /// Returns:
  /// - `Right(List<Intersection>)`: 반경 내 교차로 목록
  /// - `Left(CacheFailure())`: 로컬 데이터 로드 실패
  Future<Either<Failure, List<Intersection>>> getNearbyIntersections({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  });

  /// 모든 교차로 데이터 로드 (캐싱용)
  ///
  /// Returns:
  /// - `Right(List<Intersection>)`: 전체 교차로 목록
  /// - `Left(CacheFailure())`: 로컬 데이터 로드 실패
  Future<Either<Failure, List<Intersection>>> loadAllIntersections();
}
