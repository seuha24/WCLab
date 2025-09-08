# Flutter Analyze 문제 해결 가이드

## 📊 문제 현황
- **초기 문제 수**: 156개
- **dart fix 적용 후**: 53개 (✅ 103개 자동 수정 완료)
- **현재 경고(warning)**: 3개  
- **현재 정보(info)**: 50개
- **작성일**: 2025-09-09
- **Flutter 버전**: 3.18+ (deprecated API 변경사항 포함)

---

## ✅ Phase 1 완료 (dart fix --apply로 자동 수정됨)

### 자동 수정된 항목들 (103개)
- **use_super_parameters**: 20개 → 생성자 매개변수를 super parameter로 변경
- **deprecated_member_use** (background/onBackground): 39개 → surface/onSurface로 변경
- **unnecessary_library_name**: 9개 → library 이름 제거
- **use_key_in_widget_constructors**: 5개 → widget에 key parameter 추가
- **unused_import**: 7개 → 사용하지 않는 import 제거
- **non_constant_identifier_names**: 19개 중 일부 자동 수정
- **unnecessary_brace_in_string_interps**: 2개 → 불필요한 중괄호 제거
- **avoid_function_literals_in_foreach_calls**: 1개 → forEach 대신 for-in 사용

---

## 🔄 남은 문제들 (53개)

### 🟢 쉬운 문제 (Easy) - 30분 이내 해결 가능

#### 1. non_constant_identifier_names (8개)
**문제**: 변수명이 lowerCamelCase가 아님
**예시 위치**: 
- `lib\presentation\controllers\map_view_controller.dart:42:12` (current_latitude)
- `lib\presentation\controllers\map_view_controller.dart:45:12` (current_longitude)
- `lib\presentation\controllers\map_view_controller.dart:57:12` (remain_distance)
- `lib\presentation\controllers\map_view_controller.dart:100:15` (s_latitude)
- `lib\presentation\controllers\map_view_controller.dart:175:8` (ShowLowGpsAlertOnce)
- `lib\presentation\views\home_view.dart:123:27` (FLV)

**현재 코드**:
```dart
RxDouble current_latitude = 0.0.obs;
RxDouble current_longitude = 0.0.obs;
bool ShowLowGpsAlertOnce = false;
```

**해결책**:
```dart
RxDouble currentLatitude = 0.0.obs;
RxDouble currentLongitude = 0.0.obs;
bool showLowGpsAlertOnce = false;
```

#### 2. library_private_types_in_public_api (1개)
**문제**: public API에서 private 타입 사용
**위치**: `lib\presentation\views\test_view.dart:7:3`

**현재 코드**:
```dart
class TestView extends StatefulWidget {
  @override
  _TestViewState createState() => _TestViewState();
}
```

**해결책**:
```dart
class TestView extends StatefulWidget {
  @override
  State<TestView> createState() => _TestViewState();
}
```

#### 3. unrelated_type_equality_checks (2개)
**문제**: 관련 없는 타입 비교
**위치**: `lib\domain\usecases\auth_usecase.dart:279, 300`

**현재 코드**:
```dart
if (userData == false) // AuthDataModel?과 bool 비교
```

**해결책**:
```dart
if (userData == null) // null 체크로 변경
```

---

### 🟡 중간 문제 (Medium) - 1시간 이내 해결 가능

#### 1. deprecated_member_use (6개)
**문제**: deprecated된 API 사용

##### a) withOpacity (3개)
**위치**: `lib\presentation\views\setting_view.dart`
```dart
// 현재
color.withOpacity(0.5)
// 해결
color.withValues(alpha: 0.5)
```

##### b) discoverServices (3개)
**위치**: `lib\data\sources\blue_native_data_source.dart`
```dart
// 현재
await bluetooth.discoverServices(deviceId);
// 해결
await bluetooth.discoverAllServices(deviceId);
final services = await bluetooth.getDiscoveredServices(deviceId);
```

##### c) NaverMapSdk.initialize (2개)
**위치**: `lib\main.dart:29`
```dart
// 현재
await NaverMapSdk.instance.initialize();
// 해결
await FlutterNaverMap.init();
```

#### 2. 경고(warning) - 3개

##### a) unreachable_switch_default (1개)
**위치**: `lib\domain\entities\auth_type.dart:16:7`
```dart
// 모든 case가 커버되어 default가 불필요
// default 제거하거나 특정 case로 변경
```

##### b) unused_shown_name (1개)
**위치**: `lib\framework\data_source.dart:5:23`
```dart
// HttpResponse가 import되었지만 사용 안 함
import 'dart:io' show Platform; // HttpResponse 제거
```

##### c) unrecognized_error_code (1개)
**위치**: 외부 패키지 (text_to_speech)
```yaml
# 패키지 관리자가 해결해야 함 - 무시 가능
```

---

