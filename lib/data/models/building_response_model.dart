part of object;

class BuildingResponseModel {
  final List<EntranceModel> entrancesModel;

  BuildingResponseModel({
    required this.entrancesModel,
  });

  factory BuildingResponseModel.fromList(List<dynamic> list) {
    return BuildingResponseModel(
      entrancesModel: list
          .map((e) => EntranceModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  BuildingResponse toEntity() {
    return BuildingResponse(
      entrances: entrancesModel.map((e) => Entrance(
        entranceName: e.entranceName,
        location: LatLng(e.latitude, e.longitude),
      )).toList(),
    );
  }
}

class EntranceModel {
  final String entranceName;
  final double latitude;
  final double longitude;

  EntranceModel({
    required this.entranceName,
    required this.latitude,
    required this.longitude,
  });

  factory EntranceModel.fromMap(Map<String, dynamic> map) {
    return EntranceModel(
      entranceName: map['entranceName'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}