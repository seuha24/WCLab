# IMU 위치추적 기능 명세서

## 개요
SafeLight 애플리케이션의 IMU(Inertial Measurement Unit) 위치추적 시스템은 GPS 신호가 약하거나 불안정한 환경에서도 사용자의 정확한 위치를 추적할 수 있는 고급 기능입니다. 가속도계, 자이로스코프, 나침반 센서를 통합하여 상대좌표를 계산하고 이를 절대좌표(위도/경도)로 변환하는 Dead Reckoning 방식을 구현합니다.

## 핵심 기술

### 1. Dead Reckoning (추측 항법)
- **원리**: 초기 위치에서 시작하여 이동 방향과 거리를 누적 계산
- **활용**: GPS 신호 불량 시 IMU 센서로 위치 추적 지속
- **정확도**: GPS 정확도 15m 이상일 때 자동 전환

### 2. 센서 융합 (Sensor Fusion)
- **가속도계**: 선형 움직임 감지
- **자이로스코프**: 회전 움직임 감지
- **나침반**: 절대 방향 제공
- **GPS**: 절대 위치 기준점 제공

## 시스템 구조

### 1. 센서 데이터 수집
```dart
// 가속도계 (UserAccelerometer)
- 샘플링 주기: 20ms
- 측정값: x, y, z 축 가속도 (m/s²)
- 중력 제외된 순수 가속도

// 자이로스코프 (Gyroscope)
- 샘플링 주기: 20ms
- 측정값: x, y, z 축 회전 속도 (rad/s)
- Yaw rate 계산용

// 나침반 (Compass)
- 측정값: heading (0-360도)
- 절대 방향 기준
```

### 2. 좌표 시스템

#### 2.1 상대좌표 (Relative Coordinates)
- **px, py**: 미터 단위의 상대 위치
- **원점**: 초기 GPS 위치 또는 사용자 지정 위치
- **계산**: 가속도 적분 → 속도 → 위치

#### 2.2 절대좌표 (Absolute Coordinates)
- **위도/경도**: WGS84 좌표계
- **변환**: 상대좌표 + 초기 위치 → 절대좌표
- **지구 반경**: 6371km 사용

## 주요 알고리즘

### 1. 가속도 적분 (Acceleration Integration)

#### 1.1 속도 계산
```dart
velocityX += (currentAccX - prevAccX) * dt
velocityY += (currentAccY - prevAccY) * dt
```

#### 1.2 위치 계산
```dart
px += (currentSpeed * cos(yawRate))
py += (currentSpeed * sin(yawRate))
```

#### 1.3 속도 크기
```dart
currentSpeed = sqrt(velocityX² + velocityY²)
```

### 2. 노이즈 필터링

#### 2.1 가속도 필터링
- **임계값**: 0.06 m/s²
- **목적**: 미세 진동 제거
- **처리**: 임계값 이하 → 속도 0으로 리셋

#### 2.2 가중 이동평균 필터 (Weighted Average Filter)
```dart
class WeightedAverageFilter {
  - 큐 크기: 5
  - 가중치: [0.1, 0.2, 0.3, 0.4, 0.5]
  - 최근 데이터에 높은 가중치
}
```

#### 2.3 자이로스코프 필터링
- **임계값**: 0.3 rad/s (약 17도/s)
- **목적**: 미세 회전 노이즈 제거
- **보정**: iPhone12 기준 (1/130) * (π/180) rad

### 3. Yaw Rate 계산

#### 3.1 회전 각속도 누적
```dart
yawRate += -(yawRatePerDt + addYawRateNoise(0))
if (yawRate >= 2π || yawRate <= -2π) {
  yawRate = 0  // 오버플로우 방지
}
```

#### 3.2 나침반 보정
```dart
yawRate2 = turnUpdate2(bearingToPoint, compassValue) * angleToRadian
```

### 4. 상대좌표 → 절대좌표 변환

#### 4.1 거리 및 방향 계산
```dart
distanceKm = sqrt(px² + py²) / 1000.0
bearing = atan2(py, px) * radianToAngle
```

#### 4.2 새로운 위경도 계산 (Haversine 공식)
```dart
Map<String, double> calLatLng(
  double startLat, double startLng, 
  double bearing, double distanceKm
) {
  const earthRadiusKm = 6371.0
  // 구면 삼각법 적용
  newLatRad = asin(sin(startLatRad) * cos(distanceRad) +
              cos(startLatRad) * sin(distanceRad) * cos(bearingRad))
  newLngRad = startLngRad + atan2(...)
  return {'latitude': newLat, 'longitude': newLng}
}
```

