part of '../../framework/controller.dart';

/// 지도 패널을 제어하는 Controller
class MapPanelController extends GetxController {
  /// SlidingPanelController
  late SlidingPanelController slidingController;

  /// 네이버 맵 컨트롤러
  late NaverMapViewController mapController;

  MapPanelController();

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  /// 컨트롤러를 초기화합니다
  void _initializeController() {
    slidingController = Get.find<SlidingPanelController>();
    mapController = Get.find<NaverMapViewController>();
  }

  /// 즐겨찾기 지점으로 경로 안내를 시작합니다
  Future<void> startNavigationWithFavoritePoint(
    BuildContext context,
    FavoritePoint point,
  ) async {
    // TTS 안내 (fire-and-forget)
    mapController.tts.speakWithChannel(
      '${point.name}으로 안내를 선택했습니다.',
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
    );

    // 출입구 좌표가 있으면 사용, 없으면 일반 좌표 사용
    final lat = point.entranceLatitude ?? point.latitude;
    final lng = point.entranceLongitude ?? point.longitude;

    // 목적지 설정
    mapController.handleDestinationLocationSelection(
      GeoLocation(lat: lat, lng: lng),
    );

    // SearchBloc 목적지 텍스트 업데이트
    context.read<SearchBloc>().add(
          SearchDestinationRequested(
            searchDestination: point.name,
            geoLocation: GeoLocation(lat: lat, lng: lng),
          ),
        );

    // 경로 선택 모달 표시
    String? selectedRoute = await showRouteSelectionModal(context);
    if (selectedRoute != null) {
      mapController.chooseRoute.value = selectedRoute;
      await mapController.startNavigation();

      // 즐겨찾기 패널 닫기
      slidingController.collapseSlidingBar('favorite_panel');
    }
  }

  /// 즐겨찾기 경로로 경로 안내를 시작합니다
  Future<void> startNavigationWithFavoriteRoute(
    BuildContext context,
    FavoriteRoute route,
  ) async {
    // TTS 안내 (fire-and-forget)
    mapController.tts.speakWithChannel(
      '${route.name}으로 안내를 선택했습니다.',
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
    );

    if (route.startPoint == null || route.finishPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출발지 또는 목적지 정보가 없습니다.')),
      );
      return;
    }

    // 경유지 리스트 생성
    List<LatLng> waypoints = route.stopovers
        .whereType<RoutePoint>()
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    // 경로 선택 모달 표시
    String? selectedRoute = await showRouteSelectionModal(context);
    if (selectedRoute != null) {
      // 경로 안내 시작
      await mapController.startNavigationWithRoute(
        startLatitude: route.startPoint!.latitude,
        startLongitude: route.startPoint!.longitude,
        endLatitude: route.finishPoint!.latitude,
        endLongitude: route.finishPoint!.longitude,
        waypoints: waypoints,
        chooseRoute: selectedRoute,
      );

      // 즐겨찾기 패널 닫기
      slidingController.collapseSlidingBar('favorite_panel');
    }
  }

  /// 출발지 검색 화면을 엽니다
  Future<GeoLocation?> openStartLocationSearch(BuildContext context) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartSearch(
          searchValue: mapController.searchLocation.value,
        ),
      ),
    );
  }

  /// 목적지 검색 화면을 엽니다
  Future<GeoLocation?> openDestinationSearch(BuildContext context) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DesSearch(
          destinationValue: mapController.destinationLocation.value,
        ),
      ),
    );
  }

  /// 경로 선택 모달을 표시합니다
  Future<String?> showRouteSelectionModal(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, "0"),
              child: const Text("추천"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, "4"),
              child: const Text("추천+대로우선"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, "10"),
              child: const Text("최단"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, "30"),
              child: const Text("최단+계단제외"),
            ),
          ],
        ),
      ),
    );
  }

  /// 출발지 위치를 처리합니다
  Future<void> handleStartLocationSelection(
      BuildContext context, GeoLocation? newStart) async {
    if (newStart != null) {
      mapController.handleStartLocationSelection(newStart);
    }
  }

  /// 목적지 위치를 처리합니다
  Future<void> handleDestinationLocationSelection(
      BuildContext context, GeoLocation? newDest) async {
    if (newDest != null) {
      mapController.handleDestinationLocationSelection(newDest);

      // 경로 선택 모달 표시
      String? selectedRoute = await showRouteSelectionModal(context);
      if (selectedRoute != null) {
        mapController.chooseRoute.value = selectedRoute;
        await mapController.startNavigation();
      }
    }
  }
}
