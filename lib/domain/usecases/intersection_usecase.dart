part of '../../framework/usecase.dart';

/// 서울시 공공데이터 교차로 UseCase
///
/// GPS 위치 기반으로 주변 교차로를 조회하는 비즈니스 로직
abstract class IntersectionUseCase {}

/// 주변 교차로 조회 파라미터
class NearbyIntersectionsParams extends Equatable {
  final double latitude;
  final double longitude;
  final double radiusInMeters;

  const NearbyIntersectionsParams({
    required this.latitude,
    required this.longitude,
    this.radiusInMeters = 1000,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusInMeters];
}

/// 현재 위치 기준 반경 내 교차로 목록 조회 UseCase
///
/// GPS 위치 기반으로 반경 내(기본 1000m) 교차로를 조회한다.
/// 지도에 교차로 마커를 표시할 때 사용한다.
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<GetNearbyIntersections>();
/// final result = await usecase(NearbyIntersectionsParams(
///   latitude: 37.4865,
///   longitude: 126.8018,
///   radiusInMeters: 1000,
/// ));
/// result.fold(
///   (failure) => print('조회 실패: ${failure.message}'),
///   (intersections) => print('조회 성공: ${intersections.length}개'),
/// );
/// ```
class GetNearbyIntersections extends IntersectionUseCase
    implements UseCase<List<Intersection>, NearbyIntersectionsParams> {
  final IntersectionRepository repository;

  GetNearbyIntersections({required this.repository});

  @override
  Future<Either<Failure, List<Intersection>>> call(
    NearbyIntersectionsParams params,
  ) async {
    return await repository.getNearbyIntersections(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusInMeters: params.radiusInMeters,
    );
  }
}

/// 전체 교차로 데이터 로드 UseCase
///
/// 앱 시작 시 CSV 데이터를 메모리에 캐싱할 때 사용한다.
class LoadAllIntersections extends IntersectionUseCase
    implements UseCase<List<Intersection>, NoParams> {
  final IntersectionRepository repository;

  LoadAllIntersections({required this.repository});

  @override
  Future<Either<Failure, List<Intersection>>> call(NoParams params) async {
    return await repository.loadAllIntersections();
  }
}
