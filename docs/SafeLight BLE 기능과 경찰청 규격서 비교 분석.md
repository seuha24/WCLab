# SafeLight BLE 기능과 경찰청 시각장애인용 음향신호기 규격서 비교 분석

## 요약
SafeLight 프로젝트는 경찰청 시각장애인용 음향신호기 규격서(2022.4.27 개정)의 BLE 통신 프로토콜을 부분적으로 준수하고 있으며, 일부 개선이 필요한 사항들이 있습니다.

---

## 1. 공통점 (✅ 규격서 준수 사항)

### 1.1 UUID 체계
| 항목 | 규격서 | SafeLight | 준수 여부 |
|------|--------|-----------|-----------|
| UART SERVICE UUID | 0003cdd0-0000-1000-8000-00805f9b0131 | 0003cdd0-0000-1000-8000-00805f9b0131 | ✅ 일치 |
| UART RX UUID | 0003cdd2-0000-1000-8000-00805f9b0131 | 0003cdd2-0000-1000-8000-00805f9b0131 | ✅ 일치 |

### 1.2 통신 방식
- **BLE 통신 프로토콜**: 양쪽 모두 BLE (Bluetooth Low Energy) 사용
- **데이터 전송 방식**: writeCharacteristicWithoutResponse 사용
- **스캔 방식**: UUID 필터링을 통한 선택적 스캔

### 1.3 명령 패킷 구조
- **패킷 크기**: 3 Bytes
- **HEADER**: 0x31 (Start Transmission)
- **OPCODE**: 0x00 (명령 메시지 유형)
- **DATA**: 1 Byte (상위/하위 니블 구분)

### 1.4 하드웨어 처리 시간 고려
- **규격서**: 최소 1초의 딜레이 필요
- **SafeLight**: 
  - 스캔 시 1초 딜레이 적용 ✅
  - 전송 후 500ms 대기 후 연결 해제 ✅

---

## 2. 차이점 (⚠️ 개선 필요 사항)

### 2.1 BLE DEVICE NAME 형식
| 항목 | 규격서 요구사항 | SafeLight 현재 구현 | 차이점 |
|------|----------------|-------------------|---------|
| DEVICE NAME | "AHG001+BBA050E123D4+" (20 Bytes) | 미구현 | ⚠️ DEVICE NAME 형식 검증 없음 |
| 구성 | HEADER(7B) + ADDRESS(13B) | - | ⚠️ 형식 파싱 로직 없음 |

### 2.2 명령 코드 체계 불일치
| 기능 | 규격서 명령 코드 | SafeLight 명령 코드 | 문제점 |
|------|-----------------|-------------------|---------|
| 위치안내 | [0x31, 0x00, 0x01] | CMD_VOICE: [0x31, 0x00, 0x01] | ⚠️ 명칭 불일치 (위치안내 ≠ VOICE) |
| 신호안내 | [0x31, 0x00, 0x02] | CMD_ACOUSTIC: [0x31, 0x00, 0x02] | ⚠️ 명칭 불일치 (신호안내 ≠ ACOUSTIC) |
| 음성안내 | [0x31, 0x00, 0x03] | 미구현 | ❌ 음성안내 기능 없음 |

### 2.3 UUID 누락
| UUID 종류 | 규격서 | SafeLight | 상태 |
|----------|--------|-----------|------|
| UART TX | 0003cdd1-0000-1000-8000-00805f9b0131 | 미사용 | ⚠️ 수신 기능 미구현 |
| PIN SERVICE | 0003cde0-0000-1000-8000-00805f9b0131 | 미사용 | ⚠️ PIN 변경 기능 없음 |
| Change PIN CODE | 0003cde1-0000-1000-8000-00805f9b0131 | 미사용 | ⚠️ PIN 변경 기능 없음 |

### 2.4 응답 패킷 처리
- **규격서**: 수신기 → 앱으로 응답 패킷 전송 (ACK/NAK)
- **SafeLight**: 단방향 통신만 구현 (응답 수신 로직 없음) ❌

### 2.5 수신기 사양 정보
- **규격서**: 응답 패킷에 수신기 사양 정보 포함
- **SafeLight**: 수신기 정보 파싱 미구현 ❌

---

## 3. 추가 기능 (SafeLight 독자 구현)

### 3.1 자동 스캔 기능
- 20초 주기로 자동 반복 스캔
- 백그라운드에서 지속적으로 작동
- **장점**: 사용자 편의성 증대
- **단점**: 배터리 소모 증가

### 3.2 Firebase 연동
- 횡단보도 정보를 Firebase에서 관리
- 위치 기반 매칭 및 방향 정보 제공
- **장점**: 풍부한 정보 제공
- **참고**: 규격서에는 없는 추가 기능

### 3.3 나침반 기능 (iOS)
- 횡단보도 방향을 진동으로 안내
- **장점**: 시각장애인 편의성 향상
- **참고**: 규격서 범위 외 기능

---

## 4. 개선 계획

### 4.1 즉시 개선 필요 (높은 우선순위)

#### 1) 명령 코드 명칭 및 용도 정정
```dart
// 현재 (잘못된 명칭)
static const List<int> CMD_VOICE = [0x31, 0x00, 0x01];     // 음성 유도?
static const List<int> CMD_ACOUSTIC = [0x31, 0x00, 0x02];  // 압버튼 누르기?

// 개선안 (규격서 준수)
static const List<int> CMD_LOCATION = [0x31, 0x00, 0x01];  // 위치안내
static const List<int> CMD_SIGNAL = [0x31, 0x00, 0x02];    // 신호안내
static const List<int> CMD_VOICE = [0x31, 0x00, 0x03];     // 음성안내
```

