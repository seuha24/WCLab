# SafeLight IMU vs SmartPDR 비교 분석 보고서

## 개요
본 문서는 SafeLight 프로젝트의 IMU 위치추적 시스템과 SmartPDR 논문의 기술을 비교 분석하여, 우리 프로젝트의 방향성을 정립하고 개선점을 도출하기 위해 작성되었습니다.

## 1. 기술 접근 방식 비교

### 1.1 시스템 아키텍처

| 구분 | SafeLight IMU | SmartPDR |
|------|--------------|----------|
| **기본 방식** | GPS/IMU 하이브리드 | 순수 IMU 기반 PDR |
| **GPS 활용** | 정확도 15m 기준 자동 전환 | GPS 없이 독립 작동 |
| **초기 위치** | GPS 또는 사용자 지정 | 사전 설정 필요 |
| **좌표계** | 상대좌표 ↔ 절대좌표 변환 | 상대좌표 누적 |
| **플랫폼** | Flutter (Cross-platform) | Android Native |

### 1.2 센서 활용

| 센서 | SafeLight | SmartPDR | 차이점 |
|------|-----------|----------|--------|
| **가속도계** | UserAccelerometer (중력 제외) | 3축 가속도계 (중력 포함) | SafeLight이 더 정제된 데이터 사용 |
| **자이로스코프** | Yaw rate 계산용 | 방향 추정용 | 유사한 활용 |
| **나침반** | 절대 방향 기준 | 자기 북극 기준 | SafeLight이 더 직접적 활용 |
| **GPS** | 핵심 보정 수단 | 미사용 | SafeLight만의 장점 |

## 2. 알고리즘 상세 비교

### 2.1 걸음 감지 (Step Detection)

#### SafeLight IMU
```dart
// 속도 기반 이동 감지
velocityX += (currentAccX - prevAccX) * dt
velocityY += (currentAccY - prevAccY) * dt
currentSpeed = sqrt(velocityX² + velocityY²)

// 임계값 필터링
if (acceleration < 0.06 m/s²) → 속도 리셋
```
- **특징**: 연속적 속도 추적
- **장점**: 부드러운 궤적
- **단점**: 걸음 수 계산 불가

#### SmartPDR
```
// 3단계 걸음 검증
1. Peak 감지 (>0.5 m/s²)
2. Peak-to-Peak (>1.0 m/s²)
3. 기울기 패턴 확인

tstep = tpeak ∩ tpp ∩ tslope
```
- **특징**: 개별 걸음 명확히 식별
- **장점**: 정확한 걸음 수, 보폭 계산 가능
- **단점**: 불규칙 보행 시 누락

### 2.2 방향 추정 (Heading Estimation)

#### SafeLight IMU
```dart
// 나침반 우선 + Yaw rate 보정
yawRate = compassValue * angleToRadian
yawRate += -(yawRatePerDt + noise)

// 단순 전환
if (compassReliable) use compass
else use gyroscope
```
- **접근**: 센서별 독립 사용
- **전환**: 이진적 선택

#### SmartPDR
```
// 4가지 Case 기반 융합
Case I: prev + mag + gyro (직진, 일치)
Case II: mag + gyro (회전, 일치)
Case III: prev only (회전, 불일치)
Case IV: prev + gyro (직진, 불일치)

// 가중 평균
weights = [2:1:2] (prev:mag:gyro)
```
- **접근**: 상황별 적응적 융합
- **전환**: 연속적 가중치 조정

**비교 결과**: SmartPDR의 접근이 더 정교하고 실용적

### 2.3 위치 계산 (Position Calculation)

#### SafeLight IMU
```dart
// 가속도 → 속도 → 위치 (2차 적분)
px += (currentSpeed * cos(yawRate))
py += (currentSpeed * sin(yawRate))

// Haversine 공식으로 위경도 변환
newLat = asin(sin(startLat)×cos(dist) + ...)
newLng = startLng + atan2(...)
```

#### SmartPDR
```
// 걸음별 위치 갱신
sk = sk-1 + lk × [sin(hk), cos(hk)]T

// 동적 보폭 모델
lk = β × ⁴√(astep_pp) + γ (낮은 충격)
lk = β × log(astep_pp) + γ (높은 충격)
```

**핵심 차이**: 
- SafeLight: 연속 적분 방식
- SmartPDR: 이산 걸음 누적 방식

## 3. 성능 및 정확도 비교

### 3.1 정확도 지표

