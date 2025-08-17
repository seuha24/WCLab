# CLAUDE.md - SafeLight 프로젝트 지침

## 프로젝트 개요
SafeLight - Flutter 기반 경로 안내 애플리케이션

## 기술 스택
- **Frontend**: Flutter/Dart
- **State Management**: Provider/Riverpod (프로젝트에 맞게 수정)
- **Navigation**: Flutter Navigation
- **Maps**: Google Maps / Kakao Maps (프로젝트에 맞게 수정)

## 코드 작성 규칙

### Flutter/Dart 컨벤션
- **파일명**: snake_case (예: route_service.dart)
- **클래스명**: PascalCase (예: RouteService)
- **변수/함수**: camelCase (예: calculateRoute)
- **상수**: SCREAMING_SNAKE_CASE (예: MAX_WAYPOINTS)

### 프로젝트 구조
```
lib/
├── core/           # 핵심 비즈니스 로직
├── data/           # 데이터 레이어 (API, 모델)
├── presentation/   # UI 레이어 (화면, 위젯)
├── services/       # 서비스 레이어
└── utils/          # 유틸리티 함수
```

### 필수 준수 사항
1. **DRY 원칙**: 코드 중복 절대 금지
2. **SSOT**: 상태는 한 곳에서만 관리
3. **에러 처리**: 모든 비동기 작업에 에러 처리 필수
4. **빌드 검증**: 코드 수정 후 `flutter build` 실행 필수

### 금지 패턴
- `Future.delayed()` 사용 금지
- `debugPrint` 사용 금지 (프로덕션 코드)
- try-catch로 에러 무시 금지
- 테스트 코드 작성 금지 (별도 요청 시에만)

## 빌드 및 실행 명령어
```bash
# iOS 빌드
flutter build ios

# Android 빌드  
flutter build apk

# 개발 서버 실행
flutter run

# 빌드 클린
flutter clean

# 의존성 설치
flutter pub get
```

## 경유지 기능 관련
- 현재 경유지 기능 1차 개발 중
- 임시 주석 처리된 로직 있음 (commit: 2f7b499)
- iOS 최소 버전: 14.0
- Android Gradle 설정 최근 변경됨

## 브랜치 정보
- **현재 브랜치**: hojung_develop
- **메인 브랜치**: master (PR 타겟)

## 작업 시 주의사항
1. 경유지 관련 코드 수정 시 기존 주석 확인
2. iOS/Android 빌드 설정 변경 시 양쪽 플랫폼 테스트 필수
3. master 브랜치로 PR 생성 시 충돌 확인

## 프로젝트별 특이사항
- iOS 최소 지원 버전: 14.0
- Android Gradle 최근 수정됨 (빌드 오류 해결)
- 경유지 기능 개발 진행 중