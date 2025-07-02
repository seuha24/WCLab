part of object;

/// SendStartPointParams의 데이터 변환을 담당하는 Model 클래스
class SendStartPointModel {
  final SendPointParams params;

  SendStartPointModel(this.params);

  /// SendStartPointParams -> JSON 변환 (서버로 전송용)
  Map<String, dynamic> toJson() {
    return {
      'roadAddress': params.roadAddress,
      'buildingName': params.buildingName,
      'buildingDetail': params.buildingDetail,
      'buildingPoint': {
        'lon': params.longitude,
        'lat': params.latitude,
      },
      'entrances': params.entrances
          .map((e) => {
                'entranceName': e.entranceName,
                'lon': e.location.longitude,
                'lat': e.location.latitude,
              })
          .toList(),
    };
  }
}