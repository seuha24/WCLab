part of '../../framework/object.dart';

/// [CitsJunctionModel]은 API/CSV 데이터를 [CitsJunction]로 변환하는 모델
class CitsJunctionModel extends CitsJunction {
  const CitsJunctionModel({
    required super.intersectionId,
    required super.name,
    required super.linkedCode,
    required super.districtCode,
    required super.address,
    required super.meterNumber,
    required super.roadType,
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
      intersectionId: (json['jct_number'] as num).toString(),
      name: json['name'] as String,
      linkedCode: (json['connection_jct_number'] as num).toString(),
      districtCode: (json['district_code'] as String?),
      address: (json['address'] as String?),
      meterNumber: (json['meter_number'] as String?),
      roadType: (json['road_type'] as String?),
      longitude: location['lon'] as double,
      latitude: location['lat'] as double,
    );
  }

  /// CSV 행에서 생성 (2-2 다운로드)
  ///
  /// CSV 컬럼: 교차로번호,교차로명,연동교차로코드,구코드,지번,계량기번호,도로구분,경도,위도
  factory CitsJunctionModel.fromCsvRow(List<String> row) {
    return CitsJunctionModel(
      intersectionId: row[0].trim(),
      name: row[1].trim(),
      linkedCode: row[2].trim(),
      districtCode: row[3].trim(),
      address: row[4].trim(),
      meterNumber: row[5].trim(),
      roadType: row[6].trim(),
      longitude: double.parse(row[7].trim()),
      latitude: double.parse(row[8].trim()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intersectionId': intersectionId,
      'name': name,
      'linkedCode': linkedCode,
      'districtCode': districtCode,
      'address': address,
      'meterNumber': meterNumber,
      'roadType': roadType,
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}