## GPS/IMU 전환 로직

### 1. 전환 조건
```dart
if (position.accuracy >= 15) {
  isGps = false  // IMU 사용
  // 가중평균 필터 적용
  velocityX = _filteringX.calculateWeightedAverage()
  velocityY = _filteringY.calculateWeightedAverage()
  current_latitude = newlatitude   // IMU 계산 위도
  current_longitude = newlongitude // IMU 계산 경도
} else {
  isGps = true   // GPS 사용
  current_latitude = position.latitude   // GPS 위도
  current_longitude = position.longitude // GPS 경도
  resetSpeedUtilsValue() // IMU 변수 초기화
}
```

### 2. 초기화 프로세스
```dart
initialLatitude = current_latitude
initialLongitude = current_longitude
yawRate = compassValue * angleToRadian
px = 0.0
py = 0.0
```

## 경로 추적 및 보정

### 1. 경계 이탈 감지

#### 1.1 거리 기반 감지
- **경계 범위**: 1.5m (boundary)
- **재검색 범위**: 15m (searchNewPathBoundary)
- **계산**: 점-선 거리 또는 점-점 거리 중 최소값

#### 1.2 이탈 처리
```dart
if (distanceToPath > boundary) {
  outOfBound = true
  // 진동 피드백 100ms
  // 음성 안내 (시계 방향)
}
```

### 2. 경로 재검색

#### 2.1 출발지 이탈
- **기준**: 출발지에서 50m 이상 벗어남
- **대기 시간**: 10초
- **처리**: 현재 위치를 새 출발지로 설정

#### 2.2 경로 이탈
- **기준**: 경로에서 15m 이상 벗어남
- **대기 시간**: 10초 (5회 연속 감지)
- **처리**: 현재 위치에서 목적지까지 재검색

### 3. 커스텀 출발지 설정

#### 3.1 수동 위치 보정
```dart
void setCustomStartLocationFromCamera() {
  if (!isGps) {  // GPS 불량 시만 활성화
    // 지도 중심을 출발지로 설정
    cameraPosition = mapController.getCameraPosition()
    targetLat = cameraPosition.target.latitude
    targetLng = cameraPosition.target.longitude
    
    // 상대좌표 재계산
    updateRelativeCoordinates(
      current_latitude, current_longitude,
      targetLat, targetLng
    )
    
    // 현재 위치 갱신
    current_latitude = targetLat
    current_longitude = targetLng
  }
}
```

#### 3.2 상대좌표 업데이트
```dart
Map<String, double> latLonToXY(
  double baseLat, double baseLng,
  double targetLat, double targetLng
) {
  deltaLat = targetLat - baseLat
  deltaLon = targetLng - baseLng
  avgLat = (baseLat + targetLat) / 2.0
  x = deltaLon * 111320 * cos(avgLat * π/180)
  y = deltaLat * 111320
  return {'x': x, 'y': y}
}
```

## 방향 안내 시스템

### 1. 시계 방향 안내

#### 1.1 각도 계산
```dart
double angleToTarget(...) {
  // 구면 삼각법으로 3점 각도 계산
  breakPointAngle = breakPoint(...)
  if (boundaryExit > 0) {
    guidanceAngle = (baseAngle + yawRateTurn2) % 360
  } else {
    guidanceAngle = (baseAngle - yawRateTurn2) % 360
  }
  return guidanceAngle
}
```

#### 1.2 방향 라벨 변환
```dart
String getGuidanceDirection(...) {
  // -15 ~ +15도: 12시
  // 15 ~ 45도: 1시
  // ...
  directionLabels = ['12시', '1시', ..., '11시']
  direction = ((guidanceAngle + 15) % 360) ~/ 30
  return directionLabels[direction]
}
```

### 2. 경로 정렬 피드백

#### 2.1 진동 피드백
- **조건**: 경로 방향과 현재 방향 차이 18도 이내
- **진동**: 200ms
- **목적**: 올바른 방향 알림

#### 2.2 음성 안내
- 경계 이탈 시 방향 안내
- 분기점 15m 전 사전 안내
- 횡단보도 접근 시 경고

## 성능 최적화

### 1. 센서 데이터 처리

