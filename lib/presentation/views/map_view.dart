part of '../../framework/ui.dart';

/// [NaverMapView]는 네이버 지도를 화면에 표시하는 GetX View입니다.
/// 지도, 검색 입력창, 모드 토글 버튼 등을 포함합니다.
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

    // 컨트롤러 생성 및 등록 (Get.put()을 통해 NaverMapViewController의 인스턴스를 주입)
    final NaverMapViewController controller = Get.put(NaverMapViewController());

    return Scaffold(
        body: Stack(
          children: [
            Obx(() {
              /// 로딩 중이면 CircularProgressIndicator를 표시합니다.
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

              /// 지도 로딩이 완료되면 호출됩니다.
              onMapReady: (naverMapController) {
                debugPrint('네이버 맵 로딩됨');
                controller.mapController = naverMapController;
                controller.updateMapPosition(
                  controller.current_latitude.value,
                  controller.current_longitude.value,
                  controller.compassValue.value,
                );
              },

              /// 사용자가 제스처(드래그 등)로 카메라를 이동할 때 호출됩니다.
              onCameraChange: (reason, animated) {
                if (reason == NCameraUpdateReason.gesture) {
                  controller.handleMapDrag();
                }
              },

              /// 사용자가 지도를 탭하면 호출되며, 탭한 위치와 관련된 안내 메시지를 음성으로 전달합니다.
              onMapTapped: (NPoint point, NLatLng latLng) {
                int meters = (controller.remain_distance.value * 1000).round();
                controller.speakText('다음 안내까지 ${meters}미터 남았습니다.');
                // 필요 시 추가 처리...
              },
            ),
            
            /// 앱 실행 후 GPS 수신도 낮을때 출발지 위치 조정 멘트(한번만)
            Obx(() {
              if (controller.showLowAccuracyDialog.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("알림"),
                      content: Text("초기 위치 확인 시 GPS 정확도가 낮습니다.\n출발지 입력 또는 마커로 위치 조정하세요."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            controller.showLowAccuracyDialog.value = false;
                            Navigator.of(context).pop(); // 팝업 닫기
                            },
                            child: Text("확인"),
                          ),
                        ],
                      )
                    );
                  });
                }
              return SizedBox.shrink(); // UI를 무언가 반환해야 하니까 빈 위젯
            }),

            /// 출발지 검색 입력창 (상단 위치에 고정)
            Obx(() {
              // SearchBloc에서 제공하는 검색 시작 위치를 controller의 Rx 변수에 업데이트
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
                      /// 사용자가 입력창을 탭하면 출발지 검색 페이지로 이동합니다.
                      GeoLocation? newStart = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation,
                                  secondaryAnimation) =>
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
                        debugPrint('출발지 좌표: ${newStart.lat}, ${newStart.lng}');
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

            /// 목적지 검색 입력창 (출발지 아래에 위치)
            Obx(() {
              controller.destinationLocation.value =
                  context.watch<SearchBloc>().state.searchDestinationLocation ??
                      '';

              return Positioned(
                top: 122.0,
                left: 20.0,
                right: 75.0,  // star 버튼 공간 확보
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 190, 164, 164),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GestureDetector(
                    /// 사용자가 입력창을 탭하면 목적지 검색 페이지로 이동합니다.
                    onTap: () async {
                      GeoLocation? newDest = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
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

                        // 경로 선택 BottomSheet 표시
                        String? selectedRoute = await showModalBottomSheet<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, "0"),
                                    child: Text("추천"),
                                    ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, "4"),
                                    child: Text("추천+대로우선"),
                                    ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, "10"),
                                    child: Text("최단"),
                                    ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, "30"),
                                    child: Text("최단거리+계단제외"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                          if (selectedRoute != null) {
                          controller.choose_route.value = selectedRoute;
                          debugPrint('선택된 경로: ${controller.choose_route.value}');
                          // 경로 선택 완료 후 경로 탐색 시작
                          await controller.startNavigation();
                          }
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

            /// 즐겨찾기 버튼
            Positioned(
              top: 122.0,
              right: 20.0,
              child: Container(
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
                child: IconButton(
                  icon: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 30,
                  ),
                  onPressed: () async {
                    // 즐겨찾기 화면으로 이동
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FavoritesMainView(),
                      ),
                    );
                    
                    if (result != null && result is Map) {
                      if (result['type'] == 'point') {
                        // 즐겨찾기 지점 선택 시
                        final favoritePoint = result['data'] as FavoritePoint;
                        
                        // 출입구 좌표가 있으면 사용, 없으면 일반 좌표 사용
                        final lat = favoritePoint.entranceLatitude ?? favoritePoint.latitude;
                        final lng = favoritePoint.entranceLongitude ?? favoritePoint.longitude;
                        
                        // 목적지 설정
                        controller.handleDestinationLocationSelection(GeoLocation(
                          lat: lat,
                          lng: lng,
                        ));
                        
                        // 목적지 텍스트 업데이트
                        context.read<SearchBloc>().add(
                          SearchDestinationRequested(
                            searchDestination: favoritePoint.name,
                            geoLocation: GeoLocation(lat: lat, lng: lng),
                          ),
                        );
                        
                        // 경로 선택 BottomSheet 표시
                        String? selectedRoute = await showModalBottomSheet<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, "0"),
                                    child: Text("추천"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, "4"),
                                    child: Text("추천+대로우선"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, "10"),
                                    child: Text("최단"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, "30"),
                                    child: Text("최단거리+계단제외"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        
                        if (selectedRoute != null) {
                          controller.choose_route.value = selectedRoute;
                          debugPrint('선택된 경로: ${controller.choose_route.value}');
                          // 경로 선택 완료 후 경로 탐색 시작
                          await controller.startNavigation();
                        }
                      } else if (result['type'] == 'route') {
                        // 경로 즐겨찾기는 일단 지점만 처리
                        // TODO: 추후 경유지 포함 경로 안내 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('경로 즐겨찾기는 준비 중입니다.')),
                        );
                      }
                    }
                  },
                ),
              ),
            ),

            /// 화면 중앙 고정 마커(출발지 설정시 사라짐)
            Stack(
              children: [
                Obx(() {
                  final isSet = controller.isSetStartLocation.value;
                   if (isSet) return SizedBox.shrink(); // 숨김 처리
                return Center(
                  child: Icon(Icons.place, color: Colors.red, size: 40),
                );
              }),

            /// 커스텀 출발지 설정 버튼
            Obx(() {
              final isSet = controller.isSetStartLocation.value;

              // 이미 설정되면 버튼 제거
              if (isSet) return SizedBox.shrink();
              
            return Positioned(
              bottom: 100.0,
              left: 20.0,
              right: 20.0,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await controller.setCustomStartLocationFromCamera(); // 카메라 중심을 출발지로 설정
                  },
                  icon: Icon(Icons.add_location_alt, color: Colors.white),
                  label: Text(
                    "현재 위치 설정",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
            );
          }),
        ],
      ),

            /// 시스템 상단 바 높이에 따른 패딩 (상단 영역의 색상 처리)
            Container(
              color: isDark
                  ? Theme.of(context).colorScheme.shadow.withOpacity(0.5)
                  : null,
              height: MediaQuery.of(context).padding.top,
            ),

            /// 지도 모드 버튼 (우측 하단)
            Positioned(
              right: 20.0,
              bottom: 20.0,
              child: Obx(() {
                return FloatingActionButton(
                  onPressed: () {
                    controller.toggleMapMode();

                    /// 모드 변경 시 시각적 피드백 추가
                    HapticFeedback.mediumImpact();
                  },
                  backgroundColor: _getButtonColor(),
                  child: AnimatedRotation(
                    duration: Duration(milliseconds: 300),
                    turns: controller.mapMode.value == MapControlMode.on2 ? 0.5 : 0,
                    child: Icon(_getButtonIcon()),
                  ),
                );
              }),
            ),

            /// 경로 안내 종료 버튼 (하단 중앙)
            Positioned(
              bottom: 20.0,
              left: 0,
              right: 0,
              child: Obx(() {
                if (controller.isNavigating.value) {
                  return Center(
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        controller.stopNavigationTimer();
                        // 검색 상태 초기화 추가
                        context.read<SearchBloc>().add(SearchResetRequested());
                        // 검색창 텍스트도 초기화
                        controller.searchLocation.value = '';
                        controller.destinationLocation.value = '';
                      },
                      backgroundColor: Colors.red,
                      icon: Icon(Icons.stop, color: Colors.white),
                      label: Text(
                        '경로 안내 종료',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
            ),
          ],
        ));
      }

        //// 주석처리 확인하기 - 연주
        //   ],
        // ),
        // /// 모드 토글 FloatingActionButton (맵 모드를 전환합니다.)
        // floatingActionButton: Obx(() {
        //   return FloatingActionButton(
        //     onPressed: controller.toggleMapMode,
        //     backgroundColor: _getButtonColor(),
        //     child: Icon(_getButtonIcon()),
        //   );
        // }));
        //}

  /// 모드 토글 버튼의 아이콘을 결정합니다.
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

  /// 모드 토글 버튼의 배경 색상을 결정합니다.
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
