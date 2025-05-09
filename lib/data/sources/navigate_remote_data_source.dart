part of data_source;

/// 실제 네트워크 요청(서버 통신)을 담당하는 인터페이스.
/// RepositoryImpl에서 사용하는 메소드 형태만을 정의한다.
abstract class NavigateRemoteDataSource {
  Future<LatLng> getCurrentLatLng();

  /// 사용자 지정 출발지 정보를 서버에 전송.
  Future<void> sendCustomStartPoint({
    required String buildingName,
    required String entranceName,
    required double latitude,
    required double longitude,
  });

  /// 특정 건물 입구 목록을 서버에서 가져오는 요청.
  Future<BuildingResponse> getBuildingEntrances({
  required String buildingName,
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

  @override
  Future<void> sendCustomStartPoint({
    required String buildingName,
    required String entranceName,
    required double latitude,
    required double longitude,
  }) async {
    print("DatasourceImpl: sendCustomStartPoint 함수 진입");
    try {
      final response = await dio.post(
      ApiEndpoints.saveBuildingEntrance,//api_endpoints.dart에서 가져와서 url로 사용
        data: {
          'buildingName': buildingName,
          'entranceName': entranceName,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      print("response: $response");
      if (response.statusCode != 200) {
        throw ServerException();
      }
    } catch (e) {
      print('DatasourceImpl: 서버 통신 에러 $e');

      if (e is DioException) {
        print('DioException 발생');
        print('statusCode: ${e.response?.statusCode}');
        print('response data: ${e.response?.data}');
        print('message: ${e.message}');
      }

      throw ServerException();
}

}

  /// 특정 건물 입구 목록을 서버로부터 GET 방식으로 조회 요청.
  @override
  Future<BuildingResponse> getBuildingEntrances({
    required String buildingName,
  }) async {
    try {
      final String urlBuildingName = buildingName;


      final response = await dio.get(
        //api_endpoints.dart의 getBuildingEntrance메서드를 호출하여 urlBuildingName을 넣어 url로 사용
        ApiEndpoints.getBuildingEntrance(urlBuildingName),
      );

      if (response.statusCode == 200) {
        print('서버 응답 데이터: ${response.data}');
        final buildingResponseModel = BuildingResponseModel.fromList(response.data);
        

        return buildingResponseModel.toEntity();
      } else {
        throw ServerException();
      }
    } catch (e) {
      if (e is DioException) {
        print('DioException 발생');
        print('statusCode: ${e.response?.statusCode}');
        print('response data: ${e.response?.data}');
        print('message: ${e.message}');
      } else {
        print('알 수 없는 에러 발생: $e');
      }
      throw ServerException();
    }
  }
}