#### 2) BLE DEVICE NAME 검증 로직 추가
```dart
// DEVICE NAME 파싱 함수 추가
bool validateDeviceName(String name) {
  // "AHG001+MAC주소+" 형식 검증
  final pattern = RegExp(r'^AHG001\+[A-F0-9]{12}\+$');
  return pattern.hasMatch(name);
}

// 스캔 시 검증
if (validateDeviceName(device.name)) {
  // 유효한 음향신호기
}
```

#### 3) 음성안내 기능 구현
```dart
// BlueNativeDataSource에 추가
Future<void> sendVoiceGuide(DiscoveredDevice post) async {
  await send(post, command: [0x31, 0x00, 0x03]);
}
```

### 4.2 중기 개선 사항 (중간 우선순위)

#### 1) 양방향 통신 구현
- UART TX UUID를 통한 응답 수신
- ACK/NAK 처리 로직 추가
- 수신기 사양 정보 파싱

```dart
// 응답 수신 구현 예시
Stream<List<int>> receiveResponse(DiscoveredDevice post) {
  final characteristic = QualifiedCharacteristic(
    characteristicId: Uuid.parse('0003cdd1-0000-1000-8000-00805f9b0131'),
    serviceId: Uuid.parse(Bluetooth.SERVICE_UUID),
    deviceId: post.id,
  );
  
  return bluetooth.subscribeToCharacteristic(characteristic);
}

// 응답 파싱
void parseResponse(List<int> data) {
  if (data.length != 3) return;
  
  final header = data[0];  // 0x32
  final opcode = data[1];  // 0x00
  final status = data[2];
  
  final isAck = (status & 0x0F) == 0x00;
  final deviceInfo = (status & 0xF0) >> 4;
  
  // 처리 로직...
}
```

#### 2) PIN 인증 기능 추가
- PIN SERVICE UUID 활용
- 보안 강화를 위한 PIN 코드 관리

### 4.3 장기 개선 사항 (낮은 우선순위)

#### 1) 완전한 규격서 준수
- 모든 프로토콜 세부사항 구현
- 호환성 테스트 수행
- 인증 획득 고려

#### 2) 성능 최적화
- 스캔 알고리즘 개선
- 배터리 소모 최적화
- 연결 안정성 향상

---

## 5. 위험 요소 및 고려사항

### 5.1 호환성 문제
- **현재 상태**: 부분적 호환
- **위험**: 일부 음향신호기와 통신 실패 가능성
- **대응**: 명령 코드 정정 우선 수행

### 5.2 법적/규제 이슈
- **규격서 미준수**: 공공기관 도입 시 문제 가능
- **대응**: 단계적 규격서 준수율 향상

### 5.3 기술적 제약
- **iOS/Android 차이**: 플랫폼별 BLE 동작 차이
- **하드웨어 의존성**: 음향신호기 제조사별 차이
- **대응**: 충분한 현장 테스트 필요

---

## 6. 구현 로드맵

### Phase 1 (1주일 내)
- [ ] 명령 코드 명칭 수정
- [ ] 음성안내 기능 추가
- [ ] DEVICE NAME 검증 로직 구현

### Phase 2 (2-4주)
- [ ] 양방향 통신 구현
- [ ] ACK/NAK 처리
- [ ] 에러 핸들링 강화

### Phase 3 (1-2개월)
- [ ] PIN 인증 기능
- [ ] 완전한 규격서 준수
- [ ] 호환성 테스트

---

## 7. 테스트 계획

### 7.1 단위 테스트
```dart
// 명령 코드 테스트
test('위치안내 명령 코드 검증', () {
  expect(Bluetooth.CMD_LOCATION, equals([0x31, 0x00, 0x01]));
});

// DEVICE NAME 검증 테스트
test('DEVICE NAME 형식 검증', () {
  expect(validateDeviceName('AHG001+BBA050E123D4+'), isTrue);
  expect(validateDeviceName('INVALID'), isFalse);
});
```

### 7.2 통합 테스트
- 실제 음향신호기와 연동 테스트
- 다양한 제조사 기기 호환성 테스트
- 필드 테스트 (실제 횡단보도)

### 7.3 성능 테스트
- 배터리 소모량 측정
- 연결 속도 측정
- 안정성 테스트 (장시간 운영)

---

## 8. 참고 자료

### 8.1 규격서 문서
- 시각장애인용 음향신호기 규격서 (2022.4.27 개정)
- 경찰청 교통신호제어기 표준규격서

### 8.2 기술 문서
- Flutter Reactive BLE Documentation
- Bluetooth SIG Specifications
- Firebase Firestore Guide

### 8.3 관련 코드
- `lib/core/utils/bluetooth.dart` - BLE 상수 정의
- `lib/data/sources/blue_native_data_source.dart` - BLE 통신 구현
- `lib/domain/entities/crosswalk.dart` - 횡단보도 엔티티

---

## 9. 결론

SafeLight 프로젝트는 경찰청 규격서의 핵심 기능을 구현하고 있으나, 완전한 호환성을 위해서는 다음과 같은 개선이 필요합니다:

1. **즉시 수정 필요**: 명령 코드 명칭 및 용도 정정
2. **단기 개선**: DEVICE NAME 검증, 음성안내 기능 추가
3. **중기 개선**: 양방향 통신, ACK/NAK 처리
4. **장기 목표**: 완전한 규격서 준수 및 인증

현재 구현된 자동 스캔, Firebase 연동, 나침반 기능 등은 규격서를 넘어선 부가가치를 제공하고 있어, 기본 규격 준수와 함께 차별화된 서비스를 제공할 수 있습니다.

---

**작성일**: 2025-09-07  
**작성자**: SafeLight 개발팀  
**버전**: 1.0