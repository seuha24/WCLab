part of '../../framework/repository.dart';

/// CitsCrosswalkRepository 구현체
///
/// 음향신호기 CSV 다운로드 및 로컬 저장소 연동
class CitsCrosswalkRepositoryImpl implements CitsCrosswalkRepository {
  final CitsCrosswalkRemoteDataSource remoteDataSource;
  final CitsCrosswalkLocalDataSource localDataSource;

  CitsCrosswalkRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> downloadAndSaveCrosswalks(int version) async {
    try {
      // 1. 서버에서 CSV 다운로드
      final csvData = await remoteDataSource.downloadCrosswalkCsv();

      // 2. 로컬에 저장 (버전 포함)
      await localDataSource.saveCsv(csvData, version);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? '음향신호기 데이터 다운로드 실패'));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Left(NetworkFailure('다운로드 시간 초과'));
      } else if (e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure('서버 연결 실패'));
      }
      return Left(NetworkFailure('네트워크 오류: ${e.message}'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '로컬 저장 실패'));
    } catch (e) {
      return Left(CacheFailure('음향신호기 데이터 저장 실패: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CitsCrosswalk>>> getNearbyCrosswalks({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  }) async {
    try {
      final crosswalks = await localDataSource.getWithinRadius(
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );
      return Right(crosswalks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '캐시 오류'));
    } catch (e) {
      return Left(CacheFailure('음향신호기 조회 실패: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getLocalVersion() async {
    try {
      final version = await localDataSource.getLocalVersion();
      return Right(version ?? 0);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '버전 조회 실패'));
    } catch (e) {
      return Left(CacheFailure('로컬 버전 조회 실패: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CitsCrosswalk>>> loadAllCrosswalks() async {
    try {
      final crosswalks = await localDataSource.loadAll();
      return Right(crosswalks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '캐시 오류'));
    } catch (e) {
      return Left(CacheFailure('음향신호기 데이터 로드 실패: $e'));
    }
  }
}
