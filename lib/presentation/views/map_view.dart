part of '../../framework/ui.dart';

enum MapControlMode {
  idle, // 초기 상태 (초기 위치를 설정하기 위한 상태)
  off, // 자유롭게 지도 이동 (기본)
  on1, // 지도 고정, 회전하지 않음. marker에 방향 표시, 사용자가 회전하면 Marker의 화살표도 회전
  on2, // 사용자의 방향 회전에 따라 지도도 회전
}

class NaverMapView extends StatefulWidget {
  const NaverMapView({super.key});

  @override
  State<NaverMapView> createState() => _NaverMapViewState();
}

class _NaverMapViewState extends State<NaverMapView> {
  late final NavigationBloc _navigationBloc;
  NaverMapController? mapController;
  MapControlMode _currentMode = MapControlMode.idle;

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

  void _toggleMode() {
    setState(() {
      // 현재 모드가 idle인 경우 다음 모드로 바로 변경
      if (_currentMode == MapControlMode.idle) {
        _currentMode = MapControlMode.off;
        debugPrint("Mode: Off - 초기화 이후 자유 지도 이동 가능");
      }

      // idle 상태를 건너뛰도록 로직 추가
      _currentMode = MapControlMode
          .values[(_currentMode.index + 1) % MapControlMode.values.length];
      if (_currentMode == MapControlMode.idle) {
        _currentMode = MapControlMode.off;
      }

      switch (_currentMode) {
        case MapControlMode.idle:
          debugPrint("Mode: idle - 초기 상태");
          // idle 상태를 건너뛰도록 처리
          break;
        case MapControlMode.off:
          debugPrint("Mode: Off - 자유 지도 이동 가능");
          break;
        case MapControlMode.on1:
          debugPrint("Mode: On-1 - 지도 현재 위치 고정");
          // 현재 위치로 지도와 마커 초기화
          _navigationBloc.add(OnMapReady());
          break;
        case MapControlMode.on2:
          debugPrint("Mode: On-2 - 지도 방향 고정");
          // 현재 위치로 지도와 마커 초기화
          _navigationBloc.add(OnMapReady());
          break;
      }
    });
  }

  /// 사용자가 지도를 드래그했을 때 호출되는 메서드
  /// 드래그 시 모드를 off로 전환
  void _handleMapDrag() {
    if (_currentMode != MapControlMode.off) {
      setState(() {
        _currentMode = MapControlMode.off;
      });
      debugPrint("지도를 드래그하여 Off 상태로 전환");
    }
  }

