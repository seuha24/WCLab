part of '../../framework/data_source.dart';

/// C-ITS 음향신호기 RemoteDataSource
///
/// API 2-5 (CSV 다운로드만 담당, 버전 조회는 CitsVersionRemoteDataSource 사용)
abstract class CitsCrosswalkRemoteDataSource {
  /// 2-5: 음향신호기 CSV 다운로드
  Future<String> downloadCrosswalkCsv();
}

class CitsCrosswalkRemoteDataSourceImpl implements CitsCrosswalkRemoteDataSource {
  final Dio dio;

  CitsCrosswalkRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> downloadCrosswalkCsv() async {
    try {
      final response = await dio.get(
        ApiEndpoints.downloadCitsCrosswalk,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as String;
      } else {
        throw ServerException('음향신호기 CSV 다운로드 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException('음향신호기 CSV 다운로드 실패: ${e.message}');
    } catch (e) {
      throw ServerException('음향신호기 CSV 다운로드 실패: $e');
    }
  }
}
