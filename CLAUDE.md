# CLAUDE.md - SafeLight 프로젝트 지침

## 프로젝트 개요
SafeLight - Flutter 기반 시각 장애인 안전 경로 안내 애플리케이션

## 기술 스택

### Core Framework
- **Flutter**: 3.22.3 (Dart SDK ^3.2.6)
- **Architecture**: Clean Architecture + BLoC Pattern
- **State Management**: flutter_bloc (^9.1.0), get_it (^8.0.3)
- **Dependency Injection**: get_it, injection.dart

### Backend & Authentication
- **Firebase**: Core (^3.8.1), Auth (^5.5.1), Firestore (^5.5.1)
- **OAuth**: Google Sign In (^6.2.2), Sign in with Apple (^6.1.4)

### Maps & Navigation
- **Map SDK**: flutter_naver_map (^1.4.0)
- **Location**: geolocator (^14.0.0), flutter_compass (^0.8.0)
- **Routing**: Custom navigation API service

### Device Features
- **Sensors**: sensors_plus (^6.1.1), camera (^0.11.1)
- **TTS/STT**: flutter_tts (^4.2.2), speech_to_text (^7.0.0)
- **Flash/Torch**: torch_light (^1.0.0)
- **Notifications**: flutter_local_notifications (^18.0.1)
- **Permissions**: permission_handler (^11.1.0)
- **Haptic**: vibration (^3.1.3)

### Data & Network
- **HTTP Client**: dio (^5.7.0), pretty_dio_logger (^1.4.0)
- **Local Storage**: hive (^2.2.3), shared_preferences
- **Serialization**: Equatable, dartz

## 프로젝트 구조

```
lib/
├── core/                 # 핵심 비즈니스 로직
│   ├── caches/          # 로컬 캐시 (color_mode, flash_mode, setting)
│   ├── errors/          # 에러 처리
│   ├── usecases/        # UseCase 인터페이스
│   └── utils/           # 유틸리티 (validators, apis, enums, tts)
├── data/                # 데이터 레이어
│   ├── models/          # 데이터 모델 (DTO)
│   ├── network/         # 네트워크 설정 (dio_client, interceptor)
│   ├── repositories/    # Repository 구현체
│   ├── services/        # 외부 서비스 (auth, tts, navigation_api)
│   └── sources/         # 데이터 소스 (remote, native, cache)
├── domain/              # 도메인 레이어
│   ├── entities/        # 비즈니스 엔티티
│   ├── repositories/    # Repository 인터페이스
│   └── usecases/       # 비즈니스 로직
├── framework/           # 프레임워크 추상화
│   ├── controller.dart
│   ├── core.dart
│   ├── data_source.dart
│   ├── repository.dart
│   ├── ui.dart
│   └── usecase.dart
├── presentation/        # 프레젠테이션 레이어
│   ├── bloc/           # BLoC (auth, crosswalk, entrance, registration, search)
│   ├── controllers/    # 컨트롤러
│   ├── cubit/          # Cubit (bluetooth, location permissions)
│   ├── views/          # 화면 (UI)
│   └── widgets/        # 재사용 위젯
├── firebase_options.dart
├── initializer.dart    # 앱 초기화
├── injection.dart      # DI 설정
└── main.dart          # 엔트리 포인트
```

## 코딩 컨벤션

### 네이밍 규칙
- **파일명**: snake_case (예: auth_service.dart)
- **클래스명**: PascalCase (예: AuthService)
- **변수/메서드**: camelCase (예: getUserData)
- **상수**: SCREAMING_SNAKE_CASE (API 엔드포인트 등)
- **Private**: 언더스코어 prefix (예: _privateMethod)

### Clean Architecture 규칙
1. **의존성 방향**: Presentation → Domain ← Data
2. **Domain 독립성**: Domain 레이어는 Flutter에 의존하지 않음
3. **Repository Pattern**: 인터페이스는 Domain, 구현은 Data
4. **UseCase**: 하나의 비즈니스 로직만 담당 (단일 책임)

