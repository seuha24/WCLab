# BLE 리팩토링 기획서

> **작성일**: 2026-01-15
> **버전**: 1.2 (연결 후 명령 버튼 UI 추가)
> **상태**: 기획 완료, 구현 대기

---

## 1. 개요

### 1.1 목적
BLE 연결 방식을 개선하여 사용자 경험 향상 및 불필요한 기능 제거

### 1.2 주요 변경사항
| 번호 | 기능 | 현재 | 변경 |
|------|------|------|------|
| 1 | 수동 BLE 연결 | 패널 열면 자동 스캔 | 버튼 클릭 후 스캔 |
| 2 | 자동 BLE 연동 | 없음 | GPS 기반 자동 연결 |
| 3 | 방향 안내 | dir, pos, Compass 존재 | 전체 제거 |

---

## 2. 현재 코드 구조 참조 (필독)

### 2.1 Entity 관계 이해

```
┌─────────────────────────────────────────────────────────────────────┐
│                   두 가지 음향신호기 데이터                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────┐    ┌─────────────────────────────┐    │
│  │   Crosswalk (BLE)       │    │   SignalDevice (공공DB)     │    │
│  │                         │    │                             │    │
│  │  - BLE 스캔으로 발견    │    │  - 서울시 CSV 8,000개+      │    │
│  │  - 실제 기기 객체 포함  │    │  - GPS 좌표만 있음          │    │
│  │  - 15m 범위             │    │  - 1000m 범위 표시          │    │
│  │                         │    │                             │    │
│  │  post: DiscoveredDevice │    │  latitude, longitude        │    │
│  │  name: String           │    │  managementId: String       │    │
│  │  type: ECrosswalk       │    │  direction: int?            │    │
│  │  dir: String? (제거예정)│    │                             │    │
│  │  pos: LatLng? (제거예정)│    │                             │    │
│  └─────────────────────────┘    └─────────────────────────────┘    │
│                                                                     │
│  ※ Crosswalk = BLE로 연결 가능한 실제 기기                          │
│  ※ SignalDevice = GPS 위치만 있는 공공 DB 정보                      │
│  ※ 자동 연결: SignalDevice 위치 근처 → BLE 스캔 → Crosswalk 발견    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 현재 CrosswalkState 구조

**파일**: `lib/presentation/bloc/crosswalk_bloc/crosswalk_state.dart`

```dart
// 현재 구조 (변경 전)
abstract class CrosswalkState extends Equatable {}

class SearchOn extends CrosswalkState {
  final bool infinite;  // true: 무한스캔, false: 1회스캔
}

class SearchOff extends CrosswalkState {
  final List<Crosswalk> results;  // 스캔 결과
}

class CrosswalkError extends CrosswalkState {
  final String message;
}

class ConnectOn extends CrosswalkState {}  // 연결 중

class ConnectOff extends CrosswalkState {
  final bool enableCompass;  // 제거 예정
  final LatLng? latLng;      // 제거 예정
}
```

### 2.3 현재 CrosswalkEvent 구조

**파일**: `lib/presentation/bloc/crosswalk_bloc/crosswalk_event.dart`

```dart
// 현재 구조
abstract class CrosswalkEvent extends Equatable {}

class SearchFiniteCrosswalkEvent extends CrosswalkEvent {}      // 1회 스캔
class SearchInfiniteCrosswalkEvent extends CrosswalkEvent {}    // 무한 스캔

class SendAcousticSignalEvent extends CrosswalkEvent {          // 신호안내 (0x02)
  final Crosswalk crosswalk;
}
class SendVoiceInductorEvent extends CrosswalkEvent {           // 위치안내 (0x01)
  final Crosswalk crosswalk;
}
class SendVoiceGuideEvent extends CrosswalkEvent {              // 음성안내 (0x03)
  final Crosswalk crosswalk;
}
```

### 2.4 TtsService 구조

**파일**: `lib/data/services/tts_service.dart`

```dart
// TTS 서비스 - convenience 메서드 패턴 사용
class TtsService {
  // 기본 메서드
  Future<void> speak(String text);
  Future<void> speakWithChannel(String text, {required ETtsChannel channel, ...});

  // BLE 관련 convenience 메서드 (기존)
  void speakAutoScanStarted();           // "자동 스캔이 시작됩니다"
  void speakSmartButtonsFound(int count); // "N개의 스마트 압버튼을 찾았습니다"
  void speakRequestSignalGuide(String name);
  void speakCommandSent();
  void speakConnectionFailed();
  // ... 등
}
```

**파일**: `lib/core/utils/tts_messages.dart`

```dart
// TTS 문자열 중앙 관리
abstract class TtsMessages {
  static const String autoScanStarted = '자동 스캔이 시작됩니다.';
  static String smartButtonsFound(int count) => '$count 개의 스마트 압버튼을 찾았습니다.';
  // ... 등
}
```

### 2.5 DI 등록 패턴

**파일**: `lib/injection.dart`

```dart
// 서비스 등록 예시
DI.registerLazySingleton<TtsService>(
  () => TtsService(DI<FlutterTts>()),
);

