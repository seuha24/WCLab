part of '../../framework/usecase.dart';

/// C-ITS 음향신호기 데이터 UseCase
///
/// 음향신호기 CSV 다운로드 및 조회 비즈니스 로직
abstract class CitsCrosswalkUseCase {}

/// 음향신호기 CSV 다운로드 및 저장 파라미터
class SyncCitsCrosswalksParams extends Equatable {
  final int version;

  const SyncCitsCrosswalksParams({required this.version});

  @override
  List<Object?> get props => [version];
}

/// 주변 음향신호기 조회 파라미터
class NearbyCitsCrosswalksParams extends Equatable {
  final double latitude;
  final double longitude;
  final double radiusInMeters;

  const NearbyCitsCrosswalksParams({
    required this.latitude,
    required this.longitude,
    this.radiusInMeters = 1000,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusInMeters];
}

/// 음향신호기 CSV 다운로드 및 저장 UseCase
///
/// 서버에서 음향신호기 CSV를 다운로드하여 로컬에 저장
/// 버전 정보도 함께 저장하여 다음 동기화 시 비교에 사용
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<SyncCitsCrosswalks>();
/// final result = await usecase(SyncCitsCrosswalksParams(version: 2512));
/// result.fold(
///   (failure) => print('동기화 실패: ${failure.message}'),
///   (_) => print('음향신호기 데이터 동기화 완료'),
/// );
/// ```
class SyncCitsCrosswalks extends CitsCrosswalkUseCase
    implements UseCase<void, SyncCitsCrosswalksParams> {
  final CitsCrosswalkRepository repository;

  SyncCitsCrosswalks({required this.repository});

  @override
  Future<Either<Failure, void>> call(SyncCitsCrosswalksParams params) async {
    return await repository.downloadAndSaveCrosswalks(params.version);
  }
}

/// 현재 위치 기준 반경 내 음향신호기 목록 조회 UseCase
///
/// GPS 위치 기반으로 반경 내(기본 1000m) 음향신호기를 조회한다.
/// 지도에 음향신호기 마커를 표시할 때 사용한다.
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<GetNearbyCitsCrosswalks>();
/// final result = await usecase(NearbyCitsCrosswalksParams(
///   latitude: 37.4865,
///   longitude: 126.8018,
///   radiusInMeters: 1000,
/// ));
/// result.fold(
///   (failure) => print('조회 실패: ${failure.message}'),
///   (crosswalks) => print('조회 성공: ${crosswalks.length}개'),
/// );
/// ```
class GetNearbyCitsCrosswalks extends CitsCrosswalkUseCase
    implements UseCase<List<CitsCrosswalk>, NearbyCitsCrosswalksParams> {
  final CitsCrosswalkRepository repository;

  GetNearbyCitsCrosswalks({required this.repository});

  @override
  Future<Either<Failure, List<CitsCrosswalk>>> call(
    NearbyCitsCrosswalksParams params,
  ) async {
    return await repository.getNearbyCrosswalks(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusInMeters: params.radiusInMeters,
    );
  }
}

/// 로컬에 저장된 음향신호기 데이터 버전 조회 UseCase
///
/// 서버 버전과 비교하여 동기화 필요 여부를 판단할 때 사용
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<GetLocalCitsCrosswalksVersion>();
/// final result = await usecase(NoParams());
/// result.fold(
///   (failure) => print('버전 조회 실패'),
///   (version) => print('로컬 버전: $version'),
/// );
/// ```
class GetLocalCitsCrosswalksVersion extends CitsCrosswalkUseCase
    implements UseCase<int, NoParams> {
  final CitsCrosswalkRepository repository;

  GetLocalCitsCrosswalksVersion({required this.repository});

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getLocalVersion();
  }
}

/// 전체 음향신호기 데이터 로드 UseCase
///
/// 앱 시작 시 CSV 데이터를 메모리에 캐싱할 때 사용한다.
class LoadAllCitsCrosswalks extends CitsCrosswalkUseCase
    implements UseCase<List<CitsCrosswalk>, NoParams> {
  final CitsCrosswalkRepository repository;

  LoadAllCitsCrosswalks({required this.repository});

  @override
  Future<Either<Failure, List<CitsCrosswalk>>> call(NoParams params) async {
    return await repository.loadAllCrosswalks();
  }
}
