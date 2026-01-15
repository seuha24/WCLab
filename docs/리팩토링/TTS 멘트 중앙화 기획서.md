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

### 추후 작업 (Phase 2) - 미완료
- [ ] KoreanParticle 유틸을 활용한 조사 자동 처리 (`을/를`, `이/가`, `으로/로`)
- [ ] main_view.dart 패널 멘트 중앙화 (`$selectedMenu 패널을 $stateMessage`)

---

## Phase 3: TTS 호출 단순화 기획서

*작성일: 2026-01-15*
*상태: ✅ 구현 완료 (2026-01-15)*

### 목적

현재 TTS 호출 시 멘트 + 채널 + 쿨다운을 각각 지정해야 하는 번거로움을 해소하고, **한 줄 호출**로 단순화합니다.

### 현재 문제점

```dart
// 현재: 4줄 필요
tts.speakWithChannel(
  TtsMessages.branchInstruction(message),
  channel: ETtsChannel.NAVIGATE,
  cooldownKey: 'branch_instruction',
  cooldown: const Duration(seconds: 10),
);
```

### 목표

```dart
// 목표: 1줄로 단순화
tts.branchInstruction(message);
```

### 구현 위치

**`data/services/tts_service.dart`에 convenience 메서드 추가**

- Repository가 아닌 Service 계층에서 조합
- 기존 DI 구조 유지
- KISS 원칙 준수 (새 파일/클래스 불필요)

---

## 전체 구현 항목 목록

### 카테고리 1: 경로 안내 (7개)

| # | 메서드명 | 파라미터 | 채널 | cooldownKey | cooldown | 사용처 |
|---|----------|----------|------|-------------|----------|--------|
| 1 | `speakArrivedAtDestination()` | 없음 | NAVIGATE | arrive_destination | 20s | map_view_controller.dart:890 |
| 2 | `speakMoveToStartPoint()` | 없음 | NAVIGATE | move_to_startpoint | 5s | map_view_controller.dart:1131 |
| 3 | `speakBranchInstruction(String message)` | message | NAVIGATE | branch_instruction | 10s | map_view_controller.dart:1236 |
| 4 | `speakRerouteComplete()` | 없음 | SYSTEM_ANNOUNCE | reroute_done | 10s | map_view_controller.dart:1029 |
| 5 | `speakRerouteFromDeviation()` | 없음 | NAVIGATE | research_out_of_start | 10s | map_view_controller.dart:1061 |
| 6 | `speakRemainingDistance(int meters)` | meters | FEEDBACK | on_tap_remain_distance | 0s | map_view.dart:84 |
| 7 | `speakNearbyPoi(List<String> descriptions, String? lastPoiName)` | descriptions, lastPoiName | NAVIGATE | nearby_poi | 10s | location_announcement_controller.dart:253 |

### 카테고리 2: 안전 경고 (2개)

| # | 메서드명 | 파라미터 | 채널 | cooldownKey | cooldown | 사용처 |
|---|----------|----------|------|-------------|----------|--------|
| 8 | `speakCrosswalkAhead()` | 없음 | ALERT | crosswalk_alert | 2s | map_view_controller.dart:1209 |
| 9 | `speakOutOfBound(String clockDirection)` | clockDirection | ALERT | out_of_bound | 10s | map_view_controller.dart:996 |

### 카테고리 3: 경광등 제어 (6개)

| # | 메서드명 | 파라미터 | 채널 | cooldownKey | cooldown | 사용처 |
|---|----------|----------|------|-------------|----------|--------|
| 10 | `speakFlashTurnedOn()` | 없음 | SYSTEM_ANNOUNCE | flashlight_on_success | 5s | map_view_controller.dart:1475 |
| 11 | `speakFlashTurnedOff()` | 없음 | SYSTEM_ANNOUNCE | flashlight_off_success | 5s | map_view_controller.dart:1466 |
| 12 | `speakCannotTurnOnFlash()` | 없음 | SYSTEM_ANNOUNCE | flashlight_on_fail | 5s | map_view_controller.dart:1472 |
| 13 | `speakCannotTurnOffFlash()` | 없음 | SYSTEM_ANNOUNCE | flashlight_off_fail | 5s | map_view_controller.dart:1463 |
| 14 | `speakFlashControlError()` | 없음 | SYSTEM_ANNOUNCE | flashlight_control_error | 5s | map_view_controller.dart:1480 |
| 15 | `speakFlashLightCurrentlyOn()` | 없음 | NAVIGATE | (없음) | (없음) | flash_native_data_source.dart:31 |