// UseCase 등록 예시
DI.registerLazySingleton<GetNearbySignalDevices>(
  () => GetNearbySignalDevices(repository: DI()),
);

// Bloc 등록 예시 (Factory)
DI.registerFactory(
  () => CrosswalkBloc(...),
  instanceName: BLOC_BLUE_SEARCH_FINITE,
);
```

### 2.6 GPS 업데이트 위치

**파일**: `lib/presentation/controllers/map_view_controller.dart`

```dart
// GPS 업데이트가 일어나는 메서드
Future<void> _getLocation() async {
  Position position = await Geolocator.getCurrentPosition(...);

  currentLatitude.value = position.latitude;
  currentLongitude.value = position.longitude;

  // 센서 업데이트 호출
  onSensorUpdate(
    currentLatitude.value,
    currentLongitude.value,
    compassValue.value,
    isGpsAccurate.value,
  );

  // ⭐ 여기에 자동 BLE 연결 트리거 추가 예정
}

// 100ms마다 호출됨 (_initLocation에서 Timer.periodic 설정)
Timer.periodic(Duration(milliseconds: 100), (timer) {
  _getLocation();
});
```

---

## 3. 기능 1: BLE 수동 연결 UI/UX 수정

### 3.1 현재 플로우
```
패널 열기 → 자동 SearchInfiniteCrosswalk 시작 → 20초마다 반복 스캔 → 결과 표시
```

### 3.2 변경 플로우
```
패널 열기 → 초기 화면 (BLE 찾기 버튼) → 버튼 클릭 → 찾는 중 (로딩) → 찾은 리스트 표시
                                                                    ↓
                                                              결과 없음 → 다시찾기 버튼
```

### 3.3 UI 상태 설계

#### 상태 1: 초기 화면
```
┌─────────────────────────────────────┐
│           횡단보도                    │
├─────────────────────────────────────┤
│                                     │
│      🔍 주변 음향신호기를 찾으려면    │
│         아래 버튼을 눌러주세요        │
│                                     │
│     ┌─────────────────────────┐     │
│     │    🔵 BLE 찾기          │     │
│     └─────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

#### 상태 2: 찾는 중
```
┌─────────────────────────────────────┐
│           횡단보도                    │
├─────────────────────────────────────┤
│                                     │
│            ⟳ (로딩)                 │
│                                     │
│      주변 음향신호기를 찾는 중...     │
│                                     │
│     ┌─────────────────────────┐     │
│     │       ⏹ 중단            │     │
│     └─────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

#### 상태 3: 결과 있음
```
┌─────────────────────────────────────┐
│           횡단보도                    │
├─────────────────────────────────────┤
│                                     │
│  🚦 단일 신호등 지역                 │
│      AHG001+BBA050E123D4+           │
│                                     │
│  🚦 교차로 지역                      │
│      AHG001+CCA123F456E7+           │
│                                     │
│     ┌─────────────────────────┐     │
│     │    🔄 다시찾기           │     │
│     └─────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

#### 상태 4: 결과 없음
```
┌─────────────────────────────────────┐
│           횡단보도                    │
├─────────────────────────────────────┤
│                                     │
│      ❌ 주변에서 음향신호기를         │
│         찾을 수 없습니다             │
│                                     │
│     ┌─────────────────────────┐     │
│     │    🔄 다시찾기           │     │
│     └─────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

### 3.4 State 변경 상세

**기존 State 유지**, 새로운 State 추가:

```dart
// 추가할 State
class CrosswalkInitial extends CrosswalkState {}  // 초기 화면

// 기존 State 유지 (이름 변경 없음)
// SearchOn      → 찾는 중
// SearchOff     → 결과 표시 (results.isEmpty면 결과 없음)
// ConnectOn     → 연결 중
// ConnectOff    → 연결 완료 (단순화 예정)
// CrosswalkError → 에러
```

### 3.5 Event 변경 상세

```dart
// 추가할 Event
class StopScanEvent extends CrosswalkEvent {}  // 스캔 중단

