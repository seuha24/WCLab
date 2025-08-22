# TTS 음성 안내 시스템 명세서

## 1. 개요
SafeLight 애플리케이션의 TTS(Text-to-Speech) 음성 안내 시스템은 시각 장애인과 일반 사용자에게 중요한 정보를 음성으로 전달하는 핵심 접근성 기능입니다. 경로 안내, 횡단보도 검색, 경계 이탈 알림 등 다양한 상황에서 실시간 음성 피드백을 제공합니다.

## 2. 시스템 아키텍처

### 2.1 핵심 구성 요소

#### TtsService (lib/data/services/tts_service.dart)
- **역할**: 메인 TTS 서비스 클래스
- **특징**:
  - 큐 기반 음성 재생 관리
  - 순차적 텍스트 처리
  - 플랫폼별 최적화된 재생 속도
  - text_to_speech 라이브러리 래핑

#### TTS 유틸리티 (lib/core/utils/tts.dart)
- **역할**: 간단한 TTS 호출 인터페이스
- **특징**:
  - FlutterTts 라이브러리 직접 사용
  - 전역 enable/disable 플래그
  - 즉시 재생 모드

### 2.2 의존성 주입 구조
```dart
// injection.dart
DI.registerLazySingleton(() => FlutterTts());
DI.registerLazySingleton<TtsService>(() => TtsService());
DI.registerLazySingleton<TTS>(() => TTS(tts: DI()));
```

## 3. 주요 기능

### 3.1 큐 기반 음성 재생
```dart
class TtsService {
  final _ttsQueue = StreamController<String>();
  
  Future<void> speak(String text) async {
    _ttsQueue.add(text);  // 큐에 추가
  }
  
  void _processQueue() {
    // 순차적으로 큐 처리
    // 이전 재생 완료 후 다음 재생
  }
}
```

**특징**:
- 음성 재생 요청을 큐로 관리
- 동시 재생으로 인한 겹침 방지
- 재생 시간 자동 계산 (초당 10자 기준)

### 3.2 플랫폼별 최적화
```dart
// Android
if (Platform.isAndroid) {
  _tts.setRate(1.6);  // 1.6배속
}

// iOS
else if (Platform.isIOS) {
  _tts.setRate(1.2);  // 1.2배속
  await flutterTts.setIosAudioCategory(
    IosTextToSpeechAudioCategory.playback,
    [IosTextToSpeechAudioCategoryOptions.duckOthers],
  );
}
```

### 3.3 설정 관리
- **위치**: 설정 화면 (setting_view.dart)
- **저장**: Hive 로컬 스토리지
- **키**: 'tts' (boolean)
- **기본값**: false (비활성화)

## 4. 사용 사례별 음성 안내

### 4.1 경로 안내 (NaverMapViewController)

#### 기본 안내
- **출발 안내**: "출발지로 이동하세요."
- **도착 안내**: "목적지에 도착했습니다."
- **분기점 안내**: "{description}하세요." (예: "좌회전하세요")

#### 경계 이탈 안내
- **경계 이탈 감지**: 시계 방향 안내 (예: "3시 방향")
- **경로 재검색**: "경로를 이탈하여 새로운 경로로 안내합니다."
- **출발지 이탈**: "출발지에 벗어나 새로운 경로로 안내합니다."

#### 특수 상황
- **횡단보도 접근**: "잠시 후 횡단보도 입니다. 차량에 유의하세요!"
- **GPS 신호 약함**: 위치 조정 안내

### 4.2 BLE 횡단보도 기능 (CrosswalkBloc)

#### 검색 기능
- **자동 스캔 시작**: "자동 스캔이 시작됩니다."
- **검색 결과**: "{n}개의 스마트 압버튼을 찾았습니다."

#### 연결 기능
- **연결 시작**: "{횡단보도명}에 연결합니다."
- **방향 안내**: "진동이 울리지 않는 방향으로 보행하세요."

### 4.3 경광등 기능
- **경광등 켜짐**: "안전 경광등이 켜졌습니다."
- **경광등 꺼짐**: "안전 경광등이 꺼졌습니다."
- **무한 모드 알림**: 30초마다 "현재 경광등이 켜져 있습니다."

## 5. 음성 안내 시점 및 우선순위

### 5.1 즉시 재생 (높은 우선순위)
1. 위험 상황 알림 (횡단보도, 경계 이탈)
2. 연결 상태 변경
3. 사용자 액션 피드백