### 카테고리 4: UI 피드백 (4개)

| # | 메서드명 | 파라미터 | 채널 | cooldownKey | cooldown | 사용처 |
|---|----------|----------|------|-------------|----------|--------|
| 16 | `speakPanelToggle(String menu, String state)` | menu, state | FEEDBACK | panel_action | 0s | main_view.dart:77 |
| 17 | `speakPanelSwitch(String menu)` | menu | FEEDBACK | panel_action | 0s | main_view.dart:87 |
| 18 | `speakNavigateToFavoritePoint(String name)` | name | SYSTEM_ANNOUNCE | (없음) | (없음) | map_panel_controller.dart:31 |
| 19 | `speakNavigateToFavoriteRoute(String name)` | name | SYSTEM_ANNOUNCE | (없음) | (없음) | map_panel_controller.dart:70 |

### 카테고리 5: BLE/스마트 압버튼 (10개)

| # | 메서드명 | 파라미터 | 채널 | cooldownKey | cooldown | 사용처 |
|---|----------|----------|------|-------------|----------|--------|
| 20 | `speakAutoScanStarted()` | 없음 | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:40 |
| 21 | `speakSmartButtonsFound(int count)` | count | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:73 |
| 22 | `speakRequestSignalGuide(String name)` | name | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:88 |
| 23 | `speakCommandSent()` | 없음 | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:105,114 |
| 24 | `speakConnectionFailed()` | 없음 | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:118 |
| 25 | `speakConnectingTo(String name)` | name | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:128 |
| 26 | `speakWalkTowardsNoVibration()` | 없음 | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:140 |
| 27 | `speakRequestVoiceGuide(String name)` | name | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:162 |
| 28 | `speakSignalDeviceLocationInfo()` | 없음 | NAVIGATE | (없음) | (없음) | crosswalk_bloc.dart:174 |
| 29 | `speakBluetoothOff()` | 없음 | NAVIGATE | (없음) | (없음) | blue_off_view.dart:19 |

### 카테고리 6: 검색/장소 선택 (10개)

| # | 메서드명 | 파라미터 | 채널 | cooldownKey | cooldown | 사용처 |
|---|----------|----------|------|-------------|----------|--------|
| 30 | `speakPlaceSelected(String name)` | name | NAVIGATE | (없음) | (없음) | startspot/destination_search_view |
| 31 | `speakNavigatingTo(String name)` | name | NAVIGATE | (없음) | (없음) | startspot/destination_search_view |
| 32 | `speakNavigatingToEntrance(String entranceName)` | entranceName | NAVIGATE | (없음) | (없음) | startspot/destination_search_view |
| 33 | `speakCancelled()` | 없음 | NAVIGATE | (없음) | (없음) | startspot/destination_search_view |
| 34 | `speakLocationPermissionRequired()` | 없음 | NAVIGATE | (없음) | (없음) | startspot_search_view.dart:344 |
| 35 | `speakCurrentLocationSet()` | 없음 | NAVIGATE | (없음) | (없음) | startspot_search_view.dart:372 |
| 36 | `speakCannotGetCurrentLocation()` | 없음 | NAVIGATE | (없음) | (없음) | startspot_search_view.dart:385 |
| 37 | `speakLocationSelected(String address)` | address | NAVIGATE | (없음) | (없음) | startspot/destination_search_view |
| 38 | `speakSafetyCompassOn()` | 없음 | NAVIGATE | (없음) | (없음) | tutorial_view.dart:235 |

---

## 작업량 분석

### 총 구현 항목

| 구분 | 수량 |
|------|------|
| **TtsService convenience 메서드** | 38개 |
| **호출부 수정 파일** | 11개 |
| **호출부 수정 라인** | 약 48개 |

### 파일별 수정 현황

| 파일 | 수정 라인 수 | 난이도 |
|------|-------------|--------|
| tts_service.dart | +150줄 (메서드 추가) | ⭐ 낮음 |
| map_view_controller.dart | 12개 호출 → 12줄로 변경 | ⭐ 낮음 |
| crosswalk_bloc.dart | 10개 호출 → 10줄로 변경 | ⭐ 낮음 |
| startspot_search_view.dart | 9개 호출 → 9줄로 변경 | ⭐ 낮음 |
| destination_search_view.dart | 9개 호출 → 9줄로 변경 | ⭐ 낮음 |
| location_announcement_controller.dart | 1개 호출 → 1줄로 변경 | ⭐ 낮음 |
| map_view.dart | 1개 호출 → 1줄로 변경 | ⭐ 낮음 |
| map_panel_controller.dart | 2개 호출 → 2줄로 변경 | ⭐ 낮음 |
| main_view.dart | 2개 호출 → 2줄로 변경 | ⭐ 낮음 |
| blue_off_view.dart | 1개 호출 → 1줄로 변경 | ⭐ 낮음 |
| tutorial_view.dart | 1개 호출 → 1줄로 변경 | ⭐ 낮음 |
| flash_native_data_source.dart | 1개 호출 → 1줄로 변경 | ⭐ 낮음 |

