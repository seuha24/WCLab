part of object;

/// 출입구 정보 엔티티
class Entrance {
  final String entranceName;
  final LatLng location; // 위도, 경도 정보를 LatLng으로 묶음

  Entrance({
    required this.entranceName,
    required this.location,
  });
}

/// 건물 정보 엔티티
class BuildingResponse {
  final int buildingId;         // 건물 ID
  final String buildingName;    // 건물명
  final String buildingDetail;  // 건물 상세 정보
  final List<Entrance> entrances; // 여러 개의 출입구 리스트

  BuildingResponse({
    required this.buildingId,
    required this.buildingName,
    required this.buildingDetail,
    required this.entrances,
  });

  BuildingResponse copyWith({
    int? buildingId,
    String? buildingName,
    String? buildingDetail,
    List<Entrance>? entrances,
  }) {
    return BuildingResponse(
      buildingId: buildingId ?? this.buildingId,
      buildingName: buildingName ?? this.buildingName,
      buildingDetail: buildingDetail ?? this.buildingDetail,
      entrances: entrances ?? this.entrances,
    );
  }
}