### 🔴 어려운 문제 (Hard) - 2시간 이상 소요 가능

#### use_build_context_synchronously (30개)
**문제**: async 갭에서 BuildContext 사용 (가장 위험한 패턴)
**주요 위치**:
- `lib\presentation\views\startspot_search_view.dart` (9개)
- `lib\presentation\views\destination_search_view.dart` (9개)
- `lib\presentation\views\home_view.dart` (6개)
- `lib\presentation\views\map_view.dart` (3개)
- 기타 view 파일들

**현재 코드**:
```dart
Future<void> _loadData() async {
  await someAsyncOperation();
  Navigator.of(context).pop(); // 위험!
}
```

**해결책 1 - mounted 체크**:
```dart
Future<void> _loadData() async {
  await someAsyncOperation();
  if (mounted) {
    Navigator.of(context).pop();
  }
}
```

**해결책 2 - context 사전 저장**:
```dart
Future<void> _loadData(BuildContext context) async {
  final nav = Navigator.of(context);
  await someAsyncOperation();
  nav.pop();
}
```

**해결책 3 - 콜백 패턴**:
```dart
Future<void> _loadData(VoidCallback onComplete) async {
  await someAsyncOperation();
  onComplete();
}

// 사용
_loadData(() {
  if (mounted) {
    Navigator.of(context).pop();
  }
});
```

---

## 🔧 빠른 수정 스크립트

### PowerShell 일괄 변경 스크립트
```powershell
# 변수명 수정 (snake_case → camelCase)
$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"
foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $content = $content -replace 'current_latitude', 'currentLatitude'
    $content = $content -replace 'current_longitude', 'currentLongitude'
    $content = $content -replace 'remain_distance', 'remainDistance'
    $content = $content -replace 's_latitude', 'sLatitude'
    $content = $content -replace 's_longitude', 'sLongitude'
    $content = $content -replace 's_accuracy', 'sAccuracy'
    $content = $content -replace 'ShowLowGpsAlertOnce', 'showLowGpsAlertOnce'
    $content = $content -replace 'withOpacity\(([\d.]+)\)', 'withValues(alpha: $1)'
    Set-Content $file.FullName $content
}
```

### VSCode 검색/바꾸기 정규식
```
# snake_case를 camelCase로
찾기: ([a-z])_([a-z])
바꾸기: $1\u$2

# withOpacity 변경
찾기: withOpacity\(([\d.]+)\)
바꾸기: withValues(alpha: $1)
```

---

## 📋 우선순위 작업 계획

### ✅ Phase 1: 자동 수정 완료
1. [✓] `dart fix --apply` 실행 - 103개 자동 수정
2. [✓] use_super_parameters 수정 완료
3. [✓] use_key_in_widget_constructors 수정 완료
4. [✓] unnecessary_this 대부분 제거

### Phase 2: 수동 수정 필요 (30분)
1. [ ] non_constant_identifier_names 수정 (8개)
2. [ ] withOpacity → withValues 변경 (3개)
3. [ ] discoverServices → discoverAllServices (3개)
4. [ ] NaverMapSdk → FlutterNaverMap (2개)
5. [ ] unrelated_type_equality_checks 수정 (2개)

### Phase 3: BuildContext 문제 해결 (2-3시간)
1. [ ] use_build_context_synchronously 패턴 수정 (30개)
2. [ ] mounted 체크 추가
3. [ ] 경고(warning) 3개 해결

---

## 📊 예상 결과

### 수정 현황
- **✅ Phase 1 완료**: 156 → 53개 (dart fix 자동 수정)
- **Phase 2 진행 시**: 53 → ~35개 (예상)
- **Phase 3 완료 시**: ~35 → 0개 (예상)

### 성능 영향
- **긍정적**: unused 코드 제거로 빌드 크기 감소
- **중립적**: 대부분의 변경은 코드 스타일만 영향
- **주의필요**: BuildContext 관련 수정은 충분한 테스트 필요

---

## ⚠️ 주의사항

1. **백업 필수**: 대량 수정 전 git commit 필수
2. **단계별 테스트**: 각 Phase 후 앱 동작 확인
3. **BuildContext 수정**: 가장 신중하게 접근 (런타임 에러 가능)
4. **deprecated API**: Flutter 업그레이드 시 breaking change 확인

---

## 🔗 참고 자료

- [Flutter 3.18 Migration Guide](https://docs.flutter.dev/release/breaking-changes/material-3-migration)
- [Effective Dart: Style](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Lints](https://pub.dev/packages/flutter_lints)
- [BuildContext Best Practices](https://docs.flutter.dev/development/ui/advanced/actions-and-shortcuts#using-buildcontext)

---

**작성자**: SafeLight 개발팀  
**최종 수정**: 2025-09-09  
**Phase 1 완료**: 2025-09-09 (dart fix 자동 수정으로 103개 해결)