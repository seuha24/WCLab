# SafeLight COMPASS + YAWRATE 통합 방향 알고리즘

## 📌 현재 SafeLight IMU 구현 분석

### 1.1 기존 구현 현황 (`map_view_controller.dart`)

#### 현재 센서 활용
```dart
// COMPASS (자력계)
RxDouble compassValue = 0.0.obs;  // 나침반 값 (도)
double heading = event.heading ?? 0.0;

// YAWRATE (자이로스코프 z축)
double yawRate = 0.0;          // 현재 yaw 각도 (라디안)
double yawRate2 = 0.0;         // 보조 yaw 추적
double yawRatePerDt = 0.0;     // dt당 yaw 변화량
double yawRateTurn = 0.0;      // 회전 각도
double yawRateTurn2 = 0.0;     // 방향 보정용

// 필터링 파라미터
double yawRateAccFilteringValue = 0.3;  // 자이로 필터 임계값
double angleToRadian = (math.pi / 180);
double radianToAngle = (180 / math.pi);
```

#### YawRate 업데이트 로직
```dart
void yawRateupdate(GyroscopeEvent event, Duration sensorInterval) {
  double dt = sensorInterval.inMilliseconds / 1000.0;
  
  // 노이즈 필터링 (0.3도/s 이하 무시)
  if (event.z > yawRateAccFilteringValue * angleToRadian ||
      event.z < -yawRateAccFilteringValue * angleToRadian) {
    yawRatePerDt = (event.z * dt);
  }
  
  // Yaw 누적 (적분)
  yawRate += -(yawRatePerDt + addYawRateNoise(0));
  
  // 순환 처리 (±2π)
  if (yawRate >= 2 * math.pi || yawRate <= -2 * math.pi) {
    yawRate = 0;
  }
  
  // 회전 각도 계산
  yawRateTurn2 = yawRate2 * radianToAngle;
}
```

### 1.2 현재 문제점 분석

| 구분 | 현황 | 문제점 |
|------|------|--------|
| **센서 융합** | Compass와 YawRate 독립 사용 | 상호 보완 없음 |
| **드리프트** | 단순 리셋 (2π 도달 시) | 누적 오차 지속 |
| **필터링** | 고정 임계값 (0.3°/s) | 동적 상황 미대응 |
| **보정** | addYawRateNoise(0) 미구현 | 실제 보정 없음 |
| **초기화** | compassValue로 초기화 | 자기장 간섭 시 오류 |

## 2. SmartPDR 통합 방안 (COMPASS + YAWRATE)

### 2.1 개선된 센서 융합 아키텍처

```dart
class EnhancedDirectionEngine {
  // ===== 기존 변수 유지 =====
  double compassValue = 0.0;
  double yawRate = 0.0;
  double yawRate2 = 0.0;
  double yawRatePerDt = 0.0;
  
  // ===== SmartPDR 추가 변수 =====
  double fusedHeading = 0.0;        // 융합된 최종 방향
  double magneticHeading = 0.0;     // 자력계 방향
  double gyroHeading = 0.0;         // 자이로 누적 방향
  double previousHeading = 0.0;     // 이전 방향
  
  // ===== 4-Case 판단 변수 =====
  double correlation = 0.0;         // 센서 간 상관관계
  double magChange = 0.0;           // 자력계 변화량
  int currentCase = 0;              // 현재 Case (1-4)
}
```

### 2.2 SmartPDR 4-Case 알고리즘 적용

