part of '../../framework/object.dart';

/// [SignalDevice]는 서울시 공공데이터 기반 음향신호기 엔티티이다.
///
/// CSV 데이터에서 파싱된 음향신호기 위치 정보를 나타낸다.
/// GPS 위치 기반으로 주변 횡단보도를 지도에 표시할 때 사용한다.
///
/// |field|설명|
/// |:-------|:--------|
/// |[managementId]|음향신호관리번호 (고유 ID)|
/// |[postId]|지주관리번호|
/// |[direction]|횡단 방향 (도)|
/// |[manufacturer]|제조회사|
/// |[displayType]|표출구분|
/// |[deviceType]|종류|
/// |[status]|상태|
/// |[longitude]|경도|
/// |[latitude]|위도|
class SignalDevice extends Equatable {
  /// 음향신호관리번호 (고유 ID)
  final String managementId;

  /// 지주관리번호
  final String postId;

  /// 횡단 방향 (도)
  /// 0, 90, 180, 270, 315 등의 값
  final int? direction;

  /// 제조회사
  final String? manufacturer;

  /// 표출구분 (1 또는 2)
  final int displayType;

  /// 종류 (음향신호기 종류)
  final int deviceType;

  /// 상태 코드 (예: "001")
  final String status;

  /// 경도 (longitude)
  final double longitude;

  /// 위도 (latitude)
  final double latitude;

  const SignalDevice({
    required this.managementId,
    required this.postId,
    this.direction,
    this.manufacturer,
    required this.displayType,
    required this.deviceType,
    required this.status,
    required this.longitude,
    required this.latitude,
  });

  /// LatLng 객체로 변환
  LatLng get latLng => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [managementId];

  @override
  String toString() {
    return 'SignalDevice(id: $managementId, lat: $latitude, lng: $longitude)';
  }
}