### BLoC 패턴 규칙
- **Event**: ~Event 접미사 (예: AuthEvent)
- **State**: ~State 접미사 (예: AuthState)
- **BLoC**: ~Bloc 접미사 (예: AuthBloc)
- **Equatable**: 모든 Event/State는 Equatable 상속

### 필수 준수 사항
1. **DRY 원칙**: 코드 중복 절대 금지
2. **SSOT**: 상태는 한 곳에서만 관리 (BLoC/Cubit)
3. **에러 처리**: 모든 비동기 작업에 에러 처리 필수
4. **빌드 검증**: 코드 수정 후 빌드 필수
5. **DI 사용**: 직접 인스턴스 생성 대신 get_it 사용

### 금지 패턴
- `Future.delayed()` 사용 금지
- `debugPrint` 사용 금지 (프로덕션 코드)
- try-catch로 에러 무시 금지
- 테스트 코드 작성 금지 (별도 요청 시에만)
- View에서 직접 Repository/DataSource 호출 금지
- Global 변수 사용 금지 (DI로 대체)

## 빌드 및 실행 명령어

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Hive 등)
flutter pub run build_runner build --delete-conflicting-outputs

# 개발 서버 실행
flutter run

# iOS 빌드
flutter build ios

# Android 빌드
flutter build apk
flutter build appbundle  # Play Store용

# 빌드 클린
flutter clean
flutter pub get

# 네이티브 스플래시 생성
flutter pub run flutter_native_splash:create
```

## API & 서비스 정보

### Naver Map
- **Client ID**: pzijwnqrpi
- **인증 타입**: Public

### Firebase 프로젝트
- Firebase 옵션: firebase_options.dart
- 지원 플랫폼: iOS, Android

## 주요 기능별 담당 모듈

| 기능 | BLoC/Cubit | Repository | UseCase |
|-----|-----------|------------|---------|
| 인증 | AuthBloc | AuthRepository | AuthUseCase |
| 횡단보도 | CrosswalkBloc | CrosswalkRepository | CrosswalkUseCase |
| 즐겨찾기 | - | FavoriteRepository | FavoriteUseCase |
| 경로탐색 | SearchBloc | NavigatorRepository | NavUseCase |
| 권한관리 | LocationPermissionCubit | PermissionRepository | PermissionUseCase |
| 플래시 | - | FlashRepository | - |

## 브랜치 정보
- **현재 브랜치**: hojung_develop
- **메인 브랜치**: master (PR 타겟)

## 버전 정보
- **iOS**: 2.0.1+21 (최소 지원: iOS 14.0)
- **Android**: 1.1.1+4

## 성능 기준

### Flutter Performance 기준 (필수 달성)
- **Frame Rendering**: 60 FPS 유지 (16ms/frame)
- **Jank Rate**: < 5% (스킵된 프레임 비율)
- **앱 시작 시간**: < 2초 (Cold Start)
- **메모리 사용량**: < 150MB (일반 사용 시)
- **배터리 소모**: 시간당 < 5%

### Performance Monitoring
```bash
# Flutter DevTools 실행
flutter pub global activate devtools
flutter pub global run devtools

# Performance 프로파일링
flutter run --profile

# 성능 측정
flutter test --profile
```

### 성능 최적화 체크리스트
- [ ] 불필요한 rebuild 제거 (const 위젯 사용)
- [ ] 큰 이미지 최적화 (압축, 캐싱)
- [ ] ListView에 itemExtent 설정
- [ ] 애니메이션 최적화 (RepaintBoundary)
- [ ] 비동기 작업 최적화 (compute 함수)

## 작업 시 주의사항
1. DI 컨테이너(injection.dart) 수정 시 앱 재시작 필수
2. Firebase 관련 수정 시 firebase_options.dart 확인
3. 권한 요청 로직은 PermissionUseCase 통해서만 처리
4. TTS 서비스는 TtsService 싱글톤 사용
5. 네트워크 요청은 반드시 DioClient 사용
6. BLoC 이벤트 처리 시 동시성 문제 주의
7. **성능 기준 미달 시 PR 불가**