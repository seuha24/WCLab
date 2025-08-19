import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:safelight/domain/entities/branch_info.dart';

/// **NavigationApiService**
///
/// 내비게이션 경로 데이터를 가져오고 처리하는 API 서비스 클래스입니다.
/// TMAP API를 통해 경로 및 브랜치 데이터를 요청하고, 응답 데이터를 파싱하여 필요한 형식으로 반환합니다.
///
/// ### 주요 역할:
/// - API 요청 및 응답 처리
/// - 경로 데이터 파싱 및 구조화
/// - 경유지를 포함한 다중 구간 경로 처리
///
/// ### 사용법:
/// 1. `fetchPathData`: 시작 및 종료 위치를 기준으로 경로 데이터를 가져옵니다.
/// 2. `parsePathData`: 가져온 API 응답 데이터를 경로와 브랜치 정보로 파싱합니다.
/// 3. `fetchMultiWaypointPath`: 경유지를 포함한 전체 경로를 가져옵니다.
///
/// ### 의존성:
/// - `http` 패키지: HTTP 요청 처리
/// - `latlong2`: 좌표 데이터 관리
/// - `BranchInfo`: 브랜치 지점 데이터를 나타내는 도메인 엔티티

class NavigationApiService {
  /// TMAP API URL
  static const String _apiUrl =
      'https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&callback=function';

  /// TMAP API 요청 헤더
  static const Map<String, String> _headers = {
    'accept': 'application/json',
    'appKey': 'QKrZQE7KkR6MtxXBFx49A6gmY1a8TN3y8IyQ0qjh', // 인증 키
    'content-type': 'application/json',
  };

