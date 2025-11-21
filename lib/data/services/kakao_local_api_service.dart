import 'dart:convert';
import 'package:http/http.dart' as http;

/// 카카오 로컬 API 통합 서비스
///
/// **역할:**
/// - 카카오 REST API Key 중앙 관리
/// - 카카오 로컬 API 공통 요청 처리
/// - 키워드 검색, 역지오코딩 등 제공
///
/// **API 문서:**
/// - https://developers.kakao.com/docs/latest/ko/local/dev-guide
///
/// **사용 예시:**
/// ```dart
/// final service = KakaoLocalApiService();
///
/// // 키워드 검색
/// final places = await service.searchPlaces('아주대학교');
///
/// // 역지오코딩 (좌표 → 주소)
/// final address = await service.getAddressFromCoordinates(
///   latitude: 37.4859,
///   longitude: 126.8015,
/// );
/// ```
///
/// **참고:**
/// - 기존 6군데 중복되던 API Key를 한 곳에서 관리
/// - destination_search_view.dart 등에서도 이 서비스 사용 권장
class KakaoLocalApiService {
  /// 카카오 REST API 키
  ///
  /// **주의:**
  /// - 이 Key는 프로젝트 전체에서 공유됩니다
  /// - 변경 시 이 파일만 수정하면 됩니다
  /// - 기존 중복 위치:
  ///   1. destination_search_view.dart
  ///   2. startspot_search_view.dart
  ///   3. destination_picker_view.dart
  ///   4. map_view.dart
  ///   5. registration_bloc.dart
  ///   6. geocoding_service.dart (삭제 예정)
  static const String _apiKey = '93848fcc11798c6f48099dd2e2373263';

  /// 카카오 API 공통 헤더
  static Map<String, String> get _headers => {
        'Authorization': 'KakaoAK $_apiKey',
      };

  /// 키워드로 장소 검색
  ///
  /// **API:** https://developers.kakao.com/docs/latest/ko/local/dev-guide#search-by-keyword
  ///
  /// **Parameters:**
  /// - `query`: 검색 키워드 (예: "아주대학교")
  /// - `x`: (선택) 중심 경도 (결과 정렬용)
  /// - `y`: (선택) 중심 위도 (결과 정렬용)
  /// - `radius`: (선택) 검색 반경 (미터, 기본값: 20000)
  /// - `page`: (선택) 페이지 번호 (1~45, 기본값: 1)
  /// - `size`: (선택) 한 페이지에 보여질 문서 수 (1~15, 기본값: 15)
  ///
  /// **Returns:**
  /// - 성공: JSON 응답 (Map<String, dynamic>)
  /// - 실패: Exception
  ///
  /// **응답 구조:**
  /// ```json
  /// {
  ///   "documents": [
  ///     {
  ///       "place_name": "아주대학교",
  ///       "address_name": "경기 수원시 영통구 원천동 산5",
  ///       "road_address_name": "경기 수원시 영통구 월드컵로 206",
  ///       "x": "127.044696258564",
  ///       "y": "37.2822455365507",
  ///       "category_name": "교육,연구 > 학교 > 대학교",
  ///       "phone": "031-219-2114"
  ///     }
  ///   ]
  /// }
  /// ```
  Future<Map<String, dynamic>> searchPlaces(
    String query, {
    double? x,
    double? y,
    int? radius,
    int page = 1,
    int size = 15,
  }) async {
    // URL 구성
    final uri = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/keyword.json',
    ).replace(queryParameters: {
      'query': query,
      if (x != null) 'x': x.toString(),
      if (y != null) 'y': y.toString(),
      if (radius != null) 'radius': radius.toString(),
      'page': page.toString(),
      'size': size.toString(),
    });