| 지표 | SafeLight | SmartPDR | 비고 |
|------|-----------|----------|------|
| **평균 위치 오차** | GPS 정확도 의존적 | 1.35m | SmartPDR이 일관성 있음 |
| **방향 오차** | 나침반 정확도 ±5도 | 2.28도 ±3.63도 | SmartPDR이 더 정확 |
| **누적 오차** | GPS 보정으로 리셋 | 시간에 따라 증가 | SafeLight이 장기 추적 유리 |
| **초기화 시간** | GPS 수신 대기 | 즉시 가능 | SmartPDR이 빠름 |

### 3.2 환경 적응성

| 환경 | SafeLight | SmartPDR | 우위 |
|------|-----------|----------|------|
| **실내** | GPS 불량 시 IMU 전환 | 최적화됨 | SmartPDR |
| **실외** | GPS 우선 활용 | 누적 오차 | SafeLight |
| **지하/터널** | IMU 모드 자동 전환 | 일관된 성능 | 동등 |
| **자기장 간섭** | 영향 받음 | 적응적 대응 | SmartPDR |

## 4. 장단점 종합 분석

### 4.1 SafeLight IMU의 장점

1. **GPS 연동**
   - 절대 위치 보정 가능
   - 누적 오차 자동 리셋
   - 실내외 통합 추적

2. **실시간 경로 안내**
   - 경로 이탈 감지 (1.5m)
   - 시계 방향 음성 안내
   - 경로 재검색 기능

3. **Flutter 기반**
   - iOS/Android 동시 지원
   - 빠른 개발 및 유지보수
   - 풍부한 UI/UX

### 4.2 SafeLight IMU의 단점

1. **방향 추정 단순**
   - 센서 융합 미흡
   - 이진적 전환 로직
   - 자기장 간섭 취약

2. **걸음 감지 부재**
   - 개별 걸음 식별 불가
   - 보폭 추정 불가
   - 걸음 수 통계 없음

3. **GPS 의존성**
   - 실내 진입 시 지연
   - GPS 없으면 정확도 하락

### 4.3 SmartPDR의 장점

1. **정교한 알고리즘**
   - 적응적 센서 융합
   - 동적 보폭 모델
   - 3단계 걸음 검증

2. **독립성**
   - 인프라 불필요
   - GPS 불필요
   - 즉시 사용 가능

3. **검증된 성능**
   - 1.35m 평균 정확도
   - 논문 검증 완료

### 4.4 SmartPDR의 단점

1. **누적 오차**
   - 시간 경과 시 증가
   - 절대 위치 보정 불가
   - 장거리 추적 한계

2. **초기 위치 문제**
   - 사전 설정 필요
   - 절대 좌표 미지원

3. **경로 안내 부재**
   - 단순 위치 추적만
   - 경로 이탈 감지 없음

## 5. SafeLight 프로젝트 개선 방향

### 5.1 즉시 적용 가능한 개선사항

#### 1. SmartPDR 방향 추정 알고리즘 도입
```dart
// 현재 SafeLight 로직을 SmartPDR 방식으로 개선
enum HeadingCase { 
  case1_straight_match,
  case2_turn_match,
  case3_turn_mismatch, 
  case4_straight_mismatch 
}

double calculateAdaptiveHeading() {
  double correlation = abs(magnetometer - gyroscope);
  double magVariation = abs(magnetometer - prevMagnetometer);
  
  if (correlation < 5.0) {  // 센서 일치
    if (magVariation < 2.0) {  // Case I: 직진
      return weighted_average(prev: 2, mag: 1, gyro: 2);
    } else {  // Case II: 회전
      return weighted_average(mag: 1, gyro: 1);
    }
  } else {  // 센서 불일치
    if (magVariation < 2.0) {  // Case III: 직진
      return previousHeading;
    } else {  // Case IV: 회전
      return weighted_average(prev: 2, gyro: 1);
    }
  }
}
```

#### 2. 걸음 감지 알고리즘 추가
```dart
class StepDetector {
  // SmartPDR의 3단계 검증 구현
  bool detectStep(List<double> accData) {
    bool isPeak = checkPeak(accData, threshold: 0.5);
    bool isPeakToPeak = checkPeakToPeak(accData, threshold: 1.0);
    bool hasCorrectSlope = checkSlope(accData);
    
    return isPeak && isPeakToPeak && hasCorrectSlope;
  }
  
  // 동적 보폭 계산
  double calculateStepLength(double peakToPeak) {
    if (peakToPeak < 3.230) {
      return 1.479 * pow(peakToPeak, 0.25) - 1.259;
    } else {
      return 1.131 * log(peakToPeak) + 0.159;
    }
  }
}
```

