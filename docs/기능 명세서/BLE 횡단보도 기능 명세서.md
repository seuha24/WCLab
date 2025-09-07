# BLE 횡단보도 기능 명세서

## 개요
SafeLight 애플리케이션의 BLE(Bluetooth Low Energy) 기반 스마트 횡단보도 제어 시스템은 시각장애인이 안전하게 횡단보도를 건널 수 있도록 지원하는 핵심 기능입니다. 홈 화면(HomeView)을 통해 주변 스마트 압버튼을 검색하고, 블루투스 통신으로 음성 유도 및 압버튼 누르기 기능을 제공합니다.

## 주요 기능

### 1. 스마트 압버튼 검색 및 연결

#### 1.1 수동 스캔
- **동작 시간**: 1초 동안 주변 스캔
- **스캔 범위**: BLE 신호가 도달하는 반경 내 모든 스마트 압버튼
- **결과 표시**: 검색된 횡단보도 목록 제공
- **중복 제거**: 동일 횡단보도의 여러 비콘 포스트 자동 필터링

#### 1.2 자동 스캔
- **동작 방식**: 20초 주기로 자동 반복 스캔
- **즉시 연결**: 검색된 압버튼에 자동으로 유도 신호 전송
- **백그라운드 동작**: 앱 사용 중 지속적으로 작동

### 2. 압버튼 제어 명령

#### 2.1 음성 유도 명령
- **명령 코드**: `[0x31, 0x00, 0x02]`
- **기능**: 횡단보도 위치를 음성으로 안내
- **용도**: 시각장애인이 횡단보도 위치 파악

#### 2.2 압버튼 누르기 명령
- **명령 코드**: `[0x31, 0x00, 0x01]`
- **기능**: 보행 신호 변경 요청
- **용도**: 물리적 버튼 누르기와 동일한 효과

### 3. 횡단보도 유형 분류

#### 3.1 ECrosswalk 열거형
```dart
enum ECrosswalk {
  SINGLE_ROAD,      // 단일 신호등 지역 (index: 0)
  INTERSECTION,     // 교차로 지역 (index: 1)
  FLASH_CROSSING,   // 점멸 신호등 지역 (index: 2)
  UNKNOWN          // 미확인 지역 (index: 3)
}
```

#### 3.2 유형별 특징
- **단일 신호등**: 일반적인 직진 횡단보도
- **교차로**: 여러 방향으로 건널 수 있는 복잡한 횡단보도
- **점멸 신호**: 버튼을 눌러야 신호가 바뀌는 횡단보도
- **미확인**: DB에 등록되지 않은 횡단보도

## 시스템 아키텍처

### 1. 계층 구조
```
Presentation Layer (Bloc/View)
    ↓
Domain Layer (UseCase)
    ↓
Data Layer (Repository)
    ↓
Data Source Layer (BLE/Firebase)
```

### 2. 주요 컴포넌트

#### 2.1 Presentation Layer

##### HomeView (메인 UI)
- **주요 기능**:
  - 내 주변 횡단보도 목록 표시
  - 자동/수동 스캔 제어
  - 안전 리모콘 모달 제공
  - 경광등 통합 제어 (iOS)

- **UI 구성요소**:
  - **AppBar**: 
    - SafeLight 로고 이미지
    - 설정 버튼
    - 자동 스캔 새로고침 버튼
    - 경광등 버튼 (iOS 전용)
  
  - **Board 위젯**: 
    - 제목: "내 주변 횡단보도"
    - 횡단보도 목록 ListView
    - Shimmer 로딩 효과
    - Lottie 애니메이션 (검색/빈 상태/에러)
  
  - **하단 버튼**: 
    - "횡단보도 압버튼 찾기" (90px 높이)
    - 아이콘 변경 (검색/중지/일시정지)

- **안전 리모콘 모달**:
  - **크기**: 700px 높이 BottomSheet
  - **제목**: "안전 리모콘"
  - **기능 선택**:
    - 음성 유도 (위치 아이콘)
    - 압버튼 누르기 (보행자 아이콘)
  - **타임아웃**: 3분 자동 닫기
  - **스크롤**: 가로 스크롤로 모드 전환

##### CrosswalkBloc
- **상태 관리**:
  - 검색 상태 (SearchOn/SearchOff)
  - 연결 상태 (ConnectOn/ConnectOff)
  - 에러 상태 (CrosswalkError)

- **이벤트 처리**:
  - SearchInfiniteCrosswalkEvent: 자동 스캔
  - SearchFiniteCrosswalkEvent: 수동 스캔
  - SendVoiceInductorEvent: 음성 유도
  - SendAcousticSignalEvent: 압버튼 누르기

