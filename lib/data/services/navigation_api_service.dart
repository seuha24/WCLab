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

/// 경유지를 포함한 경로 결과를 담는 클래스
class MultiWaypointPathResult {
  final List<LatLng> paths;
  final List<BranchInfo> branchInfo;
  final double totalDistance; // 미터 단위
  final int totalTime; // 초 단위
  final List<Map<String, dynamic>> segmentDetails; // 각 구간별 상세 정보

  MultiWaypointPathResult({
    required this.paths,
    required this.branchInfo,
    required this.totalDistance,
    required this.totalTime,
    required this.segmentDetails,
  });
}

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
    required String choose_route,
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
      "searchOption": choose_route,
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

  /// **fetchMultiWaypointPath**
  ///
  /// 경유지를 포함한 전체 경로를 구간별로 API 호출하여 합치는 메서드입니다.
  ///
  /// - **매개변수**:
  ///   - `waypoints` (List<LatLng>): 출발지, 경유지들, 도착지 순서의 좌표 리스트
  ///   - `chooseRoute` (String): 경로 옵션 ("0": 추천, "4": 추천+대로우선, "10": 최단, "30": 최단거리+계단제외)
  ///
  /// - **반환값**:
  ///   - `Future<MultiWaypointPathResult>`: 통합된 경로 정보를 반환합니다.
  ///
  /// - **예외**:
  ///   - 경유지가 2개 미만일 때 `ArgumentError`가 발생합니다.
  ///   - API 호출 실패 시 `Exception`이 발생합니다.
  ///
  /// - **사용 예시**:
  /// ```dart
  /// final apiService = NavigationApiService();
  /// final waypoints = [
  ///   LatLng(37.55677, 126.92365), // 출발
  ///   LatLng(37.55395, 126.92775), // 경유지1
  ///   LatLng(37.55337, 126.92577), // 경유지2
  ///   LatLng(37.55279, 126.92432), // 도착
  /// ];
  /// final result = await apiService.fetchMultiWaypointPath(waypoints, "0");
  /// print('총 거리: ${result.totalDistance}m');
  /// print('총 시간: ${result.totalTime}초');
  /// ```
  Future<MultiWaypointPathResult> fetchMultiWaypointPath({
    required List<LatLng> waypoints,
    required String chooseRoute,
  }) async {
    if (waypoints.length < 2) {
      throw ArgumentError('최소 2개의 지점(출발지, 도착지)이 필요합니다.');
    }

    List<LatLng> allPaths = [];
    List<BranchInfo> allBranchInfo = [];
    double totalDistance = 0.0;
    int totalTime = 0;
    List<Map<String, dynamic>> segmentDetails = [];

    // 각 구간별로 API 호출
    for (int i = 0; i < waypoints.length - 1; i++) {
      final startPoint = waypoints[i];
      final endPoint = waypoints[i + 1];

      print('구간 ${i + 1}: ${startPoint.latitude}, ${startPoint.longitude} -> ${endPoint.latitude}, ${endPoint.longitude}');

      try {
        // 구간별 경로 데이터 가져오기
        final segmentData = await fetchPathData(
          startLatitude: startPoint.latitude,
          startLongitude: startPoint.longitude,
          endLatitude: endPoint.latitude,
          endLongitude: endPoint.longitude,
          choose_route: chooseRoute,
        );

        // 구간 데이터 파싱
        final parsedSegment = parsePathData(segmentData);
        final segmentPaths = parsedSegment['paths'] as List<LatLng>;
        final segmentBranchInfo = parsedSegment['branchInfo'] as List<BranchInfo>;

        // 구간별 거리 및 시간 정보 추출
        final segmentStats = _extractSegmentStats(segmentData);
        totalDistance += segmentStats['distance'] ?? 0.0;
        totalTime += (segmentStats['time'] as int? ?? 0);

        // 구간 상세 정보 저장
        segmentDetails.add({
          'segmentIndex': i + 1,
          'startPoint': startPoint,
          'endPoint': endPoint,
          'distance': segmentStats['distance'],
          'time': segmentStats['time'],
          'pathCount': segmentPaths.length,
        });

        // 중복 포인트 처리하여 경로 합치기
        if (i == 0) {
          // 첫 번째 구간: 모든 포인트 추가
          allPaths.addAll(segmentPaths);
          allBranchInfo.addAll(segmentBranchInfo);
        } else {
          // 이후 구간: 첫 번째 포인트(경유지) 제외하고 추가
          if (segmentPaths.isNotEmpty) {
            allPaths.addAll(segmentPaths.skip(1));
          }
          if (segmentBranchInfo.isNotEmpty) {
            allBranchInfo.addAll(segmentBranchInfo.skip(1));
          }
        }

        print('구간 ${i + 1} 완료 - 거리: ${segmentStats['distance']}m, 시간: ${segmentStats['time']}초');

      } catch (e) {
        print('구간 ${i + 1} API 호출 실패: $e');
        String errorMessage = '구간 ${i + 1} 경로 조회 실패';
        
        if (e.toString().contains('SocketException')) {
          errorMessage += ': 인터넷 연결을 확인해주세요';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage += ': 요청 시간이 초과되었습니다';
        } else if (e.toString().contains('400')) {
          errorMessage += ': 잘못된 좌표입니다';
        } else if (e.toString().contains('401')) {
          errorMessage += ': API 키가 유효하지 않습니다';
        } else if (e.toString().contains('500')) {
          errorMessage += ': 서버 오류입니다';
        }
        
        throw Exception(errorMessage);
      }
    }

    print('전체 경로 합치기 완료 - 총 거리: ${totalDistance}m, 총 시간: ${totalTime}초, 총 포인트: ${allPaths.length}개');

    return MultiWaypointPathResult(
      paths: allPaths,
      branchInfo: allBranchInfo,
      totalDistance: totalDistance,
      totalTime: totalTime,
      segmentDetails: segmentDetails,
    );
  }

  /// API 응답에서 거리와 시간 정보를 추출하는 헬퍼 메서드
  Map<String, dynamic> _extractSegmentStats(Map<String, dynamic> responseData) {
    try {
      final features = responseData['features'] as List<dynamic>;
      double distance = 0.0;
      int time = 0;

      for (var feature in features) {
        final properties = feature['properties'] as Map<String, dynamic>?;
        if (properties != null) {
          // 거리 정보 (미터 단위)
          if (properties.containsKey('distance')) {
            distance += (properties['distance'] as num).toDouble();
          }
          // 시간 정보 (초 단위)
          if (properties.containsKey('time')) {
            final timeValue = properties['time'] as num;
            time += timeValue.toInt();
          }
        }
      }

      return {
        'distance': distance,
        'time': time,
      };
    } catch (e) {
      print('구간 통계 추출 실패: $e');
      return {
        'distance': 0.0,
        'time': 0,
      };
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