#### 1.1 샘플링 주기
- **가속도계/자이로**: 20ms (50Hz)
- **GPS 업데이트**: 100ms (10Hz)
- **경로 체크**: 2초 (0.5Hz)

#### 1.2 메모리 관리
```dart
List<StreamSubscription> _streamSubscriptions = []
// onClose 시 모든 구독 취소
_streamSubscriptions.forEach((sub) => sub.cancel())
```

### 2. 계산 최적화

#### 2.1 거리 계산 캐싱
- Haversine 공식 결과 재사용
- 윈도우 기반 분기점 검색 (5개)

#### 2.2 조건부 업데이트
- 지도 모드별 선택적 업데이트
- 임계값 기반 필터링

## 정확도 및 한계

### 1. 정확도 요인

#### 1.1 센서 정확도
- **가속도계**: ±0.01 m/s²
- **자이로스코프**: ±0.001 rad/s
- **나침반**: ±5도

#### 1.2 누적 오차
- **드리프트**: 시간에 따른 오차 누적
- **보정**: GPS 신호 복구 시 자동 리셋

### 2. 사용 제한

#### 2.1 환경 요인
- 자기장 간섭 (금속 구조물)
- 진동이 심한 환경
- 급격한 온도 변화

#### 2.2 하드웨어 요구사항
- 3축 가속도계 필수
- 3축 자이로스코프 필수
- 디지털 나침반 필수

## 플랫폼별 특이사항

### iOS
- **나침반 지원**: 완전 지원
- **센서 정확도**: 높음
- **필터 보정**: iPhone12 기준 최적화

### Android
- **나침반 지원**: 기기별 상이
- **센서 정확도**: 제조사별 차이
- **캘리브레이션**: 수동 필요할 수 있음

## 테스트 시나리오

### 1. GPS 전환 테스트
- GPS 정확도 15m 경계 테스트
- 실내/실외 전환 테스트
- 터널 진입/진출 테스트

### 2. IMU 정확도 테스트
- 직선 100m 이동 오차 측정
- 360도 회전 후 복귀 테스트
- 계단 오르내리기 테스트

### 3. 경로 이탈 테스트
- 의도적 경로 이탈 후 재검색
- 출발지 변경 테스트
- 급격한 방향 전환 테스트

## 개발 현황

### 완료된 기능
- [x] 3축 센서 데이터 수집
- [x] 가속도 적분 알고리즘
- [x] 가중평균 필터 구현
- [x] 상대/절대 좌표 변환
- [x] GPS/IMU 자동 전환
- [x] 경로 이탈 감지
- [x] 시계 방향 안내

### 개선 필요사항
- [ ] 칼만 필터 적용
- [ ] 기압계 연동 (고도 추적)
- [ ] 머신러닝 기반 보정
- [ ] 걸음 감지 알고리즘
- [ ] 배터리 최적화

## 문제 해결 가이드

### IMU 추적이 부정확할 때
1. 나침반 캘리브레이션 (8자 그리기)
2. 앱 재시작으로 센서 리셋
3. GPS 신호 복구 대기
4. 수동 위치 보정 사용

### 경로 이탈이 자주 발생할 때
1. 경계 범위 조정 (1.5m → 3m)
2. 필터 임계값 조정
3. GPS 정확도 기준 완화

### 센서 데이터 수집 실패
1. 앱 권한 확인 (위치, 모션)
2. 기기 센서 지원 확인
3. 백그라운드 제한 해제

## 참고 자료

### 1. 알고리즘
- Dead Reckoning Navigation
- Haversine Formula
- Weighted Moving Average
- Sensor Fusion Techniques

### 2. 표준
- WGS84 좌표계
- IMU 센서 표준 (IEEE)
- 지구 타원체 모델

### 3. 라이브러리
- Flutter sensors_plus
- Flutter compass
- Geolocator

## 보안 및 프라이버시

### 1. 데이터 보호
- 위치 데이터 로컬 처리
- 센서 데이터 비저장
- 경로 이력 비보관

### 2. 권한 관리
- 위치 권한 (필수)
- 모션 센서 권한 (iOS)
- 백그라운드 위치 (선택)

## 참고사항
- IMU 추적은 보조 수단으로 사용
- GPS 신호 복구 시 자동 전환
- 장시간 사용 시 배터리 소모 증가
- 정기적인 캘리브레이션 권장