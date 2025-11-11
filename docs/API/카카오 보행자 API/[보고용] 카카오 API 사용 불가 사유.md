# [교수님 보고용] 카카오 보행자 길찾기 API 사용 불가 사유

> **작성일**: 2025-11-11
> **보고 대상**: 지도교수님
> **결론**: 카카오 API는 SafeLight 앱에 사용 불가능 ❌

---

## 1. 결론 요약

**카카오 보행자 길찾기 API는 시각장애인 앱인 SafeLight에 사용할 수 없습니다.**

**핵심 이유**: 시각장애인에게 필수적인 턴바이턴 안내, 랜드마크 정보, 횡단보도 정보를 전혀 제공하지 않음

---

## 2. 카카오 API 제공 정보 (공식 문서 확인)

### 2.1 제공하는 것
```json
{
  "routes": [{
    "summary": {
      "distance": 1281,  // ✅ 총 거리
      "duration": 1220   // ✅ 소요 시간
    },
    "sections": [{
      "roads": [{
        "vertexes": [126.992, 37.564, 126.993, 37.565]  // ✅ 좌표 배열
      }]
    }]
  }]
}
```

### 2.2 제공하지 않는 것 (치명적)

| 정보 | 필수도 | TMAP | 카카오 |
|------|--------|------|--------|
| **방향 안내** ("좌회전", "우회전") | 🔴 필수 | ✅ | ❌ |
| **랜드마크** ("대흥인테리어에서") | 🔴 필수 | ✅ | ❌ |
| **횡단보도 정보** | 🔴 필수 | ✅ | ❌ |
| **분기점 정보** | 🔴 필수 | ✅ | ❌ |

---

## 3. TMAP vs 카카오 비교

### TMAP API (현재 SafeLight 사용 중)
```dart
BranchInfo{
  point: LatLng(37.497223, 126.906985),
  isBranch: true,  // ✅ 분기점
  description: "대흥인테리어에서 좌회전 후 108m 이동",  // ✅ 턴바이턴 안내
  crosswalk: false,  // ✅ 횡단보도
  waypoint: false
}
```

**TTS 음성 출력**: "대흥인테리어에서 좌회전 후 108m 이동"

### 카카오 API
```json
{
  "vertexes": [126.992, 37.564, 126.993, 37.565]
  // ❌ description 없음 → TTS 안내 불가능
  // ❌ 좌표만 있음 → "126.992에서 회전" (의미 없음)
}
```

**TTS 음성 출력**: 불가능

---

## 4. SafeLight 핵심 기능 영향

### 4.1 음성 안내 (TTS)
- ❌ **불가능**: 방향 안내 문구가 없어 음성으로 안내할 수 없음
- 현재: "대흥인테리어에서 좌회전 후 108m 이동"
- 카카오 사용 시: 안내 불가능

### 4.2 BLE 횡단보도 연동
- ❌ **불가능**: 횡단보도 정보가 없어 BLE 음향신호기 연동 불가
- 현재: 횡단보도 접근 시 자동으로 BLE 스캔 시작
- 카카오 사용 시: 횡단보도 감지 불가능 → 안전 기능 상실

### 4.3 실시간 경로 안내
- ❌ **불가능**: 분기점 정보가 없어 언제 안내해야 할지 알 수 없음
- 현재: 분기점 5m 전방에서 TTS 안내
- 카카오 사용 시: 안내 타이밍 결정 불가능

---

## 5. 대안 검토 결과

### 5.1 좌표로 방향 계산?
- **결론**: 불가능 (정확도 낮음, 랜드마크 없음)
- GPS 오차로 인해 방향 계산 부정확
- "어디서" 회전해야 하는지 알 수 없음 (랜드마크 없음)

### 5.2 외부 POI 데이터 결합?
- **결론**: 불가능 (비용 증가, 정확도 낮음, 복잡도 증가)
- 경로 1개당 수십 번의 추가 API 호출 필요
- POI와 분기점이 정확히 일치하지 않음
- 개발 및 유지보수 복잡도 급증

---

## 6. 실제 API 호출 테스트 결과

### 6.1 테스트 정보
- **테스트 일시**: 2025-11-11
- **API 호출**: 실제 카카오 API 직접 호출
- **테스트 경로**: 강남역 → 역삼역 (약 885m)

### 6.2 실제 응답 JSON (summary=false)
```json
{
  "trans_id": "019a727fcde673f891ff77a74c408864",
  "routes": [{
    "result_code": 0,
    "result_message": "길찾기 성공",
    "summary": {
      "distance": 885,
      "duration": 952
    },
    "sections": [{
      "distance": 885,
      "duration": 952,
      "roads": [
        {
          "distance": 5,
          "duration": 6,
          "vertexes": [127.0276, 37.4979, 127.0276, 37.4979]
          // ❌ description 없음
          // ❌ turn_type 없음
          // ❌ landmark 없음
          // ❌ crosswalk 없음
        },
        {
          "distance": 10,
          "duration": 13,
          "vertexes": [127.0276, 37.4979, 127.0277, 37.4979]
          // ❌ 모든 roads 객체에 방향 정보 없음
        }
        // ... 총 25개의 roads 객체 모두 동일
      ]
    }]
  }]
}
```

