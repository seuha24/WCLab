# 카카오 보행자 길찾기 API 명세서

> **작성일**: 2025-11-09
> **최종 업데이트**: 2025-11-11
> **API 버전**: v1
> **문서 목적**: TMAP 보행자 길찾기 API를 카카오 보행자 길찾기 API로 전환
> **프로젝트**: SafeLight (App ID: 1328836)

---

## 📑 목차
1. [기본 정보](#1-기본-정보)
2. [인증](#2-인증)
3. [API 명세](#3-api-명세)
4. [응답 구조](#4-응답-구조)
5. [에러 처리](#5-에러-처리)
6. [TMAP과의 비교](#6-tmap과의-비교)
7. [구현 가이드](#7-구현-가이드)
8. [주의사항](#8-주의사항)
9. [참고 자료](#9-참고-자료)
10. [프로젝트 정보 요약](#10-프로젝트-정보-요약)

---

## 1. 기본 정보

### 1.1 API 개요
| 항목 | 내용 |
|------|------|
| **서비스명** | 카카오모빌리티 제휴용 보행자 길찾기 API |
| **Base URL** | `https://apis-navi.kakaomobility.com` |
| **API Path** | `/affiliate/walking/v1/directions` |
| **HTTP Method** | GET |
| **Content-Type** | application/json |

### 1.2 계정 정보
| 항목 | 내용 |
|------|------|
| **App 이름** | safelight |
| **App ID** | 1328836 |
| **개발자 계정** | snyfromwcl25@gmail.com |
| **카카오 개발자 센터** | https://developers.kakao.com |

### 1.3 API 키
> ⚠️ **보안 주의**: 이 키들은 절대 공개 저장소에 커밋하지 마세요. 환경 변수로 관리하세요.

| 키 타입 | 키 값 | 용도 |
|--------|------|------|
| **네이티브 앱 키** | 30a78c461fe23564318ea0e7ec732454 | Android/iOS 네이티브 앱 |
| **REST API 키** | 1cdd32ab3a57b7a5c671f3dd43cb097e | 서버 및 API 호출 |
| **JavaScript 키** | fc82dd479a82783af5865513061ff522 | 웹 애플리케이션 |
| **Admin 키** | 0b31744a302bddd4f90215cb2fda8dcb | 관리자 기능 |

**사용할 키**: REST API 키 (`1cdd32ab3a57b7a5c671f3dd43cb097e`)

---

## 2. 인증

### 2.1 인증 방식
REST API 키를 사용한 KakaoAK 인증

### 2.2 필수 헤더
```http
Authorization: KakaoAK {REST_API_KEY}
service: {SERVICE_NAME}
accept: application/json
```

| 헤더 | 설명 | 필수 | 예시 |
|------|------|------|------|
| Authorization | 카카오 REST API 키 | ✅ | "KakaoAK xxxxxxxxxxxxxx" |
| service | 서비스 구분용 문자열 | ✅ | "SafeLight" |
| accept | 응답 형식 | ⬜ | "application/json" |

---

## 3. API 명세

### 3.1 API 엔드포인트

#### 기본 길찾기 API
```
GET https://apis-navi.kakaomobility.com/affiliate/walking/v1/directions
```

#### Delivery 전용 API (추가 엔드포인트)
카카오모빌리티에서 제공하는 배달/물류 전용 도보 길찾기 API:

| 엔드포인트 | 설명 |
|-----------|------|
| `/v1/api/navi-affiliate/walking/delivery` | 기본 배달 경로 탐색 |
| `/v1/api/navi-affiliate/walking/origins/delivery` | 다중 출발지 경로 탐색 |
| `/v1/api/navi-affiliate/walking/destinations/delivery` | 다중 도착지 경로 탐색 |
| `/v1/api/navi-affiliate/walking/waypoints/delivery` | 경유지 포함 배달 경로 |

> 📌 **참고**: SafeLight 프로젝트에서는 기본 길찾기 API를 사용합니다. Delivery API는 배달/물류 서비스에 특화된 기능입니다.

### 3.2 Query Parameters

#### 필수 파라미터
| 파라미터 | 타입 | 설명 | 예시 |
|---------|------|------|------|
| origin | String | 출발지 좌표 (경도,위도) | "127.110,37.395" |
| destination | String | 도착지 좌표 (경도,위도) | "127.108,37.402" |

#### 선택 파라미터
| 파라미터 | 타입 | 설명 | 기본값 | 예시 |
|---------|------|------|-------|------|
| waypoints | String | 경유지 (최대 5개, \| 구분) | - | "127.109,37.400\|127.107,37.401" |
| priority | String | 경로 우선순위 | DISTANCE | DISTANCE, MAIN_STREET |
| summary | Boolean | 요약 정보만 반환 여부 | false | true, false |
| default_speed | Float | 보행 속도 (km/h) | 4.0 | 3.5, 4.5, 5.0 |

#### 우선순위 옵션
| 값 | 설명 |
|---|------|
| DISTANCE | 최단 거리 우선 (기본값) |
| MAIN_STREET | 큰 도로 우선 |

### 3.3 요청 예시

#### cURL
```bash
curl -X GET "https://apis-navi.kakaomobility.com/affiliate/walking/v1/directions?origin=127.110,37.395&destination=127.108,37.402&priority=DISTANCE&summary=false" \
  -H "Authorization: KakaoAK 1cdd32ab3a57b7a5c671f3dd43cb097e" \
  -H "service: SafeLight" \
  -H "accept: application/json"
```

#### Dart (Dio 사용)
```dart
final response = await dio.get(
  '/affiliate/walking/v1/directions',
  queryParameters: {
    'origin': '${origin.longitude},${origin.latitude}',
    'destination': '${destination.longitude},${destination.latitude}',
    'priority': 'DISTANCE',
    'summary': false,
  },
  options: Options(
    headers: {
      'Authorization': 'KakaoAK $REST_API_KEY',
      'service': 'SafeLight',
      'accept': 'application/json',
    },
  ),
);
```

---

## 4. 응답 구조

### 4.1 성공 응답 (HTTP 200)

#### 요약 정보만 요청 (summary=true)
```json
{
  "trans_id": "20251109123456789",
  "routes": [
    {
      "result_code": 0,
      "result_message": "길찾기를 성공하였습니다.",
      "summary": {
        "distance": 1281,
        "duration": 1220
      }
    }
  ]
}
```

#### 전체 정보 요청 (summary=false)
```json
{
  "trans_id": "20251109123456789",
  "routes": [
    {
      "result_code": 0,
      "result_message": "길찾기를 성공하였습니다.",
      "summary": {
        "distance": 1281,
        "duration": 1220
      },
      "sections": [
        {
          "distance": 534,
          "duration": 509,
          "roads": [
            {
              "distance": 534,
              "duration": 509,
              "vertexes": [
                127.110, 37.395,
                127.109, 37.396,
                127.108, 37.397
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

### 4.2 응답 필드 상세

#### Root Level
| 필드 | 타입 | 설명 |
|------|------|------|
| trans_id | String | 경로 요청 고유 ID |
| routes | Array | 경로 정보 배열 (보통 1개) |

#### routes[]
| 필드 | 타입 | 설명 |
|------|------|------|
| result_code | Integer | 결과 코드 (0: 성공) |
| result_message | String | 결과 메시지 |
| summary | Object | 경로 요약 정보 |
| sections | Array | 구간 정보 (summary=false일 때만) |

#### summary
| 필드 | 타입 | 단위 | 설명 |
|------|------|------|------|
| distance | Integer | meter | 총 이동 거리 |
| duration | Integer | second | 예상 소요 시간 |

#### sections[]
| 필드 | 타입 | 설명 |
|------|------|------|
| distance | Integer | 구간 거리 (meter) |
| duration | Integer | 구간 소요 시간 (second) |
| roads | Array | 도로 정보 배열 |

#### roads[]
| 필드 | 타입 | 설명 |
|------|------|------|
| distance | Integer | 도로 구간 거리 (meter) |
| duration | Integer | 도로 구간 소요 시간 (second) |
| vertexes | Array[Float] | 좌표 배열 [경도, 위도, 경도, 위도, ...] |

---

## 5. 에러 처리

### 5.1 HTTP 상태 코드
| 코드 | 설명 | 원인 |
|------|------|------|
| 200 | 성공 | - |
| 400 | Bad Request | 잘못된 파라미터 |
| 401 | Unauthorized | 인증 실패 (API 키 오류) |
| 403 | Forbidden | 권한 없음 (제휴 미승인) |
| 500 | Internal Server Error | 서버 오류 |

### 5.2 result_code
| 코드 | 설명 | 처리 방법 |
|------|------|----------|
| 0 | 성공 | 정상 처리 |
| 1 | 경로를 찾을 수 없음 | 출발지/도착지 재확인 |
| 2 | 파라미터 오류 | 요청 파라미터 검증 |
| 3 | 서비스 오류 | 재시도 또는 고객센터 문의 |

### 5.3 에러 응답 예시
```json
{
  "trans_id": "20251109123456789",
  "routes": [
    {
      "result_code": 1,
      "result_message": "경로를 찾을 수 없습니다."
    }
  ]
}
```

---

## 6. TMAP과의 비교

### 6.1 API 차이점
| 항목 | TMAP | 카카오 |
|------|------|--------|
| **Base URL** | `https://apis.openapi.sk.com` | `https://apis-navi.kakaomobility.com` |
| **인증** | appKey 쿼리 파라미터 | Authorization 헤더 |
| **좌표 형식** | 경도,위도 | 경도,위도 (동일) |
| **경유지** | passList | waypoints (\| 구분) |
| **우선순위** | searchOption | priority |
| **속도 설정** | speed | default_speed |
| **응답 구조** | features[] | routes[].sections[] |

### 6.2 마이그레이션 매핑

#### 요청 파라미터
| TMAP | 카카오 | 변환 |
|------|--------|------|
| startX, startY | origin | "{startX},{startY}" |
| endX, endY | destination | "{endX},{endY}" |
| passList | waypoints | split('_').join('\|') |
| searchOption | priority | 0→DISTANCE, 10→MAIN_STREET |
| speed | default_speed | 동일 |

#### 응답 필드
| TMAP | 카카오 | 변환 |
|------|--------|------|
| features[].properties.totalDistance | routes[0].summary.distance | 직접 매핑 |
| features[].properties.totalTime | routes[0].summary.duration | 초 단위로 변환 |
| features[].geometry.coordinates | sections[].roads[].vertexes | 평탄화 필요 |

---

## 7. 구현 가이드

### 7.1 Repository 구조 (SafeLight 기준)

#### 1) NavigatorRepository Interface (domain/repositories/)
```dart
abstract class NavigatorRepository {
  /// 카카오 보행자 길찾기
  Future<RouteEntity> getWalkingRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    RoutePriority priority = RoutePriority.distance,
    double? defaultSpeed,
  });
}
```

#### 2) NavigatorRepositoryImpl (data/repositories/)
```dart
class NavigatorRepositoryImpl implements NavigatorRepository {
  final KakaoNavigatorDataSource _kakaoDataSource;

  @override
  Future<RouteEntity> getWalkingRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    RoutePriority priority = RoutePriority.distance,
    double? defaultSpeed,
  }) async {
    try {
      final response = await _kakaoDataSource.getWalkingDirections(
        origin: '${origin.longitude},${origin.latitude}',
        destination: '${destination.longitude},${destination.latitude}',
        waypoints: waypoints?.map((w) => '${w.longitude},${w.latitude}').join('|'),
        priority: priority == RoutePriority.distance ? 'DISTANCE' : 'MAIN_STREET',
        summary: false,
        defaultSpeed: defaultSpeed,
      );

      return _mapToRouteEntity(response);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  RouteEntity _mapToRouteEntity(Map<String, dynamic> json) {
    final route = json['routes'][0];
    final summary = route['summary'];

    // vertexes 평탄화
    final List<LatLng> coordinates = [];
    for (var section in route['sections']) {
      for (var road in section['roads']) {
        final vertexes = road['vertexes'] as List;
        for (int i = 0; i < vertexes.length; i += 2) {
          coordinates.add(LatLng(vertexes[i + 1], vertexes[i]));
        }
      }
    }

    return RouteEntity(
      distance: summary['distance'],
      duration: summary['duration'],
      coordinates: coordinates,
    );
  }
}
```

#### 3) KakaoNavigatorDataSource (data/sources/)
```dart
class KakaoNavigatorDataSource {
  final Dio _dio;
  static const String _baseUrl = 'https://apis-navi.kakaomobility.com';
  static const String _apiKey = '1cdd32ab3a57b7a5c671f3dd43cb097e'; // SafeLight REST API 키

  Future<Map<String, dynamic>> getWalkingDirections({
    required String origin,
    required String destination,
    String? waypoints,
    String priority = 'DISTANCE',
    bool summary = false,
    double? defaultSpeed,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/affiliate/walking/v1/directions',
      queryParameters: {
        'origin': origin,
        'destination': destination,
        if (waypoints != null) 'waypoints': waypoints,
        'priority': priority,
        'summary': summary,
        if (defaultSpeed != null) 'default_speed': defaultSpeed,
      },
      options: Options(
        headers: {
          'Authorization': 'KakaoAK $_apiKey',
          'service': 'SafeLight',
          'accept': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['routes'][0]['result_code'] != 0) {
        throw ServerException(
          message: data['routes'][0]['result_message'],
        );
      }
      return data;
    } else {
      throw ServerException(
        message: 'HTTP ${response.statusCode}: ${response.statusMessage}',
      );
    }
  }
}
```

### 7.2 DI 설정 (get_it)
```dart
// core/di/injection.dart
void setupNavigatorDependencies() {
  // DataSource
  sl.registerLazySingleton<KakaoNavigatorDataSource>(
    () => KakaoNavigatorDataSource(sl<Dio>()),
  );

  // Repository
  sl.registerLazySingleton<NavigatorRepository>(
    () => NavigatorRepositoryImpl(sl<KakaoNavigatorDataSource>()),
  );

  // UseCase
  sl.registerLazySingleton<GetWalkingRouteUseCase>(
    () => GetWalkingRouteUseCase(sl<NavigatorRepository>()),
  );
}
```

### 7.3 사용 예시 (BLoC)
```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final GetWalkingRouteUseCase _getWalkingRoute;

  Future<void> _onSearchRoute(SearchRouteEvent event, Emitter emit) async {
    emit(SearchLoading());

    final result = await _getWalkingRoute(
      RouteParams(
        origin: event.origin,
        destination: event.destination,
        priority: RoutePriority.distance,
        defaultSpeed: 4.0, // 시각장애인 보행 속도
      ),
    );

    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (route) => emit(SearchSuccess(route)),
    );
  }
}
```

### 7.4 환경 변수 관리
```dart
// .env 파일
KAKAO_REST_API_KEY=your_kakao_rest_api_key_here

// lib/core/config/env.dart
class Env {
  static const kakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
    defaultValue: '',
  );
}
```

### 7.5 테스트 체크리스트
- [ ] API 키 발급 및 설정
- [ ] 제휴 신청 완료 확인
- [ ] 기본 경로 탐색 테스트
- [ ] 경유지 포함 경로 테스트
- [ ] 에러 처리 테스트 (401, 403, 500)
- [ ] result_code != 0 처리 테스트
- [ ] 좌표 변환 정확성 검증
- [ ] TMAP 대비 성능/정확도 비교

---

## 8. 주의사항

### 8.1 API 제약사항
- ⚠️ 제휴 API이므로 사전 승인 필요
- ⚠️ 경유지는 최대 5개까지
- ⚠️ 일일 호출 제한이 있을 수 있음 (제휴 조건 확인)

### 8.2 🚨 **시각장애인 앱 사용 불가 사유** (중요!)

**카카오 보행자 길찾기 API는 SafeLight 같은 시각장애인 앱에 사용할 수 없습니다.**

#### 제공되지 않는 필수 정보:

| 정보 | 시각장애인 필수도 | TMAP 제공 여부 | 카카오 제공 여부 |
|------|------------------|----------------|-----------------|
| **턴바이턴 안내** (좌회전, 우회전) | 🔴 필수 | ✅ | ❌ |
| **건물명/랜드마크** | 🔴 필수 | ✅ | ❌ |
| **안내 문구** (description) | 🔴 필수 | ✅ | ❌ |
| **횡단보도 정보** | 🔴 필수 | ✅ | ❌ |
| **분기점 정보** (isBranch) | 🔴 필수 | ✅ | ❌ |

#### 카카오 API가 제공하는 것:
- ✅ 좌표 배열 (vertexes)
- ✅ 거리/시간 (distance, duration)
- ❌ 방향 안내 없음
- ❌ 랜드마크 없음
- ❌ 횡단보도 정보 없음

#### 실제 응답 예시 (공식 문서):
```json
{
  "routes": [{
    "sections": [{
      "roads": [{
        "distance": 20,
        "duration": 18,
        "vertexes": [126.992, 37.564, 126.993, 37.565]
        // ❌ description 없음
        // ❌ turn_type 없음
        // ❌ landmark 없음
        // ❌ crosswalk 없음
      }]
    }]
  }]
}
```

#### TMAP API 응답 비교 (SafeLight 실제 사용):
```dart
BranchInfo{
  point: LatLng(37.497223, 126.906985),
  isBranch: true,  // ✅ 분기점
  description: "대흥인테리어에서 좌회전 후 108m 이동",  // ✅ 턴바이턴
  crosswalk: false,  // ✅ 횡단보도
  waypoint: false
}
```

> 📌 **상세 비교 분석**: `docs/API/카카오 vs TMAP 비교 분석 - 시각장애인 앱 적합성.md` 참고

### 8.3 일반 보행자 앱 고려사항
- ✅ default_speed를 3.5~4.0km/h로 설정 (시각장애인 평균 보행 속도)
- ✅ priority를 MAIN_STREET로 설정하여 안전한 큰 도로 우선
- ⚠️ 턴바이턴 안내는 좌표로 직접 계산 필요 (정확도 낮음)

### 8.4 마이그레이션 시 검증 항목
1. 경로 거리/시간 정확도 비교
2. 좌표 배열 순서 검증 (경도→위도)
3. TTS 음성 안내와의 호환성
4. IMU 센서 기반 위치 추적과의 연동
5. BLE 횡단보도 연동 유지

---

## 9. 참고 자료
- 공식 문서: https://developers.kakaomobility.com/docs/affiliate/walking/directions/
- 카카오 개발자센터: https://developers.kakao.com
- REST API 키 발급: https://developers.kakao.com/console/app

---

## 10. 프로젝트 정보 요약

### 카카오 계정
- **App 이름**: safelight
- **App ID**: 1328836
- **개발자 계정**: snyfromwcl25@gmail.com

### 사용 API 키
- **REST API 키**: `1cdd32ab3a57b7a5c671f3dd43cb097e`

### API 엔드포인트
- **기본 길찾기**: `/affiliate/walking/v1/directions`
- **Delivery API**: `/v1/api/navi-affiliate/walking/delivery` (추가 옵션)

---

*Last Updated: 2025-11-11*
*Author: SafeLight Development Team*


  📌 다음 작업 제안

  1. API 키 발급 (카카오 개발자센터)
  2. 제휴 신청 (affiliate API 사용 권한)
  3. DataSource 구현 (문서 7.1절 참고)
  4. 기존 TMAP 코드와 비교 테스트