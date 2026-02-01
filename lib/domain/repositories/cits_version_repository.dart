part of '../../framework/repository.dart';

/// C-ITS 버전 관리 Repository 인터페이스
///
/// API 2-3 `/api/location/sync` 전용
/// 교차로와 음향신호기 버전을 한번에 조회하여 동기화 판단에 사용
abstract class CitsVersionRepository {
  /// 서버에서 현재 C-ITS 데이터 버전 조회
  ///
  /// Returns:
  /// - `Right(CitsVersion)`: 교차로 및 음향신호기 버전 정보
  /// - `Left(ServerFailure)`: 서버 연결 실패
  /// - `Left(NetworkFailure)`: 네트워크 연결 실패
  Future<Either<Failure, CitsVersion>> getServerVersions();
}
