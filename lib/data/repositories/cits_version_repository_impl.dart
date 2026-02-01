part of '../../framework/repository.dart';

/// CitsVersionRepository 구현체
///
/// API 2-3 버전 동기화 API 호출
class CitsVersionRepositoryImpl implements CitsVersionRepository {
  final CitsVersionRemoteDataSource remoteDataSource;

  CitsVersionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CitsVersion>> getServerVersions() async {
    try {
      final versions = await remoteDataSource.getVersions();
      return Right(versions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'C-ITS 버전 조회 실패'));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Left(NetworkFailure('네트워크 응답 시간 초과'));
      } else if (e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure('서버 연결 실패'));
      }
      return Left(NetworkFailure('네트워크 오류: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('C-ITS 버전 조회 실패: $e'));
    }
  }
}
