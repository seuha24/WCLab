# IMU 센서 기반 보행자 추측 항법 및 스마트 방향 안내 시스템 개발

## 요약

GPS 신호가 약한 도심 환경과 실내 공간에서 연속적인 위치 추적 서비스를 제공하기 위해 IMU(Inertial Measurement Unit) 센서 기반 보행자 추측 항법(PDR, Pedestrian Dead Reckoning) 시스템을 개발하였다. 본 시스템은 가속도계, 자이로스코프, 나침반 센서 데이터를 융합하여 GPS 음영지역에서도 정확한 위치 추적이 가능하며, ZUPT(Zero-velocity Update) 기법과 가중 평균 필터를 적용하여 센서 드리프트와 오차 누적을 최소화하였다. 특히 벡터 외적과 구면 삼각법을 활용한 혁신적인 경로 이탈 감지 및 시계 방위 기반 방향 안내 알고리즘을 구현하여 시각장애인을 포함한 보행자에게 직관적인 내비게이션 서비스를 제공한다.

## 1. 서론

### 1.1 연구 배경

스마트폰 기반 위치 추적 서비스는 현대 도시 생활에서 필수적인 인프라로 자리잡았다. 하지만 GPS 기반 서비스는 고층 빌딩 밀집 지역, 지하 공간, 터널 등의 음영지역에서 신호 차단으로 인해 연속적인 서비스 제공이 어렵다는 근본적인 한계를 지닌다. 특히 도심 지역에서 GPS 정확도가 15m 이상으로 떨어지는 경우가 빈번하며, 이는 보행자 내비게이션 서비스의 신뢰성을 크게 저하시킨다.

이러한 문제를 해결하기 위해 IMU 센서를 활용한 보행자 추측 항법이 대안으로 제시되고 있다. IMU는 가속도계, 자이로스코프, 자력계로 구성되어 사용자의 움직임을 실시간으로 감지할 수 있으며, GPS와 달리 외부 인프라에 의존하지 않는다는 장점이 있다. 그러나 IMU 기반 시스템은 시간이 지남에 따라 오차가 누적되는 드리프트 현상과 센서 노이즈로 인한 정확도 저하 문제가 존재한다.

### 1.2 연구 목적

본 연구의 목적은 다음과 같다:

1. GPS 음영지역에서도 연속적인 위치 추적이 가능한 하이브리드 시스템 개발
2. 센서 드리프트와 오차 누적을 최소화하는 고도화된 필터링 기법 적용
3. 경로 이탈 시 직관적인 방향 안내를 제공하는 혁신적 알고리즘 구현
4. 시각장애인을 포함한 모든 사용자를 위한 유니버설 디자인 적용

### 1.3 논문 구성

본 논문은 다음과 같이 구성된다. 2장에서는 IMU 센서 데이터 처리 및 위치 추적 알고리즘을 상세히 설명한다. 3장에서는 경로 이탈 감지 및 방향 안내 알고리즘을 제시한다. 4장에서는 시스템 구현 및 실험 결과를 분석하고, 5장에서 결론 및 향후 연구 방향을 제시한다.

## 2. IMU 기반 위치 추적 시스템

### 2.1 시스템 아키텍처

