import 'package:safelight/data/services/kakao_local_api_service.dart';
import 'package:safelight/domain/entities/favorite_point.dart';

/// 카카오 로컬 API 장소 검색 결과 Entity
///
/// **카카오 API 응답 매핑:**
/// - `place_name` → `name`
/// - `address_name` / `road_address_name` → `address`
/// - `x`, `y` → `geometry.location`
/// - `distance` → `distance` (선택적, Category Search API에서만 제공)
///
/// **사용처:**
/// - 목적지 검색 (destination_search_view.dart)
/// - 출발지 검색 (startspot_search_view.dart)
/// - 지도 검색 (map_view.dart)
/// - 즐겨찾기 등록 (registration_bloc.dart)
/// - 현재 위치 파악 (location_announcement_controller.dart)
class PlaceResult {
  final String name;
  final String address;
  final LatLngGeometry geometry;

  /// 중심 좌표까지의 거리 (단위: 미터)
  ///
  /// **제공 조건:**
  /// - Category Search API (`/v2/local/search/category.json`)에서만 제공
  /// - Keyword Search API에서는 null
  ///
  /// **예시:**
  /// - distance: 23 → "23미터 거리"
  /// - distance: null → 거리 정보 없음
  final int? distance;

  /// 장소 카테고리 코드
  ///
  /// **사용 목적:**
  /// - 카카오 POI vs 즐겨찾기 구분
  /// - FAV: 사용자 등록 즐겨찾기
  /// - 그 외: 카카오 API 카테고리
  final KakaoCategoryCode? category;

  /// ex) name: '가톨릭대학교 성심교정', address: '경기도 부천시 소사로 327', geometry: LatLngGeometry, distance: 150
  PlaceResult({
    required this.name,
    required this.address,
    required this.geometry,
    this.distance,
    this.category,
  });

  /// FavoritePoint를 PlaceResult로 변환
  ///
  /// **사용 목적:**
  /// - 즐겨찾기 관심지점을 카카오 POI와 동일한 형태로 통합
  /// - LocationAnnouncementController에서 거리 비교 시 활용
  ///
  /// **예시:**
  /// ```dart
  /// final favoritePoint = FavoritePoint(name: '집', latitude: 37.5, longitude: 127.0);
  /// final placeResult = PlaceResult.fromFavoritePoint(favoritePoint);
  /// ```
  factory PlaceResult.fromFavoritePoint(FavoritePoint point) {
    return PlaceResult(
      name: point.name,
      address: '',
      geometry: LatLngGeometry(
        location: GeoLocation(
          lat: point.latitude,
          lng: point.longitude,
        ),
      ),
      category: KakaoCategoryCode.FAV,
    );
  }
}

/// 위경도 정보 모델 클래스
class GeoLocation {
  final double lat;
  final double lng;

  GeoLocation({
    required this.lat,
    required this.lng,
  });
}

/// LatLng 포맷을 GeoLocation으로 감싼 구조
class LatLngGeometry {
  final GeoLocation location;

  LatLngGeometry({
    required this.location,
  });
}
