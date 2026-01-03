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
/// 네비게이션 진행 상태를 나타내는 열거형입니다.
enum NavPhase {
  moveToStart,
  navigating,
  outOfBound,
  rerouting,
  stopped,
}
/// 네비게이션 진행 상태 변경 이유를 나타내는 열거형입니다.
enum NavPhaseReason {
  notStarted,
  normal,
  outOfBound,
  reroutingLock,
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

  /// 센서 융합 heading 가중치 (1.0 = compass only, 0.0 = gyro only)
  double _sensorFusionWeight = 1.0;

  /// 커스텀 시작 지점 사용 여부
  RxBool isCustomStartPoint = false.obs;

  /// 선택된 시작 위치
  Rxn<GeoLocation> selectedStartLocation = Rxn<GeoLocation>();
  /// 선택된 목적지 위치
  Rxn<GeoLocation> selectedDestLocation = Rxn<GeoLocation>();
  /// 시작 위치가 설정되었는지 여부
  RxBool isStart = false.obs;
  RxBool isOutOfStart = false.obs;
  /// 시작 위치가 설정되었음을 나타내는 Reactive 변수
  RxBool isSetStartLocation = false.obs;
  /// 목적지 위치가 설정되었음을 나타내는 Reactive 변수
  RxBool isSetDestinationLocation = false.obs;

  /// 경광등 상태를 나타내는 Reactive 변수
  RxBool isFlashOn = false.obs;

  /// 횡단보도 구간 내 여부 (flash 유지용)
  bool isInCrosswalk = false;

  /// 횡단보도 진입 시 타겟 인덱스 (탈출 감지용)
  int? _crosswalkEntryTargetIndex;

  /// 경로 안내 중인지 여부를 나타내는 Reactive 변수
  RxBool isNavigating = false.obs;

  /// GPS 신호 사용 여부 (반응형)
  RxBool isGpsAccurate = true.obs;

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
  /// GPS 정확도 임계값 (미터 단위)
  int kMinGpsAccuracyThreshold = 1;
  /// 위치 업데이트 타이머
  Timer? _locationUpdateTimer;
  Timer? navigationTimer;

  /// 주변 건물 자동 알림 타이머
  Timer? _autoPoiAnnounceTimer;

  /// 주변 건물 자동 알림 활성화 상태
  RxBool isAutoPoiAnnounceEnabled = false.obs;

  /// 나침반 데이터 수신 완료 여부를 판단하기 위한 Completer
  Completer<void> compassReady = Completer<void>();

  /// POI 안내 마지막 호출 시간 (API 호출 빈도 제한용)
  DateTime? _lastPoiAnnouncementTime;

  // 방향 관련 변수
  double? heading;
  double firstBearingToPoint = 0.0;
  String clock = "";

  /// 센서 융합 heading 계산: (compass * w) + (gyro * (1-w))
  double get fusedHeading {
    final w = _sensorFusionWeight;
    return (compassValue.value * w) + (pdrCalculator.pdrYawDeg * (1 - w));
  }

  // 이동 거리 계산 변수
  double distanceToPath = 0.0;

  // 경계 및 재경로 검색 관련 변수들
  bool outOfBound = false;
  double boundary = 5; // 경계 이탈 감지 거리 (1.5미터)
  bool searchNewPath = false;
  /// 경계 조건 문자열 (디버깅용)
  String checkBoundaryCondition = "";
  double searchNewPathBoundary = 15;
  int searchNewPathTime = 0;

