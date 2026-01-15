import 'package:safelight/core/utils/korean_particle.dart';

/// TTS 멘트 중앙 관리
///
/// 모든 TTS 멘트를 한 곳에서 관리하여 일관성을 유지합니다.
/// SSOT(Single Source of Truth) 원칙 적용.
///
/// **사용 예시:**
/// ```dart
/// final message = TtsMessages.poiAnnouncement('열두시', 25, '농협사거리 횡단보도');
/// ttsService.speak(message);
/// ```
abstract class TtsMessages {
  // ============================================================
  // POI 안내 멘트
  // ============================================================

  /// 단일 POI 안내 문구 생성
  ///
  /// [direction]: 시계 방향 (예: "열두시", "세시")
  /// [meters]: 거리 (미터)
  /// [name]: POI 이름
  ///
  /// 반환: "열두시방향 25미터에 농협사거리 횡단보도"
  static String poiDescription(String direction, int meters, String name) =>
      '$direction방향 $meters미터에 $name';

  /// 여러 POI 안내 문구 생성
  ///
  /// [descriptions]: POI 설명 목록 (poiDescription으로 생성)
  /// [lastPoiName]: 마지막 POI 이름 (조사 결정용)
  ///
  /// 반환: "주변에 열두시방향 25미터에 A, 세시방향 30미터에 B가 있습니다"
  static String nearbyPoiSummary(List<String> descriptions, {String? lastPoiName}) {
    if (descriptions.isEmpty) return '';

    // 마지막 POI 이름으로 조사 결정
    final particle = lastPoiName != null
        ? KoreanParticle.subjectParticle(lastPoiName)
        : '이'; // 기본값

    return '주변에 ${descriptions.join(', ')}$particle 있습니다';
  }

  // ============================================================
  // 횡단보도/음향신호기 안내 멘트
  // ============================================================

  /// 교차로명이 있는 횡단보도
  ///
  /// [intersectionName]: 교차로명 (예: "농협사거리", "역곡역")
  ///
  /// 반환: "농협사거리 횡단보도"
  static String crosswalkWithIntersection(String intersectionName) =>
      '$intersectionName 횡단보도';

  /// 교차로명이 없는 횡단보도
  static const String crosswalkOnly = '횡단보도';

  // ============================================================
  // 즐겨찾기 안내 멘트
  // ============================================================

  /// 즐겨찾기 장소 이름
  ///
  /// [name]: 즐겨찾기 이름
  ///
  /// 반환: "내 장소 집"
  static String favoritePlaceName(String name) => '내 장소 $name';

  // ============================================================
  // 에러/상태 안내 멘트
  // ============================================================

  /// GPS 정보 없음
  static const String gpsError = 'GPS 정보를 가져올 수 없습니다';

  /// 네트워크 에러
  static const String networkError = '네트워크 연결을 확인해주세요';

  /// 주변에 장소 없음
  static const String noNearbyPlaces = '주변에 등록된 장소가 없습니다';

  /// 타임아웃
  static const String timeout = '위치 정보 조회 시간이 초과되었습니다. 다시 시도해주세요';

  // ============================================================
  // BLE/스마트 압버튼 안내 멘트
  // ============================================================

  /// 자동 스캔 시작
  static const String autoScanStarted = '자동 스캔이 시작됩니다.';

  /// 스마트 압버튼 발견
  static String smartButtonsFound(int count) => '$count 개의 스마트 압버튼을 찾았습니다.';

  /// 신호안내 요청
  static String requestSignalGuide(String name) => '$name에 신호안내를 요청합니다.';

  /// 명령 전송 완료
  static const String commandSent = '명령이 전송되었습니다.';

  /// 연결 실패
  static const String connectionFailed = '연결 실패했습니다.';

  /// 연결 중
  static String connectingTo(String name) => '$name에 연결합니다.';

  /// 진동 안내
  static const String walkTowardsNoVibration = '진동이 울리지 않는 방향으로 보행하세요.';

  /// 음성안내 요청
  static String requestVoiceGuide(String name) => '$name에 음성안내를 요청합니다.';

  /// 음향신호기 위치 안내
  static const String signalDeviceLocationInfo = '음향신호기 설치 위치 정보를 안내합니다.';

