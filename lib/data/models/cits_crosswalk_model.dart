part of '../../framework/object.dart';

/// [CitsCrosswalkModel]은 API/CSV 데이터를 [CitsCrosswalk]로 변환하는 모델
class CitsCrosswalkModel extends CitsCrosswalk {
  const CitsCrosswalkModel({
    required super.longitude,
    required super.latitude,
  });

  /// API JSON 응답에서 생성 (2-4)
  ///
  /// ```json
  /// {
  ///   "cw_key": 1,
  ///   "cw_mgmt_key": "24-0000010295",
  ///   "direction": 180,
  ///   "manufacturer": "(주)한길HC",
  ///   "type": 1,
  ///   "status": 001,
  ///   "location": { "lon": 126.8015, "lat": 37.4859 }
  /// }
  /// ```
  factory CitsCrosswalkModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    return CitsCrosswalkModel(
      longitude: location['lon'] as double,
      latitude: location['lat'] as double,
    );
  }

  /// CSV 행에서 생성 (2-5 다운로드)
  ///
  /// CSV 컬럼: 음향신호관리번호,지주관리번호,방향,제조회사,시설번호,표출구분,종류,상태,이력ID,위치정보,경도,위도
  factory CitsCrosswalkModel.fromCsvRow(List<String> row) {
    return CitsCrosswalkModel(
      longitude: double.parse(row[10].trim()),
      latitude: double.parse(row[11].trim()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': {'lon': longitude, 'lat': latitude},
    };
  }
}