  /// **fetchPathData**
  ///
  /// 경로 데이터를 API를 통해 가져오는 메서드입니다.
  ///
  /// - **매개변수**:
  ///   - `startLatitude` (double): 출발지의 위도.
  ///   - `startLongitude` (double): 출발지의 경도.
  ///   - `endLatitude` (double): 목적지의 위도.
  ///   - `endLongitude` (double): 목적지의 경도.
  ///
  /// - **반환값**:
  ///   - `Future<Map<String, dynamic>>`: API의 JSON 응답 데이터를 반환합니다.
  ///
  /// - **예외**:
  ///   - API 호출 실패 시 `Exception`이 발생합니다.
  ///
  /// - **사용 예시**:
  /// ```dart
  /// final apiService = NavigationApiService();
  /// final data = await apiService.fetchPathData(
  ///   startLatitude: 37.5665,
  ///   startLongitude: 126.9780,
  ///   endLatitude: 37.5651,
  ///   endLongitude: 126.9895,
  /// );
  /// print(data);
  /// ```
  Future<Map<String, dynamic>> fetchPathData({
    required double startLatitude,
    required double startLongitude,
    //required double current_Latitude,
    //required double current_longitude,
    required double endLatitude,
    required double endLongitude,
    required String chooseRoute,
  }) async {
    final Map<String, dynamic> requestData = {
      //"startX": current_longitude,
      //"startY": current_Latitude,
      "startX": startLongitude,
      "startY": startLatitude,
      "angle": 20,
      "speed": 30,
      "endPoiId": "10001",
      "endX": endLongitude,
      "endY": endLatitude,
      "reqCoordType": "WGS84GEO",
      "startName": "%EC%B6%9C%EB%B0%9C",
      "endName": "%EB%8F%84%EC%B0%A9",
      "searchOption": chooseRoute,
      "resCoordType": "WGS84GEO",
      "sort": "index"
    };

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: _headers,
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  /// **fetchPathDataWithWaypoints**
  ///
  /// 경유지를 포함한 경로 데이터를 API를 통해 가져오는 메서드입니다.
  ///
  /// - **매개변수**:
  ///   - `startLatitude` (double): 출발지의 위도.
  ///   - `startLongitude` (double): 출발지의 경도.
  ///   - `endLatitude` (double): 목적지의 위도.
  ///   - `endLongitude` (double): 목적지의 경도.
  ///   - `waypoints` (List<LatLng>): 경유지 좌표 리스트 (최대 5개).
  ///   - `chooseRoute` (String): 경로 탐색 옵션.
  ///
  /// - **반환값**:
  ///   - `Future<Map<String, dynamic>>`: API의 JSON 응답 데이터를 반환합니다.
  ///
  /// - **예외**:
  ///   - API 호출 실패 시 `Exception`이 발생합니다.
  ///   - 경유지가 5개를 초과하면 `Exception`이 발생합니다.
  Future<Map<String, dynamic>> fetchPathDataWithWaypoints({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    required List<LatLng> waypoints,
    required String chooseRoute,
  }) async {
    // 경유지 최대 5개 제한
    if (waypoints.length > 5) {
      throw Exception('경유지는 최대 5개까지 설정할 수 있습니다.');
    }

    // 경유지를 passList 형식으로 변환 (longitude,latitude_longitude,latitude)
    String passList = '';
    if (waypoints.isNotEmpty) {
      passList = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join('_');
    }

    final Map<String, dynamic> requestData = {
      "startX": startLongitude,
      "startY": startLatitude,
      "endX": endLongitude,
      "endY": endLatitude,
      "reqCoordType": "WGS84GEO",
      "startName": "%EC%B6%9C%EB%B0%9C",
      "endName": "%EB%8F%84%EC%B0%A9",
      "searchOption": chooseRoute,
      "resCoordType": "WGS84GEO",
      "sort": "index"
    };

    // 경유지가 있으면 passList 추가
    if (passList.isNotEmpty) {
      requestData["passList"] = passList;
    }

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: _headers,
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  /// **parsePathData**
  ///
  /// API 응답 데이터를 파싱하여 경로와 브랜치 정보를 반환하는 메서드입니다.
  ///
  /// - **매개변수**:
  ///   - `responseData` (Map<String, dynamic>): API 응답 데이터.
  ///
  /// - **반환값**:
  ///   - `Map<String, List<dynamic>>`: 경로 및 브랜치 정보가 포함된 맵을 반환합니다.
  ///     - `paths`: `LatLng` 타입의 경로 좌표 리스트.
  ///     - `branchInfo`: `BranchInfo` 타입의 브랜치 정보 리스트.
  ///
  /// - **사용 예시**:
  /// ```dart
  /// final apiService = NavigationApiService();
  /// final response = await apiService.fetchPathData(
  ///   startLatitude: 37.5665,
  ///   startLongitude: 126.9780,
  ///   endLatitude: 37.5651,
  ///   endLongitude: 126.9895,
  /// );
  /// final parsedData = apiService.parsePathData(response);
  /// print(parsedData['paths']);
  /// print(parsedData['branchInfo']);
  /// ```
  Map<String, List<dynamic>> parsePathData(Map<String, dynamic> responseData) {
    List<dynamic> features = responseData['features'];

    List<LatLng> paths = [];
    List<BranchInfo> branchInfo = [];

    for (var feature in features) {
      List<dynamic> coordinates = feature['geometry']['coordinates'];
      if (feature['geometry']['type'] == 'LineString') {
        paths.addAll(coordinates.map((coord) => LatLng(coord[1], coord[0])));
        for (var coord in coordinates) {
          LatLng point = LatLng(coord[1], coord[0]);
          if (branchInfo.isNotEmpty &&
              branchInfo[branchInfo.length - 1].point == point) {
            continue;
          }
          branchInfo.add(BranchInfo(
            point,
            '', // 설명
            0.0, // `bearingToPoint`는 항상 0.0으로 설정
            int.parse(feature['properties']['facilityType']) == 15,
            false, // `branch`는 기본적으로 false로 설정
          ));
        }
      }
      if (feature['geometry']['type'] == 'Point' && branchInfo.isNotEmpty) {
        double latitude = coordinates[1];
        double longitude = coordinates[0];
        String description = feature['properties']['description'];
        for (var branch in branchInfo) {
          if (branch.point.latitude == latitude &&
              branch.point.longitude == longitude) {
            branch.branch = true;
            branch.description = description;
            break;
          }
        }
      }
    }

    return {'paths': paths, 'branchInfo': branchInfo};
  }
}