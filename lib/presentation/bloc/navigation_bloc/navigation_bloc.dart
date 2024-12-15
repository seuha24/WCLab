import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:safelight/domain/entities/branch_info.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
