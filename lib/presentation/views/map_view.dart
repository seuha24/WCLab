part of '../../framework/ui.dart';

/// 네이버 맵 화면을 구현하는 위젯입니다.
/// 사용자는 이 화면에서 출발지와 목적지를 설정하고 경로를 탐색할 수 있습니다.
/// 지도 상의 현재 위치를 기반으로 내비게이션 정보를 제공하며,
/// 브랜치 지점 및 경로 안내를 포함한 다양한 기능을 제공합니다.
class NaverMapView extends StatefulWidget {
  const NaverMapView({super.key});

  @override
  State<NaverMapView> createState() => _NaverMapViewState();
}

class _NaverMapViewState extends State<NaverMapView> {
  // late final NavigationService _navigationBloc.navigationService; // 내비게이션 서비스
  late final NavigationBloc _navigationBloc;
  NaverMapController? mapController;

  NMarker? _currentLocationMarker;
  NMarker? _testMarker;

  @override
  void initState() {
    super.initState();
    // DI를 통해 NavigationService 초기화
    _navigationBloc = DI.get<NavigationBloc>();
    // _navigationBloc.navigationService = DI.get<NavigationService>(param1: context);

    // 내비게이션 서비스 초기화
    _navigationBloc.navigationService.init();
  }

  @override
  void dispose() {
    // 내비게이션 서비스 자원 정리
    _navigationBloc.navigationService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 검색 블록으로부터 출발지와 목적지 가져오기
    final searchLocation = context.watch<SearchBloc>().startLocation;
    final destinationLocation = context.watch<SearchBloc>().destinationLocation;

    // 현재 테마 상태 확인
    final box = Hive.box(SystemTheme.themeBox);
    final mode = box.get(SystemTheme.mode);
    final systemBright = MediaQuery.of(context).platformBrightness;
    bool isDark = (mode == 'dark') ||
        (mode == 'system' && systemBright == Brightness.dark);

    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) {
        log('MapView State : $state');
        // 내비게이션 상태에 따라 UI와 데이터를 갱신
        if (state is NavigationReady) {
          // 경로 및 브랜치 정보를 내비게이션 서비스에 업데이트
          // _navigationBloc.navigationService.paths = state.paths;
          // _navigationBloc.navigationService.branchInfoList =
          //     state.branchInfoList;

          // 지도에 경로 오버레이 및 브랜치 마커 추가
          addOverlays(state.paths);
          addBranchMarkers(state.branchInfoList);

          // 브랜치 정보 업데이트 (각 브랜치 간의 방향 계산)
          for (int i = 0;
              i < _navigationBloc.navigationService.branchInfoList.length - 1;
              i++) {
            double newBearingValue =
                _navigationBloc.navigationService.calculateBearing(
              _navigationBloc
                  .navigationService.branchInfoList[i].point.latitude,
              _navigationBloc
                  .navigationService.branchInfoList[i].point.longitude,
              _navigationBloc
                  .navigationService.branchInfoList[i + 1].point.latitude,
              _navigationBloc
                  .navigationService.branchInfoList[i + 1].point.longitude,
            );
            _navigationBloc.navigationService.branchInfoList[i].bearingToPoint =
                newBearingValue;
          }

          // 내비게이션 타이머 시작
          _navigationBloc.navigationService.startNavigationTimer();
        } else if (state is LocationMarkerUpdated) {
          // 위치 마커 업데이트
          debugPrint('LocationMarkerUpdated');
          _updateCurrentLocationMarker(
            state.latitude,
            state.longitude,
            state.isGps,
          ); // GPS 여부에 따라 마커 색상 변경
        } else if (state is MapPositionUpdated) {
          // 지도 위치 업데이트
          debugPrint('MapPositionUpdated');
          _updateMapPosition(
            state.latitude,
            state.longitude,
            state.compassValue,
          ); // 나침반 값에 따라 지도 방향 변경
        } else if (state is NavigationFailure) {
          // 경로 로드 실패 시 디버그 출력
          debugPrint('경로 로드 실패: ${state.error}');
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _navigationBloc.navigationService.isLoading,
        builder: (context, isLoading, child) {
          // 로딩 상태에 따라 로딩 인디케이터 또는 지도 화면 표시
          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          return Scaffold(
            body: Stack(
              children: [
                // 네이버 맵 표시
                NaverMap(
                  options: NaverMapViewOptions(
                    indoorEnable: true,
                    // 실내 지도 활성화
                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(
                          _navigationBloc.navigationService.finalLatitude,
                          _navigationBloc.navigationService.finalLongitude),
                      zoom: 18.5,
                      // 초기 줌 레벨
                      bearing: _navigationBloc.navigationService.compassValue,
                      // 초기 지도 방향
                      tilt: 0, // 초기 입체 각도
                    ),
                    mapType: NMapType.basic,
                    // 지도 타입 설정
                    activeLayerGroups: [
                      NLayerGroup.building, // 건물 레이어
                      NLayerGroup.transit, // 대중교통 레이어
                    ],
                    locationButtonEnable: false, // 기본 위치 버튼 비활성화
                  ),
                  onMapReady: (controller) {
                    // 맵 컨트롤러 초기화
                    mapController = controller;

                    // 현재 위치 마커와 맵 위치 업데이트
                    // todo: onMapReady 새로운 이벤트 필요.
                    _navigationBloc.add(OnMapReady());
                    // _updateCurrentLocationMarker();
                    // _updateMapPosition();
                  },
                  onMapTapped: (NPoint point, NLatLng latLng) async {
                    // 지도 클릭 시 남은 거리 안내 음성 출력
                    int meters =
                        (_navigationBloc.navigationService.remainDistance *
                                1000)
                            .round();
                    await _navigationBloc.navigationService
                        .announceTts('다음 안내까지 $meters미터 남았습니다.');
                  },
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

  /// 출발지 및 목적지 입력 버튼을 생성하는 메서드.
  Widget _buildSearchInput(BuildContext context, String searchLocation,
      String destinationLocation, bool isDark) {
    return Column(
      children: [
        _buildSearchButton(
          context: context,
          label: searchLocation.isEmpty ? '출발지를 입력하세요.' : searchLocation,
          isDark: isDark,
          onTap: () async {
            // 출발지 설정 화면으로 이동
            GeoLocation? newStartLocation = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    StartSearch(searchValue: searchLocation),
              ),
            );
            if (newStartLocation != null) {
              // 출발지 선택 후 내비게이션 서비스에 업데이트
              // 화면을 갱신하기 위해 setState 호출
              setState(() {
                _navigationBloc.navigationService.startSelectedLocation =
                    newStartLocation;
                _navigationBloc.navigationService.isStart = true;
              });
            }
          },
        ),
        const SizedBox(height: 10),
        _buildSearchButton(
          context: context,
          label:
              destinationLocation.isEmpty ? '목적지를 입력하세요.' : destinationLocation,
          isDark: isDark,
          onTap: () async {
            // 목적지 설정 화면으로 이동
            GeoLocation? newDestinationLocation = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DesSearch(destinationValue: destinationLocation),
              ),
            );
            if (newDestinationLocation != null) {
              // 목적지 선택 후 내비게이션 서비스에 업데이트
              // 화면을 갱신하기 위해 setState 호출
              setState(() {
                _navigationBloc.navigationService.selectedLocation =
                    newDestinationLocation;
              });

              // 경로 요청을 위해 시작 지점 좌표 설정
              final startLat = _navigationBloc.navigationService.isStart
                  ? _navigationBloc.navigationService.startSelectedLocation!.lat
                  : _navigationBloc.navigationService.finalLatitude;
              final startLng = _navigationBloc.navigationService.isStart
                  ? _navigationBloc.navigationService.startSelectedLocation!.lng
                  : _navigationBloc.navigationService.finalLongitude;

              // NavigationService를 통해 Bloc에 경로 요청
              _navigationBloc.navigationService.requestNewPath(
                startLat: startLat,
                startLng: startLng,
                endLat: newDestinationLocation.lat,
                endLng: newDestinationLocation.lng,
              );
            }
          },
        ),
      ],
    );
  }

  /// 검색 버튼 위젯을 생성하는 메서드.
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

  /// 지도에 경로 오버레이를 추가하는 메서드.
  /// [paths]: 표시할 경로의 위경도 리스트.
  void addOverlays(List<LatLng> paths) {
    debugPrint('addOverlays()');
    if (mapController == null) {
      debugPrint('addOverlays() mapController is not initialized yet.');
      return;
    }

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
        outlineWidth: 3, // 경로표시 선의 두께 지정 (3->9)
      ),
    };
    mapController!.addOverlayAll(overlays);
  }

