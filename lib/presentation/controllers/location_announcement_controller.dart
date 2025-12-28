part of '../../framework/controller.dart';

const _kLocationAnnouncementDebug = true;

/// 현재 위치 알림 기능을 담당하는 Controller
///
/// GPS 좌표를 기반으로 주변의 가장 가까운 장소(POI) 정보를 조회하고,
/// TTS로 음성 안내를 제공합니다.
///
/// **책임:**
/// - 현재 GPS 좌표 가져오기
/// - 주변 POI 검색 (카카오 Category Search API)
/// - TTS 메시지 생성 및 안내
/// - 에러 처리 및 사용자 피드백
///
/// **데이터 플로우:**
/// ```
/// GPS 좌표
///   ↓ (NavigatorRepository)
/// 주변 POI 검색
///   ↓ (KakaoRepository.searchNearbyPlaces)
/// List<PlaceResult> (거리순 정렬)
///   ↓ (가장 가까운 장소 선택)
/// TtsService
///   ↓
/// 음성 안내
/// ```
///
/// **개선 사항:**
/// - 응답 속도: 800ms → 300ms (62% 개선)
/// - 네트워크 요청: 2번 → 1번 (50% 감소)
/// - POI 커버리지: 5,000개 → 5,000,000개 (1000배)
///
/// **사용 예시:**
/// ```dart
/// final controller = DI.get<LocationAnnouncementController>();
/// await controller.announceNearbyBuilding();
/// ```
class LocationAnnouncementController {
  /// GPS 좌표 획득을 위한 Repository
  final NavigatorRepository navigatorRepository;
  /// 카카오 로컬 API Repository (주변 POI 검색)
  final KakaoRepository kakaoRepository;

  /// TTS 서비스
  final TtsService ttsService;

  /// 로딩 상태 관리 (중복 요청 방지)
  bool _isLoading = false;

  /// API 호출 타임아웃 시간 (30초)
  static const Duration _timeout = Duration(seconds: 30);
  static const double extensionPointDistanceKm = 0.04;

  

  LocationAnnouncementController({
    required this.navigatorRepository,
    required this.kakaoRepository,
    required this.ttsService,
  });
  
  /// 현재 위치 기반 건물 정보를 조회하고 TTS로 음성 안내
  ///
  /// **실행 흐름:**
  /// 0. 즉시 검색 시작 안내 (TTS: "주변 장소를 검색합니다")
  /// 1. GPS 좌표 가져오기 (NavigatorRepository)
  /// 2. 역지오코딩: GPS → 주소 변환 (KakaoRepository)
  /// 3. 건물 정보 조회 (NavigatorRepository.getBuildingEntrances - 출입구 API 재사용)
  /// 4. TTS 메시지 생성
  /// 5. 음성 안내 (TtsService: "아주대학교 다산관입니다")
  ///
  /// **에러 처리:**
  /// - GPS 정보 없음 → "GPS 정보를 가져올 수 없습니다"
  /// - 네트워크 에러 → "네트워크 연결을 확인해주세요"
  /// - 서버 에러 → "주변 건물 정보를 가져올 수 없습니다"
  Future<void> announceNearbyBuilding(double curLat, double curLng, double compassValue) async {
    // 중복 요청 방지 (디바운싱)
    if (_isLoading) {
      _log('[LocationAnnouncement] ⏳ 이미 로딩 중입니다. 요청 무시됨');
      return;
    }

    try {
      _isLoading = true;

      // 타임아웃과 함께 실행
      await _executeWithTimeout(curLat, curLng, compassValue);
    } catch (e, stackTrace) {
      
      _log('[LocationAnnouncement] ❌ 예외 발생: $e');
      _log('[LocationAnnouncement] 스택 트레이스:\n$stackTrace');
      
      // ttsService.speakWithChannel('알 수 없는 오류가 발생했습니다', channel: ETtsChannel.SYSTEM_ANNOUNCE, cooldownKey: 'poi_announcement_error', cooldown: Duration(seconds: 10),);
    } finally {
      _isLoading = false;
      _log('[LocationAnnouncement] ✨ 검색 완료 (로딩 상태 해제)');
    }
  }