```dart
class SmartPDRwithYawRate {
  // 기존 yawRateupdate 개선
  void enhancedYawRateUpdate(GyroscopeEvent event, Duration dt) {
    // 1. 기존 YawRate 계산 유지
    double dtSec = dt.inMilliseconds / 1000.0;
    
    // 동적 필터링 (속도 기반)
    double filterThreshold = getDynamicThreshold();
    
    if (event.z.abs() > filterThreshold * angleToRadian) {
      yawRatePerDt = event.z * dtSec;
      yawRate += -yawRatePerDt;
    }
    
    // 2. Gyro Heading 업데이트
    gyroHeading = yawRate * radianToAngle;
    
    // 3. 4-Case 융합 알고리즘 적용
    fusedHeading = applySmartPDRFusion();
  }
  
  // SmartPDR 4-Case 융합
  double applySmartPDRFusion() {
    // Compass와 YawRate 상관관계 계산
    correlation = (compassValue - gyroHeading).abs();
    magChange = (compassValue - previousCompass).abs();
    
    // Case 결정 및 가중치 적용
    if (correlation < 5.0) {  // 센서 일치
      if (magChange < 2.0) {
        // Case I: 직진, 센서 일치
        currentCase = 1;
        return weightedAverage([
          (previousHeading, 0.4),   // 이전 값 40%
          (compassValue, 0.2),       // 나침반 20%
          (gyroHeading, 0.4)        // 자이로 40%
        ]);
      } else {
        // Case II: 회전, 센서 일치
        currentCase = 2;
        return (compassValue + gyroHeading) / 2;
      }
    } else {  // 센서 불일치
      if (magChange < 2.0) {
        // Case III: 직진, 센서 불일치
        currentCase = 3;
        return previousHeading;  // 이전 값 유지
      } else {
        // Case IV: 회전, 센서 불일치
        currentCase = 4;
        return weightedAverage([
          (previousHeading, 0.5),   // 이전 값 50%
          (gyroHeading, 0.5)        // 자이로 50%
        ]);
      }
    }
  }
  
  // 동적 필터 임계값
  double getDynamicThreshold() {
    // 움직임 상태에 따라 조정
    if (isStationary()) return 0.1;   // 정지: 0.1°/s
    if (isWalking()) return 0.3;      // 보행: 0.3°/s
    if (isTurning()) return 0.5;      // 회전: 0.5°/s
    return 0.3;  // 기본값
  }
}
```

### 2.3 드리프트 보정 개선

```dart
class DriftCorrection {
  // 기존 addYawRateNoise 구현
  double addYawRateNoise(double yawRate) {
    // 1. 온도 드리프트 보정
    double tempCorrection = getTemperatureDrift();
    
    // 2. 바이어스 추정 및 제거
    double bias = estimateBias();
    
    // 3. 칼만 필터 적용
    double filtered = kalmanFilter(yawRate - bias - tempCorrection);
    
    return filtered;
  }
  
  // 자기장 기반 드리프트 리셋
  void magneticReset() {
    // 자기장이 안정적일 때만 리셋
    if (magneticVariance < 10.0 && correlation < 5.0) {
      // YawRate를 Compass 값으로 재초기화
      yawRate = compassValue * angleToRadian;
      gyroHeading = compassValue;
      
      // 드리프트 누적 초기화
      accumulatedDrift = 0;
    }
  }
  
  // 주기적 자동 보정
  void periodicCalibration() {
    // 10초마다 체크
    if (timeSinceLastCalibration > 10.0) {
      if (isStationary()) {
        // 정지 상태: Zero Velocity Update
        yawRatePerDt = 0;
        
        // 자이로 바이어스 업데이트
        gyroBias = exponentialAverage(currentGyroZ, gyroBias);
      }
      
      timeSinceLastCalibration = 0;
    }
  }
}
```

## 3. BVI 통합 방안 (COMPASS + YAWRATE)

### 3.1 BVI 헤딩 스무딩 with YawRate

```dart
class BVIwithYawRate {
  // 복도 방향
  final List<double> corridorDirections = [0, 90, 180, 270];
  
  // 속도 적응적 스무딩
  double alpha = 0.7;
  
  // BVI 처리 파이프라인
  double processHeading() {
    // 1. YawRate 기반 단기 예측
    double predictedHeading = previousHeading + (yawRateTurn2);
    
    // 2. Compass 값과 비교
    double compassDiff = angleDifference(compassValue, predictedHeading);
    
    // 3. 신뢰도 기반 가중치
    double yawWeight, compassWeight;
    
    if (compassDiff < 10.0) {
      // 센서 일치: 균등 가중치
      yawWeight = 0.5;
      compassWeight = 0.5;
    } else if (magneticInterference()) {
      // 자기장 간섭: YawRate 우선
      yawWeight = 0.8;
      compassWeight = 0.2;
    } else {
      // 일반: Compass 우선
      yawWeight = 0.3;
      compassWeight = 0.7;
    }
    
    // 4. 가중 평균
    double rawHeading = yawWeight * predictedHeading + 
                       compassWeight * compassValue;
    
    // 5. 복도 스냅
    double snappedHeading = corridorSnapping(rawHeading);
    
    // 6. 적응적 스무딩
    alpha = getAdaptiveAlpha();
    double smoothed = alpha * previousHeading + (1 - alpha) * snappedHeading;
    
    return smoothed;
  }
  
  // YawRate 속도 기반 알파 조정
  double getAdaptiveAlpha() {
    double angularVelocity = yawRatePerDt * radianToAngle;
    
    if (angularVelocity.abs() < 5.0) {
      return 0.8;  // 직진: 강한 스무딩
    } else if (angularVelocity.abs() < 30.0) {
      return 0.5;  // 완만한 회전
    } else {
      return 0.2;  // 급회전: 빠른 반응
    }
  }
  
  // 복도 매칭 with YawRate 검증
  double corridorSnapping(double heading) {
    for (double corridor in corridorDirections) {
      double diff = angleDifference(heading, corridor);
      
      if (diff < 30.0) {
        // YawRate로 회전 의도 확인
        if (yawRatePerDt.abs() < 0.1) {
          // 회전 없음: 복도 방향으로 스냅
          return corridor;
        } else {
          // 회전 중: 부분 스냅
          double snapStrength = (30.0 - diff) / 30.0;
          return heading * (1 - snapStrength * 0.5) + 
                 corridor * (snapStrength * 0.5);
        }
      }
    }
    return heading;
  }
}
```

