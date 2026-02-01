part of '../../framework/repository.dart';

/// C-ITS 교차로 데이터 Repository 인터페이스
///
/// API 2-2 `/api/location/junctions/download` 전용
/// 교차로 CSV 파일 다운로드 및 로컬 저장 관리
abstract class CitsJunctionRepository {
  /// 서버에서 교차로 CSV 다운로드 및 로컬 저장
  ///
  /// [version]: 저장할 버전 번호 (SharedPreferences에 기록)
  ///
  /// Returns:
  /// - `Right(void)`: 다운로드 및 저장 성공
  /// - `Left(ServerFailure)`: 서버 연결 실패
  /// - `Left(CacheFailure)`: 로컬 저장 실패
  Future<Either<Failure, void>> downloadAndSaveJunctions(int version);

  /// 현재 위치 기준 반경 내 교차로 목록 조회
  ///
  /// [latitude], [longitude]: 현재 위치 좌표
  /// [radiusInMeters]: 검색 반경 (기본값: 1000m)
  ///
  /// Returns:
  /// - `Right(List<CitsJunction>)`: 반경 내 교차로 목록
  /// - `Left(CacheFailure)`: 로컬 데이터 로드 실패
  Future<Either<Failure, List<CitsJunction>>> getNearbyJunctions({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  });

  /// 로컬에 저장된 교차로 데이터 버전 조회
  ///
  /// Returns:
  /// - `Right(int)`: 로컬 버전 번호 (없으면 0)
  /// - `Left(CacheFailure)`: 버전 조회 실패
  Future<Either<Failure, int>> getLocalVersion();

  /// 모든 교차로 데이터 로드 (캐싱용)
  ///
  /// Returns:
  /// - `Right(List<CitsJunction>)`: 전체 교차로 목록
  /// - `Left(CacheFailure)`: 로컬 데이터 로드 실패
  Future<Either<Failure, List<CitsJunction>>> loadAllJunctions();
}
