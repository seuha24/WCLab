part of '../../framework/controller.dart';

/// 지도 제어 모드를 나타내는 열거형입니다.
/// - idle: 초기 상태 (초기 위치를 설정하기 위한 상태)
/// - off: 자유롭게 지도 이동 (기본)
/// - on1: 지도 고정, 회전하지 않음. Marker에 방향 표시, 사용자가 회전하면 Marker의 화살표도 회전
/// - on2: 사용자의 방향 회전에 따라 지도도 회전
enum MapControlMode {
  idle,
  off,
  on1,
  on2,
}

/// GetX Controller: NaverMapViewController
/// 네이버 지도와 관련된 위치, 센서, 경로 안내, 오버레이 업데이트 등을 관리합니다.
class NaverMapViewController extends GetxController {
  // ============================================================
  // 1. 의존성 주입 (DI) 필드
  // ============================================================
  
  /// API 서비스 (경로 데이터 요청 등)
  final NavigationApiService apiService = DI.get<NavigationApiService>();
  /// TTS 서비스 (텍스트를 음성으로 변환)
  final TtsService tts = DI.get<TtsService>();
  /// 센서 컨트롤러 (센서 데이터 수집 및 처리)
  final SensorController sensorController = DI<SensorController>();
  /// 센서 허브
  final SensorStreams sensorStreams = DI<SensorStreams>();
  /// PDR 모듈 (위치 계산 및 이동 거리 계산)
  final PdrCalculator pdrCalculator = DI<PdrCalculator>();
  /// 가중 이동평균 필터 인스턴스 (X축)
  final WeightedAverageFilter _filteringX = DI<WeightedAverageFilter>(
    instanceName: PDR_WEIGTHED_AVERAGE_FILTER_X,
  );
  /// 가중 이동평균 필터 인스턴스 (Y축)
  final WeightedAverageFilter _filteringY = DI<WeightedAverageFilter>(
    instanceName: PDR_WEIGTHED_AVERAGE_FILTER_Y,
  );
  /// 경로 컨트롤러 (경로 데이터 요청 및 오버레이 추가)
  final RouteController routeController = DI<RouteController>();
  /// 오버레이 컨트롤러 (지도 위 오버레이 관리)
  final MapOverlayController overlayController = DI<MapOverlayController>();
  /// 인덱스 컨트롤러 (분기점 인덱스 관리)
  final IndexController indexController = DI<IndexController>();
  /// Flash 제어 서비스 (외부 플래시 장치 제어)
  final ControlFlash flashOnWithWeather = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_ON_WITH_WEATHER,
  );
  /// Flash 제어 서비스 (수동 경광등 켜기)
  final ControlFlash flashOn = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_ON,
  );
  /// Flash 제어 서비스 (수동 경광등 끄기)
  final ControlFlash flashOff = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_OFF,
  );

  /// 경로 안내 계산
  /// 상태가 없는 클래스라 DI가 불필요 할 수 도 있음.
  final GuidanceCalculator guidanceCalculator = DI.get<GuidanceCalculator>();

  ///
  final LocationAnnouncementController locationAnnouncementController =
      DI.get<LocationAnnouncementController>();
  // ============================================================
  // 2. 상태 변수들
  // ============================================================

  /// 네이버 맵 컨트롤러 (지도 업데이트 및 오버레이 추가에 사용)
  NaverMapController? mapController;

  /// 현재 지도 모드를 Reactive 변수로 관리합니다.
  Rx<MapControlMode> mapMode = MapControlMode.idle.obs;
  /// 로딩 상태를 나타내는 Reactive 변수입니다.
  RxBool isLoading = true.obs;

  /// 현재 위도 (초기값: 37.4865) - 가톨릭대학교 위도
  RxDouble currentLatitude = 37.4865.obs;
  /// 현재 경도 (초기값: 126.8018) - 가톨릭대학교 경도
  RxDouble currentLongitude = 126.8018.obs;
  /// 커스텀 시작 위도 (초기값: 37.4865) - 가톨릭대학교 위도
  RxDouble cameraStartLat = 37.4865.obs;
  /// 커스텀 시작 경도 (초기값: 126.8018) - 가톨릭대학교 경도
  RxDouble cameraStartLng = 126.8018.obs;

  /// 출발지 또는 목적지 설정 모드 (start: 출발지 설정, dest: 목적지 설정, none: 없음)
  RxString settingMode = 'none'.obs;
  /// 경로 안내 시 남은 거리를 나타내는 Reactive 변수입니다.
  RxDouble remainDistance = double.infinity.obs;

  /// 검색창에 표시할 시작 위치 문자열
  RxString searchLocation = ''.obs;
  /// 검색창에 표시할 목적지 문자열
  RxString destinationLocation = ''.obs;
  /// 경로선택
  RxString chooseRoute = ''.obs;

  /// 현재 나침반 값을 나타내는 Reactive 변수
  RxDouble compassValue = 0.0.obs;
  /// 커스텀 시작 지점 사용 여부
  RxBool isCustomStartPoint = false.obs;

  /// 선택된 시작 위치
  Rxn<GeoLocation> selectedStartLocation = Rxn<GeoLocation>();
  /// 선택된 목적지 위치
  Rxn<GeoLocation> selectedDestLocation = Rxn<GeoLocation>();
  /// 시작 위치가 설정되었는지 여부
  RxBool isStart = false.obs;
  /// 시작 위치가 설정되었음을 나타내는 Reactive 변수
  RxBool isSetStartLocation = false.obs;
  /// 목적지 위치가 설정되었음을 나타내는 Reactive 변수
  RxBool isSetDestinationLocation = false.obs;

  /// 경광등 상태를 나타내는 Reactive 변수
  RxBool isFlashOn = false.obs;

  /// 경로 안내 중인지 여부를 나타내는 Reactive 변수
  RxBool isNavigating = false.obs;

  /// GPS 신호 사용 여부
  bool isGps = true;

  /// 앱 실행 후 GPS 수신도 낮을때 출발지 위치 조정 멘트(한번만)
  bool showLowGpsAlrertOnce = false;
  RxBool showLowAccuracyDialog = false.obs;

  // 지도 고정 시 현재 지도 방향을 저장하는 변수
  double? _currentBearing;

  /// 현재 경로의 경유지 리스트 (재검색시 사용)
  List<LatLng> currentWaypoints = [];
  /// 출발지와 목적지 사이의 남은 거리를 나타내는 변수
  late double remainStartpoint;

  /// 분기(체크포인트) 인덱스 관리 변수
  int branchTargetIndex = 0;

  /// 네이티브 위치 데이터 (디버깅용)
  late double sLatitude;
  late double sLongitude;
  late double sAccuracy;

  /// 위치 업데이트 타이머
  Timer? _locationUpdateTimer;
  Timer? navigationTimer;

  /// 나침반 데이터 수신 완료 여부를 판단하기 위한 Completer
  Completer<void> compassReady = Completer<void>();

  /// POI 안내 마지막 호출 시간 (API 호출 빈도 제한용)
  DateTime? _lastPoiAnnouncementTime;

  // 방향 관련 변수
  late double? heading;
  double firstBearingToPoint = 0.0;
  String clock = "";

  // 이동 거리 계산 변수
  double distanceToPath = 0.0;

  // 경계 및 재경로 검색 관련 변수들
  bool outOfBound = false;
  double boundary = 3; // 경계 이탈 감지 거리 (1.5미터)
  bool searchNewPath = false;
  /// 경계 조건 문자열 (디버깅용)
  String checkBoundaryCondition = "";
  double searchNewPathBoundary = 15;
  int searchNewPathTime = 0;

  /// 출발지 이탈 시작 시간
  DateTime? _startPointDeviationTime;
  /// 출발지 이탈 임계값 (20초)
  static const Duration _startDeviationThreshold = Duration(seconds: 20);

  /// 현재 BuildContext
  BuildContext? _context;

  // 센서 스트림 구독 객체들
  StreamSubscription? _compassSub;
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  // ============================================================
  // 3. 생명주기 메서드
  // ============================================================

  /// onInit: 컨트롤러 초기화 시 호출되며, 위치 업데이트, 센서 데이터 수집 등 초기 설정을 수행합니다.
  @override
  void onInit() {
    super.onInit();
    
    sensorController.start();
    _initSensorStreams();
    _initializeLocationServices();
  }

  /// onClose: 컨트롤러 종료 시 타이머 및 센서 스트림 구독을 취소합니다.
  @override
  void onClose() {
    tts.stopAll();
    _locationUpdateTimer?.cancel();
    // 센서 스트림 구독 취소
    _compassSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();

    // 센서 컨트롤러 및 스트림 종료
    sensorController.stop();
    sensorStreams.dispose();

    //컨트롤러 종료시 위치 계산값 초기화
    pdrCalculator.resetPdrCalculator();
    // 경로 데이터 초기화
    routeController.clearPathData();
    // 오버레이 초기화
    overlayController.clearOverlays();
    super.onClose();
  }

  // ============================================================
  // 4. 초기화 메서드
  // ============================================================

  /// 위치 서비스 초기화를 안전하게 수행합니다.
  Future<void> _initializeLocationServices() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          // 기본 위치로 설정 (가톨릭대학교)
          currentLatitude.value = 37.4865;
          currentLongitude.value = 126.8018;
          isLoading.value = false;
          return;
        }
      }

      // 위치 서비스가 활성화되어 있는지 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('위치 서비스가 비활성화되어 있습니다.');
        currentLatitude.value = 37.4865;
        currentLongitude.value = 126.8018;
        isLoading.value = false;
        return;
      }

      await _initLocation();

    } catch (e) {
      debugPrint('위치 서비스 초기화 실패: $e');
      currentLatitude.value = 37.4865;
      currentLongitude.value = 126.8018;
      isLoading.value = false;
    }
  }

  /// _initLocation: GPS 및 IMU 데이터를 기반으로 초기 위치를 설정하고,
  /// 주기적으로 위치 업데이트를 수행하는 타이머를 시작합니다.
  Future<void> _initLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
    currentLatitude.value = position.latitude;
    currentLongitude.value = position.longitude;
    //초기 위치 설정
    pdrCalculator.setInitialPosition(currentLatitude.value, currentLongitude.value);

    // 초기 yawRate 설정
    pdrCalculator.setPdrYaw(Calculators.deg2rad(compassValue.value));

    _locationUpdateTimer =Timer.periodic(Duration(milliseconds: 100), (timer) {
      sAccuracy = position.accuracy;
      _getLocation();
    });
  }

  /// BuildContext 설정 메서드
  void setContext(BuildContext context) {
    _context = context;
  }

  // /// resetSpeedUtilsValue: 경로 재설정 시 속도, 방향, 위치 계산 관련 변수를 초기화합니다.
  // void resetSpeedUtilsValue() {
  //   pdrCalculator.resetValue(0, Calculators.deg2rad(compassValue.value), 0.0, 0.0);
  // }

  // ============================================================
  // 5. 센서 관련 메서드
  // ============================================================

  /// 센서 스트림 초기화
  void _initSensorStreams() {
    _compassSub = sensorStreams.compass.listen((headingVal) {
      heading = headingVal;
      compassValue.value = headingVal;
      if (!compassReady.isCompleted) {
        compassReady.complete();
      }
    });
    _gyroSub = sensorStreams.gyro.listen((gyroEvent) {
      pdrCalculator.orientationUpdate(gyroEvent, Duration(milliseconds: 20));
    });
    _accelSub = sensorStreams.accel.listen((accelEvent) {
      pdrCalculator.positionUpdate(accelEvent, Duration(milliseconds: 20));
    });
  }

  /// onSensorUpdate: 센서 업데이트 데이터(위치, 나침반)를 받아 지도 업데이트를 수행합니다.
  void onSensorUpdate(
      double latitude, double longitude, double compassVal, bool isGps) {
    currentLatitude.value = latitude;
    currentLongitude.value = longitude;
    compassValue.value = compassVal;
    updateMapByMode(latitude, longitude, compassVal, isGps);
  }

  // ============================================================
  // 6. 위치 관련 메서드
  // ============================================================

  /// _getLocation: 현재 위치를 가져와 센서 데이터와 지도 업데이트를 수행합니다.
  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      // GPS 정확도에 따라 출발지 안내 멘트 유/무
      if (!showLowGpsAlrertOnce && position.accuracy >= 1) {
        showLowGpsAlrertOnce = true; // 중복 표시 방지 플래그
        showLowAccuracyDialog.value = true; // 알림 다이얼로그 표시 신호
      }

      if (position.accuracy >= 1) {
        isGps = false; // GPS 신호 불량
        pdrCalculator.setVelocityValue(_filteringX.calculateWeightedAverage(), _filteringY.calculateWeightedAverage());
        currentLatitude.value = pdrCalculator.newlatitude; // 센서 계산 위도
        currentLongitude.value = pdrCalculator.newlongitude; // 센서 계산 경도
        isLoading.value = false;
      } else {
        isGps = true; // GPS 신호 정상
        currentLatitude.value = position.latitude; //  GPS 위도
        currentLongitude.value = position.longitude; //  GPS 경도
        pdrCalculator.setInitialPosition(currentLatitude.value, currentLongitude.value);
        pdrCalculator.resetValue(0, Calculators.deg2rad(compassValue.value), 0.0, 0.0);
        isLoading.value = false;
      }
      onSensorUpdate(
        currentLatitude.value,
        currentLongitude.value,
        compassValue.value,
        isGps,
      );
    } catch (e) {
      debugPrint("현위치 수신에러 $e");
      isLoading.value = false;
    }
  }



  // ============================================================
  // 7. 경로 안내 시작 메서드
  // ============================================================

  /// startNavigationWithPath: 경로 데이터를 로드하고 경로 안내를 시작합니다.
  Future<void> startNavigationWithPath(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    String chooseRoute,
    double compass,
    int targetIndex,
    {List<LatLng> waypoints = const []}
  ) async {
    try {
      // 1️⃣ 경로 데이터 로드
      final response = waypoints.isEmpty
          ? await routeController.loadPathData(
              startLat, startLng, endLat, endLng, chooseRoute)
          : await routeController.loadPathDataWithWaypoints(
              startLat, startLng, endLat, endLng, waypoints, chooseRoute);

      // 2️⃣ 파싱 및 상태 반영
      routeController.applyParsePathData(response);

      // 경유지 정보가 있으면 branchInfo에 waypoint 플래그 설정
      if (waypoints.isNotEmpty) {
        routeController.checkWaypointsInBranchInfo(waypoints);
      }

      // 3️⃣ 로깅 (waypoint 유무에 따라 다른 로그)
      waypoints.isEmpty
          ? routeController.logLoadPathData()
          : routeController.logLoadPathDataWithWayPoint();

      // 4️⃣ 분기점 방향 계산
      routeController.calculatePathBearing();
      // 5️⃣ 인덱스 초기화
      indexController.reset(startIndex: 0);
      // 6️⃣ 나침반 기준 yaw 오프셋 설정
      routeController.resetDeviationYaw(targetIndex, compass);
      // 7️⃣ 지도 오버레이 추가
      overlayController
        ..addPathOverlays(routeController.paths)
        ..addBranchMarkers();
      // 8️⃣ 네비게이션 시작
      startNavigationTimer();

    } catch (e, s) {
      debugPrint('startNavigationWithPath 실패: $e\n$s');
    }
  }

  /// startNavigationWithRoute: 즐겨찾기 경로를 사용한 경로 안내 시작
  Future<void> startNavigationWithRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    required List<LatLng> waypoints,
    required String chooseRoute,
  }) async {
    debugPrint('경유지 포함 경로 안내 시작');
    debugPrint('출발지: $startLatitude, $startLongitude');
    debugPrint('목적지: $endLatitude, $endLongitude');
    debugPrint('경유지: ${waypoints.length}개');

    // 출발지, 목적지 설정
    selectedStartLocation.value = GeoLocation(
      lat: startLatitude,
      lng: startLongitude,
    );
    selectedDestLocation.value = GeoLocation(
      lat: endLatitude,
      lng: endLongitude,
    );
    isSetStartLocation.value = true;
    isSetDestinationLocation.value = true;
    this.chooseRoute.value = chooseRoute;

    // 경유지 저장 (재검색시 사용)
    currentWaypoints = waypoints;

    // 경유지 포함 경로 로드
    await routeController.loadPathDataWithWaypoints(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
      waypoints,
      chooseRoute,
    );
  }

  /// startNavigation: 경로 선택이 완료된 후 경로 탐색을 시작합니다.
  /// 추후에 startNavigationWithPath로 통합될 가능성 있음
  Future<void> startNavigation() async {
    if (isSetStartLocation.value && isSetDestinationLocation.value) {
      debugPrint('경로 선택 완료. 경로 탐색을 시작합니다.');
      // 일반 경로 안내시에는 경유지 초기화
      currentWaypoints.clear();
      await startNavigationWithPath(
          selectedStartLocation.value!.lat,
          selectedStartLocation.value!.lng,
          selectedDestLocation.value!.lat,
          selectedDestLocation.value!.lng,
          chooseRoute.value,
          compassValue.value,
          indexController._targetIndex,);
    } else {
      debugPrint('출발지 또는 목적지가 설정되지 않았습니다.');
    }
  }

  // ============================================================
  // 8. 경로 안내 실행 메서드
  // ============================================================

  /// startNavigationTimer: 경로 안내를 위한 타이머를 시작합니다.
  void startNavigationTimer() {
    debugPrint('startNavigationTimer()');

    initNavigation();

    navigationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      // 목적지 도착 체크 (3m 이내)
      ///////////////////////목적지 도착 체크///////////////////////
      if (routeController.branchinfo.isNotEmpty) {
        // 마지막 브랜치(목적지)와 현재 위치 거리 계산
        final destinationDistance = checkDistanceToDestination();

        bool isArrived = checkIsArrived(destinationDistance);
        // 목적지 3m(0.003km) 이내 도착 시 자동 종료
        if (isArrived) {
          debugPrint('목적지 도착 감지: ${destinationDistance * 1000}m');

          // TTS 음성 안내
          await tts.speakWithChannel(
            '목적지에 도착했습니다.',
            channel:ETtsChannel.NAVIGATE,
            cooldownKey: 'arrive_destination',
            cooldown: Duration(seconds: 20),
          );

          // 경로 안내 자동 종료
          await stopNavigationTimer();
          return; // 타이머 콜백 종료
        }
      }
      /////////////////////////////////////////////////////////////
      ///경계이탈 체크
      checkBoundary();
      ///경로 안내 진행
      indexController.indexUpdate();
      
      /////////////////////정상 출발 체크/////////////////////////////
      // 출발지(첫 번째 분기점)와 현재 위치 사이 거리 계산
      checkIsStart();
      // 출발지와 현재 위치가 50m 이상 차이나면 재검색 준비
      if (remainStartpoint > 0.05 && isStart.value == false) {
        // 이탈 시작 시간 기록
        _startPointDeviationTime ??= DateTime.now();
        // 경과 시간 계산
        final deviationDuration = DateTime.now().difference(_startPointDeviationTime!);
        if (deviationDuration >= _startDeviationThreshold) {
          // 20초 이상 지속 시 경로 재검색
          debugPrint('출발지와 너무 멀어짐. ${_startDeviationThreshold.inSeconds}초 후 자동으로 경로 재검색 수행');

          // 현재 위치를 새로운 출발지로 설정하고 지도 업데이트
          // 경유지가 있으면 경유지 포함 경로 재검색
          // 경로를 다시 안그림
          if (currentWaypoints.isNotEmpty) {
            debugPrint('경유지 ${currentWaypoints.length}개를 포함한 경로 재검색');
            await routeController.loadPathDataWithWaypoints(
              currentLatitude.value,
              currentLongitude.value,
              selectedDestLocation.value!.lat,
              selectedDestLocation.value!.lng,
              currentWaypoints,
              chooseRoute.value,
            );
          } else {
            await routeController.loadPathData(
              currentLatitude.value,
              currentLongitude.value,
              selectedDestLocation.value!.lat,
              selectedDestLocation.value!.lng,
              chooseRoute.value,
            );
          }
          
          tts.speakWithChannel(
            '출발지에 벗어나 새로운 경로로 안내합니다.',
            channel: ETtsChannel.NAVIGATE,
            cooldownKey: 'research_out_of_start',
            cooldown: Duration(seconds: 10),
          );
          debugPrint('출발지를 현재 위치로 변경하고 지도 업데이트 완료');
          _startPointDeviationTime = null; // 시간 초기화
        }
      } else {
        // 정상 범위로 돌아오면 초기화
        _startPointDeviationTime = null;
      }
      ///////////////////////////////정상적인 경로 안내///////////////////
      if (isStart.value) {
        if (routeController.branchinfo.isNotEmpty && indexController.targetIndex < routeController.branchinfo.length) {
          branchTargetIndex = indexController.targetIndex;
          while (branchTargetIndex < routeController.branchinfo.length &&
              !routeController.branchinfo[branchTargetIndex].branch) {
            branchTargetIndex++;
          }
          if (routeController.branchinfo[branchTargetIndex].branch) {
            remainDistance.value = Calculators.calculateDistance(
              currentLatitude.value,
              currentLongitude.value,
              routeController.branchinfo[branchTargetIndex].point.latitude,
              routeController.branchinfo[branchTargetIndex].point.longitude,
            );
            clock = guidanceCalculator.getGuidanceDirection(
              routeController.branchinfo[indexController.currentIndex].point.longitude,
              routeController.branchinfo[indexController.currentIndex].point.latitude,
              routeController.branchinfo[indexController.targetIndex].point.longitude,
              routeController.branchinfo[indexController.targetIndex].point.latitude,
              currentLatitude.value,
              currentLongitude.value,
              pdrCalculator.deviationYawTurn,
              routeController.branchinfo[indexController.currentIndex].bearingToPoint,
            );
          }
        } else {
          debugPrint("branchinfo 리스트가 비어 있거나 targetIndex가 유효하지 않습니다.");
        }
        /////////////////////////////////브랜치 도달 안내///////////////////////////
        if (remainDistance.value < 0.015) {
          if (routeController.branchinfo[indexController.currentIndex].crosswalk == true) {
            final result = await flashOnWithWeather(NoParams());
            if (result.isLeft()) {
              debugPrint('안전 경광등을 사용할 수 없습니다.');
            } else {
              debugPrint('안전 경광등이 켜졌습니다.');
            }
            
            tts.speakWithChannel('잠시 후 횡단보도 입니다. 차량에 유의하세요!', channel: ETtsChannel.ALERT,cooldownKey: 'crosswalk_alert', cooldown: Duration(seconds: 2),);
          }
          if (routeController.branchinfo[indexController.targetIndex].branch == true) {
            
            String message = routeController.branchinfo[indexController.targetIndex].description;
            tts.speakWithChannel(message, channel: ETtsChannel.NAVIGATE, cooldownKey: 'branch_instruction', cooldown: Duration(seconds: 10),);
          }
        }
        /////////////////////////POI 안내 /////////////////////////
        // 10초에 한 번만 API 호출 (성능 최적화)
        final now = DateTime.now();
        if (_lastPoiAnnouncementTime == null ||
            now.difference(_lastPoiAnnouncementTime!).inSeconds >= 20) {
          _lastPoiAnnouncementTime = now;
          locationAnnouncementController.announceNearbyBuilding(
            currentLatitude.value,
            currentLongitude.value,
            compassValue.value,
          );
        }

        ///////////////////////////////경로내 진동 안내///////////////////////////
        if (indexController.currentIndex > 0 &&
            ((routeController.branchinfo[indexController.currentIndex].bearingToPoint - compassValue.value)
                        .abs() <=
                    18 ||
                (routeController.branchinfo[indexController.currentIndex].bearingToPoint - compassValue.value)
                        .abs() >=
                    342)) {
          Vibration.vibrate(duration: 500);
          debugPrint(
              "경로내 진동 베어링 값 ${(routeController.branchinfo[indexController.currentIndex].bearingToPoint - compassValue.value)}");
        }
        ///////////////////////////////경계이탈 안내///////////////////////////
        if (outOfBound) {
          Vibration.vibrate(duration: 100);
          
          debugPrint('searchNewPath : $searchNewPath');
          // speakText(clock);
          tts.speakWithChannel(clock, channel: ETtsChannel.ALERT, cooldownKey: 'out_of_bound', cooldown: Duration(seconds: 2),);
          if (searchNewPath) {
            searchNewPathTime++;
            if (searchNewPathTime >= 5) {
              // 경유지가 있으면 경유지 포함 경로 재검색
              if (currentWaypoints.isNotEmpty) {
                debugPrint(
                    '경로 이탈 - 경유지 ${currentWaypoints.length}개를 포함한 경로 재검색');
                await routeController.loadPathDataWithWaypoints(
                  currentLatitude.value,
                  currentLongitude.value,
                  selectedDestLocation.value!.lat,
                  selectedDestLocation.value!.lng,
                  currentWaypoints,
                  chooseRoute.value,
                );
              } else {
                await routeController.loadPathData(
                  currentLatitude.value,
                  currentLongitude.value,
                  selectedDestLocation.value!.lat,
                  selectedDestLocation.value!.lng,
                  chooseRoute.value,
                );
              }
              
              tts.speakWithChannel("경로를 이탈하여 새로운 경로로 안내합니다.", channel: ETtsChannel.SYSTEM_ANNOUNCE, cooldownKey: 'research_out_of_path', cooldown: Duration(seconds: 10),);
              searchNewPathTime = 0;
            }
          } else {
            searchNewPathTime = 0;
          }
        }
      } else if (isStart.value) {
        
        tts.speakWithChannel("출발지로 이동하세요.", channel: ETtsChannel.NAVIGATE, cooldownKey: 'move_to_startpoint', cooldown: Duration(seconds: 5),);
      }
    });
  }

  /// stopNavigationTimer: 경로 안내 종료 및 지도 초기화(비동기식)
  Future<void> stopNavigationTimer() async {
    try {
      // 1. 먼저 타이머를 취소하고 네비게이션 상태를 false로 설정
      isNavigating.value = false;
      navigationTimer?.cancel();
      isStart.value == false;
      navigationTimer = null;
      // 2. 지도 컨트롤러가 유효한지 확인
      if (mapController == null) {
        debugPrint('지도 컨트롤러가 초기화되지 않았습니다.');
        return;
      }
      // 3. 모든 오버레이 제거
      await overlayController.clearOverlays();
      // 4. 위치 서비스 초기화
      await _initializeLocationServices();
      // 5. 상태 변수 초기화
      resetStateVariables();
      // 6. SearchBloc 상태 초기화
      if (_context != null) {
        _context!
            .read<SearchBloc>()
            .add(SearchStartLocationRequested(searchLocation: ''));
        _context!
            .read<SearchBloc>()
            .add(SearchDestinationRequested(searchDestination: ''));
      }
      // 7. 현재 위치 마커만 다시 추가
      await overlayController.updateCurrentLocationMarker(currentLatitude.value,
          currentLongitude.value, compassValue.value, false, mapMode.value);
      // 8. 지도 업데이트
      updateMapByMode(currentLatitude.value, currentLongitude.value,
          compassValue.value, isGps);
      debugPrint('경로 안내가 성공적으로 종료되었습니다.');
    } catch (e) {
      debugPrint('경로 안내 종료 중 오류 발생: $e');
    }
  }

  /// checkBoundary: 현재 위치가 경로(분기)로부터 얼마나 벗어났는지 확인합니다.
  /// 경로 이탈, 재경로 탐색 등의 조건을 판단합니다.
  void checkBoundary() {
    final currentWindow = indexController.getCurrentWindowRecords(
      routeController.branchinfo,
      indexController.currentIndex,
      5,
    );

    final result = guidanceCalculator.evaluateBoundary(
      window: currentWindow,
      currentLat: currentLatitude.value,
      currentLon: currentLongitude.value,
      boundary: boundary,
      searchNewPathBoundary: searchNewPathBoundary,
    );

    distanceToPath         = result.minDistanceMeters;
    outOfBound             = result.outOfBound;
    searchNewPath          = result.searchNewPath;
    checkBoundaryCondition = result.condition;
    debugPrint('경계 조건: $checkBoundaryCondition');
    debugPrint('경계 이탈: $outOfBound');
  }

  /// resetStateVariables: 상태 초기화 메서드
  void resetStateVariables() {
    isSetStartLocation.value = false;
    isSetDestinationLocation.value = false;
    selectedStartLocation.value = null;
    selectedDestLocation.value = null;
    searchLocation.value = '';
    destinationLocation.value = '';
    routeController.clearPathData();
    currentWaypoints.clear(); // 경유지 정보 초기화
  }

  double checkDistanceToDestination() {
    final destination = routeController.branchinfo.last.point;
    final distance = Calculators.calculateDistance(
      currentLatitude.value,
      currentLongitude.value,
      destination.latitude,
      destination.longitude,
    );

    return (distance * 1000);
  }

  bool checkIsArrived(desDis){
    if (desDis < 0.003) {
      return true;
    } else {
      return false;
    }
  }

  void initNavigation(){
    isNavigating.value = true;
    navigationTimer?.cancel(); // 기존 타이머 제거
  }

  void checkIsStart(){
          remainStartpoint = Calculators.calculateDistance(
        currentLatitude.value,
        currentLongitude.value,
        routeController.branchinfo[0].point.latitude,
        routeController.branchinfo[0].point.longitude,
      );

      if (remainStartpoint<0.015) {
        isStart.value = true;
      }
  }
  // ============================================================
  // 9. 지도 제어 메서드
  // ============================================================

  /// updateMapPosition: 지도 카메라를 현재 위치 및 모드에 따라 업데이트합니다.
  /// [currentLatitude]: 현재 위도.
  /// [currentLongitude]: 현재 경도.
  /// [compassValue]: 현재 나침반 값.
  void updateMapPosition(
      double currentLatitude, double currentLongitude, double compassValue) {
    if (mapController == null) return;

    // on1 모드에서는 저장된 방향(_currentBearing)을 사용
    final targetBearing = mapMode.value == MapControlMode.on2
        ? compassValue
        : (mapMode.value == MapControlMode.on1 && _currentBearing != null)
            ? _currentBearing
            : 0.0;

    final zoomLevel = 18.5;
    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(currentLatitude, currentLongitude),
      zoom: zoomLevel,
      bearing: targetBearing,
    )..setAnimation(animation: NCameraAnimation.easing);
    mapController!.updateCamera(cameraUpdate);
  }

  /// updateMapByMode: 현재 지도 모드에 따라 지도와 마커를 업데이트합니다.
  /// [latitude]: 현재 위도.
  /// [longitude]: 현재 경도.
  /// [compassValue]: 현재 나침반 값.
  /// [isGps]: GPS 신호 사용 여부.
  Future<void> updateMapByMode(double latitude, double longitude,
      double compassValue, bool isGps) async {
    if (mapController == null) return;
    switch (mapMode.value) {
      case MapControlMode.idle:

        /// 초기상태로 최초에는 마커와 지도를 업데이트
        await overlayController.updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps, mapMode.value);
        updateMapPosition(latitude, longitude, compassValue);
        break;
      case MapControlMode.off:

        /// off 모드에서는 지도 이동은 자유롭게 하므로 카메라 업데이트 생략
        await overlayController.updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps, mapMode.value);
        break;
      case MapControlMode.on1:

        /// on1 모드에서는 지도 회전을 유지하고 마커만 회전
        /// 지도를 회전시키기 않기 위해 마지막 bearing 값으로 map을 업데이트
        mapController!.getCameraPosition().then((position) {
          _currentBearing = position.bearing;
        });
        await overlayController.updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps, mapMode.value);
        updateMapPosition(latitude, longitude, _currentBearing ?? 0.0);
        break;
      case MapControlMode.on2:

        /// 지도와 마커 모두 회전
        await overlayController.updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps, mapMode.value);
        updateMapPosition(latitude, longitude, compassValue);
        break;
    }
  }

  // ============================================================
  // 10. 사용자 인터랙션 메서드
  // ============================================================

  /// handleStartLocationSelection: 시작 위치를 설정하고, 목적지가 이미 설정되어 있다면 경로 데이터를 요청합니다.
  Future<void> handleStartLocationSelection(GeoLocation newStart) async {
    selectedStartLocation.value = newStart;
    isStart.value = true;
    isSetStartLocation.value = true;
    // 출발지만 설정하고 경로 요청은 하지 않음
    debugPrint('출발지가 설정되었습니다.');
  }

  /// handleDestinationLocationSelection: 목적지 위치를 설정하고, 시작 위치가 이미 설정되어 있다면 경로 데이터를 요청합니다.
  Future<void> handleDestinationLocationSelection(GeoLocation newDest) async {
    selectedDestLocation.value = newDest;
    isSetDestinationLocation.value = true;

    // 출발지가 설정되지 않은 경우 현재 위치를 출발지로 자동 설정
    if (!isSetStartLocation.value) {
      selectedStartLocation.value = GeoLocation(
        lat: currentLatitude.value, // 현재 GPS 위도
        lng: currentLongitude.value, // 현재 GPS 경도
      );
      isSetStartLocation.value = true;
      debugPrint(
          '출발지가 설정되지 않아 현위치를 출발지로 자동 설정됨: ${selectedStartLocation.value!.lat}, ${selectedStartLocation.value!.lng}');
    }
    // 경로 요청은 하지 않고 목적지만 설정
    debugPrint('목적지가 설정되었습니다. 경로 선택을 기다립니다.');
  }

