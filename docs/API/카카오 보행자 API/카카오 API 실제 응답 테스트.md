# 카카오 보행자 길찾기 API 실제 응답 테스트

> **테스트 일시**: 2025-11-11
> **API**: 카카오모빌리티 보행자 길찾기 API
> **REST API Key**: 1cdd32ab3a57b7a5c671f3dd43cb097e
> **목적**: 실제 API 응답 확인 및 턴바이턴 안내 정보 존재 여부 검증

---

## 1. 테스트 조건

### 1.1 테스트 경로
- **출발지**: 강남역 근처 (경도: 127.0276, 위도: 37.4979)
- **도착지**: 역삼역 근처 (경도: 127.0364, 위도: 37.5006)
- **거리**: 약 885m
- **예상 시간**: 약 952초 (15분 52초)

### 1.2 API 호출 정보
- **Base URL**: `https://apis-navi.kakaomobility.com`
- **Endpoint**: `/affiliate/walking/v1/directions`
- **Method**: GET
- **Headers**:
  - Authorization: KakaoAK 1cdd32ab3a57b7a5c671f3dd43cb097e
  - service: SafeLight
  - accept: application/json

---

## 2. 테스트 결과

### 2.1 Case 1: 요약 정보만 요청 (summary=true)

#### 요청
```bash
curl -X GET "https://apis-navi.kakaomobility.com/affiliate/walking/v1/directions?origin=127.0276,37.4979&destination=127.0364,37.5006&priority=DISTANCE&summary=true" \
  -H "Authorization: KakaoAK 1cdd32ab3a57b7a5c671f3dd43cb097e" \
  -H "service: SafeLight" \
  -H "accept: application/json"
```

#### 응답 (포맷팅)
```json
{
  "trans_id": "019a728044ed7ee2a24fc97f25f5acd5",
  "routes": [
    {
      "result_code": 0,
      "result_message": "길찾기 성공",
      "summary": {
        "distance": 885,
        "duration": 952
      }
    }
  ]
}
```

#### 분석
- ✅ `distance`: 885m (제공)
- ✅ `duration`: 952초 (제공)
- ❌ `description`: 없음
- ❌ `turn_type`: 없음
- ❌ `landmark`: 없음
- ❌ `crosswalk`: 없음
- ❌ `instructions`: 없음

---

### 2.2 Case 2: 전체 정보 요청 (summary=false)

#### 요청
```bash
curl -X GET "https://apis-navi.kakaomobility.com/affiliate/walking/v1/directions?origin=127.0276,37.4979&destination=127.0364,37.5006&priority=DISTANCE&summary=false" \
  -H "Authorization: KakaoAK 1cdd32ab3a57b7a5c671f3dd43cb097e" \
  -H "service: SafeLight" \
  -H "accept: application/json"
```

#### 응답 (포맷팅 - 일부 발췌)
```json
{
  "trans_id": "019a727fcde673f891ff77a74c408864",
  "routes": [
    {
      "result_code": 0,
      "result_message": "길찾기 성공",
      "summary": {
        "distance": 885,
        "duration": 952
      },
      "sections": [
        {
          "distance": 885,
          "duration": 952,
          "roads": [
            {
              "distance": 5,
              "duration": 6,
              "vertexes": [
                127.02763663795892,
                37.49790492413813,
                127.02761343771817,
                37.49794978592996
              ]
            },
            {
              "distance": 10,
              "duration": 13,
              "vertexes": [
                127.02761343771817,
                37.49794978592996,
                127.02771474298407,
                37.497986661980434
              ]
            },
            {
              "distance": 64,
              "duration": 82,
              "vertexes": [
                127.02839065877372,
                37.498190455363655,
                127.0284721499606,
                37.498010914540636
              ]
            }
            // ... 총 25개의 roads 객체
          ]
        }
      ]
    }
  ]
}
```

#### 전체 응답 구조
```json
{
  "trans_id": "string",
  "routes": [
    {
      "result_code": 0,
      "result_message": "길찾기 성공",
      "summary": {
        "distance": 885,
        "duration": 952
      },
      "sections": [
        {
          "distance": 885,
          "duration": 952,
          "roads": [
            {
              "distance": int,
              "duration": int,
              "vertexes": [lng, lat, lng, lat, ...]
            }
          ]
        }
      ]
    }
  ]
}
```