##### BluetoothPermissionCubit
- 블루투스 권한 상태 관리
- 권한 요청 및 검증

#### 2.2 Domain Layer
- **CrosswalkUseCase** (상위 인터페이스)
- **SearchCrosswalk** (검색 인터페이스)
  - Search2FiniteTimes: 수동 스캔
  - Search2InfiniteTimes: 자동 스캔
- **ConnectCrosswalk** (연결 인터페이스)
  - SendAcousticSignal: 음성 유도
  - SendVoiceInductor: 압버튼 누르기

#### 2.3 Data Layer
- **CrosswalkRepository** (인터페이스)
  - `getCrosswalkFiniteTimes()`: 수동 스캔
  - `getCrosswalkInfiniteTimes()`: 자동 스캔
  - `sendCommand2Crosswalk()`: 명령 전송
- **CrosswalkRepositoryImpl**: Repository 구현체

#### 2.4 Data Source Layer
- **BlueNativeDataSource**: BLE 통신 처리
  - `scan()`: BLE 디바이스 스캔
  - `send()`: 데이터 전송
  - `disconnect()`: 연결 해제
- **CrosswalkRemoteDataSource**: Firebase DB 연동
  - 횡단보도 정보 조회
  - 위치 기반 매칭
- **NavigateRemoteDataSource**: 위치 정보 제공

## BLE 통신 프로토콜

### 1. UUID 정보
```dart
class Bluetooth {
  static const String SERVICE_UUID = '0003cdd0-0000-1000-8000-00805f9b0131';
  static const String CHAR_UUID = '0003cdd2-0000-1000-8000-00805f9b0131';
}
```

### 2. 통신 과정
1. **스캔**: SERVICE_UUID를 가진 디바이스 검색
2. **연결**: 검색된 디바이스와 BLE 연결 수립
3. **서비스 탐색**: 디바이스의 서비스 목록 조회
4. **특성 찾기**: CHAR_UUID를 가진 특성 검색
5. **데이터 전송**: writeCharacteristicWithoutResponse로 명령 전송
6. **연결 해제**: 전송 완료 후 500ms 대기 후 연결 종료

### 3. 경찰청 프로토콜
- 2021년 개정된 시각장애인용 음향신호기 규격서 준수
- 표준화된 명령 코드 체계 사용
- 최소 1초 딜레이로 하드웨어 처리 시간 보장

## 데이터 모델

### 1. Crosswalk 엔티티
```dart
class Crosswalk {
  final String name;              // 횡단보도 이름
  final DiscoveredDevice post;    // BLE 디바이스 정보
  final ECrosswalk type;          // 횡단보도 유형
  final String? dir;              // 방향 정보
  final LatLng? pos;              // 맞은편 좌표
}
```

### 2. CrosswalkModel
- Crosswalk 엔티티의 구현체
- Firebase 데이터 매핑 담당
- `fromMap()` 팩토리 메서드 제공

## Firebase 연동

### 1. 컬렉션 구조
- **컬렉션명**: `safelight_db`
- **문서 필드**:
  - `name`: 횡단보도 이름
  - `post`: 비콘 포스트 ID
  - `type`: 횡단보도 유형 인덱스
  - `pos`: 양쪽 끝 좌표 배열
  - `dir`: 방향 정보

### 2. 데이터 매칭 로직
1. BLE 스캔으로 디바이스 ID 획득
2. Firebase에서 매칭되는 횡단보도 검색
3. 사용자 위치 기반 방향 및 맞은편 좌표 계산
4. 완성된 Crosswalk 객체 반환

## 사용자 경험

### 1. UI/UX 흐름

#### 1.1 메인 화면 (HomeView)
1. **앱 시작**:
   - HomeView 로드 시 자동 스캔 시작 (`initState`)
   - "자동으로 내 주변 횡단보도에 연결중입니다" 메시지
   - Lottie 검색 애니메이션 표시

2. **검색 상태**:
   - **자동 스캔 중**: 
     - "자동 스캔" 칩 표시 (CupertinoActivityIndicator)
     - 20초 주기로 반복 검색
   - **수동 스캔 중**: 
     - Shimmer 효과로 3개 항목 스켈레톤 표시
     - 1초 동안 검색 수행

3. **검색 결과 표시**:
   - **횡단보도 발견**:
     - ListTile 형태로 목록 표시
     - 유형별 아이콘 (단일/교차로/점멸)
     - 횡단보도 이름 (크게)
     - 유형 및 방향 정보 (작게)
   - **횡단보도 없음**:
     - Lottie 빈 상태 애니메이션
     - "주변에 스마트 압버튼이 없습니다" 메시지

