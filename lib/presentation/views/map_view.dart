part of '../../framework/ui.dart';

class NaverMapView extends StatefulWidget {
  const NaverMapView({super.key});

  @override
  State<NaverMapView> createState() => _NaverMapViewState();
}

class _NaverMapViewState extends State<NaverMapView> {
  late final NavigationBloc _navigationBloc;
  NaverMapController? mapController;

  NMarker? _currentLocationMarker;
  NMarker? _testMarker;

  @override
  void initState() {
    super.initState();

    // Navigation Bloc 의존성 등록
    _navigationBloc = DI.get<NavigationBloc>();

    // Init Navigation Service
    _navigationBloc.add(InitNavigation());
  }

  @override
  void dispose() {
    // Dispose Navigation Service
    _navigationBloc.add(CloseNavigation());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchLocation = context.watch<SearchBloc>().startLocation;
    final destinationLocation = context.watch<SearchBloc>().destinationLocation;

    final box = Hive.box(SystemTheme.themeBox);
    final mode = box.get(SystemTheme.mode);
    final systemBright = MediaQuery.of(context).platformBrightness;
    bool isDark = (mode == 'dark') || (mode == 'system' && systemBright == Brightness.dark);

    return Scaffold(
      body: Stack(
        children: [
          // 네이버 맵 표시 (고정된 UI로 한 번만 렌더링)
          NaverMap(
            options: NaverMapViewOptions(
              indoorEnable: true,
              initialCameraPosition: const NCameraPosition(
                target: NLatLng(37.5665, 126.9780), // 초기 좌표 (서울 시청)
                zoom: 18.5,
                bearing: 0.0,
                tilt: 0,
              ),
              mapType: NMapType.basic,
              activeLayerGroups: [
                NLayerGroup.building,
                NLayerGroup.transit,
              ],
              locationButtonEnable: false,
            ),
            onMapReady: (controller) {
              mapController = controller;
              _navigationBloc.add(OnMapReady());
            },
          ),
          // BlocConsumer로 상태 처리
          BlocListener<NavigationBloc, NavigationState>(
            listener: (context, state) {
              if (state is StartLocationSet) {
                log('StartLocationSet');
                setState(() {});
              } else if (state is DestinationLocationSet) {
                log('DestinationLocationSet');
                setState(() {});
              } else if (state is NavigationPathLoaded) {
                log('NavigationPathLoaded: ${state.paths}');
                setState(() async {
                  await mapController!.clearOverlays(type: NOverlayType.marker);
                  await addOverlays(state.paths);
                  await addBranchMarkers(state.branchInfoList);
                });
              } else if (state is LocationMarkerUpdated) {
                debugPrint('LocationMarkerUpdated');
                _updateCurrentLocationMarker(
                  state.latitude,
                  state.longitude,
                  state.isGps,
                );
              } else if (state is MapPositionUpdated) {
                debugPrint('MapPositionUpdated');
                _updateMapPosition(
                  state.latitude,
                  state.longitude,
                  state.compassValue,
                );
              } else if (state is NavigationFailure) {
                debugPrint('경로 로드 실패: ${state.error}');
              }
            },
            child: const SizedBox.shrink(),
          ),
          // 검색 입력창 표시
          Positioned(
            top: 65.0,
            left: 20.0,
            right: 20.0,
            child: _buildSearchInput(
              context,
              searchLocation,
              destinationLocation,
              isDark,
            ),
          ),
          // 시스템 상단 바 높이에 따른 패딩 조정
          Container(
            color: isDark ? Theme.of(context).colorScheme.shadow.withOpacity(0.5) : null,
            height: MediaQuery.of(context).padding.top,
          ),
        ],
      ),
    );
  }

  /// 출발지 및 목적지 입력 버튼을 생성하는 메서드.
  Widget _buildSearchInput(BuildContext context, String searchLocation, String destinationLocation, bool isDark) {
    return Column(
      children: [
        _buildSearchButton(
          context: context,
          label: searchLocation.isEmpty ? '출발지를 입력하세요.' : searchLocation,
          isDark: isDark,
          onTap: () async {
            GeoLocation? newStartLocation = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    StartSearch(searchValue: searchLocation),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
            if (newStartLocation != null) {
              setState(() {
                _navigationBloc.add(SetStartLocation(newStartLocation));
              });
            }
          },
        ),
        const SizedBox(height: 10),
        _buildSearchButton(
          context: context,
          label: destinationLocation.isEmpty ? '목적지를 입력하세요.' : destinationLocation,
          isDark: isDark,
          onTap: () async {
            GeoLocation? newDestinationLocation = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DesSearch(destinationValue: destinationLocation),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
            if (newDestinationLocation != null) {
              setState(() {
                _navigationBloc.add(SetDestinationLocation(newDestinationLocation));
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSearchButton({
    required BuildContext context,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.6),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.scaledFont(18),
                  color: label.contains('입력') ? const Color(0xff9E9E9E) : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.search),
          ],
        ),
      ),
    );
  }

  Future<void> addOverlays(List<LatLng> paths) async {
    debugPrint('addOverlays()');
    if (mapController == null) return;

    Set<NAddableOverlay> overlays = {
      NMultipartPathOverlay(
        id: "path",
        paths: [
          NMultipartPath(
            coords: paths
                .map((coord) => NLatLng(coord.latitude, coord.longitude))
                .toList(),
            outlineColor: Theme.of(context).colorScheme.primary,
          ),
        ],
        outlineWidth: 3,
      ),
    };
    mapController!.addOverlayAll(overlays);
  }

  Future<void> addBranchMarkers(List<BranchInfo> branchInfoList) async {
    debugPrint('addBranchMarkers()');
    if (mapController == null) return;

    final iconImage = await NOverlayImage.fromWidget(
      widget: Icon(
        Icons.circle,
        color: Colors.green,
        size: 15,
      ),
      size: const Size(15, 15),
      context: context,
    );

    Set<NAddableOverlay> markers = branchInfoList.map((branch) {
      return NMarker(
        id: 'branch_${branchInfoList.indexOf(branch)}',
        position: NLatLng(branch.point.latitude, branch.point.longitude),
        icon: iconImage,
      );
    }).toSet();

    mapController!.addOverlayAll(markers);
  }

  void _updateCurrentLocationMarker(double latitude, double longitude, bool isGps) async {
    if (mapController == null) return;

    final iconImage = await NOverlayImage.fromWidget(
      widget: Icon(
        Icons.circle,
        color: isGps ? Colors.blue : Colors.red,
        size: 25,
      ),
      size: const Size(25, 25),
      context: context,
    );

    _currentLocationMarker = NMarker(
      id: 'current_location',
      position: NLatLng(latitude, longitude),
      icon: iconImage,
    );

    mapController!.addOverlay(_currentLocationMarker!);
  }

  void _updateMapPosition(double latitude, double longitude, double compassValue) {
    if (mapController == null) return;

    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(latitude, longitude),
      zoom: 18.5,
      bearing: compassValue,
    );

    mapController!.updateCamera(cameraUpdate);
  }
}