#### 응답 필드 분석
| 필드 | 타입 | 설명 | 존재 여부 |
|------|------|------|-----------|
| `trans_id` | String | 경로 요청 ID | ✅ |
| `result_code` | Int | 결과 코드 | ✅ |
| `result_message` | String | 결과 메시지 | ✅ |
| `summary.distance` | Int | 총 거리 (m) | ✅ |
| `summary.duration` | Int | 총 시간 (s) | ✅ |
| `sections[]` | Array | 구간 정보 | ✅ |
| `sections[].distance` | Int | 구간 거리 | ✅ |
| `sections[].duration` | Int | 구간 시간 | ✅ |
| `sections[].roads[]` | Array | 도로 정보 | ✅ |
| `roads[].distance` | Int | 도로 거리 | ✅ |
| `roads[].duration` | Int | 도로 시간 | ✅ |
| `roads[].vertexes` | Double[] | 좌표 배열 | ✅ |
| **`roads[].description`** | String | **안내 문구** | ❌ **없음** |
| **`roads[].turn_type`** | String | **방향 타입** | ❌ **없음** |
| **`roads[].landmark`** | String | **랜드마크** | ❌ **없음** |
| **`roads[].road_name`** | String | **도로명** | ❌ **없음** |
| **`roads[].crosswalk`** | Boolean | **횡단보도** | ❌ **없음** |
| **`roads[].instruction`** | String | **지시사항** | ❌ **없음** |
| **`sections[].guides`** | Array | **안내점** | ❌ **없음** |

---

## 3. 핵심 발견 사항

### 3.1 ❌ 턴바이턴 안내 정보 없음 (치명적)

**제공되는 정보**:
```json
{
  "distance": 64,
  "duration": 82,
  "vertexes": [127.0277, 37.4979, 127.0284, 37.4981]
}
```

**제공되지 않는 정보**:
- ❌ 방향 안내 ("좌회전", "우회전", "직진")
- ❌ 랜드마크 ("대흥인테리어에서")
- ❌ 안내 문구 ("108m 이동")
- ❌ 도로명
- ❌ 횡단보도 정보
- ❌ 분기점 정보

### 3.2 실제 사용 불가능한 이유

#### 시나리오: 시각장애인이 음성 안내를 듣는 경우

**TMAP API (현재 SafeLight)**:
```dart
BranchInfo{
  point: LatLng(37.498190, 127.028390),
  isBranch: true,
  description: "대흥인테리어에서 좌회전 후 108m 이동",
  crosswalk: false
}
```
→ TTS: "대흥인테리어에서 좌회전 후 108m 이동" ✅

**카카오 API**:
```json
{
  "distance": 64,
  "duration": 82,
  "vertexes": [127.0284, 37.4982, 127.0285, 37.4980]
}
```
→ TTS: ??? (안내할 내용이 없음) ❌

### 3.3 좌표만으로 방향 계산 시도

#### 이론적 가능성
```dart
// 두 좌표로 방향 계산
double bearing = calculateBearing(
  LatLng(37.498190, 127.028390),
  LatLng(37.498010, 127.028472)
);

if (bearing > 45 && bearing < 135) {
  direction = "우회전";
} else if (bearing > 225 && bearing < 315) {
  direction = "좌회전";
}
```

#### 실제 문제점
1. **랜드마크 없음**: "어디서" 회전해야 하는지 알 수 없음
   - 좌표: (37.498190, 127.028390)
   - 안내: "37.498190에서 좌회전" (의미 없음)

2. **정확도 부족**: GPS 오차로 방향 계산 부정확
   - 실제로는 직진인데 약간의 각도 차이로 "좌회전"으로 판정될 수 있음

3. **복잡한 교차로**: Y자 교차로, 로터리 등 처리 불가
   - "첫 번째 출구로 나가세요" 같은 세밀한 안내 불가능

4. **횡단보도 감지 불가**: 좌표만으로는 횡단보도 구분 불가능
   - BLE 음향신호기 연동 불가능

---

## 4. TMAP API와의 비교

### 4.1 TMAP API 응답 구조 (SafeLight 실제 사용)

