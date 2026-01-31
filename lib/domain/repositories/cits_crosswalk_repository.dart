part of '../../framework/repository.dart';

/// C-ITS 음향신호기 데이터 Repository 인터페이스
///
/// API 2-5 `/api/location/crosswalk/download` 전용
/// 음향신호기 CSV 파일 다운로드 및 로컬 저장 관리
abstract class CitsCrosswalkRepository {
  /// 서버에서 음향신호기 CSV 다운로드 및 로컬 저장
  ///
  /// [version]: 저장할 버전 번호 (SharedPreferences에 기록)
  ///
  /// Returns:
  /// - `Right(void)`: 다운로드 및 저장 성공
  /// - `Left(ServerFailure)`: 서버 연결 실패
  /// - `Left(CacheFailure)`: 로컬 저장 실패
  Future<Either<Failure, void>> downloadAndSaveCrosswalks(int version);

  /// 현재 위치 기준 반경 내 음향신호기 목록 조회
  ///
  /// [latitude], [longitude]: 현재 위치 좌표
  /// [radiusInMeters]: 검색 반경 (기본값: 1000m)
  ///
  /// Returns:
  /// - `Right(List<CitsCrosswalk>)`: 반경 내 음향신호기 목록
  /// - `Left(CacheFailure)`: 로컬 데이터 로드 실패
  Future<Either<Failure, List<CitsCrosswalk>>> getNearbyCrosswalks({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  });

  /// 로컬에 저장된 음향신호기 데이터 버전 조회
  ///
  /// Returns:
  /// - `Right(int)`: 로컬 버전 번호 (없으면 0)
  /// - `Left(CacheFailure)`: 버전 조회 실패
  Future<Either<Failure, int>> getLocalVersion();

  /// 모든 음향신호기 데이터 로드 (캐싱용)
  ///
  /// Returns:
  /// - `Right(List<CitsCrosswalk>)`: 전체 음향신호기 목록
  /// - `Left(CacheFailure)`: 로컬 데이터 로드 실패
  Future<Either<Failure, List<CitsCrosswalk>>> loadAllCrosswalks();
}
