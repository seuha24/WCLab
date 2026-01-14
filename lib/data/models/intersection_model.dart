part of '../../framework/object.dart';

/// [IntersectionModel]은 CSV 데이터를 파싱하여 [Intersection]으로 변환하는 모델이다.
class IntersectionModel extends Intersection {
  const IntersectionModel({
    required super.intersectionId,
    required super.name,
    super.linkedCode,
    super.districtCode,
    super.address,
    super.meterNumber,
    super.roadType,
    required super.longitude,
    required super.latitude,
  });

  /// CSV 행(List<String>)에서 IntersectionModel 생성
  ///
  /// CSV 컬럼 순서:
  /// 0: 교차로번호, 1: 교차로명, 2: 연동교차로코드, 3: 구코드,
  /// 4: 지번, 5: 계량기번호, 6: 도로구분, 7: 경도, 8: 위도
  factory IntersectionModel.fromCsvRow(List<String> row) {
    return IntersectionModel(
      intersectionId: row[0].trim(),
      name: row[1].trim(),
      linkedCode: _parseNullableString(row[2]),
      districtCode: _parseNullableString(row[3]),
      address: _parseNullableString(row[4]),
      meterNumber: _parseNullableString(row[5]),
      roadType: _parseNullableString(row[6]),
      longitude: double.parse(row[7].trim()),
      latitude: double.parse(row[8].trim()),
    );
  }

  /// 빈 값, '-' 처리
  static String? _parseNullableString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    return trimmed;
  }

  /// Map에서 IntersectionModel 생성
  factory IntersectionModel.fromMap(Map<String, dynamic> map) {
    return IntersectionModel(
      intersectionId: map['intersectionId'] as String,
      name: map['name'] as String,
      linkedCode: map['linkedCode'] as String?,
      districtCode: map['districtCode'] as String?,
      address: map['address'] as String?,
      meterNumber: map['meterNumber'] as String?,
      roadType: map['roadType'] as String?,
      longitude: map['longitude'] as double,
      latitude: map['latitude'] as double,
    );
  }

  /// Map으로 변환
  Map<String, dynamic> toMap() {
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