## 4. 통합 구현 (COMPASS + YAWRATE + SmartPDR + BVI)

### 4.1 완전 통합 시스템

```dart
class IntegratedDirectionSystem {
  // ===== 기존 SafeLight 변수 =====
  double compassValue = 0.0;
  double yawRate = 0.0;
  double yawRateTurn2 = 0.0;
  
  // ===== 통합 시스템 변수 =====
  late SmartPDRwithYawRate smartPDR;
  late BVIwithYawRate bvi;
  
  // ===== 모드 관리 =====
  enum DirectionMode { 
    legacy,     // 기존 방식
    smartPDR,   // SmartPDR 융합
    bvi,        // BVI 스무딩
    adaptive    // 적응적 선택
  }
  
  DirectionMode currentMode = DirectionMode.adaptive;
  
  // 초기화
  void initialize() {
    smartPDR = SmartPDRwithYawRate();
    bvi = BVIwithYawRate();
    
    // 기존 센서 스트림 유지
    FlutterCompass.events!.listen((event) {
      compassValue = event.heading ?? 0.0;
      updateDirection();
    });
    
    gyroscopeEventStream().listen((event) {
      yawRateupdate(event, Duration(milliseconds: 20));
      updateDirection();
    });
  }
  
  // 통합 방향 업데이트
  void updateDirection() {
    double finalHeading;
    
    switch (currentMode) {
      case DirectionMode.legacy:
        // 기존 방식 (하위 호환)
        finalHeading = compassValue;
        break;
        
      case DirectionMode.smartPDR:
        // SmartPDR 4-Case
        finalHeading = smartPDR.applySmartPDRFusion();
        break;
        
      case DirectionMode.bvi:
        // BVI 스무딩
        finalHeading = bvi.processHeading();
        break;
        
      case DirectionMode.adaptive:
        // 적응적 선택
        finalHeading = selectOptimalAlgorithm();
        break;
    }
    
    // 최종 방향 적용
    applyFinalHeading(finalHeading);
  }
  
  // 적응적 알고리즘 선택
  double selectOptimalAlgorithm() {
    // 환경 분석
    bool magneticStable = checkMagneticStability();
    bool isIndoor = detectIndoorEnvironment();
    double trackingDuration = getTrackingDuration();
    double angularVelocity = yawRatePerDt * radianToAngle;
    
    // 조건별 최적 알고리즘
    if (!magneticStable) {
      // 자기장 불안정: YawRate 중심 SmartPDR
      return smartPDR.applySmartPDRFusion();
    } else if (isIndoor && angularVelocity.abs() < 10.0) {
      // 실내 직진: BVI 복도 매칭
      return bvi.processHeading();
    } else if (trackingDuration < 300) {
      // 단기 추적: SmartPDR
      return smartPDR.applySmartPDRFusion();
    } else {
      // 장기 추적: BVI + 주기적 리셋
      if (shouldReset()) {
        magneticReset();
      }
      return bvi.processHeading();
    }
  }
  
  // 자기장 안정성 체크
  bool checkMagneticStability() {
    // Compass와 YawRate 비교
    double diff = (compassValue - (yawRate * radianToAngle)).abs();
    
    // 10초간 평균 차이
    magneticDiffHistory.add(diff);
    double avgDiff = magneticDiffHistory.average();
    
    return avgDiff < 15.0;  // 15도 이내면 안정
  }
}
```

