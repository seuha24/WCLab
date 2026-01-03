import 'package:dio/dio.dart';

enum KakaoCategoryCode {
  FAV, // 즐겨찾기 (사용자 등록 관심지점)
  CSR, // 교차로
  BST, // 버스정류장
  CSW, // 횡단보도
  SC4, // 학교
  PO3, // 공공기관
  CE7, // 카페
  FD6, // 음식점
  CS2, // 편의점
  SW8, // 지하철역
  BK9, // 은행
  MT1, // 대형마트
  HP8, // 병원
  PM9, // 약국
  CT1, // 문화시설
  AT4, // 관광명소

}

/// 카카오 로컬 API 통합 서비스
///
/// 역할:
/// - 카카오 REST API Key 중앙 관리
/// - 카카오 로컬 API 공통 요청 처리
/// - 키워드 검색, 역지오코딩, 주변 장소 검색 제공
///
/// 사용 예시:
/// final service = DI<KakaoLocalApiService>();
/// final places = await service.searchPlaces('아주대학교');
class KakaoLocalApiService {
  final Dio _dio;

  KakaoLocalApiService({required Dio dio}) : _dio = dio;

  /// 카카오 REST API 키
  static const String _apiKey = '93848fcc11798c6f48099dd2e2373263';
  /// 카카오 로컬 API 기본 URL
  static const String _baseUrl = 'https://dapi.kakao.com/v2/local';
  /// 알 수 없는 위치 레이블
  static const String _unknownLocationLabel = '알 수 없는 위치';
  /// 카카오 API 공통 헤더
  Map<String, String> get _headers => {
        'Authorization': 'KakaoAK $_apiKey',
      };
  
  /// 공통 URL 빌더
  String _buildUrl(String path) {
    return '$_baseUrl$path';
  }

  /// 카카오 로컬 API 공통 GET 요청 헬퍼
  ///
  /// 역할:
  /// - 카카오 API 엔드포인트에 대한 GET 요청 수행
  /// - 인증 헤더(KakaoAK) 자동 추가
  /// - 응답 상태 코드 검증 및 타입 체크
  ///
  /// Parameters:
  /// - [path]: API 엔드포인트 경로 (예: `/search/keyword.json`)
  /// - [query]: 쿼리 파라미터 (선택)
  ///
  /// Returns:
  /// - 성공 시: JSON 응답을 `Map<String, dynamic>` 형태로 반환
  ///
  /// Throws:
  /// - HTTP 상태 코드가 200이 아닌 경우
  /// - 응답 데이터가 `Map<String, dynamic>` 타입이 아닌 경우
  ///
  /// 사용 예시:
  /// ```dart
  /// final result = await _getJson('/search/keyword.json', query: {'query': '아주대'});
  /// ```
  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    // ① URL 생성: baseUrl + path 조합
    final url = _buildUrl(path);

    // ② Dio를 사용한 GET 요청 수행
    // - 쿼리 파라미터 자동 인코딩
    // - 카카오 인증 헤더 자동 추가
    final response = await _dio.get(
      url,
      queryParameters: query,
      options: Options(headers: _headers),
    );

    // ③ HTTP 상태 코드 검증
    if (response.statusCode == 200) {
      final data = response.data;

      // ④ 응답 데이터 타입 체크
      // 카카오 API는 항상 JSON 객체를 반환해야 함
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('카카오 API 응답 포맷 오류: Map<String, dynamic>가 아닙니다.');
    }

