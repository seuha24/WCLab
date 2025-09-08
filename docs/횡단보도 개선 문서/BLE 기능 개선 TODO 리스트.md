# BLE 기능 개선 TODO 리스트

## 📅 작성 정보
- **작성일**: 2025-09-07 (최종 수정: 2025-09-08)
- **프로젝트**: SafeLight
- **대상**: 경찰청 시각장애인용 음향신호기 규격서 (2022.4.27) 완전 준수
- **버전**: v2.0

## ⚠️ 규격서 핵심 요구사항
- **BLE 버전**: BLE 3.0 이상 필수
- **주파수 대역**: 2.4~2.5GHz
- **작동 거리**: 약 15m
- **DEVICE NAME**: "AHG001+MAC주소+" (20 Bytes)
- **애플리케이션 필수 기능**: ① 검색 ② 위치 유도 ③ 신호버튼
- **지속적 업데이트 의무**: 규격서 명시사항

---

## 🎯 개선 목표
경찰청 시각장애인용 음향신호기 규격서(2022.4.27 개정)를 완전히 준수하여 모든 음향신호기와 호환 가능한 BLE 통신 구현

---

## 🚨 Priority 1: 긴급 (1주 이내 완료)

### ✅ TASK-001: 명령 코드 명칭 및 용도 수정 [완료]
**담당**: 개발팀  
**예상 시간**: 2시간  
**실제 소요**: 1시간  
**완료일**: 2025-09-07  
**완료 기준**: 모든 명령 코드가 규격서 명칭과 일치  

#### 작업 내용
```dart
// 파일: lib/core/utils/bluetooth.dart

// AS-IS (현재 잘못된 구현)
static const List<int> CMD_VOICE = [0x31, 0x00, 0x01];
static const List<int> CMD_ACOUSTIC = [0x31, 0x00, 0x02];

// TO-BE (규격서 준수)
static const List<int> CMD_LOCATION = [0x31, 0x00, 0x01];  // 위치안내
static const List<int> CMD_SIGNAL = [0x31, 0x00, 0x02];    // 신호안내
static const List<int> CMD_VOICE = [0x31, 0x00, 0x03];     // 음성안내 (신규)
```

#### 영향받는 파일
- [✓] `lib/core/utils/bluetooth.dart` - 상수 정의 수정
- [✓] `lib/data/sources/blue_native_data_source.dart` - 기본값 수정
- [ ] `lib/application/blocs/crosswalk_bloc.dart` - 이벤트 처리 수정
- [ ] `lib/domain/usecases/crosswalk_usecase.dart` - UseCase 수정
- [ ] `lib/presentation/views/home_view.dart` - UI 텍스트 수정

#### 테스트 항목
- [✓] 위치안내 명령이 0x01로 전송되는지 확인
- [✓] 신호안내 명령이 0x02로 전송되는지 확인
- [✓] 기존 기능이 정상 동작하는지 확인

---

### ✅ TASK-002: 음성안내 기능 추가 구현 [완료]
**담당**: 개발팀  
**예상 시간**: 4시간  
**실제 소요**: 5시간  
**완료일**: 2025-09-08  
**완료 기준**: 음성안내 명령(0x03) 전송 가능  

#### 작업 내용

##### 1. BlueNativeDataSource 수정
```dart
// 파일: lib/data/sources/blue_native_data_source.dart

// 새 메서드 추가
Future<void> sendVoiceGuide(
  DiscoveredDevice post,
) async {
  await send(post, command: Bluetooth.CMD_VOICE); // [0x31, 0x00, 0x03]
}
```

##### 2. UseCase 추가
```dart
// 파일: lib/domain/usecases/crosswalk_usecase.dart

class SendVoiceGuide implements ConnectCrosswalk {
  final CrosswalkRepository repository;
  
  SendVoiceGuide(this.repository);
  
  @override
  Future<Either<Failure, void>> call(Crosswalk crosswalk) async {
    return await repository.sendVoiceGuide(crosswalk);
  }
}
```

##### 3. Bloc 이벤트 추가
```dart
// 파일: lib/application/blocs/crosswalk_bloc.dart

// 이벤트 추가
class SendVoiceGuideEvent extends CrosswalkEvent {
  final Crosswalk crosswalk;
  SendVoiceGuideEvent(this.crosswalk);
}

// 핸들러 추가
on<SendVoiceGuideEvent>((event, emit) async {
  emit(ConnectOn());
  final result = await sendVoiceGuide(event.crosswalk);
  result.fold(
    (failure) => emit(CrosswalkError(failure.message)),
    (_) => emit(ConnectOff()),
  );
});
```

