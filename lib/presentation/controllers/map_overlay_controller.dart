part of '../../framework/controller.dart';

enum BranchType { start, waypoint, normal, destination }

/// 지도 위 오버레이(경로, 마커 등)를 관리하는 컨트롤러
class MapOverlayController {
  /// 생성자: NaverMapController를 주입받음
  MapOverlayController({
    required this.mapController,
    required this.routeController,
  });

  RouteController routeController;

  /// 네이버 지도 컨트롤러 (지도 조작 및 오버레이 추가/삭제에 사용)
  NaverMapController? mapController;

  /// 현재 위치 마커
  NMarker? _currentLocationMarker;

  /// 현재 위치 마커 Getter
  NMarker? get currentLocationMarker => _currentLocationMarker;

  /// 횡단보도(음향신호기) 마커 캐시
  final Map<String, NMarker> _signalDeviceMarkers = {};

  /// 횡단보도 마커 아이콘 캐시 (방향별)
  /// key: 방향(도), value: 해당 방향의 아이콘
  /// null 키는 방향 정보가 없는 경우
  final Map<int?, NOverlayImage> _crosswalkIcons = {};

  /// 마지막으로 횡단보도 마커를 업데이트한 위치
  double? _lastCrosswalkLat;
  double? _lastCrosswalkLng;

  /// 교차로 마커 캐시
  final Map<String, NMarker> _intersectionMarkers = {};

  /// 교차로 마커 아이콘 캐시
  NOverlayImage? _intersectionIcon;

  /// 마지막으로 교차로 마커를 업데이트한 위치
  double? _lastIntersectionLat;
  double? _lastIntersectionLng;

  /// addPathOverlays: 경로 오버레이를 지도에 추가
  void addPathOverlays(List<LatLng> paths) {
    if (mapController == null) return;
    final overlays = {
      NMultipartPathOverlay(
        id: "path",
        paths: [
          NMultipartPath(
            coords: paths
                .map((coord) => NLatLng(coord.latitude, coord.longitude))
                .toList(),
            outlineColor: Colors.blue,
          ),
        ],
        outlineWidth: 3,
      ),
    };
    mapController!.addOverlayAll(overlays);
  }

  // /// map_overlay_controller.dart로
  // /// addBranchMarkers: 지도에 분기(체크포인트) 마커들을 추가합니다.
  // /// 출발지: 파란색, 목적지: 빨간색, 경유지: 회색, 일반: 초록색으로 표시합니다.
  Future<void> addBranchMarkers() async {
    if (mapController == null) {
      debugPrint("mapController가 없습니다. 마커 추가 불가");
      return;
    }

    if (routeController.branchinfo.isEmpty) {
      debugPrint("branchinfo가 비어있습니다. 마커 추가 불가");
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint("navigatorKey.currentContext가 null입니다. 마커 추가 불가");
      return;
    }
    final markersCache = <String, NMarker>{};
    final markersSet = <NAddableOverlay>{};

    // 1️⃣ 타입별 색상 정의
    final Map<BranchType, Color> branchColors = {
      BranchType.start: Colors.blue,
      BranchType.destination: Colors.red,
      BranchType.waypoint: Colors.grey,
      BranchType.normal: Colors.green,
    };

    // 2️⃣ 아이콘 생성 (1회만)
    final iconMap = await _createBranchMarkerIcons(branchColors, context);

    // 3️⃣ 분기점 반복 처리
    for (int i = 0; i < routeController.branchinfo.length; i++) {
      final branch = routeController.branchinfo[i];
      final id = 'checkPoint_$i';

      // 타입 판정
      final type = _getBranchType(
        i,
        routeController.branchinfo.length,
        branch,
      );

      // 중복 방지
      if (markersCache.containsKey(id)) continue;

      final marker = NMarker(
        id: id,
        position: NLatLng(branch.point.latitude, branch.point.longitude),
        icon: iconMap[type]!,
      );

      markersCache[id] = marker;
    }

    markersSet.addAll(markersCache.values);
    await mapController!.addOverlayAll(markersSet);

    debugPrint("📍 addBranchMarkers() 완료됨 — ${markersSet.length}개 추가됨");
  }

  /// _createBranchMarkerIcons: 분기점 타입별 아이콘 생성
  Future<Map<BranchType, NOverlayImage>> _createBranchMarkerIcons(
    Map<BranchType, Color> branchColors,
    BuildContext context,
  ) async {
    const double branchIconSize = 15;
    final Map<BranchType, NOverlayImage> icons = {};

    for (final entry in branchColors.entries) {
      icons[entry.key] = await NOverlayImage.fromWidget(
        widget: Icon(Icons.circle, color: entry.value, size: branchIconSize),
        size: const Size(branchIconSize, branchIconSize),
        context: context,
      );
    }

    return icons;
  }

