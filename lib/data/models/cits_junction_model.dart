part of '../../framework/object.dart';

/// [CitsJunctionModel]은 API/CSV 데이터를 [CitsJunction]로 변환하는 모델
class CitsJunctionModel extends CitsJunction {
  const CitsJunctionModel({
    required super.name,
    required super.longitude,
    required super.latitude,
  });

  /// API JSON 응답에서 생성 (2-1)
  ///
  /// ```json
  /// {
  ///   "jct_key": 1,
  ///   "jct_number": 6029,
  ///   "connection_jct_number": 0,
  ///   "name": "은평뉴타운아이파크709동",
  ///   "location": { "lon": 126.8015, "lat": 37.4859 }
  /// }
  /// ```
  factory CitsJunctionModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    return CitsJunctionModel(
      name: json['name'] as String,
      longitude: location['lon'] as double,
      latitude: location['lat'] as double,
    );
  }

  /// CSV 행에서 생성 (2-2 다운로드)
  ///
  /// CSV 컬럼: 교차로번호,교차로명,연동교차로코드,구코드,지번,계량기번호,도로구분,경도,위도
  factory CitsJunctionModel.fromCsvRow(List<String> row) {
    return CitsJunctionModel(
      name: row[1].trim(),
      longitude: double.parse(row[7].trim()),
      latitude: double.parse(row[8].trim()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': {'lon': longitude, 'lat': latitude},
    };
  }
}