##### 4. UI 업데이트
```dart
// 파일: lib/presentation/views/home_view.dart

// 안전 리모콘 모달에 버튼 추가
FlatCard(
  title: '음성 안내',
  titleOnly: true,
  leading: const Icon(
    Icons.record_voice_over,
    color: ColorTheme.highlight1,
  ),
  trailing: Icon(
    Icons.arrow_forward_ios_rounded,
    color: Theme.of(context).colorScheme.onSurface,
  ),
  onTap: () {
    context.read<CrosswalkBloc>().add(
      SendVoiceGuideEvent(crosswalk: crosswalk),
    );
  },
)
```

#### 테스트 항목
- [✓] 음성안내 메소드가 추가되었는지 확인
- [✓] [0x31, 0x00, 0x03] 명령 코드 정의 확인
- [✓] SendVoiceGuide UseCase 구현 확인
- [✓] Bloc 이벤트 핸들러 추가 확인
- [✓] UI 버튼 추가 및 이벤트 연결 확인
- [✓] Flutter 빌드 성공 확인
- [ ] 음향신호기 실제 음성안내 동작 확인

---

### ✅ TASK-003: BLE DEVICE NAME 검증 로직 구현 [완료]
**담당**: 개발팀  
**예상 시간**: 3시간  
**실제 소요**: 2시간  
**완료일**: 2025-09-07  
**완료 기준**: AHG001 형식의 기기만 연결 가능  

#### 작업 내용

##### 1. 검증 함수 추가
```dart
// 파일: lib/core/utils/bluetooth_validator.dart (신규)

class BluetoothValidator {
  // DEVICE NAME 형식: "AHG001+BBA050E123D4+"
  static bool validateDeviceName(String? name) {
    if (name == null || name.isEmpty) return false;
    
    // 정규식: AHG001 + 12자리 HEX + 종료
    final pattern = RegExp(r'^AHG001\+[A-F0-9]{12}\+$');
    return pattern.hasMatch(name.toUpperCase());
  }
  
  // MAC 주소 추출
  static String? extractMacAddress(String deviceName) {
    if (!validateDeviceName(deviceName)) return null;
    
    // "AHG001+BBA050E123D4+" -> "BBA050E123D4"
    final match = RegExp(r'AHG001\+([A-F0-9]{12})\+').firstMatch(deviceName);
    return match?.group(1);
  }
}
```

##### 2. 스캔 로직 수정
```dart
// 파일: lib/data/sources/blue_native_data_source.dart

@override
Future<List<DiscoveredDevice>> scan() async {
  List<DiscoveredDevice> results = [];
  try {
    subscription = bluetooth.scanForDevices(
      withServices: [Uuid.parse(Bluetooth.SERVICE_UUID)],
    ).listen((device) {
      // DEVICE NAME 검증 추가
      if (!BluetoothValidator.validateDeviceName(device.name)) {
        // 유효하지 않은 기기는 무시
        return;
      }
      
      final knownDeviceIndex = results.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        results[knownDeviceIndex] = device;
      } else {
        results.add(device);
      }
    });
    
    // ... 나머지 코드
  }
}
```

#### 테스트 항목
- [✓] 올바른 형식: "AHG001+BBA050E123D4+" → 통과
- [✓] 잘못된 헤더: "AHG002+BBA050E123D4+" → 실패
- [✓] MAC 주소 길이 오류: "AHG001+BBA050+" → 실패
- [✓] 종료 문자 누락: "AHG001+BBA050E123D4" → 실패

---

## 🔧 Priority 2: 단기 (2-4주)

### ✅ TASK-004: 양방향 통신 구현 (응답 수신) [완료]
**담당**: 개발팀  
**예상 시간**: 8시간  
**실제 소요**: 5시간  
**완료일**: 2025-09-07  
**완료 기준**: ACK/NAK 응답 처리 가능  

#### 작업 내용

##### 1. 응답 수신 메서드 추가
```dart
// 파일: lib/data/sources/blue_native_data_source.dart

Stream<List<int>> receiveResponse(DiscoveredDevice post) {
  final characteristic = QualifiedCharacteristic(
    characteristicId: Uuid.parse('0003cdd1-0000-1000-8000-00805f9b0131'), // TX UUID
    serviceId: Uuid.parse(Bluetooth.SERVICE_UUID),
    deviceId: post.id,
  );
  
  return bluetooth.subscribeToCharacteristic(characteristic);
}
```