#### 1.2 안전 리모콘 모달
1. **모달 열기**:
   - 횡단보도 항목 탭
   - 700px 높이 BottomSheet 표시
   - 배경 반투명 처리
   - 3분 타임아웃 설정

2. **기능 선택 화면**:
   - **음성 유도 카드**:
     - 위치 핀 아이콘 (노란색)
     - "음성 유도" 타이틀
     - 화살표 아이콘
   - **압버튼 누르기 카드**:
     - 보행자 아이콘 (파란색)
     - "압버튼 누르기" 타이틀
     - 화살표 아이콘

3. **연결 결과 화면**:
   - **연결 중**: CircularProgressIndicator
   - **연결 성공**: 
     - 체크 아이콘 (녹색)
     - "음향신호기의 안내에 따라 보행하세요"
     - 나침반 표시 (iOS, 위치 정보 있을 때)
   - **연결 실패**:
     - 에러 아이콘 (빨간색)
     - "음향 신호기에 연결할 수 없습니다"
   - **종료 버튼**: 모달 닫기

#### 1.3 나침반 기능 (Compass 위젯)
- iOS에서 위치 정보가 있을 때 활성화
- 진동이 울리지 않는 방향으로 안내
- 실시간 방향 업데이트

### 2. 음성 안내 메시지
- "자동 스캔이 시작됩니다"
- "N개의 스마트 압버튼을 찾았습니다"
- "[횡단보도명]에 연결합니다"
- "진동이 울리지 않는 방향으로 보행하세요"
- "주변에 스마트압버튼이 없습니다"

### 3. 플랫폼별 특이사항

#### iOS
- **나침반 기능**: 
  - 횡단보도 연결 시 활성화
  - 진동으로 방향 안내
  - Compass 위젯 표시
  
- **경광등 통합**:
  - HomeView AppBar에 경광등 버튼 표시
  - 토글 방식으로 즉시 제어
  - 아이콘 변경 (켜짐: flash_on_rounded / 꺼짐: flashlight_off_outlined)
  - 색상 변경 (켜짐: 노란색 / 꺼짐: 검정색)
  - 날씨 기반 자동 제어 모드 지원
  
- **설정 연동**:
  - Hive 박스로 FlashMode 저장
  - alwayson / alwaysoff / weathers 모드

#### Android
- **나침반 기능**: 비활성화 (Visibility.visible = false)
- **경광등**: HomeView에서 버튼 숨김 (!Platform.isAndroid)
- **기본 음향 신호**: 음향신호기 안내만 제공

## UI 컴포넌트 및 애니메이션

### 1. 주요 위젯
- **Board**: 카드 형태의 컨테이너 위젯
- **FlatCard**: 리스트 아이템 카드
- **SingleChildRoundedCard**: 둥근 모서리 카드
- **Compass**: 방향 안내 위젯 (iOS)

### 2. 애니메이션
- **Lottie 애니메이션**:
  - `LOTTIE_SEARCH`: 검색 중 애니메이션
  - `LOTTIE_EMPTY`: 결과 없음 애니메이션
  - `LOTTIE_STOP_SIGN`: 에러 상태 애니메이션
- **Shimmer 효과**: 로딩 중 스켈레톤 UI
- **CupertinoActivityIndicator**: iOS 스타일 로딩 표시

### 3. 스타일 테마
- **색상 테마**:
  - `ColorTheme.highlight1`: 점멸 신호 (노란색)
  - `ColorTheme.highlight2`: 교차로 (파란색)
  - `ColorTheme.highlight3`: 단일 신호 (녹색)
  - `ColorTheme.highlight4`: 에러 (빨간색)
- **크기 테마**:
  - 패딩/마진: SizeTheme 클래스 사용
  - 반응형 크기: .w (너비), .h (높이) 확장자

### 4. 접근성
- **Semantics 위젯**: 
  - 모든 이미지와 애니메이션에 라벨 제공
  - 버튼에 명확한 설명 추가
- **TTS 음성 안내**: 
  - 모든 주요 동작에 음성 피드백
  - DI.get<TTS>()로 서비스 접근

## 권한 및 설정

### 1. 필요 권한
- **블루투스**: BLE 스캔 및 연결
- **위치**: 사용자 위치 기반 매칭
- **인터넷**: Firebase 데이터 조회

### 2. 권한 관리
- BluetoothPermissionCubit으로 상태 관리
- GetPermission/SetPermission UseCase 활용
- 권한 거부 시 에러 메시지 표시

## 성능 최적화

### 1. 스캔 최적화
- 1초 제한으로 배터리 소모 최소화
- UUID 필터링으로 불필요한 디바이스 제외
- 중복 디바이스 자동 필터링