  /// 현재 지도 모드에 따라 지도와 마커를 업데이트하는 메서드
  void _handleMapMode(double latitude, double longitude, double compassValue,
      bool isGps) async {
    switch (_currentMode) {
      case MapControlMode.idle:
        // 초기 위치 및 지도 설정
        _updateCurrentLocationMarker(latitude, longitude, compassValue, isGps);
        _updateMapPosition(latitude, longitude, compassValue);
        break;

      case MapControlMode.off:
        // 자유롭게 지도 이동 가능 (기본 동작)
        _updateCurrentLocationMarker(latitude, longitude, compassValue, isGps);
        break;

      case MapControlMode.on1:
        // 지도 고정, 마커만 회전
        final mapBearing =
            await mapController!.getCameraPosition().then((pos) => pos.bearing);
        _updateCurrentLocationMarker(latitude, longitude, compassValue, isGps);
        _updateMapPosition(latitude, longitude, mapBearing); // bearing 유지
        break;

      case MapControlMode.on2:
        // 지도와 마커 모두 회전
        _updateCurrentLocationMarker(latitude, longitude, compassValue, isGps);
        _updateMapPosition(latitude, longitude,
            compassValue); // 지도 회전 (bearing = compassValue)
        break;
    }
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

    return Scaffold(
      body: Stack(
        children: [
          // 네이버 맵 표시 (고정된 UI로 한 번만 렌더링)
          NaverMap(
            options: NaverMapViewOptions(
              // off 모드일땐 rotation 비활성화
              // rotationGesturesEnable:
              //     _currentMode == MapControlMode.off ? false : true,
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
            onCameraChange: (reason, animated) {
              if (reason == NCameraUpdateReason.gesture) {
                _handleMapDrag();
              }
            },
          ),
          // BlocConsumer로 상태 처리
          BlocListener<NavigationBloc, NavigationState>(
            listener: (context, state) {
              debugPrint('BlocListener state: $state');
              if (state is StartLocationSet) {
                log('StartLocationSet');
                setState(() {});
              } else if (state is DestinationLocationSet) {
                log('DestinationLocationSet');
                setState(() {});
              } else if (state is NavigationPathLoaded) {
                log('NavigationPathLoaded: ${state.paths}');
                setState(() async {
                  await addOverlays(state.paths);
                  await addBranchMarkers(state.branchInfoList);
                });
              } else if (state is LocationMarkerUpdated) {
                debugPrint('LocationMarkerUpdated');
                _handleMapMode(
                  state.latitude,
                  state.longitude,
                  state.compassValue,
                  state.isGps,
                );
              } else if (state is MapPositionUpdated) {
                debugPrint('MapPositionUpdated');
                _handleMapMode(
                  state.latitude,
                  state.longitude,
                  state.compassValue,
                  state.isGps,
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
            color: isDark
                ? Theme.of(context).colorScheme.shadow.withOpacity(0.5)
                : null,
            height: MediaQuery.of(context).padding.top,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMode,
        backgroundColor: _getButtonColor(),
        child: Icon(_getButtonIcon()),
      ),
    );
  }

  // 모드 버튼 아이콘
  IconData _getButtonIcon() {
    switch (_currentMode) {
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
    switch (_currentMode) {
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
          label:
              destinationLocation.isEmpty ? '목적지를 입력하세요.' : destinationLocation,
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
                _navigationBloc
                    .add(SetDestinationLocation(newDestinationLocation));
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
                  color: label.contains('입력')
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

  Future<void> addOverlays(List<LatLng> paths) async {
    debugPrint('addOverlays()');
    if (mapController == null) return;

    // 현재 위치 마커를 임시로 저장
    final NMarker? currentLocationMarker = _currentLocationMarker;

    // 모든 기존 마커를 삭제
    await mapController!.clearOverlays(type: NOverlayType.marker);

    // 유지해야 할 마커를 다시 추가
    if (currentLocationMarker != null) {
      await mapController!.addOverlay(currentLocationMarker);
    }

    // 새로운 경로 오버레이 추가
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
    await mapController!.addOverlayAll(overlays);
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

  void _updateCurrentLocationMarker(double latitude, double longitude,
      double compassValue, bool isGps) async {
    debugPrint('_updateCurrentLocationMarker()');
    if (mapController == null) return;

    // 지도 회전 값 가져오기
    final mapBearing =
        await mapController!.getCameraPosition().then((pos) => pos.bearing);

    // 마커의 방향 계산
    double adjustedAngle = compassValue - mapBearing;

    // 0° ~ 360° 범위로 조정
    if (adjustedAngle < 0) adjustedAngle += 360;

    debugPrint('adjustedAngle = $adjustedAngle');

    // 마커 아이콘 생성
    final iconImage = await NOverlayImage.fromWidget(
      widget: Transform.rotate(
        angle: adjustedAngle * (math.pi / 180), // 라디안 변환
        child: Icon(
          // off 모드일땐 회전 방향 표시 안함
          _currentMode == MapControlMode.idle || _currentMode == MapControlMode.off ? Icons.circle : Icons.navigation,
          color: isGps ? Colors.blue : Colors.red,
          size: 30,
        ),
      ),
      size: const Size(30, 30),
      context: context,
    );

    // 마커 업데이트
    _currentLocationMarker = NMarker(
      id: 'current_location',
      position: NLatLng(latitude, longitude),
      icon: iconImage,
    );

    mapController!.addOverlay(_currentLocationMarker!);
  }

  void _updateMapPosition(
      double latitude, double longitude, double compassValue) async {
    if (mapController == null) return;

    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(latitude, longitude),
      zoom: 18.5,
      bearing: _currentMode == MapControlMode.on2 ? compassValue : 0.0,
    );

    mapController!.updateCamera(cameraUpdate);
  }
}