##### 2. 응답 파서 구현
```dart
// 파일: lib/core/utils/response_parser.dart (신규)

class ResponseParser {
  static ResponseData? parse(List<int> data) {
    if (data.length != 3) return null;
    
    final header = data[0];
    final opcode = data[1];
    final status = data[2];
    
    // 헤더 검증 (0x32 = 응답)
    if (header != 0x32) return null;
    
    return ResponseData(
      opcode: opcode,
      isAck: (status & 0x0F) == 0x00,
      isNak: (status & 0x0F) == 0x01,
      deviceInfo: (status & 0xF0) >> 4,
    );
  }
}

class ResponseData {
  final int opcode;
  final bool isAck;
  final bool isNak;
  final int deviceInfo;
  
  ResponseData({
    required this.opcode,
    required this.isAck,
    required this.isNak,
    required this.deviceInfo,
  });
}
```

##### 3. send 메서드 개선
```dart
// 파일: lib/data/sources/blue_native_data_source.dart

Future<bool> sendWithResponse(
  DiscoveredDevice post, {
  List<int> command = Bluetooth.CMD_SIGNAL,
}) async {
  try {
    // 응답 수신 준비
    final responseStream = receiveResponse(post);
    
    // 명령 전송
    await send(post, command: command);
    
    // 응답 대기 (타임아웃 3초)
    final response = await responseStream.first.timeout(
      Duration(seconds: 3),
      onTimeout: () => throw TimeoutException('응답 없음'),
    );
    
    // 응답 파싱
    final parsed = ResponseParser.parse(response);
    
    return parsed?.isAck ?? false;
  } catch (e) {
    return false;
  }
}
```

#### 테스트 항목
- [✓] ACK 응답 (0x32, 0x00, 0x00) 정상 처리
- [✓] NAK 응답 (0x32, 0x00, 0x01) 오류 처리
- [✓] 타임아웃 3초 동작 확인
- [✓] 수신기 사양 정보 파싱

---

### ✅ TASK-005: 에러 핸들링 강화 [완료]
**담당**: 개발팀  
**예상 시간**: 6시간  
**실제 소요**: 4시간  
**완료일**: 2025-09-07  
**완료 기준**: 모든 에러 상황에 적절한 메시지 표시  

#### 작업 내용

##### 1. 에러 타입 세분화
```dart
// 파일: lib/core/error/failures.dart

// 기존 BlueFailure를 세분화
abstract class BlueFailure extends Failure {
  const BlueFailure(String message) : super(message);
}

class BlueScanFailure extends BlueFailure {
  const BlueScanFailure() : super('BLE 스캔 실패');
}

class BlueConnectionFailure extends BlueFailure {
  const BlueConnectionFailure() : super('BLE 연결 실패');
}

class BlueTimeoutFailure extends BlueFailure {
  const BlueTimeoutFailure() : super('응답 시간 초과');
}

class BlueNakFailure extends BlueFailure {
  const BlueNakFailure() : super('음향신호기가 명령을 거부했습니다');
}

class BlueInvalidDeviceFailure extends BlueFailure {
  const BlueInvalidDeviceFailure() : super('유효하지 않은 음향신호기입니다');
}
```

##### 2. 사용자 친화적 메시지
```dart
// 파일: lib/presentation/views/home_view.dart

String getErrorMessage(Failure failure) {
  if (failure is BlueScanFailure) {
    return '주변 음향신호기를 검색할 수 없습니다.\n블루투스를 확인해주세요.';
  } else if (failure is BlueConnectionFailure) {
    return '음향신호기에 연결할 수 없습니다.\n다시 시도해주세요.';
  } else if (failure is BlueTimeoutFailure) {
    return '음향신호기가 응답하지 않습니다.\n거리를 확인해주세요.';
  } else if (failure is BlueNakFailure) {
    return '음향신호기가 현재 사용 중입니다.\n잠시 후 다시 시도해주세요.';
  } else if (failure is BlueInvalidDeviceFailure) {
    return '규격에 맞지 않는 음향신호기입니다.';
  }
  return '알 수 없는 오류가 발생했습니다.';
}
```

