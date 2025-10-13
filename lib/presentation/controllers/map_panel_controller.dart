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