// 기존 Event 활용
// SearchFiniteCrosswalkEvent → "BLE 찾기" 버튼 클릭 시 발생
```

### 3.6 구현 파일 (전체 경로)

| 파일 | 변경 내용 |
|------|-----------|
| `lib/presentation/bloc/crosswalk_bloc/crosswalk_state.dart` | `CrosswalkInitial` State 추가 |
| `lib/presentation/bloc/crosswalk_bloc/crosswalk_event.dart` | `StopScanEvent` Event 추가 |
| `lib/presentation/bloc/crosswalk_bloc/crosswalk_bloc.dart` | 초기 상태 → `CrosswalkInitial`, 스캔 중단 핸들러 추가 |
| `lib/presentation/views/crosswalk_panel_view.dart` | UI 플로우 전면 수정 |
| `lib/data/services/tts_service.dart` | 새 TTS 메서드 추가 |
| `lib/core/utils/tts_messages.dart` | 새 TTS 문자열 추가 |

### 3.7 TTS 추가 사항

**`lib/core/utils/tts_messages.dart`에 추가:**
```dart
// BLE 수동 연결 관련
static const String bleScanPrompt = 'BLE 찾기 버튼을 눌러 주변 음향신호기를 검색하세요';
static const String bleScanning = '주변 음향신호기를 찾고 있습니다';
static const String bleNotFound = '주변에서 음향신호기를 찾을 수 없습니다';
```

**`lib/data/services/tts_service.dart`에 추가:**
```dart
/// BLE 찾기 안내
void speakBleScanPrompt() {
  speak(TtsMessages.bleScanPrompt);
}

/// BLE 스캔 중 안내
void speakBleScanning() {
  speak(TtsMessages.bleScanning);
}

/// BLE 찾지 못함 안내
void speakBleNotFound() {
  speak(TtsMessages.bleNotFound);
}
```

### 3.8 CrosswalkBloc 변경 상세

```dart
// 변경 전
CrosswalkBloc(...) : super(SearchOff(results: const [])) {
  // 기존 초기 상태: SearchOff (빈 결과)
}

// 변경 후
CrosswalkBloc(...) : super(CrosswalkInitial()) {
  on<StopScanEvent>(_stopScanEvent);  // 추가
  // ... 기존 핸들러들
}

// 스캔 중단 핸들러 추가
Future _stopScanEvent(
  StopScanEvent event,
  Emitter<CrosswalkState> emit,
) async {
  if (BlueNativeDataSourceImpl.subscription != null) {
    BlueNativeDataSourceImpl.subscription!.cancel();
  }
  timer.cancel();
  emit(CrosswalkInitial());  // 초기 화면으로 돌아감
}
```

---

## 4. 기능 2: 자동 BLE 연동

### 4.1 개념
공공 DB(SignalDevice)의 음향신호기 위치를 기반으로, 사용자가 해당 위치에 접근하면 자동으로 BLE 연결 및 신호안내 명령 전송

### 4.2 플로우
```
┌──────────────────────────────────────────────────────────────────────┐
│                         자동 BLE 연동 플로우                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [GPS 위치 업데이트] - MapViewController._getLocation()              │
│         │                                                            │
│         ▼                                                            │
│  [AutoBleConnectionService.checkAndConnect()]                        │
│         │                                                            │
│         ▼                                                            │
│  [GetNearbySignalDevices UseCase]                                   │
│  "반경 30m 이내 SignalDevice 조회"                                   │
│         │                                                            │
│         ├─── 없음 ──→ 대기 (다음 GPS 업데이트까지)                    │
│         │                                                            │
│         └─── 있음 ──→ [쿨다운 확인]                                  │
│                              │                                       │
│                              ├─── 쿨다운 중 ──→ 스킵                  │
│                              │                                       │
│                              └─── 아니오 ──→ [BLE 스캔 (1초)]         │
│                                                    │                 │
│                                                    ▼                 │
│                                          [스캔 결과 있음?]           │
│                                                    │                 │
│                                          ├─ 없음 → 스킵              │
│                                          │                           │
│                                          └─ 있음 → [자동 연결]       │
│                                                    │                 │
│                                                    ▼                 │
│                                          [CMD_SIGNAL (0x02) 전송]    │
│                                                    │                 │
│                                                    ▼                 │
│                                          [쿨다운 등록]               │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 4.3 핵심 파라미터

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| 트리거 거리 | 30m | SignalDevice 위치로부터 30m 이내 진입 시 |
| 자동 명령 | CMD_SIGNAL (0x02) | 신호안내 명령 자동 전송 |
| 쿨다운 방식 | 범위 이탈 기반 | 30m 범위를 벗어나면 쿨다운 해제 |
| BLE 스캔 시간 | 1초 | FiniteTimes 스캔 (1회) |

