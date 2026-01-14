part of '../../framework/repository.dart';

/// SignalDeviceRepository 구현체
///
/// CSV 데이터를 로컬에서 로드하여 반경 내 음향신호기를 필터링한다.
class SignalDeviceRepositoryImpl implements SignalDeviceRepository {
  final SignalDeviceLocalDataSource localDataSource;

  SignalDeviceRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<SignalDevice>>> getNearbySignalDevices({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  }) async {
    try {
      final devices = await localDataSource.getDevicesWithinRadius(
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );
      return Right(devices);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '캐시 오류'));
    } catch (e) {
      return Left(CacheFailure('음향신호기 조회 실패: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SignalDevice>>> loadAllSignalDevices() async {
    try {
      final devices = await localDataSource.loadAllDevices();
      return Right(devices);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '캐시 오류'));
    } catch (e) {
      return Left(CacheFailure('음향신호기 데이터 로드 실패: $e'));
    }
  }
}
