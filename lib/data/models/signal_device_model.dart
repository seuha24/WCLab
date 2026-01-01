part of '../../framework/object.dart';

/// [SignalDeviceModel]은 CSV 데이터를 파싱하여 [SignalDevice]로 변환하는 모델이다.
class SignalDeviceModel extends SignalDevice {
  const SignalDeviceModel({
    required super.managementId,
    required super.postId,
    super.direction,
    super.manufacturer,
    required super.displayType,
    required super.deviceType,
    required super.status,
    required super.longitude,
    required super.latitude,
  });

  /// CSV 행(List<String>)에서 SignalDeviceModel 생성
  ///
  /// CSV 컬럼 순서:
  /// 0: 음향신호관리번호, 1: 지주관리번호, 2: 방향, 3: 제조회사,
  /// 4: 시설번호, 5: 표출구분, 6: 종류, 7: 상태, 8: 이력ID,
  /// 9: 위치정보, 10: 경도, 11: 위도
  factory SignalDeviceModel.fromCsvRow(List<String> row) {
    return SignalDeviceModel(
      managementId: row[0].trim(),
      postId: row[1].trim(),
      direction: _parseDirection(row[2]),
      manufacturer: _parseManufacturer(row[3]),
      displayType: int.tryParse(row[5].trim()) ?? 1,
      deviceType: int.tryParse(row[6].trim()) ?? 1,
      status: row[7].trim(),
      longitude: double.parse(row[10].trim()),
      latitude: double.parse(row[11].trim()),
    );
  }

  /// 방향 파싱 (빈 값, '-' 처리)
  static int? _parseDirection(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    return int.tryParse(trimmed);
  }

  /// 제조회사 파싱 (빈 값, '-' 처리)
  static String? _parseManufacturer(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    return trimmed;
  }

  /// Map에서 SignalDeviceModel 생성
  factory SignalDeviceModel.fromMap(Map<String, dynamic> map) {
    return SignalDeviceModel(
      managementId: map['managementId'] as String,
      postId: map['postId'] as String,
      direction: map['direction'] as int?,
      manufacturer: map['manufacturer'] as String?,
      displayType: map['displayType'] as int,
      deviceType: map['deviceType'] as int,
      status: map['status'] as String,
      longitude: map['longitude'] as double,
      latitude: map['latitude'] as double,
    );
  }

  /// Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'managementId': managementId,
      'postId': postId,
      'direction': direction,
      'manufacturer': manufacturer,
      'displayType': displayType,
      'deviceType': deviceType,
      'status': status,
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}
