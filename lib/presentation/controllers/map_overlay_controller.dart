part of '../../framework/controller.dart';

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

  /// addBranchMarkers: 분기점(체크포인트) 마커를 지도에 추가
  Future<void> addBranchMarkers(
    bool isWaypoint,
  ) async {
    if (routeController.branchinfo.isEmpty || routeController.paths.isEmpty || mapController == null) {
      debugPrint("분기점 마커 추가 불가: 데이터 부족 또는 mapController 없음");
      return;
    }
    final Color markerColor = isWaypoint? Colors.grey: Colors.green;

    Set<NAddableOverlay> markers = {};
    final iconImage = await NOverlayImage.fromWidget(
      widget: Icon(Icons.circle, color: markerColor, size: 15),
      size: const Size(15, 15),
      context: navigatorKey.currentContext!,
    );

    for (int i = 0; i < routeController.branchinfo.length; i++) {
      final branch = routeController.branchinfo[i];
      final marker = NMarker(
        id: 'checkPoint_$i',
        position: NLatLng(branch.point.latitude, branch.point.longitude),
        icon: iconImage,
      );
      markers.add(marker);
    }

    mapController!.addOverlayAll(markers);
    debugPrint("📍 addBranchMarkers() 완료됨");
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