  // ============================================================
  // 시스템 상태 안내 멘트
  // ============================================================

  /// 경광등 켜짐 알림 (주기적)
  static const String flashLightCurrentlyOn = '현재 경광등이 켜져 있습니다.';

  /// 블루투스 꺼짐
  static const String bluetoothOff = '블루투스가 꺼져 있습니다. 블루투스를 켜주세요.';

  /// 안전 나침반 켜짐
  static const String safetyCompassOn = '안전 나침반이 켜집니다. 진동이 울리지 않는 방향으로 보행하세요.';

  // ============================================================
  // 경로 안내 멘트
  // ============================================================

  /// 목적지 도착
  static const String arrivedAtDestination = '목적지에 도착했습니다.';

  /// 출발지로 이동 안내
  static const String moveToStartPoint = '출발지로 이동하세요.';

  /// 경로 재탐색 완료
  static const String rerouteComplete = '새로운 경로로 안내합니다.';

  /// 출발지 이탈로 인한 재탐색
  static const String rerouteFromDeviation = '출발지에 벗어나 새로운 경로로 안내합니다.';

  /// 횡단보도 접근 경고
  static const String crosswalkAhead = '잠시 후 횡단보도 입니다. 차량에 유의하세요!';

  /// 분기점 안내
  static String branchInstruction(String description) => '$description하세요.';

  /// 남은 거리 안내
  static String remainingDistance(int meters) => '다음 안내까지 ${meters}미터 남았습니다.';

  // ============================================================
  // 경광등 제어 멘트
  // ============================================================

  /// 경광등 켜짐
  static const String flashTurnedOn = '안전 경광등이 켜졌습니다.';

  /// 경광등 꺼짐
  static const String flashTurnedOff = '안전 경광등이 꺼졌습니다.';

  /// 경광등 켜기 실패
  static const String cannotTurnOnFlash = '안전 경광등을 켤 수 없습니다.';

  /// 경광등 끄기 실패
  static const String cannotTurnOffFlash = '안전 경광등을 끌 수 없습니다.';

  /// 경광등 제어 오류
  static const String flashControlError = '경광등 제어 중 오류가 발생했습니다.';

  // ============================================================
  // 장소 검색 안내 멘트
  // ============================================================

  /// 장소 선택됨
  static String placeSelected(String name) =>
      '$name${KoreanParticle.objectParticle(name)} 선택하셨습니다.';

  /// 장소로 안내
  static String navigatingTo(String name) =>
      '$name${KoreanParticle.directionParticle(name)} 안내합니다.';

  /// 출입구로 안내
  static String navigatingToEntrance(String entranceName) =>
      '$entranceName${KoreanParticle.directionParticle(entranceName)} 안내합니다.';

  /// 지도에서 위치 선택됨
  static String locationSelected(String address) => '$address 위치를 선택하셨습니다.';

  /// 취소
  static const String cancelled = '취소';

  /// 현재 위치로 설정됨
  static const String currentLocationSet = '현재 위치로 설정하셨습니다.';

  /// 위치 권한 필요
  static const String locationPermissionRequired = '위치 권한이 필요합니다.';

  /// 현재 위치 가져오기 실패
  static const String cannotGetCurrentLocation = '현재 위치를 가져올 수 없습니다.';

  // ============================================================
  // UI 피드백 멘트
  // ============================================================

  /// 경로 이탈 안내 (시계 방향)
  static String outOfBound(String clockDirection) => '$clockDirection 방향으로 이동하세요.';

  /// 패널 토글 안내
  static String panelToggle(String menu, String state) => '$menu 패널을 $state';

  /// 패널 전환 안내
  static String panelSwitch(String menu) => '$menu 패널로 이동합니다.';

  /// 즐겨찾기 지점 안내 선택
  static String navigateToFavoritePoint(String name) =>
      '$name${KoreanParticle.directionParticle(name)} 안내를 선택했습니다.';

  /// 즐겨찾기 경로 안내 선택
  static String navigateToFavoriteRoute(String name) =>
      '$name${KoreanParticle.directionParticle(name)} 안내를 선택했습니다.';
}
