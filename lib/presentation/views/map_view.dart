part of '../../framework/ui.dart';

class NaverMapView extends GetView<NaverMapViewController> {
  const NaverMapView({super.key});

  
  @override
  Widget build(BuildContext context) {
    final tts = DI.get<TtsService>();
    final box = Hive.box(SystemTheme.themeBox);
    final mode = box.get(SystemTheme.mode);
    final systemBright = MediaQuery.of(context).platformBrightness;
    bool isDark = (mode == 'dark') ||
        (mode == 'system' && systemBright == Brightness.dark);

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          /// (1)지도 또는 로딩 표시
          /// 출입구 등록 패널이 활성화되어도 현위치 동적 마커는 계속 표시됨
          NaverMap(
            options: NaverMapViewOptions(
              indoorEnable: true,
              initialCameraPosition: NCameraPosition(
                target: NLatLng(
                  controller.currentLatitude.value,
                  controller.currentLongitude.value,
                ),
                zoom: 18.5,
                bearing: controller.compassValue.value,
                tilt: 0,
              ),
              mapType: NMapType.basic,
              activeLayerGroups: [NLayerGroup.building, NLayerGroup.transit],
              locationButtonEnable: false,
            ),
            onMapReady: (naverMapController) {
              controller.mapController = naverMapController;
              controller.routeController.mapController = naverMapController;
              controller.overlayController.mapController = naverMapController;
              // 맵이 준비되면 항상 초기 카메라 위치 업데이트
              controller.updateMapPosition(
                controller.currentLatitude.value,
                controller.currentLongitude.value,
                controller.compassValue.value,
              );
            },
            onCameraChange: (reason, animated) {
              if (reason == NCameraUpdateReason.gesture) {
                controller.handleMapDrag();
              }
            },
            onCameraIdle: () async {
              // 출입구 등록 패널이 활성화되었을 때만 위치 업데이트
              final slidingController = Get.find<SlidingPanelController>();
              if (slidingController.activePanelId.value == 'entrance_panel') {
                if (controller.mapController != null) {
                  final pos =
                      await controller.mapController!.getCameraPosition();
                  final latLng = pos.target;

                          // 출입구 등록 패널의 bloc에 직접 AddressUpdated 이벤트 전송
                          try {
                            final entranceBloc =
                                Get.find<EntranceRegistrationBloc>();
                            if (!entranceBloc.isClosed) {
                              entranceBloc.add(AddressUpdated(latLng));
                            }
                          } catch (e) {
                            // bloc을 찾을 수 없는 경우 무시 (아직 초기화되지 않았을 수 있음)
                            debugPrint(
                                'EntranceRegistrationBloc not found: $e');
                          }
                        }
                      }

                      // 출입구 등록 패널이 활성화되어도 현위치 마커는 계속 업데이트되어야 함
                      // 센서 데이터가 계속 업데이트되므로 현위치 마커도 자동으로 업데이트됨
                    },
                    onMapTapped: (NPoint point, NLatLng latLng) {
                      int meters =
                          (controller.remainDistance.value * 1000).round();
                      tts.speakWithChannel('다음 안내까지 ${meters}미터 남았습니다.', channel: ETtsChannel.FEEDBACK, cooldownKey: 'on_tap_remain_distance', cooldown: Duration(seconds: 0),);
                    },
                  ),
       

          /// 화면 중앙 고정 마커

          /// (2)항상 표시되는 고정 버튼들 (지도 모드 변경, 경광등)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 지도 모드 변경 FAB
                Obx(() {
                  return FloatingActionButton(
                    onPressed: () async {
                      await controller.toggleMapMode();
                      HapticFeedback.mediumImpact();
                    },
                    tooltip: '지도 모드 변경',
                    backgroundColor: _getButtonColor(controller),
                    child: AnimatedRotation(
                      duration: Duration(milliseconds: 300),
                      turns: controller.mapMode.value == MapControlMode.on2
                          ? 0.5
                          : 0,
                      child: Icon(_getButtonIcon(controller)),
                    ),
                  );
                }),

                // 경광등 토글 FAB
                SizedBox(height: 16),
                Obx(() {
                  return FloatingActionButton(
                    onPressed: () {
                      controller.toggleFlashlight();
                      HapticFeedback.mediumImpact();
                    },
                    tooltip: controller.isFlashOn.value ? '경광등 끄기' : '경광등 켜기',
                    backgroundColor: controller.isFlashOn.value
                        ? Colors.orange
                        : Colors.grey,
                    child: Icon(
                      controller.isFlashOn.value
                          ? Icons.flashlight_on
                          : Icons.flashlight_off,
                      color: Colors.white,
                    ),
                  );
                }),

                // 주변 건물 자동 알림 FAB
                SizedBox(height: 16),
                Obx(() => FloatingActionButton(
                  heroTag: 'locationAnnouncement',
                  onPressed: () {
                    controller.toggleAutoPoiAnnounce();
                    HapticFeedback.mediumImpact();
                  },
                  backgroundColor: controller.isAutoPoiAnnounceEnabled.value
                      ? Colors.green
                      : Colors.grey,
                  child: Icon(Icons.campaign, color: Colors.white),
                  tooltip: '주변 건물 자동 알림',
                )),
              ],
            ),
          ),

          /// (3)출입구 등록 패널 활성화 시 검색창
          Obx(() {
            final slidingController = Get.find<SlidingPanelController>();
            final isEntrancePanelActive =
                slidingController.activePanelId.value == 'entrance_panel';

            if (isEntrancePanelActive) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 80, // 오른쪽 버튼들을 위한 공간 확보 (20 -> 80으로 변경)
                child: _buildSearchBar(context),
              );
            }
            return SizedBox.shrink();
          }),

          /// (4)출입구 등록 마커 (현위치 마커와 함께 표시)
          /// 출입구 등록 패널이 활성화되어도 현위치 동적 마커는 계속 업데이트되어 표시됨
          /// - 빨간색 핀: 출입구 등록용 (화면 중앙 고정)
          /// - 파란색/빨간색 마커: 현위치 표시 (컨트롤러에서 지속 업데이트)
          Obx(() {
            final slidingController = Get.find<SlidingPanelController>();
            final isEntrancePanelActive =
                slidingController.activePanelId.value == 'entrance_panel';

            if (isEntrancePanelActive) {
              return Stack(
                children: [
                  // 출입구 등록용 빨간색 핀 (화면 중앙 고정)
                  Center(
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                      semanticLabel: '출입구 등록 위치',
                    ),
                  ),
                  // 현위치 동적 마커는 계속 표시되어야 함 (컨트롤러에서 관리)
                  // 센서 데이터가 계속 업데이트되므로 현위치 마커도 자동으로 업데이트됨
                ],
              );
            }
            return SizedBox.shrink();
          }),

          /// 화면 중앙 고정 마커 + 현재 위치 설정 버튼
          /// GPS 정확도가 나쁠 때만 표시하여 사용자가 직접 출발지 조정 가능
          Obx(() {
            final slidingController = Get.find<SlidingPanelController>();
            final isMapFunctionActive =
                slidingController.activePanelId.value == 'map_panel';
            final isSet = controller.isSetStartLocation.value;
            final isGpsAccurate = controller.isGpsAccurate.value;

            // 지도 기능이 활성화되지 않았거나 이미 출발지가 설정되었거나 GPS 정확도가 좋으면 숨김
            if (!isMapFunctionActive || isSet || isGpsAccurate) {
              return SizedBox.shrink();
            }

            return Stack(
              children: [
                // 화면 중앙 고정 마커
                Center(
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                    semanticLabel: '현재 위치 설정 마커',
                  ),
                ),
                // 현재 위치 설정 버튼
                Positioned(
                  bottom: 50.0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await controller
                            .setCustomStartLocationFromCamera(); // 카메라 중심을 출발지로 설정
                      },
                      icon: Icon(Icons.add_location_alt, color: Colors.white),
                      label: Text(
                        "현재 위치 설정",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          /// (5)경로 안내 종료 버튼
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Obx(() {
              if (controller.isNavigating.value) {
                return Center(
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      final searchBloc = context.read<SearchBloc>();
                      await controller.stopNavigationTimer();
                      if (!searchBloc.isClosed) {
                        searchBloc.add(SearchResetRequested());
                      }
                      controller.searchLocation.value = '';
                      controller.destinationLocation.value = '';
                    },
                    tooltip: '경로 안내 종료',
                    backgroundColor: Colors.red,
                    icon: Icon(Icons.stop, color: Colors.white),
                    label:
                        Text('경로 안내 종료', style: TextStyle(color: Colors.white)),
                  ),
                );
              }
              return SizedBox.shrink();
            }),
          ),

          /// (5)상태바 색상 처리
          Container(
            height: MediaQuery.of(context).padding.top,
            color: isDark
                ? Theme.of(context).colorScheme.shadow.withOpacity(0.5)
                : null,
          ),
        ],
      ),
    );
  }

  /// 검색 입력창 위젯 생성
  Widget _buildSearchInput({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: value.isEmpty ? label : value,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? label : value,
                  style: TextStyle(
                    fontSize: AppSizes.scaledFont(18),
                    color: value.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
              Icon(Icons.search, semanticLabel: '검색'),
            ],
          ),
        ),
      ),
    );
  }

  /// 안내 콘텐츠 카드 위젯
  Widget _buildContentCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline, color: Colors.grey[600], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

  IconData _getButtonIcon(NaverMapViewController controldler) {
    switch (controller.mapMode.value) {
      case MapControlMode.idle:
      case MapControlMode.off:
        return Icons.location_disabled;
      case MapControlMode.on1:
        return Icons.my_location;
      case MapControlMode.on2:
        return Icons.navigation;
    }
  }

  Color _getButtonColor(NaverMapViewController controller) {
    switch (controller.mapMode.value) {
      case MapControlMode.idle:
      case MapControlMode.off:
        return Colors.grey;
      case MapControlMode.on1:
        return Colors.blue;
      case MapControlMode.on2:
        return Colors.green;
    }
  }

  /// 하단 탭 위젯 생성
  Widget _buildBottomTab({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        // 탭 클릭 시 처리 로직
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 출입구 등록 패널 활성화 시 표시할 검색창 위젯
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        label: '장소를 검색하세요',
        button: true,
        child: GestureDetector(
          onTap: () => _showLocationSearch(context),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600], size: 20, semanticLabel: '검색'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '장소를 검색하세요',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 경로 선택 BottomSheet를 표시하는 메서드
  Future<String?> _showRouteSelectionBottomSheet() async {
    return await showModalBottomSheet<String>(
      context: Get.context!,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(Get.context!, "0"),
              child: const Text("추천"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(Get.context!, "4"),
              child: const Text("추천+대로우선"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(Get.context!, "10"),
              child: const Text("최단"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(Get.context!, "30"),
              child: const Text("최단+계단제외"),
            ),
          ],
        ),
      ),
    );
  }

  /// 장소 검색 화면을 표시하는 메서드
  void _showLocationSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSearchSheet(
        onLocationSelected: (latLng, address) {
          // 선택된 위치로 지도 줌인
          final mapController = Get.find<NaverMapViewController>();
          if (mapController.mapController != null) {
            final cameraUpdate = NCameraUpdate.withParams(
              target: NLatLng(latLng.latitude, latLng.longitude),
              zoom: 18.5,
            )..setAnimation(animation: NCameraAnimation.easing);
            mapController.mapController!.updateCamera(cameraUpdate);
          }

          // 출입구 등록 패널의 bloc에 위치 업데이트
          try {
            final entranceBloc = Get.find<EntranceRegistrationBloc>();
            if (!entranceBloc.isClosed) {
              entranceBloc.add(
                  AddressUpdated(NLatLng(latLng.latitude, latLng.longitude)));
            }
          } catch (e) {
            debugPrint('EntranceRegistrationBloc not found: $e');
          }
        },
      ),
    );
  }
}

/// 장소 검색을 위한 모달 시트
class _LocationSearchSheet extends StatefulWidget {
  final Function(NLatLng latLng, String address) onLocationSelected;

  const _LocationSearchSheet({required this.onLocationSelected});

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final KakaoRepository kakaoRepository = DI.get<KakaoRepository>();
  Timer? _debounce;
  List<PlaceResult> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults.clear();
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _placeSearch(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }
  
  //여기에있으면 안됨
  Future<List<PlaceResult>> _placeSearch(String query) async {
    final result = await kakaoRepository.searchPlaces(query);

    return result.fold(
      (failure) => [],
      (places) => places,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 제목
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '장소 검색',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '장소명을 입력하세요',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 검색 결과
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          '검색어를 입력하세요',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: Icon(Icons.location_on, color: Colors.red),
                            title: Text(
                              result.name,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(result.address),
                            onTap: () {
                              final latLng = NLatLng(
                                result.geometry.location.lat,
                                result.geometry.location.lng,
                              );
                              widget.onLocationSelected(latLng, result.address);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
