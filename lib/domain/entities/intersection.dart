part of '../../framework/object.dart';

/// [Intersection]은 서울시 공공데이터 기반 교차로 엔티티이다.
///
/// CSV 데이터에서 파싱된 교차로 위치 정보를 나타낸다.
/// GPS 위치 기반으로 주변 교차로를 지도에 표시할 때 사용한다.
///
/// |field|설명|
/// |:-------|:--------|
/// |[intersectionId]|교차로번호 (고유 ID)|
/// |[name]|교차로명|
/// |[linkedCode]|연동교차로코드 (0이면 독립 교차로)|
/// |[districtCode]|구코드|
/// |[address]|지번|
/// |[meterNumber]|계량기번호|
/// |[roadType]|도로구분|
/// |[longitude]|경도|
/// |[latitude]|위도|
class Intersection extends Equatable {
  /// 교차로번호 (고유 ID)
  final String intersectionId;

  /// 교차로명
  final String name;

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

  /// 경도 (longitude)
  final double longitude;

  /// 위도 (latitude)
  final double latitude;

  const Intersection({
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
  List<Object?> get props => [intersectionId];

  @override
  String toString() {
    return 'Intersection(id: $intersectionId, name: $name, lat: $latitude, lng: $longitude)';
  }
}
