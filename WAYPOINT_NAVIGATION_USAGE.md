# 경유지 네비게이션 기능 사용법

## 개요

Tmap 보행자 API에서는 공식적으로 경유지가 지원되지 않기 때문에, 출발지→경유지들→도착지 순서대로 각 구간별로 API를 호출하여 전체 경로를 합치는 기능을 구현했습니다.

## 주요 기능

### 1. NavigationApiService 확장

#### `fetchMultiWaypointPath` 메서드
- 경유지를 포함한 전체 경로를 구간별로 API 호출하여 합치는 메서드
- 중복 포인트(경유지 좌표) 처리 자동화
- 총 거리, 총 시간 계산

```dart
final apiService = NavigationApiService();
final waypoints = [
  LatLng(37.55677, 126.92365), // 출발
  LatLng(37.55395, 126.92775), // 경유지1
  LatLng(37.55337, 126.92577), // 경유지2
  LatLng(37.55279, 126.92432), // 도착
];

final result = await apiService.fetchMultiWaypointPath(
  waypoints: waypoints,
  chooseRoute: "0", // 0: 추천, 4: 추천+대로우선, 10: 최단, 30: 최단거리+계단제외
);

print('총 거리: ${result.totalDistance}m');
print('총 시간: ${result.totalTime}초');
```

#### `MultiWaypointPathResult` 클래스
경로 결과를 담는 클래스:
- `paths`: 전체 경로 좌표 리스트
- `branchInfo`: 브랜치 정보 리스트
- `totalDistance`: 총 거리 (미터)
- `totalTime`: 총 시간 (초)
- `segmentDetails`: 각 구간별 상세 정보

### 2. NaverMapViewController 확장

#### `startNavigationWithWaypoints` 메서드
경유지를 포함한 네비게이션을 시작하는 메서드:

```dart
final controller = Get.find<NaverMapViewController>();
final waypoints = [
  LatLng(37.55677, 126.92365), // 출발
  LatLng(37.55395, 126.92775), // 경유지1
  LatLng(37.55337, 126.92577), // 경유지2
  LatLng(37.55279, 126.92432), // 도착
];

await controller.startNavigationWithWaypoints(waypoints);
```

#### `loadMultiWaypointPathData` 메서드
경유지를 포함한 전체 경로를 로드하는 메서드:

```dart
await controller.loadMultiWaypointPathData(waypoints, "0");
```

#### `addWaypointOverlays` 메서드
경유지를 포함한 경로 오버레이를 지도에 추가:
- 출발지: 초록색 "출발" 마커
- 경유지: 주황색 "경유1", "경유2" 마커
- 도착지: 빨간색 "도착" 마커
- 전체 경로: 파란색 라인

## 사용 예시

### 1. 기본 사용법

```dart
// 1. 경유지 좌표 설정
final waypoints = [
  LatLng(37.55677, 126.92365), // 출발지
  LatLng(37.55395, 126.92775), // 경유지1
  LatLng(37.55337, 126.92577), // 경유지2
  LatLng(37.55279, 126.92432), // 도착지
];

// 2. 네비게이션 시작
final controller = Get.find<NaverMapViewController>();
await controller.startNavigationWithWaypoints(waypoints);
```

### 2. API 직접 호출

```dart
final apiService = NavigationApiService();

try {
  final result = await apiService.fetchMultiWaypointPath(
    waypoints: waypoints,
    chooseRoute: "0", // 추천 경로
  );
  
  print('경로 합치기 완료:');
  print('- 총 거리: ${result.totalDistance}m');
  print('- 총 시간: ${result.totalTime}초');
  print('- 총 포인트: ${result.paths.length}개');
  print('- 구간 수: ${result.segmentDetails.length}개');
  
  // 각 구간별 정보 확인
  for (var segment in result.segmentDetails) {
    print('구간 ${segment['segmentIndex']}: ${segment['distance']}m, ${segment['time']}초');
  }
  
} catch (e) {
  print('경로 조회 실패: $e');
}
```

## 테스트 방법

1. 앱을 실행합니다.
2. 하단 네비게이션에서 "홈" 또는 "설정" 탭을 선택합니다.
3. "경유지 네비게이션 테스트" 버튼을 클릭합니다.
4. 지도에서 경유지를 포함한 전체 경로가 표시되는지 확인합니다.

## 주요 특징

### 1. 중복 포인트 처리
- 각 구간의 연결점(경유지)에서 중복되는 좌표를 자동으로 제거
- 첫 번째 구간: 모든 포인트 추가
- 이후 구간: 첫 번째 포인트(경유지) 제외하고 추가

### 2. 에러 처리
- 각 구간별 API 호출 실패 시 적절한 에러 메시지 제공
- 최소 2개 지점 검증
- 네트워크 오류 및 API 응답 오류 처리

### 3. 음성 안내
- 경로 로드 완료 시 총 거리와 시간 음성 안내
- 에러 발생 시 음성 알림

### 4. 시각적 피드백
- 출발지, 경유지, 도착지를 구분하는 색상별 마커
- 전체 경로를 나타내는 파란색 라인
- 로딩 상태 및 완료 메시지

## 경로 옵션

- `"0"`: 추천 경로
- `"4"`: 추천 + 대로우선
- `"10"`: 최단 경로
- `"30"`: 최단거리 + 계단제외

## 제한사항

1. Tmap API 호출 횟수가 증가합니다 (구간 수만큼)
2. 네트워크 상태에 따라 전체 로딩 시간이 길어질 수 있습니다
3. 각 구간별 API 호출이 순차적으로 진행됩니다

## 향후 개선 사항

1. 병렬 API 호출로 성능 최적화
2. 캐싱 기능 추가
3. 경유지 순서 최적화 알고리즘
4. 실시간 경로 재계산 지원 