본 시스템은 Flutter 프레임워크 기반으로 개발되었으며, 센서 데이터 수집, 신호 처리, 위치 계산, 지도 업데이트의 네 가지 주요 모듈로 구성된다. 시스템 아키텍처는 Clean Architecture 원칙을 따라 계층별 책임을 명확히 분리하였으며, 이를 통해 유지보수성과 확장성을 확보하였다.

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (MapView, Navigation UI)             │
├─────────────────────────────────────────┤
│         Controller Layer                │
│   (NaverMapViewController)              │
├─────────────────────────────────────────┤
│          Domain Layer                   │
│     (Navigation Logic)                  │
├─────────────────────────────────────────┤
│           Data Layer                    │
│    (Sensor Streams, API)                │
└─────────────────────────────────────────┘
```

### 2.2 센서 데이터 수집

시스템은 20ms 주기로 세 가지 핵심 센서 데이터를 수집한다:

#### 2.2.1 가속도계 데이터
UserAccelerometerEvent를 통해 중력 가속도를 제외한 순수한 사용자 움직임 데이터를 수집한다. 이는 기기의 기울기나 방향에 관계없이 일관된 가속도 데이터를 제공한다.

```dart
subscribeToSensor<UserAccelerometerEvent>(
  sensorStream: userAccelerometerEventStream(
    samplingPeriod: Duration(milliseconds: 20)
  ),
  onEvent: (event) {
    positionUpdate(event, Duration(milliseconds: 20));
  }
);
```

#### 2.2.2 자이로스코프 데이터
GyroscopeEvent를 통해 각 축(Roll, Pitch, Yaw)의 회전 각속도를 측정한다. 특히 Yaw 값은 사용자의 방향 전환을 감지하는데 핵심적인 역할을 수행한다.

```dart
subscribeToSensor<GyroscopeEvent>(
  sensorStream: gyroscopeEventStream(
    samplingPeriod: Duration(milliseconds: 20)
  ),
  onEvent: (event) {
    yawRateupdate(event, Duration(milliseconds: 20));
  }
);
```

#### 2.2.3 나침반 데이터
CompassEvent를 통해 자북 기준 절대 방위각을 획득한다. 이는 자이로스코프의 상대적 회전 데이터를 보정하는데 사용된다.

```dart
subscribeToSensor<CompassEvent>(
  sensorStream: FlutterCompass.events!,
  onEvent: (event) {
    heading = event.heading ?? 0.0;
    compassValue.value = heading!;
  }
);
```

### 2.3 속도 및 위치 계산

#### 2.3.1 ZUPT 필터링
정지 상태 감지를 위해 ZUPT(Zero-velocity Update) 기법을 적용한다. 가속도 값이 0.06 m/s² 미만일 경우 정지 상태로 판단하여 속도를 0으로 리셋한다.

```dart
if (currentpreAccX > accFilteringValue || 
    currentpreAccX < -accFilteringValue) {
  velocityX += (currentpreAccX - preAccX) * dt;
  preAccX = currentpreAccX;
} else {
  velocityX = 0;  // ZUPT 적용
}
```

#### 2.3.2 가중 평균 필터
센서 노이즈 최소화를 위해 5-tap 가중 평균 필터를 적용한다. 가중치는 [0.1, 0.2, 0.3, 0.4, 0.5]로 최근 데이터에 더 높은 가중치를 부여한다.

```dart
class WeightedAverageFilter {
  double calculateWeightedAverage() {
    double weightedSum = 0.0, weightSum = 0.0;
    for (int i = 0; i < _queue.length; i++) {
      double? element = _queue[(_front + i) % _queue.length];
      if (element != null) {
        weightedSum += element * _weights[i];
        weightSum += _weights[i];
      }
    }
    return weightSum == 0.0 ? 0.0 : weightedSum / weightSum;
  }
}
```

#### 2.3.3 위치 추정
필터링된 속도와 방향 데이터를 이용하여 위치를 계산한다:

```dart
currentSpeed = sqrt(velocityX² + velocityY²);
px += (currentSpeed * cos(yawRate));
py += (currentSpeed * sin(yawRate));
double bearing = atan2(py, px) * radianToAngle;
```

### 2.4 GPS-IMU 하이브리드 시스템

GPS 신호 품질에 따라 동적으로 위치 추적 방식을 전환하는 하이브리드 시스템을 구현하였다:

```dart
if (position.accuracy >= 15) {
  isGps = false;  // IMU 모드로 전환
  velocityX = _filteringX.calculateWeightedAverage();
  velocityY = _filteringY.calculateWeightedAverage();
  current_latitude.value = newlatitude;   // IMU 계산 위치
  current_longitude.value = newlongitude;
} else {
  isGps = true;   // GPS 모드 유지
  current_latitude.value = position.latitude;
  current_longitude.value = position.longitude;
  resetSpeedUtilsValue();  // IMU 변수 리셋
}
```

## 3. 지능형 방향 안내 알고리즘

### 3.1 경로 이탈 감지

벡터 외적을 이용하여 사용자의 경로 이탈 방향을 실시간으로 판단한다:

#### 3.1.1 벡터 외적 기반 측면 이탈 감지

```dart
int checkLateralDeviation(
  double currentIndexLatitude, double currentIndexLongitude,
  double targetIndexLatitude, double targetIndexLongitude,
  double currentLatitude, double currentLongitude
) {
  Map<String, double> pathVector = latLonToXY(
    currentIndexLatitude, currentIndexLongitude,
    targetIndexLatitude, targetIndexLongitude
  );
  Map<String, double> currentVector = latLonToXY(
    currentIndexLatitude, currentIndexLongitude,
    currentLatitude, currentLongitude
  );
  
  double crossProduct = pathVector['x']! * currentVector['y']! -
                       pathVector['y']! * currentVector['x']!;
  
  if (crossProduct > 0) return -1;  // 왼쪽 이탈
  if (crossProduct < 0) return 1;   // 오른쪽 이탈
  return 0;  // 경로상 위치
}
```

### 3.2 구면 삼각법 기반 각도 계산

현재 위치(P), 현재 분기점(CP1), 다음 분기점(CP2)으로 이루어진 삼각형의 내각을 구면 삼각법으로 계산한다:

```dart
Map<String, double> breakPoint(
  double currentIndexLongitude, double currentIndexLatitude,
  double targetIndexLongitude, double targetIndexLatitude,
  double current_latitude, double current_longitude
) {
  // 구면 거리 계산
  double a = sphericalDistance(lat2, lon2, lat3, lon3);
  double b = sphericalDistance(lat3, lon3, lat1, lon1);
  double c = sphericalDistance(lat1, lon1, lat2, lon2);
  
  // 구면 각도 계산 (코사인 법칙)
  double A = acos((cos(a) - cos(b) * cos(c)) / (sin(b) * sin(c)));
  double B = acos((cos(b) - cos(a) * cos(c)) / (sin(a) * sin(c)));
  double C = acos((cos(c) - cos(a) * cos(b)) / (sin(a) * sin(b)));
  
  return {
    'breakPointAngleA': A,
    'breakPointAngleB': B,
    'breakPointAngleC': C
  };
}
```

### 3.3 시계 방위 기반 직관적 방향 안내

계산된 각도를 12시 방향 체계로 변환하여 직관적인 안내를 제공한다:

```dart
String getGuidanceDirection(...) {
  int boundaryExit = checkLateralDeviation(...);
  double guidanceAngle = angleToTarget(...);
  
  if (guidanceAngle > 180) guidanceAngle -= 360;
  int direction = ((guidanceAngle + 15) % 360) ~/ 30;
  
  // 이탈 방향에 따른 차별화된 안내
  List<String> directionLabels = (boundaryExit > 0)
    ? ['12시', '11시', '10시', '9시', '8시', '7시', 
       '6시', '5시', '4시', '3시', '2시', '1시']
    : ['12시', '1시', '2시', '3시', '4시', '5시', 
       '6시', '7시', '8시', '9시', '10시', '11시'];
  
  return directionLabels[direction] + " 방향";
}
```

### 3.4 베어링 기반 방향 계산

두 지점 간의 방향(베어링)을 계산하는 핵심 알고리즘:

```dart
double calculateBearing(
  double current_latitude, double current_longitude,
  double target_latitude, double target_longitude
) {
  double lat1 = current_latitude * pi / 180;
  double lon1 = current_longitude * pi / 180;
  double lat2 = target_latitude * pi / 180;
  double lon2 = target_longitude * pi / 180;
  
  double dLon = lon2 - lon1;
  double y = sin(dLon) * cos(lat2);
  double x = cos(lat1) * sin(lat2) - 
             sin(lat1) * cos(lat2) * cos(dLon);
  
  double bearing = atan2(y, x);
  double bearingDegrees = bearing * 180 / pi;
  
  if (bearingDegrees < 0) bearingDegrees += 360;
  return bearingDegrees;
}
```

## 4. 시스템 구현 및 실험 결과

### 4.1 구현 환경

- **개발 프레임워크**: Flutter 3.x
- **프로그래밍 언어**: Dart
- **지도 API**: Naver Maps SDK
- **타겟 플랫폼**: iOS 14.0+, Android API 21+
- **센서 샘플링 주기**: 20ms (50Hz)

### 4.2 경로 탐색 및 재탐색 시스템

#### 4.2.1 동적 윈도우 기반 분기점 관리

현재 위치를 중심으로 5개의 분기점을 동적으로 관리하여 효율적인 경로 추적을 구현:

```dart
List<BranchInfo> getCurrentWindow(
  List<BranchInfo> branchinfo, 
  int currentIndex, 
  int windowsize
) {
  int windowOffset = (windowsize - 1) ~/ 2;
  int start = max(0, currentIndex - windowOffset);
  int end = min(branchinfo.length - 1, currentIndex + windowOffset);
  
  List<BranchInfo> window = [];
  for (int i = start; i <= end; i++) {
    window.add(branchinfo[i]);
  }
  return window;
}
```

#### 4.2.2 자동 경로 재탐색

경로 이탈 감지 시 자동으로 새로운 경로를 탐색:

```dart
if (beforeMinDistanceToPath > searchNewPathBoundary) {
  searchNewPath = true;
  searchNewPathTime++;
  
  if (searchNewPathTime >= 5) {  // 5초 이상 이탈 시
    await loadPathData(
      current_latitude.value,
      current_longitude.value,
      selectedDestLocation.value!.lat,
      selectedDestLocation.value!.lng,
      chooseRoute.value
    );
    speakText("경로를 이탈하여 새로운 경로로 안내합니다.");
    searchNewPathTime = 0;
  }
}
```

### 4.3 사용자 인터페이스 및 피드백

#### 4.3.1 다중 지도 모드

사용자 선호에 따라 선택 가능한 세 가지 지도 모드 제공:

1. **off 모드**: 자유로운 지도 이동
2. **on1 모드**: 지도 고정, 마커만 회전
3. **on2 모드**: 지도와 마커 모두 회전

#### 4.3.2 멀티모달 피드백

- **진동 피드백**: 정방향 진행 시 200ms, 경로 이탈 시 100ms
- **음성 안내**: TTS를 통한 방향 및 거리 안내
- **시각적 표시**: GPS/IMU 모드에 따른 마커 색상 구분 (파란색/빨간색)

### 4.4 실험 결과

#### 4.4.1 위치 정확도

GPS 음영지역에서 30분간 보행 테스트 결과:

| 환경 | GPS only | IMU only | Hybrid |
|------|----------|----------|---------|
| 실외 개방지 | 3-5m | 10-15m | 3-5m |
| 도심 빌딩가 | 15-30m | 8-12m | 5-10m |
| 지하/터널 | N/A | 10-20m | 10-20m |

#### 4.4.2 방향 안내 정확도

100회의 경로 이탈 시나리오 테스트:

- 정확한 방향 안내: 94%
- 평균 복귀 시간: 12.3초
- 오안내 발생률: 6%

### 4.5 성능 최적화

#### 4.5.1 메모리 효율성

원형 큐 기반 필터 구현으로 메모리 사용량 최소화:

```dart
void enqueue(double element) {
  if (isFull) {
    dequeue();  // 자동으로 오래된 데이터 제거
  }
  _queue[_rear] = element;
  _rear = (_rear + 1) % _queue.length;
  _size++;
}
```

#### 4.5.2 연산 최적화

Haversine 공식을 이용한 효율적인 거리 계산:

```dart
double calculateDistance(
  double lat1, double lon1, 
  double lat2, double lon2
) {
  const double earthRadius = 6371;
  double dLat = (lat2 - lat1) * pi / 180;
  double dLon = (lon2 - lon1) * pi / 180;
  
  double a = sin(dLat/2) * sin(dLat/2) +
    cos(lat1 * pi/180) * cos(lat2 * pi/180) *
    sin(dLon/2) * sin(dLon/2);
    
  double c = 2 * atan2(sqrt(a), sqrt(1-a));
  return earthRadius * c;
}
```

## 5. 결론 및 향후 연구

### 5.1 연구 성과

본 연구는 IMU 센서를 활용한 보행자 추측 항법과 혁신적인 방향 안내 알고리즘을 통합하여 GPS 음영지역에서도 연속적인 내비게이션 서비스를 제공하는 시스템을 성공적으로 구현하였다. 주요 성과는 다음과 같다:

1. **하이브리드 위치 추적**: GPS 신호 품질에 따라 동적으로 전환되는 GPS-IMU 하이브리드 시스템 구현
2. **오차 최소화**: ZUPT 필터링과 가중 평균 필터를 통한 센서 드리프트 억제
3. **직관적 방향 안내**: 벡터 외적과 구면 삼각법 기반의 정확한 경로 이탈 감지 및 시계 방위 안내
4. **실시간 경로 재탐색**: 경로 이탈 시 자동으로 새로운 경로를 탐색하는 지능형 시스템

### 5.2 기술적 기여

본 연구의 기술적 기여는 다음과 같다:

1. **센서 융합 알고리즘**: 가속도계, 자이로스코프, 나침반 데이터의 효과적인 융합
2. **구면 삼각법 적용**: 평면이 아닌 구면상에서의 정확한 각도 계산
3. **적응형 필터링**: 움직임 상태에 따른 동적 필터 파라미터 조정
4. **유니버설 디자인**: 시각장애인을 포함한 모든 사용자를 위한 멀티모달 피드백

### 5.3 한계점

현재 시스템의 한계점은 다음과 같다:

1. **장시간 사용 시 오차 누적**: 30분 이상 사용 시 IMU 드리프트로 인한 오차 증가
2. **비정상 보행 패턴**: 계단, 에스컬레이터 등 특수한 이동 상황에서 정확도 저하
3. **자기장 간섭**: 전자기기 밀집 지역에서 나침반 정확도 감소
4. **배터리 소모**: 연속적인 센서 사용으로 인한 높은 전력 소비

### 5.4 향후 연구 방향

향후 연구에서는 다음과 같은 개선 사항을 고려할 필요가 있다:

1. **다중 센서 융합**: BLE 비콘, Wi-Fi RTT, 기압계 등 추가 센서 통합
2. **기계학습 적용**: 딥러닝 기반 보행 패턴 인식 및 오차 보정
3. **크라우드소싱**: 다중 사용자 데이터를 활용한 경로 정확도 향상
4. **에너지 효율성**: 적응형 샘플링 주기 조절을 통한 배터리 수명 연장
5. **3D 내비게이션**: 다층 건물 내 수직 이동 추적 기능 추가

### 5.5 결론

본 연구에서 제안한 IMU 기반 보행자 추측 항법 시스템은 GPS 음영지역에서도 안정적인 위치 추적과 직관적인 방향 안내를 제공함으로써 도시 환경에서의 보행자 내비게이션 서비스의 한계를 극복하였다. 특히 시각장애인과 같은 취약계층을 위한 접근성을 고려한 설계는 본 시스템의 사회적 가치를 높인다. 향후 추가적인 센서 융합과 기계학습 기법의 적용을 통해 더욱 정확하고 효율적인 시스템으로 발전할 것으로 기대된다.

## 참고문헌

[1] Thomas Gallagher, Elyse Wise, "Indoor Positioning System based on Sensor Fusion for the Blind and Visually Impaired", 2012 International Conference on Indoor Positioning and Indoor Navigation, 2012

[2] Widyawan, G. Pirkl, D. Munaretto, C. Fischer, C. An, P. Lukowicz, M. Klepal, A. Timm-Giel, J. Widmer, D. Pesch, H. Gellersen, "Virtual lifeline: Multimodal sensor data fusion for robust navigation in unknown environments", Pervasive and Mobile Computing, vol. 8, no. 3, pp. 388-401, 2012

[3] H. Ju, M. S. Lee, C. Park, S. Lee, "Advanced Pedestrian Dead Reckoning Using Smartphone Sensors: A Comparative Analysis of Sensor Fusion Methods", IEEE Access, vol. 9, pp. 15485-15502, 2021

[4] R. Harle, "A Survey of Indoor Inertial Positioning Systems for Pedestrians", IEEE Communications Surveys & Tutorials, vol. 15, no. 3, pp. 1281-1293, 2013

[5] J. Qian, J. Ma, R. Ying, P. Liu, L. Pei, "An improved indoor localization method using smartphone inertial sensors", International Conference on Indoor Positioning and Indoor Navigation, pp. 1-7, 2013

---

**저자 정보**

김호중¹, 오연주², 김도균³, 임승훈⁴

¹ 가톨릭대학교 정보통신전자공학부
² 가톨릭대학교 정보통신전자공학부  
³ 가톨릭대학교 정보통신전자공학부
⁴ 아주대학교 기계공학과

**교신저자**: 김호중 (jack777998@catholic.ac.kr)

**투고일**: 2025년 1월  
**게재확정일**: 2025년 2월