part of '../../framework/object.dart';

/// C-ITS 음향신호기 정보 엔티티
///
/// API 2-4, 2-5에서 사용
/// 위치(위도/경도)만 사용
class CitsCrosswalk extends Equatable {
  /// 경도
  final double longitude;

  /// 위도
  final double latitude;

  const CitsCrosswalk({
    required this.longitude,
    required this.latitude,
  });

  /// LatLng 객체로 변환
  LatLng get latLng => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [longitude, latitude];

  @override
  String toString() {
    return 'CitsCrosswalk(lat: $latitude, lng: $longitude)';
  }
}
