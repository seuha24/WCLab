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

    return ValueListenableBuilder<bool>(
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
                  locationButtonEnable: false, // 현위치 표시 버튼..
                ),
                onMapReady: (controller) {
                  _navLogic.mapController = controller;
                  _navLogic._updateCurrentLocationMarker(_navLogic.finalLatitude, _navLogic.finalLongitude);
                  _navLogic._updateMapPosition(
                      _navLogic.finalLatitude, _navLogic.finalLongitude, _navLogic.compassValue);
                },
                // 지도를 클릭했을 때 실행할 이벤트를 추가하는 곳
                onMapTapped: (NPoint point, NLatLng latLng) async {
                  // 지도를 클릭했을 때 tts로 남은 거리 알려주기
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
    );
  }

  Widget _buildSearchInput(BuildContext context, String searchLocation,
      String destinationLocation, bool isDark) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 190, 164, 164),
            borderRadius: BorderRadius.circular(10),
          ),
          child: GestureDetector(
            onTap: () async {
              GeoLocation? newstartSelectedLocation = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      StartSearch(
                    searchValue: searchLocation,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = 0.0;

                    const end = 1.0;

                    const curve = Curves.easeInOutQuart;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                    var fadeAnimation = animation.drive(tween);

                    return FadeTransition(
                      opacity: fadeAnimation,
                      child: child,
                    );
                  },
                ),
              );
              if (newstartSelectedLocation != null) {
                setState(() {
                  _navLogic.startSelectedLocation = newstartSelectedLocation;
                  _navLogic.isStart = true;
                });
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
                  searchLocation.isEmpty
                      ? Text(
                          '출발지를 입력하세요.',
                          style: TextStyle(
                              fontSize: AppSizes.scaledFont(18),
                              color: Color(0xff9E9E9E)),
                        )
                      : Text(
                          searchLocation,
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
        Gap(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 190, 164, 164),
            borderRadius: BorderRadius.circular(10),
          ),
          child: GestureDetector(
            onTap: () async {
              GeoLocation? newSelectedLocation = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      DesSearch(
                    destinationValue: destinationLocation,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = 0.0;
                    const end = 1.0;
                    const curve = Curves.easeInOutQuart;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                    var fadeAnimation = animation.drive(tween);

                    return FadeTransition(
                      opacity: fadeAnimation,
                      child: child,
                    );
                  },
                ),
              );
              if (newSelectedLocation != null) {
                setState(() {
                  _navLogic.selectedLocation = newSelectedLocation;
                });
                if (_navLogic.isStart == true) {
                  await _navLogic._getGeometry(
                      _navLogic.startSelectedLocation!.lat,
                      _navLogic.startSelectedLocation!.lng); // 새로운 목적지로 지도 업데이트
                } else if (_navLogic.isStart == false) {
                  await _navLogic._getGeometry(_navLogic.finalLatitude,
                      _navLogic.finalLongitude); // 새로운 목적지로 지도 업데이트
                }

                // 주기적으로 Timer를 실행하기 전에 먼저 방향값을 초기화 해준다.
                // branchinfo 배열을 순회하면서 bearingTobranch 값을 변경합니다.
                for (int i = 0; i < _navLogic.branchInfo.length - 1; i++) {
                  // 변경할 값으로 갱신합니다.
                  double newBearingValue = _navLogic.calculateBearing(
                      _navLogic.branchInfo[i].point.latitude,
                      _navLogic.branchInfo[i].point.longitude,
                      _navLogic.branchInfo[i + 1].point.latitude,
                      _navLogic.branchInfo[i + 1].point.longitude);
                  // bearingTobranch 값을 변경합니다.
                  _navLogic.branchInfo[i].bearingToPoint = newBearingValue;
                }

                // 주기적으로 거리계산, 경로이탈 탐지를 위한 계산을 하는 곳.

                _navLogic.startNavigationTimer();
              }
            },
            child: Container(
              // 버튼 모양의 컨테이너
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.6), // 그림자 색상
                    spreadRadius: 2, // 그림자 확산 정도
                    blurRadius: 5, // 그림자 흐림 정도
                    offset: Offset(0, 2), // 그림자의 위치 (가로, 세로)
                  ),
                ],
              ),
              child: Row(
                children: [
                  destinationLocation.isEmpty
                      ? Text(
                          '목적지를 입력하세요.',
                          style: TextStyle(
                              fontSize: AppSizes.scaledFont(18),
                              color: Color(0xff9E9E9E)),
                        )
                      : Text(
                          destinationLocation,
                          style: TextStyle(fontSize: AppSizes.scaledFont(18)),
                        ),
                  Spacer(),
                  Icon(Icons.search),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