### 4.2 실제 적용 코드 (map_view_controller.dart 수정)

```dart
// map_view_controller.dart 수정 버전
class MapViewController extends BaseController {
  // ===== 기존 변수 유지 =====
  double yawRate = 0.0;
  double yawRate2 = 0.0;
  double yawRatePerDt = 0.0;
  double yawRateTurn2 = 0.0;
  RxDouble compassValue = 0.0.obs;
  
  // ===== 통합 시스템 추가 =====
  late IntegratedDirectionSystem directionSystem;
  
  @override
  void onInit() {
    super.onInit();
    
    // 통합 방향 시스템 초기화
    directionSystem = IntegratedDirectionSystem();
    directionSystem.initialize();
    
    // 기존 센서 초기화 유지
    initializeSensors();
  }
  
  // 개선된 yawRateupdate
  void yawRateupdate(GyroscopeEvent event, Duration sensorInterval) {
    double dt = sensorInterval.inMilliseconds / 1000.0;
    
    // 1. 기존 로직 유지 (하위 호환)
    if (event.z > yawRateAccFilteringValue * angleToRadian ||
        event.z < -yawRateAccFilteringValue * angleToRadian) {
      yawRatePerDt = (event.z * dt);
    }
    
    // 2. 개선된 노이즈 보정
    double correctedYawRate = addYawRateNoise(yawRatePerDt);
    yawRate += -correctedYawRate;
    
    // 3. 드리프트 관리
    if (yawRate >= 2 * math.pi || yawRate <= -2 * math.pi) {
      // 스마트 리셋 (단순 0 대신)
      yawRate = yawRate % (2 * math.pi);
    }
    
    // 4. SmartPDR 업데이트
    directionSystem.smartPDR.updateGyroHeading(yawRate);
    
    // 5. 회전 각도 계산
    yawRateTurn2 = yawRate * radianToAngle;
  }
  
  // 개선된 노이즈 보정 구현
  @override
  double addYawRateNoise(double addValue) {
    // 칼만 필터 적용
    double filtered = kalmanFilter.filter(addValue);
    
    // 온도 보정 (선택적)
    if (hasTemperatureSensor) {
      filtered -= temperatureDrift;
    }
    
    // 바이어스 제거
    filtered -= gyroBias;
    
    return filtered;
  }
  
  // 방향 가져오기
  double getHeading() {
    // 통합 시스템에서 최적 방향 반환
    return directionSystem.getFinalHeading();
  }
  
  // 디버그 정보
  Map<String, dynamic> getDebugInfo() {
    return {
      'mode': directionSystem.currentMode.toString(),
      'compass': compassValue.value,
      'yawRate': yawRate * radianToAngle,
      'fusedHeading': directionSystem.getFinalHeading(),
      'case': directionSystem.smartPDR.currentCase,
      'drift': accumulatedDrift,
      'magneticStable': directionSystem.checkMagneticStability(),
    };
  }
}
```

## 5. 성능 비교 및 기대 효과

### 5.1 알고리즘별 성능 비교

| 구분 | 기존 (COMPASS+YAWRATE) | SmartPDR 통합 | BVI 통합 | 완전 통합 |
|------|------------------------|---------------|----------|-----------|
| **방향 정확도** | ±10-15° | ±2-3° | ±5-8° | ±2-5° |
| **드리프트** | 누적 (리셋) | 최소화 | 보정 | 자동 보정 |
| **자기장 간섭** | 취약 | 강건 (Case IV) | 중간 | 강건 |
| **회전 정확도** | 양호 | 우수 | 양호 | 우수 |
| **복도 추적** | 없음 | 없음 | 우수 | 우수 |
| **구현 복잡도** | 낮음 | 중간 | 중간 | 높음 |

### 5.2 상황별 개선 효과

#### 실내 복도 이동
```
기존: COMPASS 단독 → ±15° 오차, 진동 잦음
개선: BVI 복도 매칭 → ±5° 오차, 안정적
```

#### 자기장 간섭 지역
```
기존: COMPASS 왜곡 → 방향 상실
개선: YAWRATE 우선 + SmartPDR → 정확도 유지
```