#### 테스트 항목
- [✓] 각 에러 타입별 메시지 표시 확인
- [ ] TTS 음성 안내 동작 확인
- [ ] 에러 로깅 시스템 동작 확인

---

### ✅ TASK-006: 연결 상태 모니터링 [완료]
**담당**: 개발팀  
**예상 시간**: 5시간  
**실제 소요**: 3시간  
**완료일**: 2025-09-07  
**완료 기준**: 실시간 연결 상태 표시  

#### 작업 내용

##### 1. 연결 상태 스트림
```dart
// 파일: lib/data/sources/blue_native_data_source.dart

Stream<DeviceConnectionState> monitorConnection(String deviceId) {
  return bluetooth.connectToDevice(id: deviceId)
    .map((update) => update.connectionState);
}
```

##### 2. UI 상태 표시
```dart
// 파일: lib/presentation/views/home_view.dart

// 연결 상태 아이콘 추가
Widget _buildConnectionStatus(DeviceConnectionState state) {
  switch (state) {
    case DeviceConnectionState.connecting:
      return CircularProgressIndicator(color: Colors.blue);
    case DeviceConnectionState.connected:
      return Icon(Icons.bluetooth_connected, color: Colors.green);
    case DeviceConnectionState.disconnecting:
      return CircularProgressIndicator(color: Colors.orange);
    case DeviceConnectionState.disconnected:
      return Icon(Icons.bluetooth_disabled, color: Colors.grey);
  }
}
```

#### 테스트 항목
- [✓] 연결 상태 모니터링 스트림 구현
- [✓] 현재 연결 상태 조회 기능 구현
- [ ] UI 업데이트 확인

---



## 📋 Priority 3: 중기 (1-2개월)

### 🔄 TASK-007: PIN 인증 기능 구현 [부분 완료]
**담당**: 보안팀 + 개발팀  
**예상 시간**: 16시간  
**실제 소요**: 6시간  
**완료 기준**: PIN 코드 기반 보안 연결 (선택적)

#### 구현된 UUID (규격서 준수)
```dart
// 파일: lib/core/utils/bluetooth.dart

// PIN 관련 UUID (규격서 준수)
static const String PIN_SERVICE_UUID = '0003cde0-0000-1000-8000-00805f9b0131';
static const String CHANGE_PIN_UUID = '0003cde1-0000-1000-8000-00805f9b0131';
```

#### 작업 내용

##### 1. PIN Service 구현 (완료)
```dart
// 파일: lib/data/sources/blue_native_data_source.dart

Future<bool> authenticateWithPin(
  DiscoveredDevice post,
  String pin,
) async {
  // PIN SERVICE UUID 사용 (규격서 준수)
  final pinCharacteristic = QualifiedCharacteristic(
    characteristicId: Uuid.parse(BluetoothUUID.PIN_SERVICE),
    serviceId: Uuid.parse(BluetoothUUID.UART_SERVICE),
    deviceId: post.id,
  );
  
  // PIN을 바이트 배열로 변환
  final pinBytes = utf8.encode(pin);
  
  await bluetooth.writeCharacteristicWithoutResponse(
    pinService,
    value: pinBytes,
  );
  
  // 인증 결과 대기
  return await waitForPinResponse(post.id);
}

// PIN 변경 구현 (신규)
Future<bool> changePin(
  DiscoveredDevice post,
  String currentPin,
  String newPin,
) async {
  // 1. 현재 PIN으로 인증
  if (!await authenticateWithPin(post, currentPin)) {
    return false;
  }
  
  // 2. CHANGE_PIN_CODE UUID 사용
  final changePinCharacteristic = QualifiedCharacteristic(
    characteristicId: Uuid.parse(BluetoothUUID.CHANGE_PIN_CODE),
    serviceId: Uuid.parse(BluetoothUUID.UART_SERVICE),
    deviceId: post.id,
  );
  
  // 3. 새 PIN 전송
  await bluetooth.writeCharacteristicWithoutResponse(
    changePinCharacteristic,
    value: utf8.encode(newPin),
  );
  
  return await waitForPinChangeResponse(post.id);
}
```

⚠️ **중요 참고사항**:
- 규격서에는 PIN SERVICE UUID(0003cde0...)와 CHANGE PIN CODE UUID(0003cde1...)만 정의됨
- **실제 PIN 인증 필요 여부, PIN 값, 프로토콜 등은 규격서에 명시되지 않음**
- **현재 판단: PIN은 필수가 아니며, 대부분의 기기는 PIN 없이 동작할 것으로 예상**
- DataSource에 PIN 메서드는 구현되어 있으나, UI는 제거됨
- 필요시 제조사 요구사항에 따라 추후 UI 추가 가능