### 4.4 아키텍처 레이어 및 파일 위치

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Clean Architecture 레이어                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Presentation Layer (presentation/)                                 │
│  └── controllers/                                                   │
│      └── map_view_controller.dart  ← GPS 업데이트 시 서비스 호출    │
│                                                                     │
│  Data Layer (data/)                                                 │
│  └── services/                                                      │
│      ├── auto_ble_connection_service.dart  ← 신규 (자동 연결 로직)  │
│      └── tts_service.dart                                           │
│                                                                     │
│  Core Layer (core/)                                                 │
│  └── utils/                                                         │
│      └── auto_connect_cooldown_manager.dart  ← 신규 (쿨다운 관리)   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.5 구현 파일 (전체 경로)

| 파일 | 변경 내용 | 신규/수정 |
|------|-----------|-----------|
| `lib/core/utils/auto_connect_cooldown_manager.dart` | 쿨다운 관리 클래스 | 신규 |
| `lib/data/services/auto_ble_connection_service.dart` | 자동 연결 서비스 | 신규 |
| `lib/presentation/controllers/map_view_controller.dart` | `_getLocation()`에서 자동 연결 호출 | 수정 |
| `lib/injection.dart` | 새 클래스 DI 등록 | 수정 |
| `lib/data/services/tts_service.dart` | 자동 연결 TTS 메서드 추가 | 수정 |
| `lib/core/utils/tts_messages.dart` | 자동 연결 TTS 문자열 추가 | 수정 |

### 4.6 AutoConnectCooldownManager 구현

**파일**: `lib/core/utils/auto_connect_cooldown_manager.dart`

```dart
/// 자동 연결 쿨다운 관리
///
/// 30m 범위 내에 있는 동안 재연결 방지
/// 범위를 벗어나면 쿨다운 해제
class AutoConnectCooldownManager {
  final Set<String> _activeConnections = {};

  /// 쿨다운 등록 (연결 성공 시)
  void addCooldown(String signalDeviceId) {
    _activeConnections.add(signalDeviceId);
  }

  /// 쿨다운 해제 (범위 이탈 시)
  void removeCooldown(String signalDeviceId) {
    _activeConnections.remove(signalDeviceId);
  }

  /// 쿨다운 상태 확인
  bool isInCooldown(String signalDeviceId) {
    return _activeConnections.contains(signalDeviceId);
  }

  /// 범위 이탈한 SignalDevice들의 쿨다운 해제
  ///
  /// [nearbyDevices]: 현재 30m 이내 SignalDevice 목록
  void updateCooldowns(List<SignalDevice> nearbyDevices) {
    final nearbyIds = nearbyDevices.map((d) => d.managementId).toSet();
    _activeConnections.removeWhere((id) => !nearbyIds.contains(id));
  }

  /// 전체 초기화
  void clearAll() {
    _activeConnections.clear();
  }
}
```

### 4.7 AutoBleConnectionService 구현

**파일**: `lib/data/services/auto_ble_connection_service.dart`

```dart
import 'package:latlong2/latlong.dart';
import 'package:safelight/core/utils/auto_connect_cooldown_manager.dart';
import 'package:safelight/data/services/tts_service.dart';
import 'package:safelight/domain/entities/signal_device.dart';
import 'package:safelight/domain/usecases/signal_device_usecase.dart';
import 'package:safelight/domain/usecases/crosswalk_usecase.dart';
import 'package:safelight/framework/core.dart';

/// 자동 BLE 연결 서비스
///
/// GPS 위치 업데이트 시 호출되어 주변 음향신호기에 자동 연결
class AutoBleConnectionService {
  final GetNearbySignalDevices _getNearbySignalDevices;
  final SearchCrosswalk _search2FiniteTimes;
  final ConnectCrosswalk _sendAcousticSignal;
  final TtsService _ttsService;
  final AutoConnectCooldownManager _cooldownManager;

  /// 자동 연결 활성화 여부
  bool isEnabled = true;

  /// 트리거 거리 (미터)
  static const double triggerDistance = 30.0;

  AutoBleConnectionService({
    required GetNearbySignalDevices getNearbySignalDevices,
    required SearchCrosswalk search2FiniteTimes,
    required ConnectCrosswalk sendAcousticSignal,
    required TtsService ttsService,
    required AutoConnectCooldownManager cooldownManager,
  })  : _getNearbySignalDevices = getNearbySignalDevices,
        _search2FiniteTimes = search2FiniteTimes,
        _sendAcousticSignal = sendAcousticSignal,
        _ttsService = ttsService,
        _cooldownManager = cooldownManager;

  /// GPS 위치 업데이트 시 호출
  ///
  /// [latitude], [longitude]: 현재 위치
  Future<void> checkAndConnect(double latitude, double longitude) async {
    if (!isEnabled) return;

    // 1. 30m 이내 SignalDevice 조회
    final result = await _getNearbySignalDevices(
      GetNearbySignalDevicesParams(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: triggerDistance,
      ),
    );

    final nearbyDevices = result.fold(
      (failure) => <SignalDevice>[],
      (devices) => devices,
    );

    // 2. 범위 이탈한 기기들 쿨다운 해제
    _cooldownManager.updateCooldowns(nearbyDevices);

    // 3. 연결 가능한 기기 찾기 (쿨다운 아닌 것)
    final targetDevice = nearbyDevices.firstWhereOrNull(
      (device) => !_cooldownManager.isInCooldown(device.managementId),
    );

    if (targetDevice == null) return;

    // 4. BLE 스캔 (1초)
    _ttsService.speakAutoConnectStarted();

    final scanResult = await _search2FiniteTimes(NoParams());
    final scannedDevices = scanResult.fold(
      (failure) => null,
      (devices) => devices,
    );

    if (scannedDevices == null || scannedDevices.isEmpty) return;

    // 5. 가장 강한 신호의 기기 선택
    scannedDevices.sort((a, b) => b.post.rssi.compareTo(a.post.rssi));
    final targetCrosswalk = scannedDevices.first;

    // 6. 자동 연결 및 신호안내 전송
    await _sendAcousticSignal(targetCrosswalk);

    _ttsService.speakAutoConnectSuccess();

    // 7. 쿨다운 등록
    _cooldownManager.addCooldown(targetDevice.managementId);
  }
}

// List extension
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
```

