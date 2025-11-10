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

  /// addOverlays: 경로 오버레이를 지도에 추가
  void addOverlays(List<LatLng> paths) {
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
    debugPrint("🚫 mapController가 없습니다. 마커 추가 불가");
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
  final iconMap = await _createMarkerIcons(branchColors, context);

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



Future<Map<BranchType, NOverlayImage>> _createMarkerIcons(
  Map<BranchType, Color> branchColors,
  BuildContext context,
) async {
  const double iconSize = 15;
  final Map<BranchType, NOverlayImage> icons = {};

  for (final entry in branchColors.entries) {
    icons[entry.key] = await NOverlayImage.fromWidget(
      widget: Icon(Icons.circle, color: entry.value, size: iconSize),
      size: const Size(iconSize, iconSize),
      context: context,
    );
  }

  return icons;
}


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
    double current_latitude,
    double current_longitude,
    double compassValue,
    bool isGps,
    MapControlMode mapMode,
  ) async {
    if (mapController == null) return;

    // 기존 마커가 있으면 먼저 삭제 (중복 마커 방지)
    if (_currentLocationMarker != null) {
      try {
        await mapController!.deleteOverlay(_currentLocationMarker!.info);
      } catch (e) {
        // 마커가 이미 삭제되었거나 없는 경우 무시
      }
    }

    final mapBearing =
        await mapController!.getCameraPosition().then((pos) => pos.bearing);

    // 기기 나침반 각도와 지도 각도를 보정
    double adjustedAngle = compassValue - mapBearing;
    if (adjustedAngle < 0) adjustedAngle += 360;

    final IconData icon = mapMode == MapControlMode.idle ||
            mapMode == MapControlMode.off
        ? Icons.circle
        : Icons.navigation;

    final Color markerColor = isGps ? Colors.blue : Colors.red;
    

    final iconImage = await NOverlayImage.fromWidget(
      widget: Transform.rotate(
        angle: adjustedAngle * (math.pi / 180),
        child: Icon(icon, color: markerColor, size: 25),
      ),
      size: const Size(25, 25),
      context: navigatorKey.currentContext!,
    );

    _currentLocationMarker = NMarker(
      id: 'current_location',
      position: NLatLng(current_latitude, current_longitude),
      icon: iconImage,
    );

    mapController!.addOverlay(_currentLocationMarker!);
  }

  void clearOverlays() {
    if (mapController == null) return;
    mapController!.clearOverlays();
    _currentLocationMarker = null; // 현재 위치 마커 초기화
    debugPrint("모든 오버레이가 제거되었습니다.");
  }
}