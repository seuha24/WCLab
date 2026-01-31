part of '../../framework/data_source.dart';

/// C-ITS 버전 관리 RemoteDataSource
///
/// API 2-3 `/api/location/sync` 전용
/// 교차로와 음향신호기 버전을 한번에 조회
abstract class CitsVersionRemoteDataSource {
  /// 2-3: C-ITS 데이터 버전 동기화
  ///
  /// Returns: 교차로 및 음향신호기 버전 정보
  Future<CitsVersionModel> getVersions();
}

class CitsVersionRemoteDataSourceImpl implements CitsVersionRemoteDataSource {
  final Dio dio;

  CitsVersionRemoteDataSourceImpl({required this.dio});

  @override
  Future<CitsVersionModel> getVersions() async {
    try {
      final response = await dio.get(
        ApiEndpoints.syncCitsVersion,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return CitsVersionModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('C-ITS 버전 조회 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException('C-ITS 버전 조회 실패: ${e.message}');
    } catch (e) {
      throw ServerException('C-ITS 버전 조회 실패: $e');
    }
  }
}