### 4.8 DI 등록 추가

**파일**: `lib/injection.dart`에 추가:

```dart
// 쿨다운 매니저 (싱글톤)
DI.registerLazySingleton<AutoConnectCooldownManager>(
  () => AutoConnectCooldownManager(),
);

// 자동 BLE 연결 서비스 (싱글톤)
DI.registerLazySingleton<AutoBleConnectionService>(
  () => AutoBleConnectionService(
    getNearbySignalDevices: DI(),
    search2FiniteTimes: DI(instanceName: USECASE_SEARCH_CROSSWALK_FINITE),
    sendAcousticSignal: DI(instanceName: USECASE_SEND_ACOUSTIC_SIGNAL),
    ttsService: DI(),
    cooldownManager: DI(),
  ),
);
```

### 4.9 MapViewController 수정

**파일**: `lib/presentation/controllers/map_view_controller.dart`

```dart
// 클래스 멤버 추가
late final AutoBleConnectionService _autoBleService;

// onInit()에서 초기화
@override
void onInit() {
  super.onInit();
  _autoBleService = DI.get<AutoBleConnectionService>();
  // ... 기존 코드
}

// _getLocation() 메서드 내부에 추가
Future<void> _getLocation() async {
  // ... 기존 GPS 로직 ...

  onSensorUpdate(
    currentLatitude.value,
    currentLongitude.value,
    compassValue.value,
    isGpsAccurate.value,
  );

  // ⭐ 자동 BLE 연결 체크 (추가)
  _autoBleService.checkAndConnect(
    currentLatitude.value,
    currentLongitude.value,
  );
}
```

### 4.10 TTS 추가 사항

**`lib/core/utils/tts_messages.dart`에 추가:**
```dart
// 자동 BLE 연결 관련
static const String autoConnectStarted = '주변 음향신호기에 자동으로 연결합니다';
static const String autoConnectSuccess = '음향신호기에 연결되었습니다. 신호안내를 요청합니다';
static const String autoConnectFailed = '음향신호기 연결에 실패했습니다';
```

**`lib/data/services/tts_service.dart`에 추가:**
```dart
/// 자동 연결 시작 안내
void speakAutoConnectStarted() {
  speakWithChannel(
    TtsMessages.autoConnectStarted,
    channel: ETtsChannel.SYSTEM_ANNOUNCE,
    cooldownKey: 'auto_connect_start',
    cooldown: const Duration(seconds: 5),
  );
}

/// 자동 연결 성공 안내
void speakAutoConnectSuccess() {
  speakWithChannel(
    TtsMessages.autoConnectSuccess,
    channel: ETtsChannel.SYSTEM_ANNOUNCE,
    cooldownKey: 'auto_connect_success',
    cooldown: const Duration(seconds: 5),
  );
}

/// 자동 연결 실패 안내
void speakAutoConnectFailed() {
  speakWithChannel(
    TtsMessages.autoConnectFailed,
    channel: ETtsChannel.SYSTEM_ANNOUNCE,
    cooldownKey: 'auto_connect_fail',
    cooldown: const Duration(seconds: 10),
  );
}
```

