part of object;


class Entrance {
  final String entranceName;
  final LatLng location; // 위도, 경도 정보를 LatLng으로 묶음

  Entrance({
    required this.entranceName,
    required this.location,
  });
}

class BuildingResponse {
  final List<Entrance> entrances;

  BuildingResponse({
    required this.entrances,
  });
}