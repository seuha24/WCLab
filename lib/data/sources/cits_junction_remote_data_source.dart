part of '../../framework/data_source.dart';

/// C-ITS 교차로 RemoteDataSource
///
/// API 2-2 (CSV 다운로드만 담당, 버전 조회는 CitsVersionRemoteDataSource 사용)
abstract class CitsJunctionRemoteDataSource {
  /// 2-2: 교차로 CSV 다운로드
  Future<String> downloadJunctionsCsv();
}

class CitsJunctionRemoteDataSourceImpl implements CitsJunctionRemoteDataSource {
  final Dio dio;

  CitsJunctionRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> downloadJunctionsCsv() async {
    try {
      final response = await dio.get(
        ApiEndpoints.downloadCitsJunctions,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as String;
      } else {
        throw ServerException('교차로 CSV 다운로드 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException('교차로 CSV 다운로드 실패: ${e.message}');
    } catch (e) {
      throw ServerException('교차로 CSV 다운로드 실패: $e');
    }
  }
}