---

## 5. 기능 3: 방향 안내 기능 제거

### 5.1 제거 대상 (전체 경로)

| 구분 | 제거 대상 | 파일 |
|------|-----------|------|
| Entity 필드 | `Crosswalk.dir` | `lib/domain/entities/crosswalk.dart` |
| Entity 필드 | `Crosswalk.pos` | `lib/domain/entities/crosswalk.dart` |
| Widget | `Compass` 위젯 | `lib/presentation/widgets/compass.dart` (있다면) |
| State 필드 | `ConnectOff.enableCompass` | `lib/presentation/bloc/crosswalk_bloc/crosswalk_state.dart` |
| State 필드 | `ConnectOff.latLng` | `lib/presentation/bloc/crosswalk_bloc/crosswalk_state.dart` |
| Bloc 로직 | Compass 활성화 로직 | `lib/presentation/bloc/crosswalk_bloc/crosswalk_bloc.dart` |
| UI | 방향 표시 및 나침반 | `lib/presentation/views/crosswalk_panel_view.dart` |

### 5.2 제거 이유

커밋 `af6977203f09f8ad7f8f0c9adcec011b9d25c9b0`에서 테스트한 결과:
- 공공데이터의 `direction` 필드는 **횡단보도 경로 방향이 아님**
- 음향신호기가 바라보는 방향(설치 방향)으로 추정
- 사용자에게 의미있는 정보를 제공하지 못함
- 오히려 혼란을 줄 수 있음

### 5.3 Crosswalk Entity 변경

**파일**: `lib/domain/entities/crosswalk.dart`

```dart
// 변경 전
class Crosswalk extends Equatable {
  final String name;
  final DiscoveredDevice post;
  final ECrosswalk type;
  final String? dir;        // 제거
  final LatLng? pos;        // 제거

  const Crosswalk({
    this.name = '횡단보도',
    required this.post,
    this.type = ECrosswalk.UNKNOWN,
    this.dir,               // 제거
    this.pos,               // 제거
  });
}

// 변경 후
class Crosswalk extends Equatable {
  final String name;
  final DiscoveredDevice post;
  final ECrosswalk type;

  const Crosswalk({
    this.name = '횡단보도',
    required this.post,
    this.type = ECrosswalk.UNKNOWN,
  });
}
```

### 5.4 ConnectOff State 변경

**파일**: `lib/presentation/bloc/crosswalk_bloc/crosswalk_state.dart`

```dart
// 변경 전
class ConnectOff extends CrosswalkState {
  final bool enableCompass;
  final LatLng? latLng;

  ConnectOff({required this.enableCompass, this.latLng});

  @override
  List<Object?> get props => [enableCompass];
}

// 변경 후
class ConnectOff extends CrosswalkState {
  // 단순 연결 완료 상태만 유지
  // 필드 없음
}
```

### 5.5 CrosswalkBloc 변경

**파일**: `lib/presentation/bloc/crosswalk_bloc/crosswalk_bloc.dart`

```dart
// 변경 전 (_sendAcousticSignalEvent 내부)
if (event.crosswalk.pos != null) {
  final results = await getCurrentPosition(NoParams());
  results.fold(
    (failure) {
      emit(ConnectOff(enableCompass: false));
    },
    (latLng) async {
      tts.speakCommandSent();
      bool enableCompass = true;
      if (Platform.isAndroid) {
        enableCompass = false;
      }
      emit(ConnectOff(enableCompass: enableCompass, latLng: latLng));
    },
  );
} else {
  tts.speakCommandSent();
  emit(ConnectOff(enableCompass: false));
}

// 변경 후 (단순화)
tts.speakCommandSent();
emit(ConnectOff());
```

### 5.6 연결 성공 후 UI 변경

```
// 변경 전: 나침반 화면
┌─────────────────────────────────────┐
│           안전 리모콘                │
├─────────────────────────────────────┤
│            🧭 (나침반)              │
│           "12시 방향으로             │
│            이동하세요"               │
│     ┌─────────────────────────┐     │
│     │        종료              │     │
│     └─────────────────────────┘     │
└─────────────────────────────────────┘

// 변경 후: 연결 성공 메시지 + 3가지 명령 버튼
┌─────────────────────────────────────┐
│           안전 리모콘                │
├─────────────────────────────────────┤
│  ✅ 음향신호기에 연결되었습니다       │
├─────────────────────────────────────┤
│                                     │
│  📍 위치 안내                    >  │ ← 0x31 0x00 0x01
│                                     │
│  🚦 신호 안내                    >  │ ← 0x31 0x00 0x02
│                                     │
│  🔊 음성 안내                    >  │ ← 0x31 0x00 0x03
│                                     │
│     ┌─────────────────────────┐     │
│     │        종료              │     │
│     └─────────────────────────┘     │
└─────────────────────────────────────┘
```