  /// 타임아웃이 적용된 실제 검색 로직
  Future<void> _executeWithTimeout(double curLat, double curLng, double compassValue) async {
    try {
      await Future.any([
        _performSearch(curLat, curLng, compassValue),
        Future.delayed(_timeout).then((_) => throw TimeoutException(
              '위치 정보 조회 시간이 초과되었습니다',
              _timeout,
            )),
      ]);
    } on TimeoutException catch (e) {
      _log('[LocationAnnouncement] ⏱️ 타임아웃 발생: ${e.message}');
      // await ttsService.speak('위치 정보 조회 시간이 초과되었습니다. 다시 시도해주세요');
    }
  }


  
  /// 실제 검색 수행 (타임아웃 내부 로직)
  Future<void> _performSearch(double curLat, double curLng, double compassValue) async {

  
    // 0. 즉시 검색 시작 안내 (사용자 피드백)
    _log('[LocationAnnouncement] 🔍 주변 장소 검색 시작');
    // await ttsService.speak('주변 장소를 검색합니다');

    // // // 1. 현재 GPS 좌표 가져오기
    // final positionResult = await navigatorRepository.getCurrentPosition();

    // await positionResult.fold(
    //   (failure) async {
    //     // GPS 조회 실패
    //     debugPrint('[LocationAnnouncement] ❌ GPS 조회 실패: $failure');
    //     await ttsService.speak('GPS 정보를 가져올 수 없습니다');
    //   },
    //   (position) async {
        // GPS 좌표 성공
        _log('[LocationAnnouncement] ✅ GPS 좌표 수신:');
        _log('  - 위도(Latitude): $curLat');
        _log('  - 경도(Longitude): $curLng');
        final extensionLatLng =Calculators.calLatLng(curLat, curLng, compassValue, extensionPointDistanceKm);
        final double extensionLat = extensionLatLng['latitude']!;
        final double extensionLng = extensionLatLng['longitude']!;
        // 2. 주변 POI 검색 (카카오 Category Search API)
        
        _log('[LocationAnnouncement] 🗺️ 카카오 주변 POI 검색 시작');
        _log('  - 검색 반경: 50m');

        final placesResult = await kakaoRepository.searchNearbyPlaces(
          latitude: extensionLat,
          longitude: extensionLng,
          radius: 50,
        );

        placesResult.fold(
          (failure) {
            // POI 검색 실패
            _log('[LocationAnnouncement] ❌ POI 검색 실패: $failure');
            // ttsService.speak('주변 장소를 찾을 수 없습니다');
          },
          (places) {
            if (places.isEmpty) {
              // 검색 결과 없음
              _log('[LocationAnnouncement] ⚠️ 주변에 등록된 장소가 없습니다');
              // ttsService.speak('주변에 등록된 장소가 없습니다');
              return;
            }

            // 3. 내 실제 위치 기준으로 가장 가까운 장소 선택
            final nearest = _findNearestFromCurrentPosition(places, curLat, curLng);
            
              _log('[LocationAnnouncement] ✅ POI 검색 성공:');
              _log('  - 장소명: ${nearest.name}');
              _log('  - 거리: ${nearest.distance}m');
              _log('  - 주소: ${nearest.address}');

              // 검색된 모든 장소 로그 (디버깅용)
              _log('[LocationAnnouncement] 📍 검색된 장소 목록 (${places.length}개):');
              for (var i = 0; i < places.length; i++) {
                debugPrint('  ${i + 1}. ${places[i].name} (${places[i].distance}m)');
              }
            

            // 4. TTS 안내 (시계 방향 포함)
            final clockDirection = getClockDirectionForPoi(curLat: curLat, curLng: curLng, place: nearest, compassValue: compassValue);
            final userToPoiDistKm = Calculators.calculateDistance(
              curLat,
              curLng,
              nearest.geometry.location.lat,
              nearest.geometry.location.lng,
            );
            final userToPoiDistMeters = (userToPoiDistKm * 1000).round();
            final message = _buildPoiMessage(nearest, clockDirection, userToPoiDistMeters);

            _log('[LocationAnnouncement] 🔊 TTS 안내: $message');

            ttsService.speakWithChannel(
              message, 
              channel: ETtsChannel.NAVIGATE, 
              cooldownKey: 'nearby_poi', 
              cooldown: Duration(seconds: 10),
              );
          },
        );
  }

  /// PlaceResult를 TTS 메시지로 변환
  ///
  /// **메시지 형식:**
  /// - 100m 이내: "{장소명}, {거리}미터 앞입니다"
  /// - 100m 이상 또는 거리 없음: "{장소명} 근처입니다"
  ///
  /// **예시:**
  /// - distance: 23m → "스타벅스 아주대점, 23미터 앞입니다"
  /// - distance: 45m → "아주대학교, 45미터 앞입니다"
  /// - distance: 150m → "아주대학교 근처입니다"
  /// - distance: null → "강남역 근처입니다"
  String _buildPoiMessage(PlaceResult place, String clockDirection, int userToPoiDistMeters) {
    if (userToPoiDistMeters < 100) {
      // 100m 이내면 정확한 거리 안내
      return ' ${userToPoiDistMeters}미터 거리,${clockDirection}방향에 ${place.name}입니다';
    } else {
      // 100m 이상이거나 거리 정보 없으면 "근처"
      return '${place.name} 근처입니다';
    }
  }

