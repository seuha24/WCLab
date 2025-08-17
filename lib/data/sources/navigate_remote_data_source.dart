part of '../../framework/data_source.dart';

/// 실제 네트워크 요청(서버 통신)을 담당하는 인터페이스.
/// RepositoryImpl에서 사용하는 메소드 형태만을 정의한다.
abstract class NavigateRemoteDataSource {
  Future<LatLng> getCurrentLatLng();

  /// 사용자 지정 출발지 정보를 서버에 전송.
  Future<void> sendCustomStartPoint({
    required String roadAddress,
    required String buildingName,
    required String buildingDetail,
    required Map<String, double> buildingPoint,
    required List<Map<String, dynamic>> entrances,
  });

  /// 특정 건물 입구 목록을 서버에서 가져오는 요청.
  Future<BuildingResponseModel> getBuildingEntrances({
    required String encodedAddr,
    required double longitude,
    required double latitude,
  });
}

/// 실제 서버와의 통신을 담당하는 DataSource 구현 클래스.
/// Dio 패키지를 통해 REST API 요청을 수행.
class NavigateRemoteDataSourceImpl implements NavigateRemoteDataSource {
  GeolocatorPlatform geolocator;
  /// 서버 통신에 사용되는 Dio HTTP 클라이언트
  final Dio dio;
  
  NavigateRemoteDataSourceImpl({required this.geolocator,required this.dio,});

  /// 사용자 지정 출발지를 서버에 POST 방식으로 전송 요청.
  @override
  Future<LatLng> getCurrentLatLng() async {
    try {
      final position = await geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ));
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw ServerException();
    }
  }

  // 11. 실제 HTTP 요청 수행
  @override
  Future<void> sendCustomStartPoint({
    required String roadAddress,
    required String buildingName,
    required String buildingDetail,
    required Map<String, double> buildingPoint,
    required List<Map<String, dynamic>> entrances,
  }) async {
    debugPrint("\n=== 출입구 데이터 서버 전송 시작 ===");
    debugPrint("요청 URL: ${ApiEndpoints.saveBuildingEntrance}");
    debugPrint("요청 메서드: POST");
    debugPrint("\n전송할 데이터:");
    debugPrint("1. 도로명 주소: $roadAddress");
    debugPrint("2. 건물명: $buildingName");
    debugPrint("3. 건물 상세: $buildingDetail");
    debugPrint("4. 건물 위치: $buildingPoint");
    debugPrint("5. 출입구 정보: $entrances");

    try {
      final requestData = {
        'roadAddress': roadAddress,
        'buildingName': buildingName,
        'buildingDetail': buildingDetail,
        'buildingPoint': buildingPoint,
        'entrances': entrances,
      };

      // HTTP 요청 데이터 로그 출력
      debugPrint('\n=== 서버로 전송될 HTTP 요청 데이터 (DataSource Layer) ===');
      debugPrint(jsonEncode(requestData));
      debugPrint('=====================================================\n');

      final response = await dio.post(
        ApiEndpoints.saveBuildingEntrance,
        data: requestData,
      );

      debugPrint("\n=== 서버 응답 ===");
      debugPrint("상태 코드: ${response.statusCode}");
      debugPrint("응답 데이터: ${response.data}");
      debugPrint("===============================\n");

      if (response.statusCode != 200) {
        throw ServerException();
      }
    } catch (e) {
      debugPrint('\n=== 서버 통신 에러 ===');
      debugPrint('에러 타입: ${e.runtimeType}');
      debugPrint('에러 메시지: $e');

      if (e is DioException) {
        debugPrint('DioException 상세 정보:');
        debugPrint('statusCode: ${e.response?.statusCode}');
        debugPrint('response data: ${e.response?.data}');
        debugPrint('message: ${e.message}');
        debugPrint('error: ${e.error}');
        debugPrint('type: ${e.type}');
        debugPrint('request options: ${e.requestOptions.uri}');
      }
      debugPrint('===============================\n');

      throw ServerException();
    }
  }

  /// 특정 건물 입구 목록을 서버로부터 GET 방식으로 조회 요청.
  @override
  Future<BuildingResponseModel> getBuildingEntrances({
    required String encodedAddr,
    required double longitude,
    required double latitude,
  }) async {
    try {
      /// URL 경로로 데이터를 직접 전달
      final url = ApiEndpoints.getBuildingEntrance(encodedAddr, longitude, latitude);
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        debugPrint('서버 응답 데이터: ${response.data}');
        return BuildingResponseModel.fromJson(response.data);
      } else {
        throw ServerException();
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('DioException 발생');
        debugPrint('statusCode: ${e.response?.statusCode}');
        debugPrint('response data: ${e.response?.data}');
        debugPrint('message: ${e.message}');
      } else {
        debugPrint('알 수 없는 에러 발생: $e');
      }
      throw ServerException();
    }
  }
}