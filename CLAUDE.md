# CLAUDE.md - SafeLight 프로젝트 지침

## 📑 목차 (Table of Contents)
- [🚀 빠른 시작](#-빠른-시작-quick-start)
- [1. 프로젝트 정보](#1-프로젝트-정보)
- [2. 개발 규칙](#2-개발-규칙)
- [3. 아키텍처](#3-아키텍처)
- [4. 기술 스택](#4-기술-스택)
- [5. 핵심 기능](#5-핵심-기능)
- [6. 빌드 및 배포](#6-빌드-및-배포)
- [7. 성능 기준](#7-성능-기준)
- [8. 문서 및 리소스](#8-문서-및-리소스)

---

## 🚀 빠른 시작 (Quick Start)

### 🔴 필수 확인 사항
```bash
# 1. 의존성 설치
flutter pub get

# 2. 빌드 테스트
flutter build apk  # Android
flutter build ios  # iOS

# 3. 개발 서버 실행
flutter run
```

### ⚠️ 절대 금지 사항
- ❌ `Future.delayed()` 사용
- ❌ `debugPrint` 사용 (프로덕션)
- ❌ try-catch 빈 블록
- ❌ View에서 Repository 직접 호출
- ❌ Global 변수 사용

### ✅ 필수 준수 사항
- ✔️ DI 사용 (get_it)
- ✔️ BLoC 패턴
- ✔️ Clean Architecture
- ✔️ 에러 처리
- ✔️ const 위젯 사용

---

## 1. 프로젝트 정보

### 1.1 개요
- **프로젝트명**: SafeLight
- **설명**: Flutter 기반 시각 장애인 안전 경로 안내 애플리케이션
- **버전**: iOS 2.0.1+21 | Android 1.1.1+4
- **최소 지원**: iOS 14.0+ | Android API 21+

### 1.2 브랜치 전략
| 브랜치 | 용도 | PR 타겟 |
|--------|------|---------|
| master | 프로덕션 | - |
| hojung_develop | 개발 브랜치 (현재) | master |

---

## 2. 개발 규칙

### 2.1 코딩 컨벤션 🔴 필수

#### 네이밍 규칙
| 구분 | 규칙 | 예시 |
|------|------|------|
| 파일명 | snake_case | `auth_service.dart` |
| 클래스명 | PascalCase | `AuthService` |
| 변수/메서드 | camelCase | `getUserData` |
| 상수 | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Private | _ prefix | `_privateMethod` |

#### 우선순위별 규칙

##### 🔴 필수 규칙
```dart
// DRY 원칙 - 코드 중복 금지
// SSOT - 상태는 한 곳에서만
// 에러 처리 - 모든 비동기 작업
// DI 사용 - get_it 활용
```

##### 🟡 권장 규칙
```dart
// const 위젯 활용
// RepaintBoundary 사용
// 적절한 주석
```

##### 🟢 선택 규칙
```dart
// 테스트 코드 (요청 시)
// TODO 주석 (최소화)
// ListView itemExtent
```

---

## 3. 아키텍처

### 3.1 Clean Architecture 계층 구조

```
┌─────────────────────────────────────┐
│        Presentation Layer           │
│    (Views, BLoC, Controllers)       │
├─────────────────────────────────────┤
│          Domain Layer               │
│   (Entities, UseCases, Repos)       │
├─────────────────────────────────────┤
│           Data Layer                │
│  (Models, Sources, Implementations) │
└─────────────────────────────────────┘
```

### 3.2 프로젝트 구조
```
lib/
├── 📁 core/                 # 핵심 유틸리티
│   ├── caches/             # 로컬 캐시
│   ├── errors/             # 에러 처리
│   ├── usecases/           # UseCase 인터페이스
│   └── utils/              # 유틸리티
│
├── 📁 data/                 # 데이터 레이어
│   ├── models/             # DTO
│   ├── network/            # 네트워크
│   ├── repositories/       # Repository 구현
│   ├── services/           # 외부 서비스
│   └── sources/            # 데이터 소스
│
├── 📁 domain/               # 비즈니스 로직
│   ├── entities/           # 엔티티
│   ├── repositories/       # Repository 인터페이스
│   └── usecases/          # UseCase
│
├── 📁 presentation/         # UI 레이어
│   ├── bloc/              # BLoC
│   ├── cubit/             # Cubit
│   ├── views/             # 화면
│   └── widgets/           # 위젯
│
└── 📄 main.dart            # 진입점
```

### 3.3 BLoC 패턴 규칙
| 요소 | 네이밍 | 상속 |
|------|--------|------|
| Event | ~Event | Equatable |
| State | ~State | Equatable |
| BLoC | ~Bloc | Bloc |
| Cubit | ~Cubit | Cubit |

---

## 4. 기술 스택

### 4.1 Core Dependencies
| 카테고리 | 패키지 | 버전 | 용도 |
|----------|--------|------|------|
| **Framework** | Flutter | 3.22.3 | Core |
| **State** | flutter_bloc | ^9.1.0 | 상태관리 |
| **DI** | get_it | ^8.0.3 | 의존성 주입 |
| **Firebase** | firebase_core | ^3.8.1 | 백엔드 |

### 4.2 주요 라이브러리
| 기능 | 패키지 | 담당 모듈 |
|------|--------|-----------|
| Maps | flutter_naver_map | NavigatorRepository |
| TTS | flutter_tts | TtsService |
| BLE | flutter_reactive_ble | BlueDataSource |
| Sensors | sensors_plus | AccelerometerRepository |
| Network | dio | DioClient |

---

## 5. 핵심 기능

### 5.1 기능별 모듈 매핑
| 기능 | BLoC/Cubit | Repository | UseCase | 상태 |
|------|------------|------------|---------|------|
| 인증 | AuthBloc | AuthRepository | AuthUseCase | ✅ |
| 횡단보도 | CrosswalkBloc | CrosswalkRepository | CrosswalkUseCase | ✅ |
| 경로탐색 | SearchBloc | NavigatorRepository | NavUseCase | ✅ |
| BLE 통신 | - | - | - | 🔨 |
| IMU 센서 | - | AccelerometerRepository | - | ✅ |

### 5.2 BLE 음향신호기 연동
```dart
// 🔴 경찰청 규격서(2022.4.27) 준수
const DEVICE_NAME = "AHG001+MAC+";  // 20 Bytes
const BLE_VERSION = "3.0+";         // 필수
const DISTANCE = 15;                // meters

// 명령 코드
CMD_LOCATION: [0x31, 0x00, 0x01]   // 위치안내
CMD_SIGNAL: [0x31, 0x00, 0x02]     // 신호안내
CMD_VOICE: [0x31, 0x00, 0x03]      // 음성안내
```

### 5.3 IMU 센서 기반 위치 추적
- **알고리즘**: SmartPDR, BVI 센서 융합
- **필터**: WeightedAverageFilter
- **모드**: 주머니 모드 지원
- **센서**: Accelerometer, Gyroscope, Magnetometer

---

## 6. 빌드 및 배포

### 6.1 빌드 명령어

#### 개발 환경
```bash
# 의존성 설치
flutter pub get

# 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 개발 서버
flutter run
```

#### 프로덕션 빌드
```bash
# Android
flutter build apk --release
flutter build appbundle  # Play Store

# iOS
flutter build ios --release

# 클린 빌드
flutter clean && flutter pub get
```

### 6.2 API Keys
| 서비스 | Key | 환경 |
|--------|-----|------|
| Naver Map | pzijwnqrpi | Public |
| Firebase | firebase_options.dart | iOS/Android |

---

## 7. 성능 기준

### 7.1 필수 달성 기준 🔴
| 지표 | 목표 | 측정 방법 |
|------|------|-----------|
| FPS | 60 FPS | DevTools |
| Jank Rate | < 5% | flutter run --profile |
| 시작 시간 | < 2초 | Cold Start |
| 메모리 | < 150MB | DevTools |
| 배터리 | < 5%/h | Device Monitor |

### 7.2 성능 모니터링
```bash
# DevTools 실행
flutter pub global activate devtools
flutter pub global run devtools

# 프로파일링
flutter run --profile
```

---

## 8. 문서 및 리소스

### 8.1 작업 시 체크리스트 ✅
- [ ] DI 컨테이너 수정 → 앱 재시작
- [ ] Firebase 수정 → firebase_options.dart 확인
- [ ] 권한 요청 → PermissionUseCase 사용
- [ ] TTS → TtsService 싱글톤
- [ ] 네트워크 → DioClient 사용
- [ ] BLE → 경찰청 규격서 준수
- [ ] IMU 센서 → WeightedAverageFilter
- [ ] 성능 기준 → 60 FPS 유지

### 8.2 프로젝트 문서 위치
| 문서 | 경로 | 설명 |
|------|------|------|
| API 문서 | `docs/API/` | API 명세 |
| 기능 명세서 | `docs/기능 명세서/` | 상세 기능 |
| BVI 센서 | `docs/BVI 센서/` | 센서 융합 |
| IMU 논문 | `docs/IMU 센서 기반 논문/` | 연구 자료 |
| 방향 알고리즘 | `docs/방향 알고리즘/` | 알고리즘 |
| BLE TODO | `docs/횡단보도 개선 문서/` | 개선 사항 |

### 8.3 문제 해결
| 문제 | 해결 방법 |
|------|-----------|
| 빌드 실패 | `flutter clean && flutter pub get` |
| DI 오류 | 앱 재시작 |
| 성능 이슈 | DevTools 프로파일링 |
| BLE 연결 실패 | 규격서 확인 |

---

## 📌 Quick Links
- [Flutter Docs](https://flutter.dev/docs)
- [BLoC Library](https://bloclibrary.dev)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- 프로젝트 이슈: GitHub Issues

---

*Last Updated: 2025-09-18*
*Version: 2.0*