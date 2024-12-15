import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:safelight/domain/entities/branch_info.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


/// 이 파일은 NavigationBloc을 구현하며, 내비게이션 관련 상태 전환을 관리합니다.
/// Flutter Bloc 아키텍처를 사용하여 비즈니스 로직을 처리합니다.
///
/// 역할:
/// - TMAP API를 사용하여 내비게이션 경로를 가져옵니다 (`LoadPath` 이벤트 처리).
/// - 이동 중 내비게이션 진행 상태를 관리합니다 (`UpdateNavigation` 이벤트 처리).
/// - 작업의 성공 또는 실패에 따라 적절한 상태를 방출합니다.
///
/// 의존성:
/// - TMAP API의 인증 키와 엔드포인트 구성이 필요합니다.
/// - `navigation_event.dart`와 `navigation_state.dart` 파일에 정의된 이벤트와 상태를 사용합니다.
///
/// 처리 이벤트:
/// - `LoadPath`: 내비게이션 경로를 가져오고 경로 및 분기점 정보를 포함한 상태를 업데이트합니다.
/// - `UpdateNavigation`: 이동 중 남은 거리 및 경계 이탈 여부 등을 포함하여 내비게이션 진행 상태를 업데이트합니다.
///
/// 방출 상태:
/// - `NavigationInitial`, `NavigationLoading`, `NavigationReady`, `NavigationInProgress`, `NavigationFailure`.
///
/// 참고:
/// - 이 Bloc은 DI(의존성 주입, 예: GetIt)를 통해 애플리케이션의 메인에 등록해야 합니다.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationInitial()) {
    on<LoadPath>(_onLoadPath);
    on<UpdateNavigation>(_onUpdateNavigation);
  }

  Future<void> _onLoadPath(LoadPath event, Emitter<NavigationState> emit) async {
    emit(NavigationLoading());

    const String apiUrl =
        'https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&callback=function';

    final Map<String, dynamic> requestData = {
      "startX": event.startLongitude, // 현재 위치의 경도값
      "startY": event.startLatitude, // 현재 위치의 위도값
      "angle": 20,
      "speed": 30,
      "endPoiId": "10001",
      "endX": event.endLongitude, // 도착지의 경도값
      "endY": event.endLatitude, // 도착지의 위도값
      "reqCoordType": "WGS84GEO",
      "startName": "%EC%B6%9C%EB%B0%9C",
      "endName": "%EB%8F%84%EC%B0%A9",
      "searchOption": "0",
      "resCoordType": "WGS84GEO",
      "sort": "index"
    };

    final Map<String, String> headers = {
      'accept': 'application/json',
      'appKey': 'QKrZQE7KkR6MtxXBFx49A6gmY1a8TN3y8IyQ0qjh',
      'content-type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        List<dynamic> features = responseData['features'];

        // 기존 paths 및 branchinfo 초기화
        List<LatLng> paths = [];
        List<BranchInfo> branchInfo = [];
        int currentIndex = 0;
        int targetIndex = 0;

        // API 응답 파싱 (기존 for문 유지)
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

        // BloC 상태 갱신
        emit(NavigationReady(paths, branchInfo));
      } else {
        // 에러 처리
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (error) {
      // 에러 상태 처리
      emit(NavigationFailure(error.toString()));
    }
  }

  void _onUpdateNavigation(
      UpdateNavigation event, Emitter<NavigationState> emit) {
    // NavigationInProgress 상태 업데이트
    emit(NavigationInProgress(
      remainDistance: 0.5, // 임의 값
      outOfBound: false,
      currentIndex: 0,
    ));
  }
}
