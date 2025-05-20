part of object;

/// 서버 응답을 모델 객체로 변환하는 클래스
class BuildingResponseModel {
  final int? buildingId;
  final String? buildingName;
  final String? buildingDetail;
  final List<EntranceModel> entrances;
  //final int exitCount;

  BuildingResponseModel({
    this.buildingId,
    required this.buildingName,
    required this.buildingDetail,
    required this.entrances,
    //required this.exitCount,
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
        //exitCount: 0,
      );
    }

    return BuildingResponseModel(
      buildingId: json['bldg_id'] as int?,
      buildingName: json['building_name'] as String?,
      buildingDetail: json['building_detail'] as String?,
      //exitCount: json['exit_count'] as int?,
      entrances: (json['entrances'] as List?)
              ?.where((e) => e != null)
              .map((e) => EntranceModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Model → Entity
  BuildingResponse toEntity() {
    return BuildingResponse(
      buildingId: buildingId ?? -1, // null이면 -1로 설정
      buildingName: buildingName ?? "데이터 없음",
      buildingDetail: buildingDetail ?? "정보 없음",
      entrances: entrances.map((e) => e.toEntity()).toList(),
      //exitCount: exitCount,
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
    return EntranceModel(
      entranceName: map['name'] as String,
      longitude: (map['lon'] as num).toDouble(),
      latitude: (map['lat'] as num).toDouble(),
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
