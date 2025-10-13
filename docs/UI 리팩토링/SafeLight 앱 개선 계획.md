# SafeLight 앱 개선 계획

## 📅 작성일
2025-01-13 (최종 업데이트: 2025-01-14)

## 📊 현황 분석

### ✅ 완료된 작업
#### 2025-01-13
- **패널 시스템 안정화**
  - DraggableScrollableController null 크래시 문제 완전 해결
  - SlidingPanelController의 animateTo 타이밍 문제 수정
  - MapPanelView를 StatefulWidget으로 리팩토링
  - 패널 초기화 생명주기 관리 개선

#### 2025-01-14 ✅ Phase 1 완료
- **NaverMapViewController 초기화 문제 완전 해결**
  - mapController를 nullable로 변경 완료
  - null safety 패턴 적용 완료
  - onMapReady 콜백 수정으로 초기화 보장
  - LateInitializationError 100% 해결
  - 모든 탭 전환 안정화 달성

### 🔍 남은 문제점
| 우선순위 | 문제점 | 영향도 | 현재 상태 |
|---------|--------|--------|-----------|
| ~~🔴 높음~~ | ~~NaverMapViewController의 mapController 초기화 오류~~ | ~~중간~~ | **✅ 해결 완료** |
| 🟡 중간 | 카카오 API 중복 호출 (동일 위치 6-7회) | 낮음 | API 할당량 낭비 |
| 🟢 낮음 | 위치/블루투스 권한 거부 시 UX | 최소 | 기능 제한됨 |

---

## 🚀 개선 계획

### Phase 1: 긴급 수정 (1-2일)

#### 1.1 NaverMapViewController 초기화 문제 해결

**문제 상황**
```
LateInitializationError: Field 'mapController' has not been initialized
위치: map_view_controller.dart:updateMapByMode()
```

**해결 방안**
```dart
// AS-IS
late final NaverMapController mapController;

// TO-BE
NaverMapController? _mapController;

// 안전한 접근 패턴
void updateMapByMode() {
  if (_mapController == null) {
    debugPrint('Map controller not ready yet');
    return;
  }
  // 기존 로직
}
```

**작업 상세**
- [ ] mapController 초기화 시점 분석
- [ ] onMapCreated 콜백 검증
- [ ] null safety 패턴 적용
- [ ] 초기화 보장 로직 구현

**수정 대상 파일**
- `lib/presentation/controllers/map_view_controller.dart`
- `lib/presentation/views/map_view.dart`

**예상 소요 시간**: 2-3시간

---

### Phase 2: 성능 최적화 (2-3일)

#### 2.1 카카오 API 호출 최적화

**현재 문제**
- 동일 위치에 대해 연속 6-7회 API 호출
- 연간 API 할당량 낭비
- 불필요한 네트워크 트래픽

**해결 방안 1: 위치 기반 캐싱**
```dart
class AddressCache {
  static final Map<String, CachedAddress> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const int _maxCacheSize = 100;

  static Future<String?> getAddress(double lat, double lng) async {
    // 좌표를 6자리로 반올림하여 키 생성 (약 10cm 정밀도)
    final key = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}';

    // 캐시 확인
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheExpiry) {
        return cached.address; // 캐시 히트
      } else {
        _cache.remove(key); // 만료된 캐시 제거
      }
    }

    // 캐시 크기 관리
    if (_cache.length >= _maxCacheSize) {
      _removeOldestEntry();
    }

    // API 호출
    final address = await KakaoApiService.getAddress(lat, lng);
    if (address != null) {
      _cache[key] = CachedAddress(address, DateTime.now());
    }

    return address;
  }

  static void _removeOldestEntry() {
    if (_cache.isEmpty) return;

    var oldestKey = _cache.keys.first;
    var oldestTime = _cache[oldestKey]!.timestamp;

    _cache.forEach((key, value) {
      if (value.timestamp.isBefore(oldestTime)) {
        oldestKey = key;
        oldestTime = value.timestamp;
      }
    });

    _cache.remove(oldestKey);
  }
}

class CachedAddress {
  final String address;
  final DateTime timestamp;

  CachedAddress(this.address, this.timestamp);
}
```

**해결 방안 2: 디바운싱 강화**
```dart
class LocationDebouncer {
  Timer? _debounceTimer;
  NLatLng? _lastLocation;

  static const double _minMovementDistance = 10.0; // 미터
  static const Duration _debounceDuration = Duration(seconds: 2);

  void updateLocation(NLatLng newLocation, Function(NLatLng) onUpdate) {
    // 최소 이동 거리 체크
    if (_lastLocation != null) {
      final distance = _calculateDistance(_lastLocation!, newLocation);
      if (distance < _minMovementDistance) {
        return; // 무시
      }
    }

    // 기존 타이머 취소
    _debounceTimer?.cancel();

    // 새 타이머 설정
    _debounceTimer = Timer(_debounceDuration, () {
      _lastLocation = newLocation;
      onUpdate(newLocation);
    });
  }

  double _calculateDistance(NLatLng loc1, NLatLng loc2) {
    // Haversine 공식으로 거리 계산
    const double earthRadius = 6371000; // 미터
    final lat1Rad = loc1.latitude * (pi / 180);
    final lat2Rad = loc2.latitude * (pi / 180);
    final deltaLat = (loc2.latitude - loc1.latitude) * (pi / 180);
    final deltaLng = (loc2.longitude - loc1.longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
```

