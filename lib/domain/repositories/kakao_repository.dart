import 'package:dartz/dartz.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/domain/entities/place_result.dart';

/// 카카오 로컬 API Repository 인터페이스
///
/// **책임:**
/// - 장소 검색 (키워드 기반)
/// - 역지오코딩 (GPS → 주소)
///
/// **구현체:**
/// - KakaoRepositoryImpl (data/repositories/)
///
/// **사용처:**
/// - destination_search_view.dart (목적지 검색)
/// - startspot_search_view.dart (출발지 검색)
/// - destination_picker_view.dart (지도 이동 시 주소)
/// - map_view.dart (지도 검색)
/// - registration_bloc.dart (건물 등록)
/// - location_announcement_controller.dart (현재 위치 알림)
abstract class KakaoRepository {
  /// 키워드로 장소 검색
  ///
  /// **API**: https://dapi.kakao.com/v2/local/search/keyword.json
  ///
  /// **Parameters:**
  /// - `query`: 검색 키워드 (예: "아주대학교", "강남역", "카페")
  /// - `x`: (선택) 중심 경도 (결과 정렬용)
  /// - `y`: (선택) 중심 위도 (결과 정렬용)
  ///
  /// **Returns:**
  /// - Right: List<PlaceResult> (검색 결과)
  /// - Left: Failure (NetworkFailure, ServerFailure)
  ///
  /// **예시:**
  /// ```dart
  /// final result = await kakaoRepository.searchPlaces('아주대학교');
  /// result.fold(
  ///   (failure) => print('검색 실패'),
  ///   (places) => print('검색 성공: ${places.length}개'),
  /// );
  /// ```
  Future<Either<Failure, List<PlaceResult>>> searchPlaces(
    String query, {
    double? x,
    double? y,
  });

  /// 좌표를 주소로 변환 (역지오코딩)
  ///
  /// **API**: https://dapi.kakao.com/v2/local/geo/coord2address.json
  ///
  /// **Parameters:**
  /// - `latitude`: 위도 (WGS84)
  /// - `longitude`: 경도 (WGS84)
  ///
  /// **Returns:**
  /// - Right: String (주소, 예: "경기도 수원시 영통구 원천동")
  /// - Left: Failure (NetworkFailure, ServerFailure)
  ///
  /// **예시:**
  /// ```dart
  /// final result = await kakaoRepository.getAddressFromCoordinates(
  ///   latitude: 37.2859,
  ///   longitude: 127.0449,
  /// );
  /// result.fold(
  ///   (failure) => print('변환 실패'),
  ///   (address) => print('주소: $address'),
  /// );
  /// ```
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });

  /// 좌표 기반 주변 장소 검색
  ///
  /// **API**: https://dapi.kakao.com/v2/local/search/category.json
  ///
  /// **Parameters:**
  /// - `latitude`: 위도 (WGS84)
  /// - `longitude`: 경도 (WGS84)
  /// - `radius`: 검색 반경 (미터, 기본값: 50m)
  ///
  /// **Returns:**
  /// - Right: List<PlaceResult> (거리순 정렬, 최대 5개)
  ///   - PlaceResult.distance 필드 포함 (미터 단위)
  /// - Left: Failure (NetworkFailure, ServerFailure)
  ///
  /// **사용 예시:**
  /// ```dart
  /// final result = await kakaoRepository.searchNearbyPlaces(
  ///   latitude: 37.2822,
  ///   longitude: 127.0447,
  ///   radius: 50,
  /// );
  /// result.fold(
  ///   (failure) => print('검색 실패'),
  ///   (places) {
  ///     if (places.isEmpty) {
  ///       print('주변에 장소 없음');
  ///     } else {
  ///       final nearest = places.first;
  ///       print('가장 가까운 장소: ${nearest.name}, ${nearest.distance}m');
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// **특징:**
  /// - 거리순으로 자동 정렬됨
  /// - distance 필드 포함
  /// - 모든 카테고리 검색 (음식점, 카페, 지하철역 등)
  Future<Either<Failure, List<PlaceResult>>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 50,
  });
}