### 2. 연결 최적화
- writeWithoutResponse로 빠른 전송
- 500ms 대기 후 즉시 연결 해제
- StreamSubscription 적절한 관리

### 3. 데이터 캐싱
- CrosswalkAPI.map으로 Firebase 데이터 캐싱
- 한 번 조회한 데이터 재사용
- 앱 실행 중 메모리 캐시 유지

## 에러 처리

### 1. BlueFailure
- BLE 스캔 실패
- BLE 연결 실패
- 데이터 전송 실패

### 2. ServerFailure
- Firebase 조회 실패
- 위치 정보 획득 실패
- 네트워크 오류

### 3. ValidateFailure
- 권한 검증 실패
- 데이터 유효성 검증 실패

## 테스트 시나리오

### 1. 기본 동작 테스트
- BLE 스캔 정상 작동
- 압버튼 연결 성공
- 명령 전송 확인

### 2. 자동 스캔 테스트
- 20초 주기 확인
- 백그라운드 동작 검증
- 중복 연결 방지

### 3. 에러 상황 테스트
- 블루투스 꺼짐 상태
- 권한 거부 상태
- 네트워크 오프라인

### 4. 성능 테스트
- 다수 디바이스 환경
- 배터리 소모량 측정
- 메모리 사용량 모니터링

## 개발 현황

### 완료된 기능
- [x] BLE 스캔 기능 (자동/수동)
- [x] 압버튼 연결 및 제어
- [x] Firebase 연동
- [x] HomeView 통합 UI
- [x] 안전 리모콘 모달
- [x] 위치 기반 매칭
- [x] TTS 음성 안내
- [x] 플랫폼별 최적화
- [x] 경광등 통합 (iOS)
- [x] Lottie 애니메이션 적용
- [x] Shimmer 로딩 효과
- [x] 3분 타임아웃 기능
- [x] 나침반 방향 안내 (iOS)
- [x] Semantics 접근성 지원

### 진행 중
- [ ] 스캔 거리 조절 기능
- [ ] 오프라인 모드 지원
- [ ] 압버튼 상태 실시간 확인
- [ ] Android 나침반 기능 추가

## 문제 해결 가이드

### 스마트 압버튼을 찾을 수 없을 때
1. 블루투스 활성화 확인
2. 위치 권한 허용 확인
3. 주변에 실제 압버튼 존재 여부 확인
4. 앱 재시작 후 재시도

### 연결이 자주 끊어질 때
1. 블루투스 간섭 요인 제거
2. 배터리 절약 모드 해제
3. 백그라운드 제한 해제
4. 최신 앱 버전 업데이트

### 자동 스캔이 작동하지 않을 때
1. 자동 스캔 버튼 활성화 확인
2. 권한 설정 재확인
3. 앱 강제 종료 후 재시작

## 관련 표준 및 참고 자료

### 1. 경찰청 프로토콜
- 시각장애인용 음향신호기 규격서 (2021년 개정)
- 스마트 IOT 음향 신호기 통신 프로토콜

### 2. 기술 표준
- Bluetooth Low Energy 5.0
- Flutter Reactive BLE 라이브러리
- Firebase Firestore

### 3. 협력 업체
- (주)한길HC: 하드웨어 기술 자문
- 비콘 포스트 제조사 프로토콜

## 보안 고려사항

### 1. 통신 보안
- BLE 통신 암호화 미적용 (표준 프로토콜)
- 민감 정보 전송 금지
- 명령 코드만 전송

### 2. 데이터 보안
- Firebase 보안 규칙 적용
- 사용자 위치 정보 비저장
- 연결 이력 로컬 저장 금지

### 3. 권한 보안
- 최소 권한 원칙 적용
- 런타임 권한 요청
- 권한 거부 시 기능 제한

## 주요 파일 경로
- **HomeView**: `lib/presentation/views/home_view.dart`
- **CrosswalkBloc**: `lib/application/blocs/crosswalk_bloc.dart`
- **BlueNativeDataSource**: `lib/data/sources/blue_native_data_source.dart`
- **CrosswalkRepository**: `lib/data/repositories/crosswalk_repository_impl.dart`
- **CrosswalkUseCase**: `lib/domain/usecases/crosswalk_usecase.dart`

## 참고 사항
- BLE 통신 거리는 환경에 따라 10-50m 가변
- 압버튼 응답 시간은 하드웨어 사양에 따라 상이
- Firebase 데이터는 관리자만 수정 가능
- 표준 프로토콜 준수로 타 앱과 호환 가능
- HomeView가 BLE 횡단보도 기능의 메인 진입점
- 모달 닫기 시 자동으로 경광등 OFF 및 자동 스캔 재시작