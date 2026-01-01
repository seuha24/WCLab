part of '../../framework/usecase.dart';

/// 서울시 공공데이터 음향신호기 UseCase
///
/// GPS 위치 기반으로 주변 음향신호기(횡단보도)를 조회하는 비즈니스 로직
abstract class SignalDeviceUseCase {}

/// 주변 음향신호기 조회 파라미터
class NearbySignalDevicesParams extends Equatable {
  final double latitude;
  final double longitude;
  final double radiusInMeters;

  const NearbySignalDevicesParams({
    required this.latitude,
    required this.longitude,
    this.radiusInMeters = 1000,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusInMeters];
}

/// 현재 위치 기준 반경 내 음향신호기 목록 조회 UseCase
///
/// GPS 위치 기반으로 반경 내(기본 500m) 음향신호기를 조회한다.
/// 지도에 횡단보도 마커를 표시할 때 사용한다.
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<GetNearbySignalDevices>();
/// final result = await usecase(NearbySignalDevicesParams(
///   latitude: 37.4865,
///   longitude: 126.8018,
///   radiusInMeters: 500,
/// ));
/// result.fold(
///   (failure) => print('조회 실패: ${failure.message}'),
///   (devices) => print('조회 성공: ${devices.length}개'),
/// );
/// ```
class GetNearbySignalDevices extends SignalDeviceUseCase
    implements UseCase<List<SignalDevice>, NearbySignalDevicesParams> {
  final SignalDeviceRepository repository;

  GetNearbySignalDevices({required this.repository});

  @override
  Future<Either<Failure, List<SignalDevice>>> call(
    NearbySignalDevicesParams params,
  ) async {
    return await repository.getNearbySignalDevices(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusInMeters: params.radiusInMeters,
    );
  }
}

/// 전체 음향신호기 데이터 로드 UseCase
///
/// 앱 시작 시 CSV 데이터를 메모리에 캐싱할 때 사용한다.
class LoadAllSignalDevices extends SignalDeviceUseCase
    implements UseCase<List<SignalDevice>, NoParams> {
  final SignalDeviceRepository repository;

  LoadAllSignalDevices({required this.repository});

  @override
  Future<Either<Failure, List<SignalDevice>>> call(NoParams params) async {
    return await repository.loadAllSignalDevices();
  }
}