```dart
// TMAP API가 제공하는 BranchInfo
List<BranchInfo> branchInfoList = [
  BranchInfo(
    point: LatLng(37.497223, 126.906985),
    isBranch: true,  // ✅ 분기점 여부
    description: "대흥인테리어에서 좌회전 후 108m 이동",  // ✅ 턴바이턴 안내
    bearingToBranch: 0.0,
    crosswalk: false,  // ✅ 횡단보도 여부
    waypoint: false
  ),
  BranchInfo(
    point: LatLng(37.497598, 126.907563),
    isBranch: true,
    description: "횡단보도를 건너세요",  // ✅ 횡단보도 안내
    bearingToBranch: 0.0,
    crosswalk: true,  // ✅ 횡단보도 플래그
    waypoint: false
  )
];
```

### 4.2 비교 표

| 기능 | TMAP API | 카카오 API | 시각장애인 필요성 |
|------|----------|-----------|------------------|
| 좌표 정보 | ✅ | ✅ | 필수 |
| 거리/시간 | ✅ | ✅ | 필수 |
| **방향 안내** | ✅ "좌회전" | ❌ | 🔴 **필수** |
| **랜드마크** | ✅ "대흥인테리어" | ❌ | 🔴 **필수** |
| **횡단보도** | ✅ crosswalk | ❌ | 🔴 **필수** |
| **분기점** | ✅ isBranch | ❌ | 🔴 **필수** |
| **안내 문구** | ✅ description | ❌ | 🔴 **필수** |

---

## 5. 결론

### 5.1 검증 결과

**카카오 보행자 길찾기 API 실제 호출 테스트 결과, 공식 문서와 동일하게 다음 정보들이 제공되지 않음을 확인했습니다:**

1. ❌ **턴바이턴 안내** (좌회전, 우회전 등)
2. ❌ **랜드마크/건물명** 정보
3. ❌ **횡단보도** 정보
4. ❌ **분기점** 정보
5. ❌ **안내 문구** (description)
6. ❌ **도로명** 정보

**제공되는 정보**:
- ✅ 좌표 배열 (vertexes)
- ✅ 거리 (distance)
- ✅ 시간 (duration)

### 5.2 시각장애인 앱 적용 불가 판정

**SafeLight 앱의 핵심 기능 구현 불가능**:

1. **TTS 음성 안내**: description 필드 없음 → 안내 불가
2. **BLE 횡단보도 연동**: crosswalk 필드 없음 → 횡단보도 감지 불가
3. **실시간 경로 안내**: isBranch 필드 없음 → 안내 타이밍 결정 불가
4. **랜드마크 기반 안내**: landmark 정보 없음 → 위치 파악 불가

### 5.3 최종 권고

**카카오 보행자 길찾기 API는 SafeLight 같은 시각장애인 앱에 사용할 수 없습니다.**

**TMAP API를 계속 사용해야 하는 이유**:
- ✅ 턴바이턴 안내 제공 (description)
- ✅ 횡단보도 정보 제공 (crosswalk)
- ✅ 분기점 정보 제공 (isBranch)
- ✅ 검증된 안정적인 구현
- ✅ 시각장애인 안전 보장

---

## 6. 전체 응답 JSON (참고용)

### 6.1 summary=true 응답
```json
{
  "trans_id": "019a728044ed7ee2a24fc97f25f5acd5",
  "routes": [
    {
      "result_code": 0,
      "result_message": "길찾기 성공",
      "summary": {
        "distance": 885,
        "duration": 952
      }
    }
  ]
}
```

