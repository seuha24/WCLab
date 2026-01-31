part of '../../framework/object.dart';

/// C-ITS 교차로 정보 엔티티
///
/// API 2-1, 2-2에서 사용
/// 교차로명과 위치(위도/경도)만 사용
class CitsJunction extends Equatable {
  /// 교차로번호 (고유 ID)
  final String? intersectionId;

  /// 교차로명
  final String? name;

  /// 연동교차로코드 (0이면 독립 교차로)
  final String? linkedCode;

  /// 구코드
  final String? districtCode;

  /// 지번 (주소)
  final String? address;

  /// 계량기번호
  final String? meterNumber;

  /// 도로구분 (001, 002 등)
  final String? roadType;

  /// 경도
  final double longitude;

  /// 위도
  final double latitude;

  const CitsJunction({
    required this.intersectionId,
    required this.name,
    this.linkedCode,
    this.districtCode,
    this.address,
    this.meterNumber,
    this.roadType,
    required this.longitude,
    required this.latitude,
  });

  /// LatLng 객체로 변환
  LatLng get latLng => LatLng(latitude, longitude);

  /// 연동 교차로 여부 (다른 교차로와 연동되어 있는지)
  bool get isLinked => linkedCode != null && linkedCode != '0';

  @override
  List<Object?> get props => [name, longitude, latitude];

  @override
  String toString() {
    return 'CitsJunction(name: $name, lat: $latitude, lng: $longitude)';
  }
}