    // HTTP GET 요청
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('장소 검색 실패: ${response.statusCode}');
    }
  }

  /// 좌표를 주소로 변환 (역지오코딩)
  ///
  /// **API:** https://developers.kakao.com/docs/latest/ko/local/dev-guide#coord-to-address
  ///
  /// **Parameters:**
  /// - `latitude`: 위도 (WGS84 좌표계)
  /// - `longitude`: 경도 (WGS84 좌표계)
  ///
  /// **Returns:**
  /// - 성공: "경기도 수원시 영통구 원천동"
  /// - 실패: "알 수 없는 위치"
  ///
  /// **응답 구조:**
  /// ```json
  /// {
  ///   "documents": [
  ///     {
  ///       "address": {
  ///         "region_1depth_name": "경기도",
  ///         "region_2depth_name": "수원시 영통구",
  ///         "region_3depth_name": "원천동"
  ///       },
  ///       "road_address": {
  ///         "region_1depth_name": "경기도",
  ///         "region_2depth_name": "수원시 영통구",
  ///         "region_3depth_name": "원천동",
  ///         "road_name": "월드컵로"
  ///       }
  ///     }
  ///   ]
  /// }
  /// ```
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // URL 구성
      final uri = Uri.parse(
        'https://dapi.kakao.com/v2/local/geo/coord2address.json',
      ).replace(queryParameters: {
        'x': longitude.toString(),
        'y': latitude.toString(),
      });

      // HTTP GET 요청
      final response = await http.get(uri, headers: _headers);

      // 응답 확인
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> documents = jsonResponse['documents'];

        // 결과가 없는 경우
        if (documents.isEmpty) {
          return '알 수 없는 위치';
        }

        final doc = documents[0];

        // 도로명 주소 우선, 없으면 지번 주소 사용
        final roadAddress = doc['road_address'];
        final address = doc['address'];

        final parts = <String>[];

        if (roadAddress != null) {
          // 도로명 주소 조합
          final region1 = roadAddress['region_1depth_name'] ?? '';
          final region2 = roadAddress['region_2depth_name'] ?? '';
          final region3 = roadAddress['region_3depth_name'] ?? '';

          if (region1.isNotEmpty) parts.add(region1);
          if (region2.isNotEmpty) parts.add(region2);
          if (region3.isNotEmpty) parts.add(region3);
        } else if (address != null) {
          // 지번 주소 조합
          final region1 = address['region_1depth_name'] ?? '';
          final region2 = address['region_2depth_name'] ?? '';
          final region3 = address['region_3depth_name'] ?? '';

          if (region1.isNotEmpty) parts.add(region1);
          if (region2.isNotEmpty) parts.add(region2);
          if (region3.isNotEmpty) parts.add(region3);
        }

        // 주소 조합 결과 반환
        return parts.isEmpty ? '알 수 없는 위치' : parts.join(' ');
      }

      // HTTP 오류
      return '알 수 없는 위치';
    } catch (e) {
      // 모든 예외를 기본값으로 처리
      return '알 수 없는 위치';
    }
  }

  /// 주소로 좌표 검색 (지오코딩)
  ///
  /// **API:** https://developers.kakao.com/docs/latest/ko/local/dev-guide#address-coord
  ///
  /// **Parameters:**
  /// - `address`: 주소 (예: "경기 수원시 영통구 월드컵로 206")
  ///
  /// **Returns:**
  /// - 성공: JSON 응답
  /// - 실패: Exception
  ///
  /// **응답 구조:**
  /// ```json
  /// {
  ///   "documents": [
  ///     {
  ///       "address_name": "경기 수원시 영통구 원천동 산5",
  ///       "x": "127.044696258564",
  ///       "y": "37.2822455365507"
  ///     }
  ///   ]
  /// }
  /// ```
  Future<Map<String, dynamic>> getCoordinatesFromAddress(
    String address,
  ) async {
    // URL 구성
    final uri = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json',
    ).replace(queryParameters: {
      'query': address,
    });

    // HTTP GET 요청
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('주소 검색 실패: ${response.statusCode}');
    }
  }

  /// 좌표 기반 주변 장소 검색 (카테고리 검색 API)
  ///
  /// **API:** https://developers.kakao.com/docs/latest/ko/local/dev-guide#search-by-category
  ///
  /// **Parameters:**
  /// - `latitude`: 위도 (WGS84)
  /// - `longitude`: 경도 (WGS84)
  /// - `radius`: 검색 반경 (미터, 기본값: 50m, 최대: 20000m)
  ///
  /// **Returns:**
  /// - 성공: List of POI (거리순 정렬)
  /// - 실패: Exception
  ///
  /// **카테고리 코드:**
  /// - MT1: 대형마트, CS2: 편의점, PS3: 어린이집/유치원
  /// - SC4: 학교, AC5: 학원, PK6: 주차장
  /// - OL7: 주유소, SW8: 지하철역, BK9: 은행
  /// - CT1: 문화시설, AG2: 중개업소, PO3: 공공기관
  /// - AT4: 관광명소, AD5: 숙박, FD6: 음식점
  /// - CE7: 카페, HP8: 병원, PM9: 약국
  ///
  /// **응답 구조:**
  /// ```json
  /// {
  ///   "documents": [
  ///     {
  ///       "place_name": "스타벅스 아주대R&D점",
  ///       "category_name": "음식점 > 카페",
  ///       "address_name": "경기 수원시 영통구 이의동 864",
  ///       "road_address_name": "경기 수원시 영통구 광교로 145",
  ///       "x": "127.044812",
  ///       "y": "37.282156",
  ///       "distance": "23"
  ///     }
  ///   ]
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 50,
  }) async {
    // 주요 카테고리 코드 (사용자가 관심있을 만한 것들)
    final categories = [
      'SC4', // 학교
      'PO3', // 공공기관
      'CE7', // 카페 (우선순위 높음)
      'FD6', // 음식점
      'CS2', // 편의점
      'SW8', // 지하철역
      'BK9', // 은행
      'MT1', // 대형마트
      'HP8', // 병원
      'PM9', // 약국
      'CT1', // 문화시설
      'AT4', // 관광명소
    ];

    final allResults = <Map<String, dynamic>>[];

    // 각 카테고리별로 검색 (최대 5개씩)
    for (final category in categories) {
      try {
        final uri = Uri.parse(
          'https://dapi.kakao.com/v2/local/search/category.json',
        ).replace(queryParameters: {
          'category_group_code': category,
          'x': longitude.toString(),
          'y': latitude.toString(),
          'radius': radius.toString(),
          'sort': 'distance',
          'size': '5',
        });

        final response = await http.get(uri, headers: _headers);

        if (response.statusCode == 200) {
          final jsonResponse =
              json.decode(response.body) as Map<String, dynamic>;
          final documents = jsonResponse['documents'] as List;

          for (var doc in documents) {
            allResults.add(doc as Map<String, dynamic>);
          }

          // 결과가 충분히 모이면 중단 (최대 15개)
          if (allResults.length >= 15) {
            break;
          }
        }
      } catch (e) {
        // 개별 카테고리 실패는 무시하고 계속 진행
        continue;
      }
    }

    // 카테고리 우선순위 유지 + 같은 카테고리 내 거리순 정렬
    allResults.sort((a, b) {
      // 카테고리 코드 추출
      final categoryA = a['category_group_code']?.toString() ?? '';
      final categoryB = b['category_group_code']?.toString() ?? '';

      // categories 배열에서 우선순위 인덱스 찾기
      final priorityA = categories.indexOf(categoryA);
      final priorityB = categories.indexOf(categoryB);

      // 우선순위가 다르면 카테고리 우선순위로 정렬
      if (priorityA != priorityB) {
        // -1(없음)은 맨 뒤로
        if (priorityA == -1) return 1;
        if (priorityB == -1) return -1;
        return priorityA.compareTo(priorityB);
      }

      // 같은 카테고리면 거리순 정렬
      final distA =
          int.tryParse(a['distance']?.toString() ?? '999999') ?? 999999;
      final distB =
          int.tryParse(b['distance']?.toString() ?? '999999') ?? 999999;
      return distA.compareTo(distB);
    });

    // 중복 제거 (같은 place_id)
    final uniqueResults = <String, Map<String, dynamic>>{};
    for (var result in allResults) {
      final id =
          result['id']?.toString() ?? result['place_name']?.toString() ?? '';
      if (id.isNotEmpty && !uniqueResults.containsKey(id)) {
        uniqueResults[id] = result;
      }
    }

    // 최대 5개만 반환
    return uniqueResults.values.take(5).toList();
  }
}