### 6.2 summary=false 응답 (전체)
```json
{
  "trans_id": "019a727fcde673f891ff77a74c408864",
  "routes": [
    {
      "result_code": 0,
      "result_message": "길찾기 성공",
      "summary": {
        "distance": 885,
        "duration": 952
      },
      "sections": [
        {
          "distance": 885,
          "duration": 952,
          "roads": [
            {
              "distance": 5,
              "duration": 6,
              "vertexes": [127.02763663795892, 37.49790492413813, 127.02761343771817, 37.49794978592996]
            },
            {
              "distance": 10,
              "duration": 13,
              "vertexes": [127.02761343771817, 37.49794978592996, 127.02771474298407, 37.497986661980434]
            },
            {
              "distance": 64,
              "duration": 82,
              "vertexes": [127.02771474298407, 37.497986661980434, 127.02839065877372, 37.498190455363655]
            },
            {
              "distance": 21,
              "duration": 27,
              "vertexes": [127.02839065877372, 37.498190455363655, 127.0284721499606, 37.498010914540636]
            },
            {
              "distance": 2,
              "duration": 4,
              "vertexes": [127.0284721499606, 37.498010914540636, 127.02849464937974, 37.49802011012961]
            },
            {
              "distance": 24,
              "duration": 43,
              "vertexes": [127.02849464937974, 37.49802011012961, 127.02874237674429, 37.498103242143316]
            },
            {
              "distance": 5,
              "duration": 5,
              "vertexes": [127.02874237674429, 37.498103242143316, 127.0287654596743, 37.49806738971537]
            },
            {
              "distance": 9,
              "duration": 8,
              "vertexes": [127.0287654596743, 37.49806738971537, 127.02885557427932, 37.49809516223161]
            },
            {
              "distance": 64,
              "duration": 58,
              "vertexes": [127.02885557427932, 37.49809516223161, 127.02951995296776, 37.49831687543099]
            },
            {
              "distance": 75,
              "duration": 68,
              "vertexes": [127.02951995296776, 37.49831687543099, 127.03030825934484, 37.49857564446261]
            },
            {
              "distance": 65,
              "duration": 59,
              "vertexes": [127.03030825934484, 37.49857564446261, 127.03099526313001, 37.49879753511405]
            },
            {
              "distance": 3,
              "duration": 3,
              "vertexes": [127.03099526313001, 37.49879753511405, 127.03102907130214, 37.49880682298556]
            },
            {
              "distance": 26,
              "duration": 47,
              "vertexes": [127.03102907130214, 37.49880682298556, 127.0312994205988, 37.498890135211816]
            },
            {
              "distance": 6,
              "duration": 5,
              "vertexes": [127.0312994205988, 37.498890135211816, 127.03136703711384, 37.49890871077309]
            },
            {
              "distance": 66,
              "duration": 59,
              "vertexes": [127.03136703711384, 37.49890871077309, 127.03206547174703, 37.49912167839832]
            },
            {
              "distance": 78,
              "duration": 70,
              "vertexes": [127.03206547174703, 37.49912167839832, 127.03288795295846, 37.49936268918653]
            },
            {
              "distance": 28,
              "duration": 25,
              "vertexes": [127.03288795295846, 37.49936268918653, 127.03319211514918, 37.49945528446651]
            },
            {
              "distance": 75,
              "duration": 68,
              "vertexes": [127.03319211514918, 37.49945528446651, 127.03398056269108, 37.49970501968082]
            },
            {
              "distance": 11,
              "duration": 20,
              "vertexes": [127.03398056269108, 37.49970501968082, 127.03409329796804, 37.49973297319702]
            },
            {
              "distance": 109,
              "duration": 98,
              "vertexes": [127.03409329796804, 37.49973297319702, 127.03525388515268, 37.500066837211115]
            },
            {
              "distance": 9,
              "duration": 8,
              "vertexes": [127.03525388515268, 37.500066837211115, 127.03534412056447, 37.500085595227276]
            },
            {
              "distance": 7,
              "duration": 6,
              "vertexes": [127.03534412056447, 37.500085595227276, 127.03532069237686, 37.500148477786524]
            },
            {
              "distance": 22,
              "duration": 40,
              "vertexes": [127.03532069237686, 37.500148477786524, 127.0355459336305, 37.50022240139866]
            },
            {
              "distance": 23,
              "duration": 30,
              "vertexes": [127.0355459336305, 37.50022240139866, 127.03561355244517, 37.50024097455629, 127.03554384770753, 37.50038457434064]
            },
            {
              "distance": 78,
              "duration": 100,
              "vertexes": [127.03554384770753, 37.50038457434064, 127.03636623860876, 37.50063457081542]
            }
          ]
        }
      ]
    }
  ]
}
```

**총 25개의 roads 객체가 있지만, 모두 distance, duration, vertexes만 포함**
**description, turn_type, landmark, crosswalk 등의 필드는 하나도 없음**

---

*테스트 일시: 2025-11-11*
*테스트 수행: SafeLight Development Team*
*검증 방법: 실제 API 호출 및 응답 분석*
