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
  late final NavigationService _navService; // 내비게이션 서비스
  late final NavigationBloc _navigationBloc; // 내비게이션 상태 관리 블록

  @override
  void initState() {
    super.initState();
    // DI를 통해 NavigationService와 NavigationBloc 초기화
    _navService = DI.get<NavigationService>(param1: context);
    _navigationBloc = DI.get<NavigationBloc>();

    // 내비게이션 서비스 초기화
    _navService.init();
  }

  @override
  void dispose() {
    // 내비게이션 서비스 자원 정리
    _navService.dispose();

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
        // 내비게이션 상태에 따라 UI와 데이터를 갱신
        if (state is NavigationReady) {
          // 경로 및 브랜치 정보를 내비게이션 서비스에 업데이트
          _navService.paths = state.paths;
          _navService.branchInfo = state.branchInfo;

          // 지도에 경로 오버레이 및 브랜치 마커 추가
          _navService.addOverlays(_navService.paths);
          _navService.addBranchMarkers();

          // 브랜치 정보 업데이트 (각 브랜치 간의 방향 계산)
          for (int i = 0; i < _navService.branchInfo.length - 1; i++) {
            double newBearingValue = _navService.calculateBearing(
              _navService.branchInfo[i].point.latitude,
              _navService.branchInfo[i].point.longitude,
              _navService.branchInfo[i + 1].point.latitude,
              _navService.branchInfo[i + 1].point.longitude,
            );
            _navService.branchInfo[i].bearingToPoint = newBearingValue;
          }

          // 내비게이션 타이머 시작
          _navService.startNavigationTimer();
        } else if (state is NavigationFailure) {
          // 경로 로드 실패 시 디버그 출력
          debugPrint('경로 로드 실패: ${state.error}');
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _navService.isLoading,
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
                    indoorEnable: true, // 실내 지도 활성화
                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(
                          _navService.finalLatitude, _navService.finalLongitude),
                      zoom: 18.5, // 초기 줌 레벨
                      bearing: _navService.compassValue, // 초기 지도 방향
                      tilt: 0, // 초기 입체 각도
                    ),
                    mapType: NMapType.basic, // 지도 타입 설정
                    activeLayerGroups: [
                      NLayerGroup.building, // 건물 레이어
                      NLayerGroup.transit, // 대중교통 레이어
                    ],
                    locationButtonEnable: false, // 기본 위치 버튼 비활성화
                  ),
                  onMapReady: (controller) {
                    // 맵 컨트롤러 초기화
                    _navService.mapController = controller;
                    // 현재 위치 마커와 맵 위치 업데이트
                    _navService._updateCurrentLocationMarker(
                        _navService.finalLatitude, _navService.finalLongitude);
                    _navService._updateMapPosition(
                        _navService.finalLatitude,
                        _navService.finalLongitude,
                        _navService.compassValue);
                  },
                  onMapTapped: (NPoint point, NLatLng latLng) async {
                    // 지도 클릭 시 남은 거리 안내 음성 출력
                    int meters = (_navService.remainDistance * 1000).round();
                    await _navService.announceTts('다음 안내까지 $meters미터 남았습니다.');
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
              setState(() {
                _navService.startSelectedLocation = newStartLocation;
                _navService.isStart = true;
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
            // 목적지 설정 화면으로 이동
            GeoLocation? newDestinationLocation = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DesSearch(destinationValue: destinationLocation),
              ),
            );
            if (newDestinationLocation != null) {
              setState(() {
                _navService.selectedLocation = newDestinationLocation;
              });

              // 경로 요청을 위해 시작 지점 좌표 설정
              final startLat = _navService.isStart
                  ? _navService.startSelectedLocation!.lat
                  : _navService.finalLatitude;
              final startLng = _navService.isStart
                  ? _navService.startSelectedLocation!.lng
                  : _navService.finalLongitude;

              // NavigationBloc으로 경로 요청 이벤트 전달
              _navigationBloc.add(LoadPath(
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
}