#### 명령 버튼 설명

| 버튼 | 명령 코드 | 설명 |
|------|-----------|------|
| 위치 안내 | `[0x31, 0x00, 0x01]` | 음향신호기 위치 안내 음성 재생 |
| 신호 안내 | `[0x31, 0x00, 0x02]` | 현재 신호 상태 안내 (빨간불/파란불) |
| 음성 안내 | `[0x31, 0x00, 0x03]` | 음향신호기 음성 안내 재생 |

#### 연결 성공 후 플로우

```
명령 버튼 클릭 → ConnectOn 상태 (로딩) → 명령 전송 완료 → ConnectOff 상태 (동일 화면 유지)
                                                            ↓
                                                   다른 명령 버튼 클릭 가능
                                                            ↓
                                                   종료 버튼으로 모달 닫기
```

> **핵심**: 연결 성공 후에도 사용자가 **다른 명령을 추가로 보낼 수 있도록** 3가지 버튼을 계속 표시

### 5.7 영향받는 파일 및 변경 사항

| 파일 | 변경 내용 |
|------|-----------|
| `lib/domain/entities/crosswalk.dart` | dir, pos 필드 제거 |
| `lib/presentation/bloc/crosswalk_bloc/crosswalk_state.dart` | ConnectOff 단순화 |
| `lib/presentation/bloc/crosswalk_bloc/crosswalk_bloc.dart` | 3개 이벤트 핸들러 단순화 |
| `lib/presentation/views/crosswalk_panel_view.dart` | Compass UI 제거, 성공 화면 단순화 |
| `lib/data/repositories/crosswalk_repository_impl.dart` | Crosswalk 생성 시 dir, pos 제거 |

---

## 6. 구현 계획

### 6.1 구현 순서

| 순서 | 기능 | 예상 영향도 | 의존성 |
|------|------|-------------|--------|
| 1 | 방향 안내 기능 제거 | 낮음 | 없음 |
| 2 | BLE 수동 연결 UI/UX 수정 | 중간 | 1번 완료 후 |
| 3 | 자동 BLE 연동 | 높음 | 2번 완료 후 |

### 6.2 상세 구현 체크리스트

#### Phase 1: 방향 안내 기능 제거 + 연결 성공 후 명령 버튼 UI 추가
- [x] `lib/domain/entities/crosswalk.dart` - dir, pos 필드 제거
- [x] `lib/data/models/crosswalk_model.dart` - dir, pos 필드 제거
- [x] `lib/data/sources/crosswalk_remote_data_source.dart` - dir, pos 제거, Distance 의존성 제거
- [x] `lib/presentation/bloc/crosswalk_bloc/crosswalk_state.dart` - ConnectOff 단순화 (enableCompass, latLng 제거)
- [x] `lib/presentation/bloc/crosswalk_bloc/crosswalk_bloc.dart` - Compass 관련 로직 제거 (3개 핸들러 단순화, getCurrentPosition 의존성 제거)
- [x] `lib/presentation/views/crosswalk_panel_view.dart` - Compass UI 제거, dir 필드 표시 제거
- [x] `lib/presentation/views/crosswalk_panel_view.dart` - **ConnectOff 상태에서 3가지 명령 버튼 UI 추가**
  - [x] 위치 안내 버튼 (SendVoiceGuideEvent → 0x31 0x00 0x03)
  - [x] 신호 안내 버튼 (SendAcousticSignalEvent → 0x31 0x00 0x02)
  - [x] 음성 안내 버튼 (SendVoiceInductorEvent → 0x31 0x00 0x01)
  - [x] 종료 버튼
- [x] `lib/injection.dart` - CrosswalkRemoteDataSourceImpl, CrosswalkBloc DI 등록 수정
- [x] `lib/presentation/widgets/compass.dart` - 삭제
- [x] `lib/framework/ui.dart` - compass.dart part 선언 제거, flutter_compass import 제거
- [x] `lib/presentation/views/tutorial_view.dart` - 안전 나침반 튜토리얼 페이지(buildPage4) 제거
- [x] `flutter build apk` 빌드 테스트 ✅

#### Phase 2: BLE 수동 연결 UI/UX 수정
- [ ] `lib/presentation/bloc/crosswalk_bloc/crosswalk_state.dart` - `CrosswalkInitial` State 추가
- [ ] `lib/presentation/bloc/crosswalk_bloc/crosswalk_event.dart` - `StopScanEvent` Event 추가
- [ ] `lib/presentation/bloc/crosswalk_bloc/crosswalk_bloc.dart`
  - [ ] 초기 상태 `CrosswalkInitial`로 변경
  - [ ] `StopScanEvent` 핸들러 추가