**확인 사항**:
- ✅ 총 25개의 roads 객체 수신
- ✅ 모든 객체에 distance, duration, vertexes 포함
- ❌ **모든 객체에 description, turn_type, landmark, crosswalk 없음**

---

## 7. 공식 문서 근거

**카카오 공식 문서**: https://developers.kakaomobility.com/docs/affiliate/walking/directions/

**응답 객체 필드 (공식 문서 표)**:

| Name | Type | Description |
|------|------|-------------|
| trans_id | String | 경로 요청 ID |
| result_code | Int | 결과 코드 |
| result_message | String | 결과 메시지 |
| distance | Int | 거리 (미터) |
| duration | Int | 시간 (초) |
| vertexes | Double[] | 좌표 배열 |

**확인 사항**:
- ❌ `description` 필드 없음
- ❌ `turn_type` 필드 없음
- ❌ `landmark` 필드 없음
- ❌ `crosswalk` 필드 없음
- ❌ `branch` 필드 없음

---

## 8. 최종 권고 사항

### ✅ TMAP API 계속 사용
- 시각장애인에게 필수적인 모든 정보 제공
- SafeLight 핵심 기능과 100% 호환
- 검증된 안정적인 구현

### ❌ 카카오 API 사용 불가
- 턴바이턴 안내 불가능 → 음성 안내 불가
- 횡단보도 정보 없음 → BLE 연동 불가, 안전 기능 상실
- 분기점 정보 없음 → 실시간 안내 불가능

---

## 9. 요약 (1분 브리핑)

**상황**:
- 카카오 보행자 길찾기 API 적용 가능성 검토

**조사 결과**:
- ✅ 카카오 공식 문서 확인
- ✅ **실제 API 호출 테스트 완료** (2025-11-11)
- ✅ 강남역 → 역삼역 경로 테스트 (885m, 25개 roads 객체)
- ❌ 모든 roads 객체에 distance, duration, vertexes만 존재
- ❌ description, turn_type, landmark, crosswalk 필드 전혀 없음

**영향**:
- TTS 음성 안내: 불가능
- BLE 횡단보도 연동: 불가능
- 실시간 경로 안내: 불가능

**결론**:
- **카카오 API 사용 불가**
- **TMAP API 계속 사용 권장**

**근거**:
- 공식 문서: https://developers.kakaomobility.com/docs/affiliate/walking/directions/
- **실제 API 호출 테스트**: `docs/API/카카오 API 실제 응답 테스트.md`
- SafeLight 실제 로그 분석
- 상세 비교: `docs/API/카카오 vs TMAP 비교 분석 - 시각장애인 앱 적합성.md`

---

*작성일: 2025-11-11*
*작성자: SafeLight Development Team*


### 6.2 SafeLight 앱의 실제 사용자 시나리오

**시나리오**: 시각장애인이 목적지까지 안전하게 도보 이동

1. **경로 탐색 시작**
   - TMAP API 호출 → branchInfoList 수신
   - TTS: "총 거리 1.2km, 예상 시간 15분입니다"

2. **첫 번째 분기점 도착** (5m 전방)
   - TTS: "5m 전방, 대흥인테리어에서 좌회전 후 108m 이동"
   - 사용자가 좌회전 수행

3. **횡단보도 도착**
   - TTS: "횡단보도가 있습니다"
   - BLE 음향신호기 자동 스캔
   - 신호 감지 시 TTS: "파란불입니다. 안전하게 건너세요"

4. **경유지 통과**
   - TTS: "경유지를 통과했습니다. 직진하세요"

5. **목적지 도착**
   - TTS: "목적지에 도착했습니다"

**카카오 API 사용 시**: 위 시나리오의 2~4단계 전체가 불가능

> 카카오 보행자 길찾기 API는 좌표 정보만 제공하며, 시각장애인에게 필수적인 턴바이턴 안내, 랜드마크 정보, 횡단보도 정보를 전혀 제공하지 않습니다. 공식 문서(https://developers.kakaomobility.com/docs/affiliate/walking/directions/)를 확인한 결과, 응답 객체에는 distance, duration, vertexes만 포함되어 있습니다. SafeLight 앱의 핵심 기능인 TTS 음성 안내 및 BLE 횡단보도 연동이 불가능하므로, TMAP API를 계속 사용해야 합니다.