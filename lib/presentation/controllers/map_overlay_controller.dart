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

    final context = navigatorKey.currentContext!;
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


  MapControlMode _previousMapmode = MapControlMode.idle;

  /// updateCurrentLocationMarker: 현재 위치 마커 업데이트
  Future<void> updateCurrentLocationMarker(
    double currentLatitude,
    double currentLongitude,
    double compassValue,
    bool isGps,
    MapControlMode mapMode,
  ) async {
    if (mapController == null) return;
    final mapBearing =
        await mapController!.getCameraPosition().then((pos) => pos.bearing);
    
    final icon = await _createLocationMarkerIcon(
      compassValue: compassValue,
      mapBearing: mapBearing,
      isGps: isGps,
      mapMode: mapMode,
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
    }
    else {
      // 마커가 이미 존재하면 아이콘 갱신
      _currentLocationMarker!.setIcon(icon);
      // 이미 존재하면 위치만 갱신
      _currentLocationMarker!.setPosition(
        NLatLng(currentLatitude, currentLongitude),
      );
      

    }
    _previousMapmode = mapMode;
  }

  
  /// 아이콘 생성 로직 (형태/색상 분리)
  Future<NOverlayImage> _createLocationMarkerIcon({
    required double compassValue,
    required double mapBearing,
    required bool isGps,
    required MapControlMode mapMode,
  }) async {
    // 기기 나침반 각도와 지도 각도를 보정
    final double adjustedAngle = _adjustAngleForIconBearing(compassValue, mapBearing);
    // mapMode에 따라 아이콘 선택
    final iconImage = _selectIconByMapMode(mapMode);
    // 센서 기반 아이콘 색상 선택
    final color = _selectColorBySource(isGps);

    const locationMarkerSize = 25.0;

    
    return NOverlayImage.fromWidget(
      widget: Transform.rotate(
        angle: Calculators.deg2rad(adjustedAngle),
        child: Icon(iconImage, color: color, size: locationMarkerSize),
      ),
      size: const Size(locationMarkerSize, locationMarkerSize),
      context: navigatorKey.currentContext!,
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
  IconData _selectIconByMapMode(MapControlMode mapMode){
    final IconData iconImage = mapMode == MapControlMode.idle ||
            mapMode == MapControlMode.off
        ? Icons.circle
        : Icons.navigation;
    
    return iconImage;
  }

  /// 색상 선택 (GPS 기반)
  Color _selectColorBySource(bool isGps) {
    return isGps ? Colors.blue : Colors.red;
  }


  /// clearOverlays: 지도에서 모든 오버레이 제거
  void clearOverlays() {
    if (mapController == null) return;
    mapController!.clearOverlays();
    _currentLocationMarker = null; // 현재 위치 마커 초기화
    debugPrint("모든 오버레이가 제거되었습니다.");
  }
}