    // ⑤ HTTP 오류 발생 시 예외 처리
    throw Exception('카카오 API 요청 실패: ${response.statusCode}');
  }

  /// 키워드로 장소 검색
  ///
  /// API: /search/keyword.json
  Future<Map<String, dynamic>> searchPlaces(
    String query, {
    double? x,
    double? y,
    int? radius,
    int page = 1,
    int size = 15,
  }) async {
    final queryParams = <String, dynamic>{
      'query': query,
      'page': '$page',
      'size': '$size',
      if (x != null) 'x': '$x',
      if (y != null) 'y': '$y',
      if (radius != null) 'radius': '$radius',
    };

    return _getJson(
      '/search/keyword.json',
      query: queryParams,
    );
  }

  /// Kakao Local API 주소 응답에서 행정구역 depth 정보를 일괄 추출합니다.
  ///
  /// 사용 대상:
  /// - `address`
  /// - `road_address`
  ///
  /// 처리 방식:
  /// - `region_1depth_name`, `region_2depth_name`, `region_3depth_name` 순서대로 읽습니다.
  /// - 값이 `null`이거나 빈 문자열인 항목은 제거합니다.
  /// - `addressData`가 `null`이거나 유효한 필드가 하나도 없으면 빈 리스트를 반환합니다.
  ///
  /// 예:
  /// - addressData가
  ///   {
  ///     "region_1depth_name": "경기도",
  ///     "region_2depth_name": "수원시 영통구",
  ///     "region_3depth_name": "원천동"
  ///   }
  ///   인 경우 → ["경기도", "수원시 영통구", "원천동"] 반환
  ///
  /// 주의:
  /// - Kakao Local API의 필드 명명 규칙(`region_1depth_name` 등)에 강하게 의존합니다.
  ///   필드 구조가 변경되면 이 함수도 함께 수정해야 합니다.
  
  List<String> _extractRegionParts(Map<String, dynamic>? addressData) {
    if (addressData == null) return [];

    return [1, 2, 3]
        .map((i) => (addressData['region_${i}depth_name'] ?? '').toString())
        .where((region) => region.isNotEmpty)
        .toList();
  }

  /// 좌표를 주소로 변환 (역지오코딩)
  ///
  /// API: /geo/coord2address.json
  ///
  /// 성공: "경기도 수원시 영통구 원천동"
  /// 실패: "알 수 없는 위치"
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final jsonResponse = await _getJson(
        '/geo/coord2address.json',
        query: {
          'x': longitude.toString(),
          'y': latitude.toString(),
        },
      );

      final documents =
          jsonResponse['documents'] as List<dynamic>? ?? <dynamic>[];

      if (documents.isEmpty) {
        return _unknownLocationLabel;
      }

      final doc = documents.first as Map<String, dynamic>;
      final roadAddress = doc['road_address'] as Map<String, dynamic>?;
      final address = doc['address'] as Map<String, dynamic>?;

      final parts = _extractRegionParts(roadAddress);
      if (parts.isEmpty) {
        parts.addAll(_extractRegionParts(address));
      }

      return parts.isEmpty ? _unknownLocationLabel : parts.join(' ');
    } catch (_) {
      return _unknownLocationLabel;
    }
  }

  /// 주소로 좌표 검색 (지오코딩)
  ///
  /// API: /search/address.json
  Future<Map<String, dynamic>> getCoordinatesFromAddress(
    String address,
  ) async {
    return _getJson(
      '/search/address.json',
      query: {
        'query': address,
      },
    );
  }

  /// 좌표 기반 주변 장소 검색 (카테고리 검색 API)
  ///
  /// API: /search/category.json
  ///
  /// 반환: 카테고리 우선순위 + 거리순 정렬, 최대 5개
  Future<List<Map<String, dynamic>>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 50,
  }) async {
    final categories = KakaoCategoryCode.values;
    final allResults = <Map<String, dynamic>>[];

    for (final category in categories) {
      try {
        final jsonResponse = await _getJson(
          '/search/category.json',
          query: {
            'category_group_code': category.name,
            'x': longitude.toString(),
            'y': latitude.toString(),
            'radius': radius.toString(),
            'sort': 'distance',
            'size': '5',
          },
        );

        final documents =
            jsonResponse['documents'] as List<dynamic>? ?? <dynamic>[];

        for (final doc in documents) {
          allResults.add(doc as Map<String, dynamic>);
        }

        // 결과가 충분히 모이면 중단 (최대 15개)
        if (allResults.length >= 15) {
          break;
        }
      } catch (_) {
        // 카테고리 하나 실패해도 전체는 계속 진행
        continue;
      }
    }

    // 카테고리 우선순위 유지 + 같은 카테고리 내 거리순 정렬
    allResults.sort((a, b) {
      final categoryA = a['category_group_code']?.toString() ?? '';
      final categoryB = b['category_group_code']?.toString() ?? '';

      int indexOfCode(String code) {
        return categories.indexWhere((c) => c.name == code);
      }

      final priorityA = indexOfCode(categoryA);
      final priorityB = indexOfCode(categoryB);

      if (priorityA != priorityB) {
        if (priorityA == -1) return 1;
        if (priorityB == -1) return -1;
        return priorityA.compareTo(priorityB);
      }

      final distA =
          int.tryParse(a['distance']?.toString() ?? '999999') ?? 999999;
      final distB =
          int.tryParse(b['distance']?.toString() ?? '999999') ?? 999999;

      return distA.compareTo(distB);
    });

    // 중복 제거 (같은 place_id 기준)
    final uniqueResults = <String, Map<String, dynamic>>{};
    for (final result in allResults) {
      final id =
          result['id']?.toString() ?? result['place_name']?.toString() ?? '';
      if (id.isNotEmpty && !uniqueResults.containsKey(id)) {
        uniqueResults[id] = result;
      }
    }

    return uniqueResults.values.take(5).toList();
  }
}
