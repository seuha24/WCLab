# TTS 멘트 중앙화 기획서

## 개요

### 목적
- 프로젝트 전체에 흩어진 TTS 멘트를 `TtsMessages` 클래스로 중앙화
- SSOT(Single Source of Truth) 원칙 적용
- 유지보수성 및 일관성 향상

### 현재 상태
- `tts_messages.dart` 파일 생성 완료 (POI 안내, 횡단보도 안내, 에러 안내)
- 새 기능(음향신호기/교차로 POI)에만 적용된 상태
- 기존 코드에 약 15개 TTS 멘트가 흩어져 있음

---

## 마이그레이션 대상

### 1. crosswalk_bloc.dart (9개) - 우선순위 높음

| 현재 멘트 | 제안 메서드명 | 비고 |
|-----------|---------------|------|
| `'자동 스캔이 시작됩니다.'` | `autoScanStarted` | 상수 |
| `'${results.length} 개의 스마트 압버튼을 찾았습니다.'` | `smartButtonsFound(int count)` | 동적 |
| `'${event.crosswalk.name}에 신호안내를 요청합니다.'` | `requestSignalGuide(String name)` | 동적 |
| `'명령이 전송되었습니다.'` | `commandSent` | 상수 |
| `'연결 실패했습니다.'` | `connectionFailed` | 상수 |
| `'${event.crosswalk.name}에 연결합니다.'` | `connectingTo(String name)` | 동적 |
| `'진동이 울리지 않는 방향으로 보행하세요.'` | `walkTowardsNoVibration` | 상수 |
| `'${event.crosswalk.name}에 음성안내를 요청합니다.'` | `requestVoiceGuide(String name)` | 동적 |
| `'음향신호기 설치 위치 정보를 안내합니다.'` | `signalDeviceLocationInfo` | 상수 |

### 2. flash_native_data_source.dart (1개)

| 현재 멘트 | 제안 메서드명 | 비고 |
|-----------|---------------|------|
| `'현재 경광등이 켜져 있습니다.'` | `flashLightOn` | 상수 |

### 3. blue_off_view.dart (1개)

| 현재 멘트 | 제안 메서드명 | 비고 |
|-----------|---------------|------|
| `'블루투스가 꺼져 있습니다. 블루투스를 켜주세요.'` | `bluetoothOff` | 상수 |

### 4. tutorial_view.dart (1개)

| 현재 멘트 | 제안 메서드명 | 비고 |
|-----------|---------------|------|
| `'안전 나침반이 켜집니다. 진동이 울리지 않는 방향으로 보행하세요.'` | `safetyCompassOn` | 상수 |

### 5. destination_search_view.dart (1개)

| 현재 멘트 | 제안 메서드명 | 비고 |
|-----------|---------------|------|
| 동적 검색 결과 메시지 | 확인 필요 | 파일 확인 후 결정 |

### 6. startspot_search_view.dart (2개)

| 현재 멘트 | 제안 메서드명 | 비고 |
|-----------|---------------|------|
| 동적 메시지 2개 | 확인 필요 | 파일 확인 후 결정 |

---

## TtsMessages 클래스 확장 설계