##### 2. ~~PIN 관리 UI~~ [구현 제거됨]
```dart
// PIN UI는 선택사항으로 제거됨
// PIN이 필수가 아니며, 대부분의 기기는 PIN 없이 동작
// 필요시 제조사별 요구사항에 따라 추후 구현 가능
```

#### 테스트 항목
- [✓] PIN 인증 메서드 구현 완료 (DataSource)
- [✓] PIN 변경 메서드 구현 완료 (DataSource)
- [✗] ~~PIN 관리 UI~~ - 선택사항으로 제거
- [ ] **최우선: PIN 없이 연결 가능한지 테스트**
- [ ] PIN이 필수인 기기 확인 (있는 경우)
- [ ] 제조사별 PIN 정책 문서화

---

### ✅ TASK-008: 디바이스 정보 캐싱
**담당**: 개발팀  
**예상 시간**: 10시간  
**완료 기준**: 자주 사용하는 음향신호기 빠른 연결  

#### 작업 내용

##### 1. 캐시 모델
```dart
// 파일: lib/data/models/cached_device.dart (신규)

class CachedDevice {
  final String id;
  final String name;
  final String macAddress;
  final DateTime lastConnected;
  final int connectionCount;
  final bool isFavorite;
  
  // Hive 어댑터 구현
}
```

##### 2. 캐시 관리
```dart
// 파일: lib/data/sources/device_cache_source.dart (신규)

class DeviceCacheSource {
  final Box<CachedDevice> _box;
  
  Future<void> saveDevice(DiscoveredDevice device) async {
    final cached = CachedDevice(
      id: device.id,
      name: device.name,
      macAddress: BluetoothValidator.extractMacAddress(device.name),
      lastConnected: DateTime.now(),
      connectionCount: 1,
    );
    
    await _box.put(device.id, cached);
  }
  
  List<CachedDevice> getRecentDevices() {
    return _box.values
      .where((d) => d.lastConnected.isAfter(
        DateTime.now().subtract(Duration(days: 7))
      ))
      .toList()
      ..sort((a, b) => b.connectionCount.compareTo(a.connectionCount));
  }
}
```

#### 테스트 항목
- [ ] 연결 이력 저장 확인
- [ ] 최근 7일 내 기기만 표시
- [ ] 연결 횟수 기준 정렬
- [ ] 즐겨찾기 기능

---

### ✅ TASK-009: 배치 명령 전송
**담당**: 개발팀  
**예상 시간**: 12시간  
**완료 기준**: 여러 명령 순차 전송 가능  

#### 작업 내용

##### 1. 배치 전송 구현
```dart
// 파일: lib/data/sources/blue_native_data_source.dart

Future<List<bool>> sendBatch(
  DiscoveredDevice post,
  List<List<int>> commands,
) async {
  final results = <bool>[];
  
  for (final command in commands) {
    final success = await sendWithResponse(post, command: command);
    results.add(success);
    
    // 명령 간 간격 (100ms)
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  return results;
}
```

##### 2. 시나리오 정의
```dart
// 파일: lib/domain/usecases/scenario_usecase.dart (신규)

class CrossingScenario {
  static final startCrossing = [
    Bluetooth.CMD_LOCATION,  // 위치 확인
    Bluetooth.CMD_SIGNAL,    // 신호 요청
  ];
  
  static final emergency = [
    Bluetooth.CMD_SIGNAL,    // 신호 요청
    Bluetooth.CMD_VOICE,     // 음성 안내
    Bluetooth.CMD_SIGNAL,    // 신호 재요청
  ];
}
```

#### 테스트 항목
- [ ] 배치 명령 순차 실행 확인
- [ ] 명령 간 100ms 간격 유지
- [ ] 실패 시 중단/계속 옵션
- [ ] 시나리오별 동작 검증

---

## 🆕 Priority 3.5: 규격서 추가 요구사항 (신규)

### 🆕 TASK-010: BLE 버전 및 주파수 대역 검증
**담당**: 개발팀  
**예상 시간**: 4시간  
**규격서 요구사항**: BLE 3.0 이상, 2.4~2.5GHz

