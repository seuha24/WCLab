part of '../../framework/object.dart';

/// C-ITS 교차로 정보 엔티티
///
/// API 2-1, 2-2에서 사용
/// 교차로명과 위치(위도/경도)만 사용
class CitsJunction extends Equatable {
  /// 교차로명
  final String name;

  /// 경도
  final double longitude;

  /// 위도
  final double latitude;

  const CitsJunction({
    required this.name,
    required this.longitude,
    required this.latitude,
  });

  /// LatLng 객체로 변환
  LatLng get latLng => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [name, longitude, latitude];

  @override
  String toString() {
    return 'CitsJunction(name: $name, lat: $latitude, lng: $longitude)';
  }
}
