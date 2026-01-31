part of '../../framework/repository.dart';

/// CitsJunctionRepository 구현체
///
/// 교차로 CSV 다운로드 및 로컬 저장소 연동
class CitsJunctionRepositoryImpl implements CitsJunctionRepository {
  final CitsJunctionRemoteDataSource remoteDataSource;
  final CitsJunctionLocalDataSource localDataSource;

  CitsJunctionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> downloadAndSaveJunctions(int version) async {
    try {
      // 1. 서버에서 CSV 다운로드
      final csvData = await remoteDataSource.downloadJunctionsCsv();

      // 2. 로컬에 저장 (버전 포함)
      await localDataSource.saveCsv(csvData, version);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? '교차로 데이터 다운로드 실패'));
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
      return Left(CacheFailure('교차로 데이터 저장 실패: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CitsJunction>>> getNearbyJunctions({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  }) async {
    try {
      final junctions = await localDataSource.getWithinRadius(
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );
      return Right(junctions);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '캐시 오류'));
    } catch (e) {
      return Left(CacheFailure('교차로 조회 실패: $e'));
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
  Future<Either<Failure, List<CitsJunction>>> loadAllJunctions() async {
    try {
      final junctions = await localDataSource.loadAll();
      return Right(junctions);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message ?? '캐시 오류'));
    } catch (e) {
      return Left(CacheFailure('교차로 데이터 로드 실패: $e'));
    }
  }
}