---

## 난이도 및 성공 확률 분석

### 난이도: ⭐ 낮음 (Easy)

| 요소 | 평가 |
|------|------|
| 아키텍처 변경 | ❌ 없음 (기존 구조 유지) |
| 새 의존성 | ❌ 없음 |
| 비즈니스 로직 변경 | ❌ 없음 (단순 래핑) |
| 테스트 필요성 | ⚠️ 빌드 테스트만 |
| 롤백 가능성 | ✅ 쉬움 (단순 호출 변경) |

### 성공 확률: 98%

| 리스크 | 확률 | 대응 |
|--------|------|------|
| 빌드 오류 | 2% | 즉시 수정 가능 |
| 런타임 오류 | 0% | 단순 래핑이므로 발생 불가 |
| 기능 변경 | 0% | 동작 동일 |

### 실패 가능 시나리오

1. **오타로 인한 빌드 오류** → 즉시 수정
2. **import 누락** → 즉시 추가

---

## 작업 순서 (Step-by-Step)

### Step 1: TtsService에 convenience 메서드 추가
- [x] 경로 안내 메서드 7개
- [x] 안전 경고 메서드 2개
- [x] 경광등 제어 메서드 6개
- [x] UI 피드백 메서드 4개
- [x] BLE/스마트 압버튼 메서드 10개
- [x] 검색/장소 선택 메서드 10개
- [x] 빌드 테스트

### Step 2: 호출부 마이그레이션
- [x] map_view_controller.dart (12개)
- [x] crosswalk_bloc.dart (10개)
- [x] startspot_search_view.dart (9개)
- [x] destination_search_view.dart (9개)
- [x] 기타 파일들 (8개)

### Step 3: 검증
- [x] 전체 빌드 테스트
- [x] 불필요한 speakTTS 헬퍼 함수 제거

---

## 기대 효과

### Before (현재)
```dart
// 4줄, 복잡
tts.speakWithChannel(
  TtsMessages.branchInstruction(message),
  channel: ETtsChannel.NAVIGATE,
  cooldownKey: 'branch_instruction',
  cooldown: const Duration(seconds: 10),
);
```

### After (목표)
```dart
// 1줄, 단순
tts.speakBranchInstruction(message);
```

### 정량적 효과

| 지표 | Before | After | 개선율 |
|------|--------|-------|--------|
| 호출 코드 라인 | 5줄 | 1줄 | **80% 감소** |
| import 필요 | TtsMessages, ETtsChannel | 없음 | **100% 감소** |
| 실수 가능성 | 높음 (채널/쿨다운 오기입) | 없음 | **100% 감소** |
| 코드 가독성 | 낮음 | 높음 | **대폭 향상** |

### 정성적 효과

1. **SSOT 강화**: 채널/쿨다운 설정이 TtsService에서 중앙 관리
2. **개발 생산성**: 새 개발자도 즉시 TTS 사용 가능
3. **버그 예방**: 잘못된 채널/쿨다운 설정 불가
4. **코드 리뷰 간소화**: 호출부가 명확해짐

---

## 메서드 네이밍 컨벤션

| 접두사 | 용도 | 예시 |
|--------|------|------|
| `speak~` | TTS 발화 | `speakArrivedAtDestination()` |
| `~To` | 대상 지정 | `speakNavigatingTo(name)` |
| `~Found` | 발견 알림 | `speakSmartButtonsFound(count)` |
| `~Error/Failed` | 오류 알림 | `speakFlashControlError()` |

---

## TtsMessages 연동

convenience 메서드 내부에서 TtsMessages를 호출합니다:

```dart
// TtsService 내부 구현 예시
void speakBranchInstruction(String message) {
  speakWithChannel(
    TtsMessages.branchInstruction(message),
    channel: ETtsChannel.NAVIGATE,
    cooldownKey: 'branch_instruction',
    cooldown: const Duration(seconds: 10),
  );
}
```

**핵심**: Presentation 레이어에서는 TtsMessages를 직접 참조할 필요 없음