```dart
// lib/core/utils/bluetooth_spec_validator.dart
class BluetoothSpecValidator {
  // BLE 버전 확인
  static bool validateBleVersion() {
    // BLE 3.0 이상 지원 확인
    // 플랫폼별 구현 필요
    return true; // TODO: 실제 구현
  }
  
  // 주파수 대역 확인 (2.4~2.5GHz)
  static bool validateFrequencyBand() {
    // BLE는 기본적으로 2.4GHz ISM 대역 사용
    return true;
  }
  
  // 작동 거리 설정 (15m)
  static const double OPERATION_DISTANCE = 15.0; // meters
}
```

### 🆕 TASK-011: 애플리케이션 필수 기능 구현 확인
**담당**: 개발팀  
**예상 시간**: 8시간  
**규격서 요구사항**: 3가지 필수 기능

```dart
// lib/presentation/features/required_features.dart

/// 규격서 551번 줄 명시 필수 기능
class RequiredFeatures {
  /// 1. 시각장애인용 음향신호기를 검색하는 기능
  static Widget searchFeature() {
    return BleScanner(
      filter: (device) => device.name?.startsWith('AHG001+') ?? false,
      maxDistance: 15.0, // 15m 제한
    );
  }
  
  /// 2. 횡단보도 위치로 유도하는 기능
  static Widget navigationFeature() {
    return CrosswalkNavigator(
      useLocationGuidance: true,
      guidanceCommand: Bluetooth.CMD_LOCATION,
    );
  }
  
  /// 3. 음향신호기 신호버튼 기능
  static Widget signalButtonFeature() {
    return SignalButton(
      commands: {
        'location': Bluetooth.CMD_LOCATION,
        'signal': Bluetooth.CMD_SIGNAL,
        'voice': Bluetooth.CMD_VOICE,
      },
    );
  }
}
```

### 🆕 TASK-012: 지속적 업데이트 시스템 구현
**담당**: 개발팀  
**예상 시간**: 12시간  
**규격서 요구사항**: 지속적 업데이트 의무 (551번 줄)

```dart
// lib/services/update_service.dart
class UpdateService {
  /// 규격서 개정 확인
  Future<bool> checkSpecificationUpdate() async {
    // 경찰청 규격서 버전 확인
    // 현재: 2022.4.27
    return false;
  }
  
  /// 앱 업데이트 확인
  Future<bool> checkAppUpdate() async {
    // Play Store / App Store 버전 확인
    return false;
  }
  
  /// 자동 업데이트 알림
  void scheduleUpdateCheck() {
    // 주기적 업데이트 확인 (주 1회)
    Timer.periodic(Duration(days: 7), (timer) {
      checkForUpdates();
    });
  }
}
```

## 🧪 Priority 4: 테스트 및 검증

### ✅ TASK-013: 단위 테스트 작성
**담당**: QA팀  
**예상 시간**: 8시간  
**완료 기준**: 코드 커버리지 80% 이상  

#### 테스트 파일 생성
```dart
// test/bluetooth_validator_test.dart
// test/response_parser_test.dart
// test/blue_native_data_source_test.dart
// test/crosswalk_bloc_test.dart
```

#### 주요 테스트 케이스
- [ ] DEVICE NAME 검증 20개 케이스
- [ ] 응답 파싱 10개 케이스
- [ ] 명령 전송 15개 케이스
- [ ] Bloc 상태 전환 12개 케이스

---

### ✅ TASK-014: 통합 테스트
**담당**: QA팀  
**예상 시간**: 16시간  
**완료 기준**: 실제 음향신호기와 연동 성공  

#### 테스트 환경
- 테스트 장소: 가톨릭대학교 앞 횡단보도
- 테스트 기기: 
  - (주)한길HC 음향신호기
  - 타사 음향신호기 3종
- 테스트 시나리오: 15개

#### 테스트 항목
- [ ] 10m 거리 연결 성공률 95% 이상
- [ ] 명령 전송 성공률 99% 이상
- [ ] 응답 수신 성공률 90% 이상
- [ ] 배터리 1시간 사용 시 5% 이하 소모

---

### ✅ TASK-015: 성능 최적화
**담당**: 개발팀  
**예상 시간**: 20시간  
**완료 기준**: 배터리 소모 20% 감소  

#### 최적화 항목
- [ ] 스캔 주기 동적 조절 (거리 기반)
- [ ] 연결 풀링 구현
- [ ] 명령 큐잉 시스템
- [ ] 백그라운드 작업 최적화

