part of '../../framework/object.dart';

/// 서버 응답을 모델 객체로 변환하는 클래스
class BuildingResponseModel {
  final int? buildingId;
  final String? buildingName;
  final String? buildingDetail;
  final List<EntranceModel> entrances;
  final int exitCount;

  BuildingResponseModel({
    this.buildingId,
    required this.buildingName,
    required this.buildingDetail,
    required this.entrances,
    required this.exitCount,
  });

  /// JSON → Model
  /// - 서버 응답이 `null`인 경우: 모든 필드를 `"데이터 없음"` 또는 빈 리스트로 초기화
  /// - `entrances` 필드가 `null`이거나 `[null, null, ...]` 형식일 경우: 빈 리스트로 초기화
  factory BuildingResponseModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return BuildingResponseModel(
        buildingId: null,
        buildingName: null,
        buildingDetail: null,
        entrances: [],
        exitCount: 0,
      );
    }

    return BuildingResponseModel(
      buildingId: json['bldg_id'] as int?,
      buildingName: json['building_name'] as String?,
      buildingDetail: json['building_detail'] as String?,
      entrances: (json['entrances'] as List?)
              ?.where((e) => e != null)
              .map((e) => EntranceModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      exitCount: json['exit_count'] as int? ?? 0,
    );
  }

  /// Model → Entity
  BuildingResponse toEntity() {
    return BuildingResponse(
      buildingId: buildingId ?? -1, // null이면 -1로 설정
      buildingName: buildingName ?? "데이터 없음",
      buildingDetail: buildingDetail ?? "정보 없음",
      entrances: entrances.map((e) => e.toEntity()).toList(),
    );
  }
}

/// 출입구 정보 모델
class EntranceModel {
  final String entranceName;
  final double longitude;
  final double latitude;

  EntranceModel({
    required this.entranceName,
    required this.longitude,
    required this.latitude,
  });

  /// JSON → Model
  factory EntranceModel.fromMap(Map<String, dynamic> map) {
    double receivedLat = (map['lat'] as num).toDouble();
    double receivedLon = (map['lon'] as num).toDouble();
    double finalLatitude;
    double finalLongitude;

    // 서버 응답에서 lat과 lon의 값이 뒤바뀌어 오는 경우를 처리하기 위한 휴리스틱:
    // 한국의 위도(latitude)는 대략 33~38.5 범위, 경도(longitude)는 대략 124~132 범위.
    // 만약 서버에서 받은 'lon' 필드 값이 위도 범위에 있고, 'lat' 필드 값이 경도 범위에 있다면, 
    // 두 값이 뒤바뀌어 온 것으로 간주합니다 (주로 출입구가 여러 개일 때의 서버 응답 형식).
    if ((receivedLon >= 33.0 && receivedLon <= 39.0) && 
        (receivedLat >= 120.0 && receivedLat <= 135.0)) {
      // 값이 뒤바뀐 경우 (lon이 실제 위도, lat이 실제 경도)
      finalLatitude = receivedLon;
      finalLongitude = receivedLat;
      // debugPrint('EntranceModel.fromMap: Swapped lat/lon based on value range.');
      // debugPrint('  Original lat: $receivedLat, Original lon: $receivedLon');
      // debugPrint('  Assigned Latitude: $finalLatitude, Assigned Longitude: $finalLongitude');
    } else {
      // 값이 정상적인 순서인 경우 (lat이 실제 위도, lon이 실제 경도) 또는 판별이 어려운 경우 기본 매핑
      finalLatitude = receivedLat;
      finalLongitude = receivedLon;
      // debugPrint('EntranceModel.fromMap: Standard lat/lon mapping.');
      // debugPrint('  Original lat: $receivedLat, Original lon: $receivedLon');
      // debugPrint('  Assigned Latitude: $finalLatitude, Assigned Longitude: $finalLongitude');
    }

    return EntranceModel(
      entranceName: map['entranceName'] as String,
      latitude: finalLatitude,
      longitude: finalLongitude,
    );
  }

  /// Model → Entity
  Entrance toEntity() {
    return Entrance(
      entranceName: entranceName,
      location: LatLng(latitude, longitude),
    );
  }
}