  /// 분기 지점의 마커를 지도에 추가하는 메서드.
  /// [branchInfoList]에 저장된 모든 분기 지점 정보를 기반으로 마커를 생성하고 지도에 추가합니다.
  void addBranchMarkers(List<BranchInfo> branchInfoList) async {
    debugPrint(':::::::::::::::addBranchMarkers');
    if (mapController == null) {
      debugPrint('addBranchMarkers() mapController is not initialized yet.');
      return;
    }

    Set<NAddableOverlay> markers = {}; // 마커들을 담을 Set
    final branchList = branchInfoList;

    final iconImage = await NOverlayImage.fromWidget(
      widget: Icon(
        Icons.circle,
        color: Colors.green,
        size: 15,
      ),
      size: const Size(15, 15),
      context: context,
    );

    for (var branch in branchList) {
      _testMarker = NMarker(
          id: 'checkPoint_${branchList.indexOf(branch)}', // 각 마커의 고유 ID
          position: NLatLng(
              branch.point.latitude, branch.point.longitude), // 마커의 좌표 설정
          icon: iconImage);

      markers.add(_testMarker!);
    }

    // 맵에 마커 추가
    mapController!.addOverlayAll(markers);
  }

  /// 현재 위치 마커를 업데이트하는 메서드.
  /// [latitude], [longitude]: 목표 위치의 위경도.
  void _updateCurrentLocationMarker(
    double latitude,
    double longitude,
    bool isGps,
  ) async {
    debugPrint(':::::::::::::::_updateCurrentLocationMarker');
    // log('**latitude: $latitude, longitude: $longitude, isGps: $isGps');
    // log('**finalLatitude: ${_navigationBloc.navigationService.finalLatitude}, '
    //     'finalLongitude: ${_navigationBloc.navigationService.finalLongitude}, '
    //     'isGps: ${_navigationBloc.navigationService.isGps},');

    if (mapController == null) {
      debugPrint(
          '_updateCurrentLocationMarker() mapController is not initialized yet.');
      return;
    }

    // GPS에 따라 마커 색상 설정
    final Color markerColor = isGps ? Colors.blue : Colors.red;
    final iconImage = await NOverlayImage.fromWidget(
        widget: Icon(
          Icons.circle,
          color: markerColor,
          size: 25,
        ),
        size: const Size(25, 25),
        context: context);

    // 현재 위치 마커를 새로 추가
    _currentLocationMarker = NMarker(
      id: 'current_location',
      position: NLatLng(latitude, longitude),
      icon: iconImage,
    );

    mapController!.addOverlay(_currentLocationMarker!);
  }

  /// 지도 위치를 업데이트하는 메서드.
  /// [latitude], [longitude]: 목표 위치의 위경도.
  /// [compassValue]: 현재 나침반 값.
  void _updateMapPosition(
    double latitude,
    double longitude,
    double compassValue,
  ) {
    debugPrint(':::::::::::::::_updateMapPosition');
    // debugPrint(
    //     '**latitude: $latitude, longitude: $longitude, compassValue: $compassValue');
    // debugPrint(
    //     '**finalLatitude: ${_navigationBloc.navigationService.finalLatitude}, '
    //     'finalLongitude: ${_navigationBloc.navigationService.finalLongitude}, '
    //     'compassValue: ${_navigationBloc.navigationService.compassValue},');

    if (mapController == null) {
      debugPrint('_updateMapPosition() mapController is not initialized yet.');
      return;
    }
    // 현재 위치를 기준으로 카메라 위치를 설정
    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(latitude, longitude),
      zoom: 18.5,
      bearing: compassValue,
    );

    // 카메라 업데이트 적용
    mapController!.updateCamera(cameraUpdate);
  }
}