/// 지도 중심 좌표를 즉시 읽어와서 현재 위치 마커로 고정 설정 (IMU 기반일 때만)
  Future<void> setCustomStartLocationFromCamera() async {
    if (!isGps) {
      // GPS 신호 불량일 때만 활성화
      isCustomStartPoint.value = true; // 커스텀 출발지 플래그 설정

      // mapController null 체크 추가
      if (mapController == null) {
        debugPrint('mapController가 아직 초기화되지 않았습니다.');
        return;
      }

      // 현재 카메라 중심을 바로 가져와서 저장
      final cameraPosition = await mapController!.getCameraPosition();
      final double targetLat = cameraPosition.target.latitude;
      final double targetLng = cameraPosition.target.longitude;

      cameraStartLat.value = targetLat; // 카메라 중심 위도
      cameraStartLng.value = targetLng; // 카메라 중심 경도

      // 상대좌표 계산 (IMU 위치 기준 → 사용자 선택 위치로 보정)
      pdrCalculator.updateRelativeCoordinates(currentLatitude.value, currentLongitude.value,
          cameraStartLat.value, cameraStartLng.value);

      // 현재 위치를 카메라 중심값으로 갱신
      currentLatitude.value = targetLat;
      currentLongitude.value = targetLng;

      // 출발지로 고정
      selectedStartLocation.value = GeoLocation(lat: targetLat, lng: targetLng);
      isSetStartLocation.value = true;

      // 마커도 즉시 지도에 반영
      await overlayController.updateCurrentLocationMarker(
          targetLat, targetLng, compassValue.value, false, mapMode.value);

      debugPrint("출발지 위치 수동 고정 완료: ($targetLat, $targetLng)");
    } else {
      debugPrint("GPS 사용 중이므로 수동 위치 설정 차단됨");
    }
  }

  /// toggleMapMode: 지도 모드를 토글합니다.
  Future<void> toggleMapMode() async {
    if (mapMode.value == MapControlMode.idle) {
      mapMode.value = MapControlMode.off;
    }
    int nextIndex = (mapMode.value.index + 1) % MapControlMode.values.length;
    if (MapControlMode.values[nextIndex] == MapControlMode.idle) {
      nextIndex = (nextIndex + 1) % MapControlMode.values.length;
    }
    mapMode.value = MapControlMode.values[nextIndex];
    debugPrint("모드 전환: ${mapMode.value}");
  }

  /// handleMapDrag: 사용자가 지도를 드래그하면 지도 모드를 'off'로 전환합니다.
  void handleMapDrag() {
    if (mapMode.value != MapControlMode.off) {
      mapMode.value = MapControlMode.off;
    }
  }

  /// 경광등 토글 메서드
  Future<void> toggleFlashlight() async {
    try {
      if (isFlashOn.value) {
        // 경광등이 켜져 있으면 끄기
        final result = await flashOff(NoParams());
        if (result.isLeft()) {
          
          tts.speakWithChannel('안전 경광등을 끌 수 없습니다.', channel: ETtsChannel.SYSTEM_ANNOUNCE, cooldownKey: 'flashlight_off_fail', cooldown: Duration(seconds: 5),);
        } else {
          isFlashOn.value = false;
          tts.speakWithChannel('안전 경광등이 꺼졌습니다.', channel: ETtsChannel.SYSTEM_ANNOUNCE, cooldownKey: 'flashlight_off_success', cooldown: Duration(seconds: 5),);
        }
      } else {
        // 경광등이 꺼져 있으면 켜기
        final result = await flashOn(NoParams());
        if (result.isLeft()) {
          tts.speakWithChannel('안전 경광등을 켤 수 없습니다.', channel: ETtsChannel.SYSTEM_ANNOUNCE, cooldownKey: 'flashlight_on_fail', cooldown: Duration(seconds: 5),);
        } else {
          isFlashOn.value = true;
          tts.speakWithChannel('안전 경광등이 켜졌습니다.', channel: ETtsChannel.SYSTEM_ANNOUNCE, cooldownKey: 'flashlight_on_success', cooldown: Duration(seconds: 5),);
        }
      }
    } catch (e) {
      debugPrint('경광등 제어 중 오류 발생: $e');
      tts.speakWithChannel('경광등 제어 중 오류가 발생했습니다.', channel: ETtsChannel.SYSTEM_ANNOUNCE, cooldownKey: 'flashlight_control_error', cooldown: Duration(seconds: 5),);
    }
  }


}
