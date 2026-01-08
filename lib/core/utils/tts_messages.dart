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
  ///
  /// 반환: "주변에 열두시방향 25미터에 A, 세시방향 30미터에 B이 있습니다"
  static String nearbyPoiSummary(List<String> descriptions) =>
      '주변에 ${descriptions.join(', ')}이 있습니다';

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
}