  /// _getBranchType: 분기점의 타입을 판정하는 헬퍼 메서드
  BranchType _getBranchType(
    int index,
    int totalLength,
    BranchInfo branch,
  ) {
    if (index == 0) return BranchType.start;
    if (index == totalLength - 1) return BranchType.destination;
    if (branch.waypoint) return BranchType.waypoint;
    return BranchType.normal;
  }

  /// updateCurrentLocationMarker: 현재 위치 마커 업데이트
  Future<void> updateCurrentLocationMarker(
    double currentLatitude,
    double currentLongitude,
    double compassValue,
    bool isGps,
    MapControlMode mapMode,
  ) async {
    if (mapController == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint("updateCurrentLocationMarker: context가 null입니다.");
      return;
    }

    final mapBearing =
        await mapController!.getCameraPosition().then((pos) => pos.bearing);

    // async gap 후 context 유효성 체크
    if (!context.mounted) return;

    // 아이콘 속성 생성
    final icon = await _createLocationMarkerIcon(
      compassValue: compassValue,
      mapBearing: mapBearing,
      isGps: isGps,
      mapMode: mapMode,
      context: context,
    );

    if (_currentLocationMarker == null) {
      // 마커가 없으면 새로 생성
      _currentLocationMarker = NMarker(
        id: 'current_location',
        position: NLatLng(currentLatitude, currentLongitude),
        icon: icon,
      );

      // 지도에 마커 추가
      mapController!.addOverlay(_currentLocationMarker!);
    } else {
      // 마커가 이미 존재하면 아이콘 갱신
      _currentLocationMarker!.setIcon(icon);
      // 이미 존재하면 위치만 갱신
      _currentLocationMarker!.setPosition(
        NLatLng(currentLatitude, currentLongitude),
      );
    }
    //debugPrint("현재 위치 마커가 업데이트되었습니다.");
  }

  /// 아이콘 생성 로직 (형태/색상 분리)
  Future<NOverlayImage> _createLocationMarkerIcon({
    required double compassValue,
    required double mapBearing,
    required bool isGps,
    required MapControlMode mapMode,
    required BuildContext context,
  }) async {
    // 기기 나침반 각도와 지도 각도를 보정
    final double adjustedAngle =
        _adjustAngleForIconBearing(compassValue, mapBearing);
    // mapMode에 따라 아이콘 선택
    final IconData iconImage = _selectIconByMapMode(mapMode);
    // 센서 기반 아이콘 색상 선택
    final Color color = _selectColorBySource(isGps);
    // 아이콘 크기 정의
    const double locationMarkerSize = 25.0;

    return NOverlayImage.fromWidget(
      widget: Transform.rotate(
        angle: Calculators.deg2rad(adjustedAngle),
        child: Icon(iconImage, color: color, size: locationMarkerSize),
      ),
      size: const Size(locationMarkerSize, locationMarkerSize),
      context: context,
    );
  }

  /// 아이콘 각도 보정 로직 (나침반 값과 지도 방향값 기반)
  /// 단위는 도입니다.
  double _adjustAngleForIconBearing(double compassValue, double mapBearing) {
    double adjustedAngle = compassValue - mapBearing;
    if (adjustedAngle < 0) adjustedAngle += 360;
    return adjustedAngle;
  }

  /// 아이콘 이미지 선택 로직 (지도 모드 기반)
  IconData _selectIconByMapMode(MapControlMode mapMode) {
    final IconData iconImage =
        mapMode == MapControlMode.idle || mapMode == MapControlMode.off
            ? Icons.circle
            : Icons.navigation;

    return iconImage;
  }

  /// 색상 선택 (GPS 기반)
  Color _selectColorBySource(bool isGps) {
    return isGps ? Colors.blue : Colors.red;
  }

  /// clearOverlays: 지도에서 모든 오버레이 제거
  Future<void> clearOverlays() async {
    if (mapController == null) return;
    mapController!.clearOverlays();
    _currentLocationMarker = null; // 현재 위치 마커 초기화
    _signalDeviceMarkers.clear(); // 횡단보도 마커 초기화
    _intersectionMarkers.clear(); // 교차로 마커 초기화
    debugPrint("모든 오버레이가 제거되었습니다.");
  }

  // ====== 횡단보도(음향신호기) 마커 관련 메서드 ======

