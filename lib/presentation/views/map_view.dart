part of '../../framework/ui.dart';

class NaverMapView extends GetView<NaverMapViewController> {
  const NaverMapView({super.key});

  @override
  Widget build(BuildContext context) {
    // 시스템 테마 모드 확인
    final box = Hive.box(SystemTheme.themeBox);
    final mode = box.get(SystemTheme.mode);
    final systemBright = MediaQuery.of(context).platformBrightness;
    bool isDark = (mode == 'dark') ||
        (mode == 'system' && systemBright == Brightness.dark);

    // 컨트롤러 생성 및 등록
    final NaverMapViewController controller = Get.put(NaverMapViewController());

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            return controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : SizedBox.shrink();
          }),
          NaverMap(
            options: NaverMapViewOptions(
              indoorEnable: true,
              initialCameraPosition: NCameraPosition(
                target: NLatLng(
                  controller.current_latitude.value,
                  controller.current_longitude.value,
                ),
                zoom: 18.5,
                bearing: controller.compassValue.value,
                tilt: 0,
              ),
              mapType: NMapType.basic,
              activeLayerGroups: [
                NLayerGroup.building,
                NLayerGroup.transit,
              ],
              locationButtonEnable: false,
              // scrollGesturesEnable: true,
              // zoomGesturesEnable: true,
              // rotationGesturesEnable: true,
            ),
            onMapReady: (naverMapController) {
              debugPrint('네이버 맵 로딩됨');
              controller.mapController = naverMapController;
              controller.updateMapPosition(
                controller.current_latitude.value,
                controller.current_longitude.value,
                controller.compassValue.value,
              );
            },
            onCameraChange: (reason, animated) {
              if (reason == NCameraUpdateReason.gesture) {
                controller.handleMapDrag();
              }
            },
            onMapTapped: (NPoint point, NLatLng latLng) {
              int meters = (controller.remain_distance.value * 1000).round();
              controller.speakText('다음 안내까지 ${meters}미터 남았습니다.');
              // 필요 시 추가 처리...
            },
          ),
          // 출발지 검색 입력창
          Obx(() {
            controller.searchLocation.value =
                context.watch<SearchBloc>().state.searchStartLocation ?? '';

            return Positioned(
              top: 65.0,
              left: 20.0,
              right: 20.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 190, 164, 164),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GestureDetector(
                  onTap: () async {
                    // 출발지 검색 페이지로 이동
                    GeoLocation? newStart = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            StartSearch(
                                searchValue: controller.searchLocation.value),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = 0.0;
                          const end = 1.0;
                          const curve = Curves.easeInOutQuart;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var fadeAnimation = animation.drive(tween);
                          return FadeTransition(
                              opacity: fadeAnimation, child: child);
                        },
                      ),
                    );
                    if (newStart != null) {
                      debugPrint('newStart : $newStart');
                      controller.handleStartLocationSelection(newStart);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.6),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        controller.searchLocation.value.isEmpty
                            ? Text(
                                '출발지를 입력하세요.',
                                style: TextStyle(
                                    fontSize: AppSizes.scaledFont(18),
                                    color: Colors.grey),
                              )
                            : Text(
                                controller.searchLocation.value,
                                style: TextStyle(
                                    fontSize: AppSizes.scaledFont(18),
                                    color: Colors.black),
                              ),
                        Spacer(),
                        Icon(Icons.search),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          // 목적지 검색 입력창
          Obx(() {
            controller.destinationLocation.value =
                context.watch<SearchBloc>().state.searchDestinationLocation ??
                    '';

            return Positioned(
              top: 122.0,
              left: 20.0,
              right: 20.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 190, 164, 164),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GestureDetector(
                  onTap: () async {
                    GeoLocation? newDest = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            DesSearch(
                                destinationValue:
                                    controller.destinationLocation.value),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = 0.0;
                          const end = 1.0;
                          const curve = Curves.easeInOutQuart;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var fadeAnimation = animation.drive(tween);
                          return FadeTransition(
                              opacity: fadeAnimation, child: child);
                        },
                      ),
                    );

                    if (newDest != null) {
                      controller.handleDestinationLocationSelection(newDest);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.6),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        controller.destinationLocation.value.isEmpty
                            ? Text(
                                '목적지를 입력하세요.',
                                style: TextStyle(
                                  fontSize: AppSizes.scaledFont(18),
                                  color: Colors.grey,
                                ),
                              )
                            : Text(
                                controller.destinationLocation.value,
                                style: TextStyle(
                                  fontSize: AppSizes.scaledFont(18),
                                  color: Colors.black,
                                ),
                              ),
                        Spacer(),
                        Icon(Icons.search),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          Container(
            color: isDark
                ? Theme.of(context).colorScheme.shadow.withOpacity(0.5)
                : null,
            height: MediaQuery.of(context).padding.top,
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        return FloatingActionButton(
          onPressed: controller.toggleMapMode,
          backgroundColor: _getButtonColor(),
          child: Icon(_getButtonIcon()),
        );
      })
    );
  }

  // 모드 버튼 아이콘
  IconData _getButtonIcon() {
    switch (controller.mapMode.value) {
      case MapControlMode.idle:
        return Icons.location_disabled;
      case MapControlMode.off:
        return Icons.location_disabled;
      case MapControlMode.on1:
        return Icons.my_location;
      case MapControlMode.on2:
        return Icons.navigation;
    }
  }

  // 모드 버튼 색상
  Color _getButtonColor() {
    switch (controller.mapMode.value) {
      case MapControlMode.idle:
        return Colors.grey;
      case MapControlMode.off:
        return Colors.grey;
      case MapControlMode.on1:
        return Colors.blue;
      case MapControlMode.on2:
        return Colors.green;
    }
  }
}