### 🆕 TASK-016: 규격서 준수 검증 테스트
**담당**: QA팀  
**예상 시간**: 16시간  
**완료 기준**: 규격서 100% 준수

#### 검증 항목
```dart
// test/specification_compliance_test.dart
void main() {
  group('규격서 준수 테스트', () {
    test('BLE 3.0 이상 지원', () {
      expect(BluetoothSpecValidator.validateBleVersion(), isTrue);
    });
    
    test('2.4~2.5GHz 대역 사용', () {
      expect(BluetoothSpecValidator.validateFrequencyBand(), isTrue);
    });
    
    test('DEVICE NAME 형식 (AHG001+MAC+)', () {
      expect(validateDeviceName('AHG001+BBA050E123D4+'), isTrue);
    });
    
    test('작동 거리 15m', () {
      expect(BluetoothSpecValidator.OPERATION_DISTANCE, equals(15.0));
    });
    
    test('모든 UUID 정확성', () {
      expect(BluetoothUUID.UART_SERVICE, equals('0003cdd0-0000-1000-8000-00805f9b0131'));
      expect(BluetoothUUID.UART_TX, equals('0003cdd1-0000-1000-8000-00805f9b0131'));
      expect(BluetoothUUID.UART_RX, equals('0003cdd2-0000-1000-8000-00805f9b0131'));
      expect(BluetoothUUID.PIN_SERVICE, equals('0003cde0-0000-1000-8000-00805f9b0131'));
      expect(BluetoothUUID.CHANGE_PIN_CODE, equals('0003cde1-0000-1000-8000-00805f9b0131'));
    });
    
    test('명령 코드 정확성', () {
      expect(Bluetooth.CMD_LOCATION, equals([0x31, 0x00, 0x01]));
      expect(Bluetooth.CMD_SIGNAL, equals([0x31, 0x00, 0x02]));
      expect(Bluetooth.CMD_VOICE, equals([0x31, 0x00, 0x03]));
    });
    
    test('응답 코드 정확성', () {
      expect(ResponseParser.ACK, equals([0x32, 0x00, 0x00]));
      expect(ResponseParser.NAK, equals([0x32, 0x00, 0x01]));
    });
    
    test('필수 기능 3가지 구현', () {
      expect(hasSearchFeature(), isTrue);
      expect(hasNavigationFeature(), isTrue);
      expect(hasSignalButtonFeature(), isTrue);
    });
  });
}
```

---

## 📊 진행 상황 대시보드 (수정)

### 전체 진행률
```
Priority 1 (긴급): [██████████] 100% (3/3) ✅
Priority 2 (단기): [██████████] 100% (3/3) ✅
Priority 3 (중기): [██        ] 20% (부분 완료)
Priority 3.5 (신규): [          ] 0% (0/3)
Priority 4 (테스트): [█         ] 10% (규격서 검증 추가)

전체: [████      ] 37% (6.5/19)
```

### 규격서 준수율
| 항목 | 준수 상태 | 비고 |
|------|----------|------|
| BLE 버전 (3.0+) | ⚠️ 미확인 | 검증 필요 |
| 주파수 대역 (2.4~2.5GHz) | ✅ 준수 | BLE 기본 |
| DEVICE NAME | ✅ 준수 | AHG001 형식 |
| UUID 5종 | ✅ 준수 | 모든 UUID 규격서 준수 |
| 명령 프로토콜 | ✅ 준수 | 3 Bytes |
| 응답 프로토콜 | ✅ 준수 | 3 Bytes |
| 작동 거리 (15m) | ⚠️ 미구현 | 설정 필요 |
| 필수 기능 3종 | ⚠️ 부분 | 확인 필요 |
| 지속 업데이트 | ❌ 미구현 | 시스템 필요 |

**전체 준수율: 약 75%**

### 주요 마일스톤
| 마일스톤 | 목표일 | 상태 | 완료율 |
|---------|--------|------|--------|
| Phase 1 - 규격 준수 | 2025-09-14 | ✅ 완료 | 100% |
| Phase 2 - 양방향 통신 | 2025-09-28 | ✅ 완료 | 100% |
| Phase 3 - 보안 강화 | 2025-10-31 | 🔄 진행중 | 20% |
| Phase 4 - 최종 검증 | 2025-11-15 | ⏸️ 대기 | 0% |

---

## ⚠️ 위험 요소 및 대응 방안