- [ ] `lib/core/utils/tts_messages.dart` - 새 TTS 문자열 추가
- [ ] `lib/data/services/tts_service.dart` - 새 TTS 메서드 추가
- [ ] `lib/presentation/views/crosswalk_panel_view.dart` - UI 전면 수정
  - [ ] 초기 화면 (BLE 찾기 버튼)
  - [ ] 찾는 중 화면 (로딩 + 중단 버튼)
  - [ ] 결과 화면 (리스트 + 다시찾기)
  - [ ] 결과 없음 화면
- [ ] `flutter build apk` 빌드 테스트

#### Phase 3: 자동 BLE 연동
- [ ] `lib/core/utils/auto_connect_cooldown_manager.dart` - 신규 생성
- [ ] `lib/data/services/auto_ble_connection_service.dart` - 신규 생성
- [ ] `lib/core/utils/tts_messages.dart` - 자동 연결 TTS 문자열 추가
- [ ] `lib/data/services/tts_service.dart` - 자동 연결 TTS 메서드 추가
- [ ] `lib/injection.dart` - DI 등록 추가
- [ ] `lib/presentation/controllers/map_view_controller.dart`
  - [ ] `_autoBleService` 멤버 추가
  - [ ] `onInit()`에서 초기화
  - [ ] `_getLocation()`에서 `checkAndConnect()` 호출
- [ ] `flutter build apk` 빌드 테스트
- [ ] 실기기 테스트 (GPS + BLE)

---

## 7. 테스트 계획

### 7.1 기능 테스트

| 테스트 항목 | 예상 결과 |
|-------------|-----------|
| 패널 열기 | 초기 화면 표시 (BLE 찾기 버튼) |
| BLE 찾기 버튼 클릭 | 스캔 시작, 로딩 표시 |
| 스캔 중단 버튼 클릭 | 스캔 중단, 초기 화면으로 돌아감 |
| 스캔 완료 (결과 있음) | 리스트 표시 |
| 스캔 완료 (결과 없음) | 실패 메시지 + 다시찾기 버튼 |
| 리스트 항목 클릭 | 안전 리모콘 모달 표시 |
| 명령 버튼 클릭 (위치/신호/음성) | 해당 명령 전송, ConnectOff 상태로 전환 |
| 연결 완료 | 연결 성공 메시지 + 3가지 명령 버튼 표시 |
| 연결 후 다른 명령 클릭 | 추가 명령 전송 가능 |
| 자동 연결 (30m 진입) | BLE 스캔 → 자동 연결 → 신호안내 |
| 자동 연결 후 재진입 | 쿨다운으로 인해 연결 안됨 |
| 자동 연결 후 범위 이탈 후 재진입 | 다시 자동 연결 |

### 7.2 에지 케이스

| 케이스 | 처리 방법 |
|--------|-----------|
| GPS 정확도 낮음 | 30m 버퍼로 충분히 커버 |
| BLE 스캔 실패 | 에러 무시, 다음 GPS 업데이트 때 재시도 |
| 동시에 여러 SignalDevice 진입 | 가장 가까운 1개만 처리 |
| 배터리 절약 모드 | GPS 업데이트 주기에 따라 자동 조절 |

---

## 8. 위험 요소 및 대응

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|-----------|
| GPS 오차로 잘못된 트리거 | 중 | 30m 버퍼로 어느 정도 커버 |
| 배터리 소모 증가 | 중 | `isEnabled` 플래그로 비활성화 가능 |
| BLE 스캔 실패 | 하 | 에러 무시, 재시도 |
| SignalDevice DB 누락 | 중 | 수동 연결 기능 유지 |

---

## 9. 참고 자료

- **경찰청 음향신호기 규격서**: `docs/횡단보도 개선 문서/시각장애인용 음향신호기 규격서.md`
- **BLE 기능 개선 TODO 리스트**: `docs/횡단보도 개선 문서/BLE 기능 개선 TODO 리스트.md`
- **공공데이터 횡단보도 연동 기획서**: `docs/횡단보도 개선 문서/음향신호기 DB/공공데이터 횡단보도 연동 기획서.md`
- **테스트 커밋**: `af6977203f09f8ad7f8f0c9adcec011b9d25c9b0`

---

**작성자**: SafeLight 개발팀
**최종 수정**: 2026-01-20
**버전**: 1.2 (연결 후 명령 버튼 UI 추가)