  /// 횡단보도 마커 업데이트 (위치 기반)
  ///
  /// 현재 위치 기준 반경 내 음향신호기를 조회하여 지도에 마커로 표시한다.
  /// 위치가 50m 이상 변경된 경우에만 업데이트하여 성능 최적화.
  Future<void> updateCrosswalkMarkers({
    required double latitude,
    required double longitude,
    //double radiusInMeters = 1000,
    double radiusInMeters = 1000, // 100km - 서울 전체 음향신호기 표시용
  }) async {
    if (mapController == null) return;

    // 위치 변경이 50m 미만이면 업데이트 스킵 (성능 최적화)
    if (_lastCrosswalkLat != null && _lastCrosswalkLng != null) {
      final distance = _calculateDistance(
        _lastCrosswalkLat!,
        _lastCrosswalkLng!,
        latitude,
        longitude,
      );
      if (distance < 50) return;
    }

    try {
      // UseCase로 주변 음향신호기 조회
      final getNearbySignalDevices = DI<GetNearbySignalDevices>();
      final result = await getNearbySignalDevices(
        NearbySignalDevicesParams(
          latitude: latitude,
          longitude: longitude,
          radiusInMeters: radiusInMeters,
        ),
      );

      result.fold(
        (failure) {
          debugPrint('횡단보도 마커 조회 실패: ${failure.message}');
        },
        (devices) async {
          await _updateSignalDeviceMarkersOnMap(devices);
          _lastCrosswalkLat = latitude;
          _lastCrosswalkLng = longitude;
          debugPrint('횡단보도 마커 업데이트: ${devices.length}개');
        },
      );
    } catch (e) {
      debugPrint('횡단보도 마커 업데이트 오류: $e');
    }
  }