#### 3. 하이브리드 위치 추적
```dart
class HybridPositionTracker {
  // GPS 가용 시: 절대 위치 + PDR 보조
  // GPS 불가 시: PDR 전용 모드
  
  Position updatePosition() {
    if (gpsAccuracy < 15.0) {
      // GPS 우선, PDR로 스무싱
      return smoothWithPDR(gpsPosition, pdrDelta);
    } else {
      // PDR 전용, 걸음 기반 갱신
      if (stepDetected) {
        pdrPosition += stepLength * direction;
      }
      return pdrPosition;
    }
  }
}
```

### 5.2 중장기 개선 로드맵

#### Phase 1: 알고리즘 고도화 (1-2개월)
- [ ] SmartPDR 방향 추정 알고리즘 구현
- [ ] 걸음 감지 및 동적 보폭 모델 추가
- [ ] 센서 융합 가중치 최적화

#### Phase 2: 정확도 향상 (2-3개월)
- [ ] 칼만 필터 적용
- [ ] 지도 매칭 (Map Matching) 구현
- [ ] 자기장 간섭 보상 알고리즘

#### Phase 3: 사용자 경험 개선 (3-4개월)
- [ ] 개인별 보행 패턴 학습
- [ ] 실시간 캘리브레이션
- [ ] 걸음 수 통계 및 분석

### 5.3 기술 융합 전략

#### GPS + IMU + PDR 통합 아키텍처
```
┌─────────────────────────────────┐
│         SafeLight 2.0           │
├─────────────────────────────────┤
│  GPS Module  │  IMU Module      │
│  - 절대위치  │  - 상대이동      │
│  - 기준점    │  - 연속추적      │
├──────────────┼──────────────────┤
│         PDR Module              │
│  - 걸음감지                     │
│  - 보폭추정                     │
│  - 방향융합                     │
├─────────────────────────────────┤
│      Fusion Engine              │
│  - 칼만필터                     │
│  - 지도매칭                     │
│  - 오차보정                     │
└─────────────────────────────────┘
```

## 6. 구현 우선순위

### 높음 (즉시 적용)
1. SmartPDR 방향 추정 알고리즘
2. 걸음 감지 기능
3. 센서 융합 가중치 조정

### 중간 (1-2개월 내)
1. 동적 보폭 모델
2. 칼만 필터
3. 개선된 노이즈 필터링

### 낮음 (장기 과제)
1. 머신러닝 기반 보정
2. 크라우드소싱 지도 구축
3. 멀티모달 센서 융합

## 7. 예상 성과

### 정확도 개선
- 현재: GPS 의존적 (5-15m)
- 목표: 실내 2m, 실외 1m

### 반응성 향상
- 현재: GPS 수신 대기 (5-30초)
- 목표: 즉시 추적 시작

### 사용성 확대
- 현재: GPS 필수
- 목표: 완전 오프라인 가능

## 8. 리스크 및 대응

### 기술적 리스크
1. **센서 호환성**: 기기별 테스트 확대
2. **배터리 소모**: 적응적 샘플링 구현
3. **계산 복잡도**: 최적화 및 병렬처리

### 프로젝트 리스크
1. **개발 기간**: 단계별 점진적 적용
2. **테스트 부담**: 자동화 테스트 구축
3. **사용자 혼란**: 점진적 UI 개선

## 9. 결론

SafeLight IMU 시스템은 GPS 연동과 경로 안내에 강점이 있지만, SmartPDR의 정교한 PDR 알고리즘을 도입하면 크게 개선될 수 있습니다. 특히 적응적 센서 융합과 걸음 기반 추적을 구현하면, GPS 불량 환경에서도 안정적인 서비스가 가능할 것입니다.

### 핵심 액션 아이템
1. **즉시**: SmartPDR 방향 추정 알고리즘 구현
2. **단기**: 걸음 감지 및 동적 보폭 모델 추가
3. **중기**: GPS/IMU/PDR 통합 프레임워크 구축

이를 통해 SafeLight는 실내외 통합 내비게이션 분야의 선도적 솔루션으로 발전할 수 있을 것입니다.

---
*작성일: 2025년 9월 10일*
*작성자: SafeLight 개발팀*
*검토자: 프로젝트 매니저*