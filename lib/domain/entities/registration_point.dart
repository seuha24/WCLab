part of object;

/// 출입구 등록을 위한 도메인 엔티티
class SendPointParams {
  final String roadAddress;
  final String buildingName;
  final String? buildingDetail;
  final double longitude;
  final double latitude;
  final List<EntranceInfo> entrances;

  const SendPointParams({
    required this.roadAddress,
    required this.buildingName,
    this.buildingDetail,
    required this.longitude,
    required this.latitude,
    required this.entrances,
  });
}

/// 출입구 정보를 담는 도메인 엔티티
class EntranceInfo {
  final String entranceName;
  final LatLng location;

  const EntranceInfo({
    required this.entranceName,
    required this.location,
  });
}