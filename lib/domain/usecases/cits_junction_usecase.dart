part of '../../framework/usecase.dart';

/// C-ITS 교차로 데이터 UseCase
///
/// 교차로 CSV 다운로드 및 조회 비즈니스 로직
abstract class CitsJunctionUseCase {}

/// 교차로 CSV 다운로드 및 저장 파라미터
class SyncCitsJunctionsParams extends Equatable {
  final int version;

  const SyncCitsJunctionsParams({required this.version});

  @override
  List<Object?> get props => [version];
}

/// 주변 교차로 조회 파라미터
class NearbyCitsJunctionsParams extends Equatable {
  final double latitude;
  final double longitude;
  final double radiusInMeters;

  const NearbyCitsJunctionsParams({
    required this.latitude,
    required this.longitude,
    this.radiusInMeters = 1000,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusInMeters];
}

/// 교차로 CSV 다운로드 및 저장 UseCase
///
/// 서버에서 교차로 CSV를 다운로드하여 로컬에 저장
/// 버전 정보도 함께 저장하여 다음 동기화 시 비교에 사용
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<SyncCitsJunctions>();
/// final result = await usecase(SyncCitsJunctionsParams(version: 2512));
/// result.fold(
///   (failure) => print('동기화 실패: ${failure.message}'),
///   (_) => print('교차로 데이터 동기화 완료'),
/// );
/// ```
class SyncCitsJunctions extends CitsJunctionUseCase
    implements UseCase<void, SyncCitsJunctionsParams> {
  final CitsJunctionRepository repository;

  SyncCitsJunctions({required this.repository});

  @override
  Future<Either<Failure, void>> call(SyncCitsJunctionsParams params) async {
    return await repository.downloadAndSaveJunctions(params.version);
  }
}

/// 현재 위치 기준 반경 내 교차로 목록 조회 UseCase
///
/// GPS 위치 기반으로 반경 내(기본 1000m) 교차로를 조회한다.
/// 지도에 교차로 마커를 표시할 때 사용한다.
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<GetNearbyCitsJunctions>();
/// final result = await usecase(NearbyCitsJunctionsParams(
///   latitude: 37.4865,
///   longitude: 126.8018,
///   radiusInMeters: 1000,
/// ));
/// result.fold(
///   (failure) => print('조회 실패: ${failure.message}'),
///   (junctions) => print('조회 성공: ${junctions.length}개'),
/// );
/// ```
class GetNearbyCitsJunctions extends CitsJunctionUseCase
    implements UseCase<List<CitsJunction>, NearbyCitsJunctionsParams> {
  final CitsJunctionRepository repository;

  GetNearbyCitsJunctions({required this.repository});

  @override
  Future<Either<Failure, List<CitsJunction>>> call(
    NearbyCitsJunctionsParams params,
  ) async {
    return await repository.getNearbyJunctions(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusInMeters: params.radiusInMeters,
    );
  }
}

/// 로컬에 저장된 교차로 데이터 버전 조회 UseCase
///
/// 서버 버전과 비교하여 동기화 필요 여부를 판단할 때 사용
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<GetLocalCitsJunctionsVersion>();
/// final result = await usecase(NoParams());
/// result.fold(
///   (failure) => print('버전 조회 실패'),
///   (version) => print('로컬 버전: $version'),
/// );
/// ```
class GetLocalCitsJunctionsVersion extends CitsJunctionUseCase
    implements UseCase<int, NoParams> {
  final CitsJunctionRepository repository;

  GetLocalCitsJunctionsVersion({required this.repository});

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getLocalVersion();
  }
}

/// 전체 교차로 데이터 로드 UseCase
///
/// 앱 시작 시 CSV 데이터를 메모리에 캐싱할 때 사용한다.
class LoadAllCitsJunctions extends CitsJunctionUseCase
    implements UseCase<List<CitsJunction>, NoParams> {
  final CitsJunctionRepository repository;

  LoadAllCitsJunctions({required this.repository});

  @override
  Future<Either<Failure, List<CitsJunction>>> call(NoParams params) async {
    return await repository.loadAllJunctions();
  }
}