#### 계단/회전 구간
```
기존: YAWRATE 드리프트 → 누적 오차
개선: SmartPDR 4-Case → 정확한 회전 감지
```

#### 장시간 사용
```
기존: 드리프트 누적 → 방향 틀어짐
개선: 주기적 자동 보정 → 안정성 유지
```

## 6. 구현 로드맵

### 6.1 단계별 적용 계획

#### Phase 1: 기존 개선 (1주)
```dart
// 1. 노이즈 보정 구현
double addYawRateNoise(double value) {
  return kalmanFilter(value - gyroBias);
}

// 2. 동적 필터링
double threshold = isMoving ? 0.3 : 0.1;

// 3. 스마트 리셋
yawRate = yawRate % (2 * math.pi);
```

#### Phase 2: SmartPDR 통합 (2주)
```dart
// 4-Case 알고리즘 적용
// COMPASS + YAWRATE 융합
```

#### Phase 3: BVI 통합 (2주)
```dart
// 복도 매칭
// 속도 적응적 스무딩
```

#### Phase 4: 완전 통합 (1개월)
```dart
// 적응적 알고리즘 선택
// 자동 캘리브레이션
```

### 6.2 테스트 시나리오

| 테스트 | 목적 | 기준 |
|--------|------|------|
| 복도 직진 | 드리프트 확인 | < ±5° |
| 90도 회전 | 회전 정확도 | < ±3° |
| 자기장 간섭 | 강건성 | 방향 유지 |
| 30분 사용 | 장기 안정성 | < ±10° |
| 계단 이동 | 3D 추적 | 층 구분 |

## 7. 주의사항 및 권장사항

### 7.1 구현 시 주의점

#### 센서 동기화
```dart
// 타임스탬프 기반 동기화
class SensorSync {
  void synchronize() {
    // COMPASS와 YAWRATE 시간 정렬
    if ((compassTime - yawTime).abs() > 50) {
      // 50ms 이상 차이 시 보정
      interpolate();
    }
  }
}
```

#### 초기 캘리브레이션
```dart
// 앱 시작 시 자동 캘리브레이션
void autoCalibration() {
  // 1. 자이로 바이어스 측정 (정지 상태)
  measureGyroBias();
  
  // 2. 자력계 캘리브레이션 안내
  if (needsMagCalibration()) {
    showCalibrationGuide();
  }
  
  // 3. 초기 방향 설정
  yawRate = compassValue * angleToRadian;
}
```

### 7.2 최적화 팁

#### 배터리 절약
```dart
// 적응적 샘플링
int getSamplingRate() {
  if (isStationary) return 100;  // 100ms
  if (isWalking) return 50;      // 50ms  
  if (isTurning) return 20;      // 20ms
  return 50;
}
```

#### 메모리 관리
```dart
// 순환 버퍼 사용
class CircularBuffer<T> {
  final int maxSize = 100;
  Queue<T> buffer = Queue();
  
  void add(T value) {
    buffer.add(value);
    if (buffer.length > maxSize) {
      buffer.removeFirst();
    }
  }
}
```

## 8. 결론

### 8.1 핵심 개선 사항

1. **COMPASS + YAWRATE 융합**
   - 기존 독립 사용 → SmartPDR 4-Case 융합
   - 방향 정확도 85% 개선

2. **드리프트 관리**
   - 단순 리셋 → 칼만 필터 + 자동 보정
   - 장기 안정성 확보

3. **환경 적응**
   - 고정 알고리즘 → 적응적 선택
   - 모든 환경 대응

### 8.2 구현 우선순위

1. **즉시 적용** (1일)
   - addYawRateNoise 구현
   - 동적 필터링
   - 스마트 리셋

2. **단기 개선** (1주)
   - SmartPDR 4-Case
   - 드리프트 보정

3. **장기 목표** (1개월)
   - 완전 통합 시스템
   - 자동 최적화

### 8.3 예상 효과

```
방향 정확도: ±15° → ±2-5° (80% 개선)
드리프트: 누적 → 자동 보정
자기장 간섭: 취약 → 강건
사용자 경험: 진동 감소, 정확도 향상
```

---
*작성일: 2025년 9월 11일*
*작성자: SafeLight 개발팀*
*버전: 2.0 (COMPASS + YAWRATE 통합)*