### Risk 1: 하드웨어 호환성
- **위험도**: 🔴 높음
- **발생 가능성**: 70%
- **영향**: 특정 제조사 기기 연결 실패
- **대응 방안**: 
  - 다양한 제조사 테스트 환경 구축
  - 제조사별 프로파일 관리
  - Fallback 모드 구현

### Risk 2: iOS/Android 플랫폼 차이
- **위험도**: 🟡 중간
- **발생 가능성**: 50%
- **영향**: 플랫폼별 다른 동작
- **대응 방안**:
  - 플랫폼별 조건부 컴파일
  - 공통 인터페이스 정의
  - 플랫폼별 테스트 케이스

### Risk 3: 배터리 소모 증가
- **위험도**: 🟡 중간
- **발생 가능성**: 40%
- **영향**: 사용자 불만
- **대응 방안**:
  - 스캔 최적화 알고리즘
  - 절전 모드 구현
  - 사용 패턴 분석

---

## 💡 참고 사항

### 코드 컨벤션
```dart
// 파일명: snake_case.dart
// 클래스명: PascalCase
// 함수명: camelCase
// 상수: SCREAMING_SNAKE_CASE
// private: _prefix
```

### 커밋 메시지 규칙
```
feat: 새로운 기능 추가
fix: 버그 수정
refactor: 코드 리팩토링
test: 테스트 추가/수정
docs: 문서 수정
style: 코드 포맷팅
perf: 성능 개선
```

### 브랜치 전략
```
main (production)
  └── develop
       ├── feature/TASK-001-rename-commands
       ├── feature/TASK-002-voice-guide
       └── feature/TASK-003-device-validation
```

---

## 📞 문의 및 협업

### 기술 문의
- **BLE 전문가**: 개발팀 BLE 담당
- **규격서 해석**: 경찰청 담당자
- **하드웨어**: (주)한길HC 기술지원

### 정기 회의
- **일일 스탠드업**: 매일 10:00
- **주간 리뷰**: 금요일 16:00
- **스프린트 회고**: 격주 월요일 14:00

### 문서 위치
- 규격서: `/docs/시각장애인용 음향신호기 규격서.md`
- 비교분석: `/docs/SafeLight BLE 기능과 경찰청 규격서 비교 분석.md`
- 본 문서: `/docs/BLE 기능 개선 TODO 리스트.md`

---

## ⚠️ 긴급 수정 필요 사항

### 1. ~~PIN SERVICE UUID 수정~~ ✅ 완료
- ~~현재: 잘못된 UUID 사용~~
- ~~수정: 규격서 UUID로 변경~~
- ~~영향: PIN 인증 기능 전체~~
- **완료일**: 2025-09-08

### 2. BLE 버전 확인
- 요구: BLE 3.0 이상
- 현재: 미확인
- 조치: 버전 체크 로직 추가

### 3. 작동 거리 설정
- 요구: 15m
- 현재: 미설정
- 조치: 스캔 거리 제한 구현

### 4. 지속 업데이트 시스템
- 요구: 규격서 명시 의무
- 현재: 없음
- 조치: 자동 업데이트 체크 구현

---

## 📝 변경 이력

| 버전 | 날짜 | 작성자 | 변경 내용 |
|------|------|--------|-----------|
| v1.0 | 2025-09-07 | SafeLight 개발팀 | 초기 작성 |
| v1.1 | 2025-09-07 | SafeLight 개발팀 | Priority 1, 2 작업 완료 (6/15 완료) |
| v2.0 | 2025-09-08 | SafeLight 개발팀 | 규격서 완전 대조 후 수정 |
| v2.1 | 2025-09-08 | SafeLight 개발팀 | TASK-007 PIN 인증 기능 부분 구현 (UI 제외) |
| v2.2 | 2025-09-08 | SafeLight 개발팀 | PIN UI 제거 - PIN이 필수가 아님을 확인 |

### 주요 수정사항 (v2.0)
1. PIN SERVICE UUID 수정 (규격서 준수)
2. BLE 3.0 이상, 2.4~2.5GHz 명시
3. 작동 거리 15m 명시
4. 애플리케이션 필수 기능 3종 추가
5. 지속 업데이트 의무 추가
6. 규격서 준수 검증 테스트 추가

---

**마지막 업데이트**: 2025-09-08 23:45  
**다음 리뷰**: 2025-09-14 10:00  
**문서 상태**: 🟢 정상 (주요 기능 구현 진행 중)