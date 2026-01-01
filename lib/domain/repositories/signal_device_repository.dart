part of '../../framework/repository.dart';

/// 서울시 공공데이터 음향신호기 Repository 인터페이스
///
/// GPS 위치 기반으로 주변 음향신호기(횡단보도)를 조회하는 기능을 제공한다.
/// CSV 데이터를 로컬에서 로드하여 반경 내 음향신호기를 필터링한다.
abstract class SignalDeviceRepository {
  /// 현재 위치 기준 반경 내 음향신호기 목록 조회
  ///
  /// [latitude], [longitude]: 현재 위치 좌표
  /// [radiusInMeters]: 검색 반경 (기본값: 1000m)
  ///
  /// Returns:
  /// - `Right(List<SignalDevice>)`: 반경 내 음향신호기 목록
  /// - `Left(CacheFailure())`: 로컬 데이터 로드 실패
  Future<Either<Failure, List<SignalDevice>>> getNearbySignalDevices({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  });

  /// 모든 음향신호기 데이터 로드 (캐싱용)
  ///
  /// Returns:
  /// - `Right(List<SignalDevice>)`: 전체 음향신호기 목록
  /// - `Left(CacheFailure())`: 로컬 데이터 로드 실패
  Future<Either<Failure, List<SignalDevice>>> loadAllSignalDevices();
}