```dart
// lib/core/utils/tts_messages.dart
abstract class TtsMessages {
  // ============================================================
  // 기존 (POI 안내)
  // ============================================================
  static String poiDescription(String direction, int meters, String name);
  static String nearbyPoiSummary(List<String> descriptions, {String? lastPoiName});
  static String crosswalkWithIntersection(String intersectionName);
  static const String crosswalkOnly;
  static String favoritePlaceName(String name);
  static const String gpsError;
  static const String networkError;
  static const String noNearbyPlaces;
  static const String timeout;

  // ============================================================
  // 추가 예정 (BLE/횡단보도 안내)
  // ============================================================

  /// 자동 스캔 시작
  static const String autoScanStarted = '자동 스캔이 시작됩니다';

  /// 스마트 압버튼 발견
  static String smartButtonsFound(int count) => '$count개의 스마트 압버튼을 찾았습니다';

  /// 신호안내 요청
  static String requestSignalGuide(String name) => '$name에 신호안내를 요청합니다';

  /// 명령 전송 완료
  static const String commandSent = '명령이 전송되었습니다';

  /// 연결 실패
  static const String connectionFailed = '연결 실패했습니다';

  /// 연결 중
  static String connectingTo(String name) => '$name에 연결합니다';

  /// 진동 안내
  static const String walkTowardsNoVibration = '진동이 울리지 않는 방향으로 보행하세요';

  /// 음성안내 요청
  static String requestVoiceGuide(String name) => '$name에 음성안내를 요청합니다';

  /// 음향신호기 위치 안내
  static const String signalDeviceLocationInfo = '음향신호기 설치 위치 정보를 안내합니다';

  // ============================================================
  // 추가 예정 (시스템 상태)
  // ============================================================

  /// 경광등 켜짐
  static const String flashLightOn = '현재 경광등이 켜져 있습니다';

  /// 블루투스 꺼짐
  static const String bluetoothOff = '블루투스가 꺼져 있습니다. 블루투스를 켜주세요';

  /// 안전 나침반 켜짐
  static const String safetyCompassOn = '안전 나침반이 켜집니다. 진동이 울리지 않는 방향으로 보행하세요';
}
```

---

## 작업 순서

### Step 1: TtsMessages 클래스 확장
- [ ] BLE/횡단보도 안내 멘트 추가
- [ ] 시스템 상태 멘트 추가

### Step 2: crosswalk_bloc.dart 마이그레이션 (9개)
- [ ] TtsMessages import 추가
- [ ] 각 멘트를 TtsMessages 메서드로 교체
- [ ] 빌드 테스트

### Step 3: 개별 파일 마이그레이션
- [ ] flash_native_data_source.dart (1개)
- [ ] blue_off_view.dart (1개)
- [ ] tutorial_view.dart (1개)

### Step 4: 검색 관련 View 확인 및 마이그레이션
- [ ] destination_search_view.dart 확인
- [ ] startspot_search_view.dart 확인
- [ ] 필요시 TtsMessages에 메서드 추가

### Step 5: 검증
- [ ] 전체 빌드 테스트
- [ ] TTS 동작 확인

---

## 예상 소요 시간

| 단계 | 예상 작업량 |
|------|-------------|
| Step 1 | TtsMessages 확장 |
| Step 2 | crosswalk_bloc.dart 9개 멘트 |
| Step 3 | 3개 파일 각 1개 멘트 |
| Step 4 | 2개 파일 확인 및 적용 |
| Step 5 | 빌드 및 테스트 |

---

## 기대 효과

1. **SSOT 달성**: 모든 TTS 멘트가 한 파일에서 관리됨
2. **유지보수성 향상**: 멘트 수정 시 한 곳만 변경
3. **일관성 보장**: 동일 상황에 동일 멘트
4. **다국어 대비**: 향후 i18n 적용 용이
5. **가독성 향상**: 각 파일에서 멘트 의미 명확화

---

## 참고 사항

### 현재 TtsMessages 파일 위치
```
lib/core/utils/tts_messages.dart
lib/core/utils/korean_particle.dart
```

### 관련 커밋
- 음향신호기-교차로 POI 안내 및 TTS 멘트 중앙화 (Phase 1 완료)

---

*작성일: 2025-01-09*
*상태: ✅ 구현 완료 (2026-01-11)*

---

## 구현 완료 내역

### 완료된 작업
- [x] TtsMessages 클래스 확장 (35개 멘트 추가)
- [x] crosswalk_bloc.dart 마이그레이션 (9개)
- [x] flash_native_data_source.dart 마이그레이션 (1개)
- [x] blue_off_view.dart 마이그레이션 (1개)
- [x] tutorial_view.dart 마이그레이션 (1개)
- [x] destination_search_view.dart 마이그레이션 (6개)
- [x] startspot_search_view.dart 마이그레이션 (8개)
- [x] map_view_controller.dart 마이그레이션 (11개)
- [x] map_view.dart 마이그레이션 (1개)

**총 마이그레이션: 39개 멘트**

### 추후 작업 (Phase 2)
- [ ] KoreanParticle 유틸을 활용한 조사 자동 처리 (`을/를`, `이/가`, `으로/로`)
- [ ] main_view.dart 패널 멘트 중앙화 (`$selectedMenu 패널을 $stateMessage`)