  //startNavigationTimer 리팩토링
  final Rx<NavPhase> navPhase = NavPhase.moveToStart.obs;
  final Rx<NavPhaseReason> navPhaseReason = NavPhaseReason.notStarted.obs;
  // Timer.periodic + async 재진입 방지
  bool _tickRunning = false;
  // 재탐색 중복 방지 락
  bool _rerouteInFlight = false;





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
    _loadFavoritePointsCache();
    _initializeLocalPois();
  }

  /// 즐겨찾기 관심지점을 서버에서 로드하여 LocationAnnouncementController 캐시에 저장
  ///
  /// 앱 시작 시 즐겨찾기 패널을 열지 않아도 POI 안내에 즐겨찾기가 포함되도록 함
  Future<void> _loadFavoritePointsCache() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        debugPrint('[MapViewController] 즐겨찾기 캐시 로드 스킵: 로그인되지 않음');
        return;
      }

      final authService = DI.get<AuthService>();
      final credentials = await authService.getFavoriteCredentials(user: user);
      if (credentials == null) {
        debugPrint('[MapViewController] 즐겨찾기 캐시 로드 스킵: 인증 정보 없음');
        return;
      }

      // 즐겨찾기 조회
      final dioClient = DioClient();
      final remoteDataSource = FavoriteRemoteDataSourceImpl(dioClient: dioClient);
      final repository = FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);
      final getFavoritePoints = GetFavoritePoints(repository);

      final result = await getFavoritePoints.call(
        GetFavoritePointsParams(
          loginMethod: credentials.loginMethod,
          userId: credentials.userId,
        ),
      );

      result.fold(
        (failure) {
          debugPrint('[MapViewController] 즐겨찾기 캐시 로드 실패: $failure');
        },
        (points) {
          locationAnnouncementController.updateFavoritePointsCache(points);
          debugPrint('[MapViewController] 즐겨찾기 캐시 로드 완료: ${points.length}개');
        },
      );
    } catch (e) {
      debugPrint('[MapViewController] 즐겨찾기 캐시 로드 에러: $e');
    }
  }

  /// 로컬 POI 초기화 (횡단보도, 버스정류장 등)
  Future<void> _initializeLocalPois() async {
    await locationAnnouncementController.initializeLocalPois();
  }

  /// 주변 건물 자동 알림 토글
  void toggleAutoPoiAnnounce() {
    isAutoPoiAnnounceEnabled.value = !isAutoPoiAnnounceEnabled.value;
    debugPrint('[AutoPoiAnnounce] 토글: ${isAutoPoiAnnounceEnabled.value ? "ON" : "OFF"}');

    if (isAutoPoiAnnounceEnabled.value) {
      _startAutoPoiAnnounce();
    } else {
      _stopAutoPoiAnnounce();
    }
  }

  /// 주변 건물 자동 알림 시작 (20초 주기)
  void _startAutoPoiAnnounce() {
    _stopAutoPoiAnnounce(); // 기존 타이머 정리
    debugPrint('[AutoPoiAnnounce] 자동 알림 시작 (20초 주기)');

    // 즉시 한 번 실행
    debugPrint('[AutoPoiAnnounce] 즉시 1회 안내 실행');
    locationAnnouncementController.announceNearbyBuilding(
      currentLatitude.value,
      currentLongitude.value,
      fusedHeading,
    );

    // 20초마다 반복
    _autoPoiAnnounceTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      // 경로 안내 중이면 자동 알림 중지
      if (isNavigating.value) {
        debugPrint('[AutoPoiAnnounce] 경로 안내 중 - 자동 알림 중지');
        _stopAutoPoiAnnounce();
        isAutoPoiAnnounceEnabled.value = false;
        return;
      }

      debugPrint('[AutoPoiAnnounce] 20초 주기 안내 실행');
      locationAnnouncementController.announceNearbyBuilding(
        currentLatitude.value,
        currentLongitude.value,
        fusedHeading,
      );
    });
  }

  /// 주변 건물 자동 알림 중지
  void _stopAutoPoiAnnounce() {
    debugPrint('[AutoPoiAnnounce] 타이머 중지');
    _autoPoiAnnounceTimer?.cancel();
    _autoPoiAnnounceTimer = null;
  }

  /// onClose: 컨트롤러 종료 시 타이머 및 센서 스트림 구독을 취소합니다.
  @override
  void onClose() {
    tts.stopAll();
    _locationUpdateTimer?.cancel();
    navigationTimer?.cancel();
    navigationTimer = null;
    _autoPoiAnnounceTimer?.cancel();
    // 센서 스트림 구독 취소
    _compassSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();

    // 센서 컨트롤러 및 스트림 종료
    sensorController.stop();
    

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
      if (!showLowGpsAlrertOnce && position.accuracy >= kMinGpsAccuracyThreshold) {
        showLowGpsAlrertOnce = true; // 중복 표시 방지 플래그
        showLowAccuracyDialog.value = true; // 알림 다이얼로그 표시 신호
      }
      
      if (position.accuracy >= kMinGpsAccuracyThreshold) {
        isGpsAccurate.value = false; // GPS 신호 불량
        pdrCalculator.setVelocityValue(_filteringX.calculateWeightedAverage(), _filteringY.calculateWeightedAverage());
        currentLatitude.value = pdrCalculator.newlatitude; // 센서 계산 위도
        currentLongitude.value = pdrCalculator.newlongitude; // 센서 계산 경도
        isLoading.value = false;
      } else {
        isGpsAccurate.value = true; // GPS 신호 정상
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
        isGpsAccurate.value,
      );
    } catch (e) {
      debugPrint("현위치 수신에러 $e");
      isLoading.value = false;
    }
  }



  // ============================================================
  // 7. 경로 안내 시작 메서드 (Navigation Setup)
  // ============================================================
  //
  // 🔷 이 섹션의 메서드 호출 순서:
  //    startNavigation()
  //      → startNavigationWithPath() : 경로 데이터 로드 및 초기화
  //          → startNavigationTimer() : 타이머 시작 (섹션 8로 이동)
  //
  // 🔷 또는 즐겨찾기 경로 사용 시:
  //    startNavigationWithRoute() : 경유지 포함 경로 설정
  //      → startNavigationWithPath()
  //          → startNavigationTimer()
  // ============================================================

  /// 경로 선택이 완료된 후 경로 탐색을 시작합니다.
  /// - 출발지/목적지가 설정되어 있어야 실행됩니다.
  /// - 추후에 startNavigationWithPath로 통합될 가능성 있음
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
      // 네비게이션 타이머 시작
      startNavigationTimer();
    } else {
      debugPrint('출발지 또는 목적지가 설정되지 않았습니다.');
    }
  }

  /// 경로 데이터를 로드하고 경로 안내를 준비합니다.
  ///
  /// 수행 작업:
  /// 1. API를 통해 경로 데이터 로드
  /// 2. 응답 데이터 파싱 및 상태 반영
  /// 3. 분기점 방향 계산
  /// 4. 인덱스 및 yaw 오프셋 초기화
  /// 5. 지도 오버레이 추가
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


    } catch (e, s) {
      debugPrint('startNavigationWithPath 실패: $e\n$s');
    }
  }

  /// 즐겨찾기 경로를 사용한 경로 안내 시작 (경유지 포함)
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

  // ============================================================
  // 8. 경로 안내 실행 메서드 (Navigation Execution)
  // ============================================================
  
  // ────────────────────────────────────────────────────────────
  // 8-1. 타이머 시작/종료
  // ────────────────────────────────────────────────────────────

  /// 경로 안내를 위한 타이머를 시작합니다.
  void startNavigationTimer() {
    debugPrint('startNavigationTimer()');

    initNavigation();

    // 기존 타이머 정리
    navigationTimer?.cancel();

    // phase 초기화
    navPhase.value = NavPhase.moveToStart;
    navPhaseReason.value = NavPhaseReason.notStarted;
    _rerouteInFlight = false;

    navigationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _onNavigationTick(timer);
    });
  }

  /// 경로 안내 종료 및 지도 초기화 (비동기식)
  Future<void> stopNavigationTimer() async {
    try {
      // 1. 타이머 취소 및 네비게이션 상태 해제
      isNavigating.value = false;
      navigationTimer?.cancel();
      isStart.value = false;
      navigationTimer = null;

      // 2. 지도 컨트롤러 유효성 확인
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
          compassValue.value, isGpsAccurate.value);

      debugPrint('경로 안내가 성공적으로 종료되었습니다.');
    } catch (e) {
      debugPrint('경로 안내 종료 중 오류 발생: $e');
    }
  }

  /// 네비게이션 초기 상태 설정
  void initNavigation() {
    isNavigating.value = true;
    isInCrosswalk = false;
    _crosswalkEntryTargetIndex = null;
    navigationTimer?.cancel();
    tts.stopAll();
  }

  /// 상태 변수 초기화
  void resetStateVariables() {
    isSetStartLocation.value = false;
    isSetDestinationLocation.value = false;
    selectedStartLocation.value = null;
    selectedDestLocation.value = null;
    searchLocation.value = '';
    destinationLocation.value = '';
    routeController.clearPathData();
    currentWaypoints.clear();
    isInCrosswalk = false;
    _crosswalkEntryTargetIndex = null;
  }

  // ────────────────────────────────────────────────────────────
  // 8-2. 타이머 Tick 핸들러 (메인 루프)
  // ────────────────────────────────────────────────────────────

  /// 2초마다 호출되는 네비게이션 메인 루프
  Future<void> _onNavigationTick(Timer timer) async {
    if (_tickRunning) return;
    _tickRunning = true;

    try {
      // 0) 도착 체크 (최우선 처리)
      final stopped = await _checkArrivedAndStopIfNeeded(timer);
      if (stopped) {
        navPhase.value = NavPhase.stopped;
        return;
      }

      // 1) 현재 phase 기준으로 필요한 상태만 갱신
      _refreshStateForPhase(navPhase.value);

      // 2) 다음 phase 결정
      final next = _decidePhaseAndReason();

      // 3) phase 반영 (변경 시에만)
      if (next != navPhase.value) {
        debugPrint('NavPhase: ${navPhase.value} -> $next (reason: ${navPhaseReason.value})');
        navPhase.value = next;
        _refreshStateForPhase(navPhase.value);
      }

      // 4) phase별 로직 실행
      await _runPhase(navPhase.value);
    } catch (e, st) {
      debugPrint('Navigation tick error: $e\n$st');
    } finally {
      _tickRunning = false;
    }
  }

  // ────────────────────────────────────────────────────────────
  // 8-3. Phase 결정 및 상태 갱신
  // ────────────────────────────────────────────────────────────

  /// 현재 상태를 기반으로 다음 NavPhase를 결정합니다.
  NavPhase _decidePhaseAndReason() {
    if (_rerouteInFlight) {
      navPhaseReason.value = NavPhaseReason.reroutingLock;
      return NavPhase.rerouting;
    }

    if (!isStart.value) {
      navPhaseReason.value = NavPhaseReason.notStarted;
      return NavPhase.moveToStart;
    }

    if (outOfBound) {
      navPhaseReason.value = NavPhaseReason.outOfBound;
      return NavPhase.outOfBound;
    }

    navPhaseReason.value = NavPhaseReason.normal;
    return NavPhase.navigating;
  }

  /// Phase에 따라 필요한 상태를 갱신합니다.
  void _refreshStateForPhase(NavPhase phase) {
    switch (phase) {
      case NavPhase.moveToStart:
        // 출발 전: 출발 판정만 수행
        checkIsStart();
        break;

      case NavPhase.navigating:
      case NavPhase.outOfBound:
        // 출발 후: 전체 상태 갱신
        checkBoundary();
        indexController.indexUpdate();
        checkIsStart();
        break;

      case NavPhase.rerouting:
        // 재탐색 중: 갱신 최소화
        break;

      case NavPhase.stopped:
        break;
    }
  }

  /// Phase별 실행 로직을 수행합니다.
  Future<void> _runPhase(NavPhase phase) async {
    switch (phase) {
      case NavPhase.moveToStart:
        await _handleStartDeviationRerouteIfNeeded();
        _announceMoveToStart();
        return;

      case NavPhase.navigating:
        await _handleStartDeviationRerouteIfNeeded();
        _updateRemainDistanceToNextBranch();
        await _handleBranchProximityGuidance();
        _announcePoiIfNeeded();
        _vibrateIfHeadingAligned();
        return;

      case NavPhase.outOfBound:
        await _handleOutOfBoundGuidanceAndMaybeTriggerReroute();
        return;

      case NavPhase.rerouting:
        await _runRerouteOnce();
        return;

      case NavPhase.stopped:
        return;
    }
  }

  // ────────────────────────────────────────────────────────────
  // 8-4. 도착 및 출발 체크
  // ────────────────────────────────────────────────────────────

  /// 목적지 도착 여부를 체크하고 도착 시 네비게이션을 종료합니다.
  Future<bool> _checkArrivedAndStopIfNeeded(Timer timer) async {
    if (routeController.branchinfo.isEmpty) return false;

    final destinationDistanceMeters = checkDistanceToDestination();
    final isArrivedNow = checkIsArrived(destinationDistanceMeters);

    if (!isArrivedNow) return false;

    debugPrint('목적지 도착 감지: ${destinationDistanceMeters.toStringAsFixed(2)}m');

    await tts.speakWithChannel(
      '목적지에 도착했습니다.',
      channel: ETtsChannel.NAVIGATE,
      cooldownKey: 'arrive_destination',
      cooldown: const Duration(seconds: 20),
    );

    await stopNavigationTimer();
    timer.cancel();
    return true;
  }

  /// 목적지까지의 거리를 계산합니다. (단위: 미터)
  double checkDistanceToDestination() {
    if (routeController.branchinfo.isEmpty) {
      return double.infinity;
    }
    final destination = routeController.branchinfo.last.point;
    final distance = Calculators.calculateDistance(
      currentLatitude.value,
      currentLongitude.value,
      destination.latitude,
      destination.longitude,
    );

    return (distance * 1000);
  }

  /// 목적지 도착 여부를 판단합니다. (3m 이내)
  bool checkIsArrived(desDis) {
    return desDis < 3.0;
  }

  /// 출발지 도착 여부를 체크하고 상태를 갱신합니다.
  void checkIsStart() {
    if (routeController.branchinfo.isEmpty) return;

    if (isStart.value == false) {
      remainStartpoint = Calculators.calculateDistance(
        currentLatitude.value,
        currentLongitude.value,
        routeController.branchinfo[0].point.latitude,
        routeController.branchinfo[0].point.longitude,
      );

      if (remainStartpoint < 0.015) {
        isStart.value = true;
        isOutOfStart.value = false;
      } else if (remainStartpoint >= 0.05) {
        isOutOfStart.value = true;
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  // 8-5. 경계 체크 및 경로 이탈 처리
  // ────────────────────────────────────────────────────────────

  /// 현재 위치가 경로로부터 얼마나 벗어났는지 확인합니다.
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
    debugPrint('경로로부터 거리: ${distanceToPath.toStringAsFixed(2)}m');
    debugPrint('경계 이탈: $outOfBound');
  }

  /// 경로 이탈 시 안내 및 재탐색 트리거를 처리합니다.
  Future<void> _handleOutOfBoundGuidanceAndMaybeTriggerReroute() async {
    if (!outOfBound) return;

    // 진동 알림
    Vibration.vibrate(duration: 100);

    final List<BranchInfo> branchInfo = routeController.branchinfo;
    if (branchInfo.isEmpty) return;
    if (indexController.currentIndex < 0 || indexController.currentIndex >= branchInfo.length) return;
    if (indexController.targetIndex < 0 || indexController.targetIndex >= branchInfo.length) return;

    // 복귀 방향 안내
    clock = guidanceCalculator.getGuidanceDirection(
      branchInfo[indexController.currentIndex].point.longitude,
      branchInfo[indexController.currentIndex].point.latitude,
      branchInfo[indexController.targetIndex].point.longitude,
      branchInfo[indexController.targetIndex].point.latitude,
      currentLatitude.value,
      currentLongitude.value,
      pdrCalculator.deviationYawTurn,
      branchInfo[indexController.currentIndex].bearingToPoint,
    );

    tts.speakWithChannel(
      clock,
      channel: ETtsChannel.ALERT,
      cooldownKey: 'out_of_bound',
      cooldown: const Duration(seconds: 10),
    );

    // 재탐색 트리거 누적
    if (!searchNewPath) {
      searchNewPathTime = 0;
      return;
    }

    searchNewPathTime++;
    if (searchNewPathTime < 5) return;

    // 5틱 지속 시 rerouting으로 전환
    searchNewPathTime = 0;
    _rerouteInFlight = true;
  }

  // ────────────────────────────────────────────────────────────
  // 8-6. 경로 재탐색 (Rerouting)
  // ────────────────────────────────────────────────────────────

  /// 경로 재탐색을 단일 실행합니다.
  Future<void> _runRerouteOnce() async {
    if (!_rerouteInFlight) return;

    try {
      await _rerouteFromCurrentLocation();

      tts.speakWithChannel(
        "새로운 경로로 안내합니다.",
        channel: ETtsChannel.SYSTEM_ANNOUNCE,
        cooldownKey: 'reroute_done',
        cooldown: const Duration(seconds: 10),
      );
    } finally {
      _rerouteInFlight = false;
      navPhase.value = NavPhase.navigating;
      navPhaseReason.value = NavPhaseReason.normal;
    }
  }

  /// 출발지 이탈(20초 지속) 시 현재 위치를 출발지로 재탐색합니다.
  Future<void> _handleStartDeviationRerouteIfNeeded() async {
    if (!isOutOfStart.value) {
      _startPointDeviationTime = null;
      return;
    }

    _startPointDeviationTime ??= DateTime.now();
    final deviationDuration =
        DateTime.now().difference(_startPointDeviationTime!);

    if (deviationDuration < _startDeviationThreshold) return;

    debugPrint(
      '출발지와 너무 멀어짐. ${_startDeviationThreshold.inSeconds}초 후 자동으로 경로 재검색 수행',
    );

    await _rerouteFromCurrentLocation();

    tts.speakWithChannel(
      '출발지에 벗어나 새로운 경로로 안내합니다.',
      channel: ETtsChannel.NAVIGATE,
      cooldownKey: 'research_out_of_start',
      cooldown: const Duration(seconds: 10),
    );

    debugPrint('출발지를 현재 위치로 변경하고 경로 재검색 완료');
    _startPointDeviationTime = null;
  }

  /// 현재 위치를 출발지로 하여 경로를 재탐색합니다. (경유지 포함)
  Future<void> _rerouteFromCurrentLocation() async {
    final dest = selectedDestLocation.value;
    if (dest == null) {
      debugPrint('_rerouteFromCurrentLocation: 목적지가 null 입니다.');
      return;
    }

    final startLat = currentLatitude.value;
    final startLon = currentLongitude.value;
    final endLat = dest.lat;
    final endLon = dest.lng;

    // 경로 데이터 재로드
    if (currentWaypoints.isNotEmpty) {
      debugPrint('경유지 ${currentWaypoints.length}개 포함 경로 재검색');
      final response = await routeController.loadPathDataWithWaypoints(
        startLat,
        startLon,
        endLat,
        endLon,
        currentWaypoints,
        chooseRoute.value,
      );
      routeController.applyParsePathData(response);
      routeController.checkWaypointsInBranchInfo(currentWaypoints);
    } else {
      final response = await routeController.loadPathData(
        startLat,
        startLon,
        endLat,
        endLon,
        chooseRoute.value,
      );
      routeController.applyParsePathData(response);
    }

    // 재탐색 후 필수 후처리
    routeController.calculatePathBearing();
    indexController.reset(startIndex: 0);

    final safeTargetIndex = 0;
    routeController.resetDeviationYaw(safeTargetIndex, compassValue.value);

    // 오버레이 갱신
    await overlayController.clearOverlays();
    overlayController
      ..addPathOverlays(routeController.paths)
      ..addBranchMarkers();

    debugPrint('_rerouteFromCurrentLocation: 경로 재탐색/파싱/베어링/인덱스 초기화 완료');
  }

  // ────────────────────────────────────────────────────────────
  // 8-7. 안내 및 알림 (Guidance & Notification)
  // ────────────────────────────────────────────────────────────

  /// 출발 전 안내 멘트를 재생합니다.
  void _announceMoveToStart() {
    tts.speakWithChannel(
      "출발지로 이동하세요.",
      channel: ETtsChannel.NAVIGATE,
      cooldownKey: 'move_to_startpoint',
      cooldown: const Duration(seconds: 5),
    );
  }

  /// 다음 브랜치(branch=true)까지의 남은 거리를 갱신합니다.
  void _updateRemainDistanceToNextBranch() {
    final List<BranchInfo> branchInfo = routeController.branchinfo;

    if (branchInfo.isEmpty) {
      remainDistance.value = double.infinity;
      return;
    }

    final target = indexController.targetIndex;
    if (target < 0 || target >= branchInfo.length) {
      debugPrint('_updateRemainDistanceToNextBranch: targetIndex 범위 오류: $target');
      remainDistance.value = double.infinity;
      return;
    }

    // 다음 branch=true 포인트 찾기
    int i = target;
    while (i < branchInfo.length && branchInfo[i].branch != true) {
      i++;
    }

    if (i >= branchInfo.length) {
      remainDistance.value = double.infinity;
      return;
    }

    branchTargetIndex = i;

    remainDistance.value = Calculators.calculateDistance(
      currentLatitude.value,
      currentLongitude.value,
      branchInfo[i].point.latitude,
      branchInfo[i].point.longitude,
    );
  }

  /// 브랜치 근접(15m) 안내 및 횡단보도 구간 경광등을 처리합니다.
  Future<void> _handleBranchProximityGuidance() async {
    final List<BranchInfo> branchInfo = routeController.branchinfo;

    if (branchInfo.isEmpty) return;

    final curIdx = indexController.currentIndex;
    final tgtIdx = indexController.targetIndex;

    if (curIdx < 0 || curIdx >= branchInfo.length) return;
    if (tgtIdx < 0 || tgtIdx >= branchInfo.length) return;

    // 브랜치 근접 기준: 15m (0.015km)
    final bool isNear = remainDistance.value < 0.015;
    if (!isNear) return;

    final currentBranch = branchInfo[curIdx];
    final targetBranch = branchInfo[tgtIdx];

    // 횡단보도 진입 처리
    if (!isInCrosswalk &&
        (currentBranch.crosswalk == true || targetBranch.crosswalk == true)) {
      isInCrosswalk = true;
      _crosswalkEntryTargetIndex = tgtIdx;
      debugPrint('횡단보도 구간 진입 (targetIndex: $tgtIdx)');

      final result = await flashOnWithWeather(NoParams());
      if (result.isLeft()) {
        debugPrint('안전 경광등을 사용할 수 없습니다.');
      } else {
        debugPrint('안전 경광등이 켜졌습니다.');
      }

      tts.speakWithChannel(
        '잠시 후 횡단보도 입니다. 차량에 유의하세요!',
        channel: ETtsChannel.ALERT,
        cooldownKey: 'crosswalk_alert',
        cooldown: const Duration(seconds: 2),
      );
    }

    // 횡단보도 탈출 처리
    if (isInCrosswalk &&
        _crosswalkEntryTargetIndex != null &&
        curIdx > _crosswalkEntryTargetIndex!) {
      isInCrosswalk = false;
      debugPrint('횡단보도 구간 탈출 (curIdx: $curIdx, entryTargetIdx: $_crosswalkEntryTargetIndex)');
      _crosswalkEntryTargetIndex = null;

      final result = await flashOff(NoParams());
      if (result.isLeft()) {
        debugPrint('경광등을 끌 수 없습니다.');
      } else {
        debugPrint('경광등이 꺼졌습니다.');
      }
    }

    // 분기 안내
    if (targetBranch.branch == true) {
      final message = targetBranch.description;
      tts.speakWithChannel(
        '$message하세요.',
        channel: ETtsChannel.NAVIGATE,
        cooldownKey: 'branch_instruction',
        cooldown: const Duration(seconds: 10),
      );
    }
  }

  /// POI 안내를 수행합니다. (20초에 1번)
  void _announcePoiIfNeeded() {
    final now = DateTime.now();
    if (_lastPoiAnnouncementTime == null ||
        now.difference(_lastPoiAnnouncementTime!).inSeconds >= 20) {
      _lastPoiAnnouncementTime = now;

      locationAnnouncementController.announceNearbyBuilding(
        currentLatitude.value,
        currentLongitude.value,
        fusedHeading,
      );
    }
  }

  /// 경로 진행 방향 정렬 시 진동 피드백을 제공합니다. (±18도)
  void _vibrateIfHeadingAligned() {
    final List<BranchInfo> branchInfo = routeController.branchinfo;
    if (branchInfo.isEmpty) return;

    final curIdx = indexController.currentIndex;
    if (curIdx <= 0 || curIdx >= branchInfo.length) return;

    final bearing = branchInfo[curIdx].bearingToPoint;
    final diff = (bearing - compassValue.value).abs();

    if (diff <= 18 || diff >= 342) {
      Vibration.vibrate(duration: 500);
      debugPrint("경로내 진동 베어링 값 ${bearing - compassValue.value}");
    }
  }

  // ────────────────────────────────────────────────────────────
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
    if (!isGpsAccurate.value) {
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
