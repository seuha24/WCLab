part of '../../framework/ui.dart';

class NaverMapView extends StatefulWidget {
  const NaverMapView({super.key});

  @override
  State<NaverMapView> createState() => _NaverMapViewState();
}

class _NaverMapViewState extends State<NaverMapView> {
  late final NavigationLogic _navLogic;

  @override
  void initState() {
    super.initState();
    _navLogic = DI.get<NavigationLogic>(param1: context);

    _navLogic.init();
  }

  @override
  void dispose() {
    _navLogic.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchLocation = context.watch<SearchBloc>().startLocation;
    final destinationLocation = context.watch<SearchBloc>().destinationLocation;

    final box = Hive.box(SystemTheme.themeBox);
    final mode = box.get(SystemTheme.mode);
    final systemBright = MediaQuery.of(context).platformBrightness;
    bool isDark = (mode == 'dark') ||
        (mode == 'system' && systemBright == Brightness.dark);

    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) {
        if (state is NavigationReady) {
          // 경로 및 브랜치 정보 업데이트
          _navLogic.paths = state.paths;
          _navLogic.branchInfo = state.branchInfo;

          // 지도에 경로 오버레이 추가
          _navLogic.addOverlays(_navLogic.paths);
          _navLogic.addBranchMarkers();

          // 브랜치 정보 업데이트
          for (int i = 0; i < _navLogic.branchInfo.length - 1; i++) {
            double newBearingValue = _navLogic.calculateBearing(
              _navLogic.branchInfo[i].point.latitude,
              _navLogic.branchInfo[i].point.longitude,
              _navLogic.branchInfo[i + 1].point.latitude,
              _navLogic.branchInfo[i + 1].point.longitude,
            );
            _navLogic.branchInfo[i].bearingToPoint = newBearingValue;
          }

          // 내비게이션 타이머 시작
          _navLogic.startNavigationTimer();
        } else if (state is NavigationFailure) {
          // 경로 로드 실패 처리
          debugPrint('경로 로드 실패: ${state.error}');
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _navLogic.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          return Scaffold(
            body: Stack(
              children: [
                NaverMap(
                  options: NaverMapViewOptions(
                    indoorEnable: true,
                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(_navLogic.finalLatitude, _navLogic.finalLongitude),
                      zoom: 18.5, // 지도의 확대 정도
                      bearing: _navLogic.compassValue, // 지도의 방향
                      tilt: 0, // 지도의 입체감 정도
                    ),
                    mapType: NMapType.basic,
                    activeLayerGroups: [
                      NLayerGroup.building,
                      NLayerGroup.transit,
                    ],
                    locationButtonEnable: false,
                  ),
                  onMapReady: (controller) {
                    _navLogic.mapController = controller;
                    _navLogic._updateCurrentLocationMarker(
                        _navLogic.finalLatitude, _navLogic.finalLongitude);
                    _navLogic._updateMapPosition(
                        _navLogic.finalLatitude, _navLogic.finalLongitude, _navLogic.compassValue);
                  },
                  onMapTapped: (NPoint point, NLatLng latLng) async {
                    int meters = (_navLogic.remainDistance * 1000).round();
                    await _navLogic.tts.speak('다음 안내까지 $meters미터 남았습니다.');
                  },
                ),
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
                Container(
                  color: isDark
                      ? Theme.of(context).colorScheme.shadow.withOpacity(0.5)
                      : null,
                  height: MediaQuery.of(context).padding.top,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchInput(BuildContext context, String searchLocation,
      String destinationLocation, bool isDark) {
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
              ),
            );
            if (newStartLocation != null) {
              setState(() {
                _navLogic.startSelectedLocation = newStartLocation;
                _navLogic.isStart = true;
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
              ),
            );
            if (newDestinationLocation != null) {
              setState(() {
                _navLogic.selectedLocation = newDestinationLocation;
              });

              final startLat = _navLogic.isStart
                  ? _navLogic.startSelectedLocation!.lat
                  : _navLogic.finalLatitude;
              final startLng = _navLogic.isStart
                  ? _navLogic.startSelectedLocation!.lng
                  : _navLogic.finalLongitude;

              // NavigationBloc으로 경로 요청
              context.read<NavigationBloc>().add(LoadPath(
                startLatitude: startLat,
                startLongitude: startLng,
                endLatitude: newDestinationLocation.lat,
                endLongitude: newDestinationLocation.lng,
              ));
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
                  color: label == '출발지를 입력하세요.' || label == '목적지를 입력하세요.'
                      ? const Color(0xff9E9E9E)
                      : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.search),
          ],
        ),
      ),
    );
  }
}