**작업 상세**
- [ ] AddressCache 클래스 구현
- [ ] LocationDebouncer 클래스 구현
- [ ] entrance_registration_panel_view.dart에 적용
- [ ] 메모리 사용량 모니터링
- [ ] API 호출 횟수 로깅

**예상 소요 시간**: 4-5시간

---

### Phase 3: UX 개선 (3-4일)

#### 3.1 권한 요청 흐름 개선

**현재 문제**
- 권한 거부 시 설명 없이 기능 제한
- 재요청 방법 안내 부족
- 필수/선택 권한 구분 없음

**개선된 권한 요청 흐름**
```dart
class PermissionManager {
  static Future<void> requestEssentialPermissions(BuildContext context) async {
    // Step 1: 권한 설명 다이얼로그
    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('SafeLight 앱 권한 안내'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionItem(
              icon: Icons.location_on,
              title: '위치 (필수)',
              description: '현재 위치 기반 경로 안내',
            ),
            SizedBox(height: 16),
            _buildPermissionItem(
              icon: Icons.bluetooth,
              title: '블루투스 (선택)',
              description: '음향신호기 연동',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('권한 설정'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    // Step 2: 위치 권한 요청 (필수)
    final locationStatus = await Permission.locationWhenInUse.request();

    if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('위치 권한 필요'),
          content: Text('경로 안내를 위해 위치 권한이 필수입니다.\n설정에서 권한을 허용해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: Text('설정 열기'),
            ),
          ],
        ),
      );
    }

    // Step 3: 블루투스 권한 요청 (선택)
    final bluetoothStatus = await Permission.bluetooth.request();

    if (bluetoothStatus.isDenied) {
      // 선택 권한이므로 간단한 스낵바만 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('블루투스 권한이 없으면 음향신호기를 사용할 수 없습니다'),
          action: SnackBarAction(
            label: '설정',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  static Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(description, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
```

**작업 상세**
- [ ] PermissionManager 클래스 구현
- [ ] 권한 설명 다이얼로그 UI 구현
- [ ] 설정 화면 바로가기 기능
- [ ] 권한 상태 실시간 모니터링
- [ ] 권한별 기능 제한 안내 UI

**예상 소요 시간**: 6-7시간

---

## 📅 실행 일정

### Week 1 (2025.01.13 - 2025.01.17)
| 요일 | 작업 내용 | 담당 | 상태 |
|------|-----------|------|------|
| 월 | mapController 초기화 문제 분석 | - | 대기 |
| 화 | mapController 수정 및 테스트 | - | 대기 |
| 수 | API 캐싱 시스템 설계 | - | 대기 |
| 목 | 캐싱 구현 및 디바운싱 강화 | - | 대기 |
| 금 | Phase 1-2 통합 테스트 | - | 대기 |

### Week 2 (2025.01.20 - 2025.01.24)
| 요일 | 작업 내용 | 담당 | 상태 |
|------|-----------|------|------|
| 월 | 권한 요청 UI 설계 | - | 대기 |
| 화 | 다이얼로그 구현 | - | 대기 |
| 수 | 권한 모니터링 시스템 | - | 대기 |
| 목 | 통합 테스트 | - | 대기 |
| 금 | 최종 검증 및 배포 준비 | - | 대기 |

---

## 📊 예상 효과

### 정량적 개선
| 지표 | 현재 | 목표 | 개선율 |
|------|------|------|--------|
| 초기화 오류 | 1건/실행 | 0건 | 100% |
| API 호출 횟수 | 6-7회/위치 | 1회/위치 | 85% 감소 |
| 권한 획득률 | 40% | 80% | 100% 증가 |
| 메모리 사용량 | - | -10% | 10% 감소 |

### 정성적 개선
- ✅ 앱 시작 시 오류 메시지 제거
- ✅ API 비용 절감
- ✅ 사용자 경험 개선
- ✅ 디버깅 용이성 향상

---

## 🚨 리스크 관리

| 리스크 | 가능성 | 영향도 | 대응 방안 |
|--------|--------|--------|-----------|
| 캐시로 인한 메모리 증가 | 낮음 | 중간 | 최대 100개 제한, TTL 5분 |
| 권한 다이얼로그 피로감 | 중간 | 낮음 | 최초 1회만 표시 |
| API 응답 지연 | 낮음 | 높음 | 타임아웃 3초 설정 |

---

## 📌 참고 사항

### 관련 문서
- [패널 생명주기 재설계 완료 보고서](./패널%20생명주기%20재설계%20완료%20보고서.md)
- [하이브리드 패널 관리 시스템](./하이브리드%20패널%20관리%20시스템.md)

