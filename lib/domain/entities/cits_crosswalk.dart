part of '../../framework/object.dart';

/// C-ITS 음향신호기 정보 엔티티
///
/// API 2-4, 2-5에서 사용
/// 음향신호기 관리번호, 방향, 위치 등 정보 포함
class CitsCrosswalk extends Equatable {
  /// 음향신호관리번호 (고유 ID)
  final String? cwMgmtKey;

  /// 횡단 방향 (도)
  /// 0, 90, 180, 270 등의 값
  final int? direction;

  /// 제조회사
  final String? manufacturer;

  /// 종류
  final int? type;

  /// 상태
  final int? status;

  /// 경도
  final double longitude;

  /// 위도
  final double latitude;

  const CitsCrosswalk({
    this.cwMgmtKey,
    this.direction,
    this.manufacturer,
    this.type,
    this.status,
    required this.longitude,
    required this.latitude,
  });

  /// LatLng 객체로 변환
  LatLng get latLng => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [cwMgmtKey, longitude, latitude];

  @override
  String toString() {
    return 'CitsCrosswalk(id: $cwMgmtKey, lat: $latitude, lng: $longitude)';
  }
}