  /// 지도에 음향신호기 마커 업데이트
  Future<void> _updateSignalDeviceMarkersOnMap(
    List<SignalDevice> devices,
  ) async {
    if (mapController == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // 현재 표시할 마커 ID 집합
    final currentIds = devices.map((d) => d.managementId).toSet();

    // 1. 더 이상 표시하지 않을 마커 제거
    final toRemove = <String>[];
    for (final id in _signalDeviceMarkers.keys) {
      if (!currentIds.contains(id)) {
        toRemove.add(id);
      }
    }
    for (final id in toRemove) {
      final marker = _signalDeviceMarkers.remove(id);
      if (marker != null) {
        mapController!.deleteOverlay(
          NOverlayInfo(type: NOverlayType.marker, id: 'crosswalk_$id'),
        );
      }
    }

    // 2. 새로운 마커 추가
    final newMarkers = <NAddableOverlay>{};
    for (final device in devices) {
      if (!_signalDeviceMarkers.containsKey(device.managementId)) {
        // 방향별 아이콘 가져오기 (캐시에 없으면 생성)
        final icon = await _getOrCreateDirectionIcon(context, device.direction);

        final marker = NMarker(
          id: 'crosswalk_${device.managementId}',
          position: NLatLng(device.latitude, device.longitude),
          icon: icon,
        );
        _signalDeviceMarkers[device.managementId] = marker;
        newMarkers.add(marker);
      }
    }

    if (newMarkers.isNotEmpty) {
      await mapController!.addOverlayAll(newMarkers);
    }
  }

  /// 방향별 아이콘 가져오기 (캐시 사용)
  Future<NOverlayImage> _getOrCreateDirectionIcon(
    BuildContext context,
    int? direction,
  ) async {
    // 캐시에 있으면 반환
    if (_crosswalkIcons.containsKey(direction)) {
      return _crosswalkIcons[direction]!;
    }

    // 없으면 생성 후 캐시에 저장
    final icon = await _createCrosswalkIconWithDirection(context, direction);
    _crosswalkIcons[direction] = icon;
    return icon;
  }

  /// 방향이 포함된 횡단보도 마커 아이콘 생성
  ///
  /// [direction]: 방향(도). 0=북, 90=동, 180=남, 270=서. null이면 방향 없음.
  Future<NOverlayImage> _createCrosswalkIconWithDirection(
    BuildContext context,
    int? direction,
  ) async {
    const double iconSize = 28.0;
    const double arrowSize = 10.0;

    // 방향을 라디안으로 변환 (0°=북=위쪽, 시계방향)
    // Flutter의 Transform.rotate는 시계방향이 양수
    final double rotationAngle =
        direction != null ? direction * math.pi / 180 : 0;

    return NOverlayImage.fromWidget(
      widget: SizedBox(
        width: iconSize,
        height: iconSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 원형 배경
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            // 방향 화살표 (방향 정보가 있을 때만)
            if (direction != null)
              Transform.rotate(
                angle: rotationAngle,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: arrowSize,
                    height: arrowSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.orange,
                      size: 8,
                    ),
                  ),
                ),
              ),
            // 방향 정보 없으면 보행자 아이콘
            if (direction == null)
              const Icon(
                Icons.directions_walk,
                color: Colors.white,
                size: 10,
              ),
          ],
        ),
      ),
      size: const Size(iconSize, iconSize),
      context: context,
    );
  }

  /// 거리 계산 (미터 단위, 간이 계산)
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const meterPerLat = 111000.0;
    const meterPerLng = 88000.0;
    final dLat = (lat2 - lat1) * meterPerLat;
    final dLng = (lng2 - lng1) * meterPerLng;
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  /// 횡단보도 마커만 제거
  Future<void> clearCrosswalkMarkers() async {
    if (mapController == null) return;

    for (final entry in _signalDeviceMarkers.entries) {
      mapController!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: 'crosswalk_${entry.key}'),
      );
    }
    _signalDeviceMarkers.clear();
    _lastCrosswalkLat = null;
    _lastCrosswalkLng = null;
    debugPrint('횡단보도 마커가 모두 제거되었습니다.');
  }

  // ====== 교차로 마커 관련 메서드 ======

  /// 교차로 마커 업데이트 (위치 기반)
  ///
  /// 현재 위치 기준 반경 내 교차로를 조회하여 지도에 마커로 표시한다.
  /// 위치가 50m 이상 변경된 경우에만 업데이트하여 성능 최적화.
  Future<void> updateIntersectionMarkers({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000, // 100km - 서울 전체 교차로 표시용
  }) async {
    if (mapController == null) return;

    // 위치 변경이 50m 미만이면 업데이트 스킵 (성능 최적화)
    if (_lastIntersectionLat != null && _lastIntersectionLng != null) {
      final distance = _calculateDistance(
        _lastIntersectionLat!,
        _lastIntersectionLng!,
        latitude,
        longitude,
      );
      if (distance < 50) return;
    }

    try {
      // UseCase로 주변 교차로 조회
      final getNearbyIntersections = DI<GetNearbyIntersections>();
      final result = await getNearbyIntersections(
        NearbyIntersectionsParams(
          latitude: latitude,
          longitude: longitude,
          radiusInMeters: radiusInMeters,
        ),
      );

      result.fold(
        (failure) {
          debugPrint('교차로 마커 조회 실패: ${failure.message}');
        },
        (intersections) async {
          await _updateIntersectionMarkersOnMap(intersections);
          _lastIntersectionLat = latitude;
          _lastIntersectionLng = longitude;
          debugPrint('교차로 마커 업데이트: ${intersections.length}개');
        },
      );
    } catch (e) {
      debugPrint('교차로 마커 업데이트 오류: $e');
    }
  }

  /// 지도에 교차로 마커 업데이트
  Future<void> _updateIntersectionMarkersOnMap(
    List<Intersection> intersections,
  ) async {
    if (mapController == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // 현재 표시할 마커 ID 집합
    final currentIds = intersections.map((i) => i.intersectionId).toSet();

    // 1. 더 이상 표시하지 않을 마커 제거
    final toRemove = <String>[];
    for (final id in _intersectionMarkers.keys) {
      if (!currentIds.contains(id)) {
        toRemove.add(id);
      }
    }
    for (final id in toRemove) {
      final marker = _intersectionMarkers.remove(id);
      if (marker != null) {
        mapController!.deleteOverlay(
          NOverlayInfo(type: NOverlayType.marker, id: 'intersection_$id'),
        );
      }
    }

    // 2. 아이콘 준비 (캐시에 없으면 생성)
    _intersectionIcon ??= await _createIntersectionIcon(context);

    // 3. 새로운 마커 추가
    final newMarkers = <NAddableOverlay>{};
    for (final intersection in intersections) {
      if (!_intersectionMarkers.containsKey(intersection.intersectionId)) {
        final marker = NMarker(
          id: 'intersection_${intersection.intersectionId}',
          position: NLatLng(intersection.latitude, intersection.longitude),
          icon: _intersectionIcon!,
        );
        _intersectionMarkers[intersection.intersectionId] = marker;
        newMarkers.add(marker);
      }
    }

    if (newMarkers.isNotEmpty) {
      await mapController!.addOverlayAll(newMarkers);
    }
  }

  /// 교차로 마커 아이콘 생성
  ///
  /// 파란색 둥근 사각형 + 교차로 심볼 (+)
  Future<NOverlayImage> _createIntersectionIcon(BuildContext context) async {
    const double iconSize = 24.0;

    return NOverlayImage.fromWidget(
      widget: SizedBox(
        width: iconSize,
        height: iconSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 둥근 사각형 배경
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            // 교차로 심볼 (+)
            const Icon(
              Icons.add,
              color: Colors.white,
              size: 12,
            ),
          ],
        ),
      ),
      size: const Size(iconSize, iconSize),
      context: context,
    );
  }

  /// 교차로 마커만 제거
  Future<void> clearIntersectionMarkers() async {
    if (mapController == null) return;

    for (final entry in _intersectionMarkers.entries) {
      mapController!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: 'intersection_${entry.key}'),
      );
    }
    _intersectionMarkers.clear();
    _lastIntersectionLat = null;
    _lastIntersectionLng = null;
    debugPrint('교차로 마커가 모두 제거되었습니다.');
  }
}