### 기술 스택
- Flutter 3.22.3
- Naver Map SDK
- Kakao REST API
- GetX + BLoC 패턴

### 테스트 환경
- Android: API 21+ (실기기 권장)
- iOS: 14.0+ (시뮬레이터 가능)

---

## ✅ 체크리스트

### Phase 1 완료 기준
- [ ] mapController 오류 0건
- [ ] 앱 시작 시 크래시 없음
- [ ] 모든 탭 전환 정상 작동

### Phase 2 완료 기준
- [ ] API 호출 80% 이상 감소
- [ ] 캐시 히트율 70% 이상
- [ ] 메모리 사용량 안정적

### Phase 3 완료 기준
- [ ] 권한 획득률 70% 이상
- [ ] 사용자 피드백 긍정적
- [ ] 설정 화면 연동 완료
● 📊 최종 평가: refactor/yeonju_develop vs 현재 브랜치

  🏆 평가 결과: refactor/yeonju_develop 브랜치가 더 높은 품질

  ---
  1️⃣ 구조적 개선점

  ✅ refactor/yeonju_develop 장점

  | 항목            | 설명                                  | 중요도      |
  |---------------|-------------------------------------|----------|
  | ✅ 패널 컨트롤러 시스템 | SlidingPanelController로 UI 상태 중앙 관리 | 🔴 매우 높음 |
  | ✅ GetX 통합     | 상태 관리 일원화                           | 🔴 높음    |
  | ✅ 에러 핸들링      | try-catch, addPostFrameCallback 적용  | 🔴 높음    |
  | ✅ UI 모던화      | AppBar, SafeArea, 일관된 디자인           | 🟡 중간    |
  | ✅ 타임아웃 처리     | 10초 타임아웃으로 무한 대기 방지                 | 🔴 높음    |
  | ✅ 성능 모니터링     | Stopwatch로 성능 측정                    | 🟢 낮음    |

  ❌ 현재 브랜치 문제점

  | 문제       | 설명                    | 심각도   |
  |----------|-----------------------|-------|
  | DRY 위반   | speakText/speakTTS 중복 | 🟡 중간 |
  | YAGNI 위반 | 사용하지 않는 변수 선언         | 🟢 낮음 |
  | UI 일관성   | AppBar 없는 커스텀 헤더      | 🟡 중간 |
  | 상태 관리 분산 | 패널 상태가 각 View에 분산     | 🔴 높음 |

  ---
  2️⃣ 코드 품질 비교

  📁 startspot_search_view.dart

  | 비교 항목    | 현재 브랜치             | refactor/yeonju_develop |
  |----------|--------------------|-------------------------|
  | UI 구조    | ❌ 커스텀 헤더           | ✅ AppBar + SafeArea     |
  | 버튼 위치    | ❌ 상단 (검색 결과 없을 때만) | ✅ 하단 고정 (키보드 위)         |
  | 타임아웃     | ❌ 없음               | ✅ 10초 타임아웃              |
  | 현재 위치 버튼 | ❌ 없음               | ✅ 추가됨                   |

  📁 sliding_panel_controller.dart (신규)

  // 🔴 핵심 개선사항
  - 중앙화된 패널 관리
  - 애니메이션 제어
  - 에러 방지 (try-catch)
  - 생명주기 관리

  ---
  3️⃣ 아키텍처 개선

  기존 방식 (현재 브랜치)

  View → 직접 UI 상태 관리
       → 각자 애니메이션 처리
       → 분산된 상태 관리

  개선된 방식 (refactor/yeonju_develop)

  View → Controller → 중앙 상태 관리
                    → 통합 애니메이션
                    → 일관된 에러 처리

  ---
  4️⃣ 리스크 평가

  ⚠️ 적용 시 주의사항

  | 리스크      | 대응 방안         |
  |----------|---------------|
  | 컨트롤러 의존성 | DI 컨테이너 설정 확인 |
  | 기존 코드 충돌 | 단계적 마이그레이션    |
  | 테스트 필요   | 각 패널 동작 테스트   |

  ---
  5️⃣ 권장 사항 🎯

  즉시 적용 권장 ✅

  1. refactor/yeonju_develop 브랜치를 적용하세요
    - 코드 품질이 더 높음
    - 아키텍처가 더 체계적
    - 유지보수가 용이함
  2. 단계적 적용 전략
  # 1단계: 백업
  git checkout -b backup/current-state

  # 2단계: 머지
  git checkout refactor/ui-redesign
  git merge refactor/yeonju_develop

  # 3단계: 충돌 해결
  # Views 파일은 refactor/yeonju_develop 버전 사용
  # Controllers 폴더 전체 적용
  3. DRY 위반 수정
  // speakText, speakTTS 중 하나만 남기기
  Future<void> speakTTS(String message) async {
    await ttsService.speak(message);
  }
  4. 테스트 체크리스트
    - 패널 애니메이션 동작
    - 검색 기능
    - 타임아웃 처리
    - 현재 위치 버튼

---

*작성자: Claude (Opus 4.1)*
*최종 수정: 2025-01-13*