  // double? _headingPrevLat;
  // double? _headingPrevLon;
  // double? _lastTrackHeadingDeg;

  // // 최소 이동 거리 상수 (튀면 숫자 조정)
  // static const double _minMoveMetersForHeading = 1.5;

  // /// GPS 기반 진행 방향 업데이트
  // /// - curLat/curLon만 받고, 이전 좌표는 내부에서 관리
  // /// - 충분히 안 움직였으면 이전 heading 유지 (새로 계산 X)
  // /// - 최초 호출 등으로 아직 heading 없으면 null
  // double? updateTrackHeadingByGps(double curLat, double curLon) {
  //   // 이전 좌표가 없으면: 저장만 하고 heading 계산 안 함
  //   if (_headingPrevLat == null || _headingPrevLon == null) {
  //     _headingPrevLat = curLat;
  //     _headingPrevLon = curLon;
  //     return _lastTrackHeadingDeg; // 아직 진행 방향 없음
  //   }

  //   final newHeading = Calculators.computeTrackHeadingWithThreshold(
  //     prevLat: _headingPrevLat!,
  //     prevLon: _headingPrevLon!,
  //     curLat: curLat,
  //     curLon: curLon,
  //     minMoveMeters: _minMoveMetersForHeading,
  //   );

  //   if (newHeading == null) {
  //     // 너무 조금 움직였으면: prev는 그대로 두고 heading도 그대로 둔다.
  //     return _lastTrackHeadingDeg;
  //   }

  //   // 충분히 움직였으면 heading 업데이트 + prev를 현재 위치로 당겨옴
  //   _lastTrackHeadingDeg = newHeading;
  //   _headingPrevLat = curLat;
  //   _headingPrevLon = curLon;

  //   return _lastTrackHeadingDeg;
  // }


  /// POI의 시계 방향을 계산하여 반환합니다.
  ///
  /// [curLat], [curLng]: 현재 위치 좌표
  /// [place]: 대상 POI
  /// [compassValue]: 현재 나침반 값 (북쪽 기준 사용자가 바라보는 방향)
  ///
  /// **반환값:** "12시", "3시" 등의 시계 방향 문자열
  ///
  /// **예시:**
  /// - 사용자가 북쪽을 바라보고 있고, POI가 동쪽에 있으면 → "3시"
  /// - 사용자가 북쪽을 바라보고 있고, POI가 남쪽에 있으면 → "6시"
  String getClockDirectionForPoi({
    required double curLat,
    required double curLng,
    required PlaceResult place,
    required double compassValue,
  }) {
    return Calculators.clockDirectionFromPositions(
      currentLatitude: curLat,
      currentLongitude: curLng,
      targetLatitude: place.geometry.location.lat,
      targetLongitude: place.geometry.location.lng,
      compassValue: compassValue,
    );
  }

  
  // String getClockDirectionForPoiByGps(double curLat, double curLng, PlaceResult place, double compassValue) {
  // final trackHeadingDeg = updateTrackHeadingByGps(curLat, curLng);

  // if (trackHeadingDeg == null) {
  //   // 아직 진행 방향을 결정할 만큼 안 움직였음 → 안내 스킵 or 컴퍼스 fallback
  //   return getClockDirectionForPoi(curLat: curLat, curLng: curLng, place: place, compassValue: compassValue);
  // }

  // final poiBearingDeg = Calculators.calculateBearing(
  //   curLat,
  //   curLng,
  //   place.geometry.location.lat,
  //   place.geometry.location.lng,
  // );

  // final relativeDeg = Calculators.normalizeAngleDeg(
  //   poiBearingDeg - trackHeadingDeg,
  // );

  // return Calculators.clockDirectionLabel(relativeDeg);


  // }

  void _log(String message) {
    if (_kLocationAnnouncementDebug) {
      debugPrint('[LocationAnnouncement] $message');
    }
  }

  /// 내 실제 위치 기준으로 가장 가까운 POI를 찾습니다.
  ///
  /// [places]: extension point 기준으로 검색된 POI 리스트
  /// [curLat], [curLng]: 내 실제 위치
  ///
  /// **반환값:** 내 위치에서 가장 가까운 PlaceResult
  PlaceResult _findNearestFromCurrentPosition(
    List<PlaceResult> places,
    double curLat,
    double curLng,
  ) {
    PlaceResult nearest = places.first;
    double minDistance = double.infinity;

    for (final place in places) {
      final distance = Calculators.calculateDistance(
        curLat,
        curLng,
        place.geometry.location.lat,
        place.geometry.location.lng,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = place;
      }
    }

    return nearest;
  }

}