### 5.2 큐 재생 (일반 우선순위)
1. 경로 안내 메시지
2. 상태 정보 알림
3. 일반 안내 메시지

## 6. 접근성 고려사항

### 6.1 음성 속도 최적화
- 플랫폼별 차별화된 재생 속도
- 중요 정보는 명확하게 발음
- 적절한 간격으로 정보 전달

### 6.2 음성 내용 설계
- 간결하고 명확한 문장
- 필수 정보만 포함
- 방향은 시계 방향으로 안내

### 6.3 사용자 제어
- 설정에서 ON/OFF 가능
- 음성 재생 중 중단 가능
- 볼륨 최대값(1.0) 설정

## 7. 기술 구현 상세

### 7.1 초기화 과정
```dart
// initializer.dart
FlutterTts flutterTts = DI.get<FlutterTts>();
await flutterTts.awaitSpeakCompletion(true);
await flutterTts.setSharedInstance(true);
await flutterTts.setVolume(1.0);
```

### 7.2 TTS 서비스 중단
```dart
void stop() {
  _ttsQueue.close();  // 스트림 종료
  _tts.stop();        // 현재 재생 중단
}
```

### 7.3 에러 처리
- TTS 초기화 실패 시 자동 재시도
- 재생 실패 시 로그 기록
- 큐 오버플로우 방지

## 8. 사용된 라이브러리

### 8.1 flutter_tts
- **버전**: pubspec.yaml 참조
- **용도**: iOS 네이티브 TTS
- **특징**: iOS 오디오 카테고리 설정 지원

### 8.2 text_to_speech
- **버전**: 0.2.3 (로컬 패키지)
- **용도**: 크로스 플랫폼 TTS
- **특징**: Android/iOS 통합 인터페이스

## 9. 성능 최적화

### 9.1 메모리 관리
- 스트림 컨트롤러 적절한 종료
- 큐 크기 제한으로 메모리 누수 방지

### 9.2 배터리 최적화
- 불필요한 재생 방지
- 백그라운드 재생 제한

## 10. 테스트 시나리오

### 10.1 기능 테스트
1. TTS 설정 ON/OFF 동작 확인
2. 각 음성 안내 메시지 재생 확인
3. 큐 순차 처리 확인

### 10.2 플랫폼 테스트
1. Android 재생 속도 (1.6x) 확인
2. iOS 재생 속도 (1.2x) 확인
3. iOS 오디오 덕킹 동작 확인

### 10.3 접근성 테스트
1. VoiceOver/TalkBack과 충돌 없음
2. 음성 명확도 확인
3. 적절한 타이밍 확인

## 11. 향후 개선 사항

### 11.1 기능 개선
- [ ] 사용자별 음성 속도 조절
- [ ] 음성 선택 기능
- [ ] 다국어 지원

### 11.2 성능 개선
- [ ] 음성 캐싱 구현
- [ ] 네트워크 TTS 백업
- [ ] 오프라인 음성 파일

### 11.3 접근성 개선
- [ ] 햅틱 피드백 연동
- [ ] 중요도별 음성 톤 구분
- [ ] 반복 재생 옵션

## 12. 관련 파일

### 핵심 파일
- `lib/data/services/tts_service.dart` - 메인 TTS 서비스
- `lib/core/utils/tts.dart` - TTS 유틸리티
- `lib/injection.dart` - 의존성 주입
- `lib/initializer.dart` - TTS 초기화

### 사용 파일
- `lib/presentation/controllers/map_view_controller.dart` - 경로 안내
- `lib/presentation/bloc/crosswalk_bloc/crosswalk_bloc.dart` - 횡단보도
- `lib/presentation/views/setting_view.dart` - 설정 화면
- `lib/presentation/views/flashlight_view.dart` - 경광등

### 라이브러리
- `text_to_speech-0.2.3/` - 로컬 TTS 패키지

## 13. 주의사항

### 13.1 개발 시
- debugPrint 사용 금지 (프로덕션)
- Future.delayed 사용 금지
- 에러 처리 필수

### 13.2 운영 시
- TTS 설정 기본값 확인
- 플랫폼별 권한 확인
- 음성 파일 무결성 확인

---

*최종 업데이트: 2025-08-22*
*작성자: Claude Code Assistant*