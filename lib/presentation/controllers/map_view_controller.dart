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
  /// API 서비스 (경로 데이터 요청 등)
  final NavigationApiService apiService = DI.get<NavigationApiService>();

  /// TTS 서비스 (텍스트를 음성으로 변환)
  final TtsService ttsService = DI.get<TtsService>();

  /// 주어진 텍스트를 음성으로 출력합니다.
  Future<void> speakText(String text) async {
    await ttsService.speak(text);
  }

  /// 네이버 맵 컨트롤러 (지도 업데이트 및 오버레이 추가에 사용)
  late NaverMapController? mapController;

  /// 현재 지도 모드를 Reactive 변수로 관리합니다.
  Rx<MapControlMode> mapMode = MapControlMode.idle.obs;

  // 지도 고정 시 현재 지도 방향을 저장하는 변수
  double? _currentBearing;

  /// 로딩 상태를 나타내는 Reactive 변수입니다.
  RxBool isLoading = true.obs;

  /// 현재 위도 (초기값: 37.4865) - 가톨릭대학교 위도
  RxDouble current_latitude = 37.4865.obs;

  /// 현재 경도 (초기값: 126.8018) - 가톨릭대학교 경도
  RxDouble current_longitude = 126.8018.obs;

  /// 커스텀 시작 위도 (초기값: 37.4865) - 가톨릭대학교 위도
  RxDouble cameraStartLat = 37.4865.obs;

  /// 커스텀 시작 경도 (초기값: 126.8018) - 가톨릭대학교 경도
  RxDouble cameraStartLng = 126.8018.obs;

  /// 출발지 또는 목적지 설정 모드 (start: 출발지 설정, dest: 목적지 설정, none: 없음)
  RxString settingMode = 'none'.obs;

  /// 경로 안내 시 남은 거리를 나타내는 Reactive 변수입니다.
  RxDouble remain_distance = double.infinity.obs;

  /// 선택된 시작 위치
  Rxn<GeoLocation> selectedStartLocation = Rxn<GeoLocation>();

  /// 선택된 목적지 위치
  Rxn<GeoLocation> selectedDestLocation = Rxn<GeoLocation>();

  /// 검색창에 표시할 시작 위치 문자열
  RxString searchLocation = ''.obs;

  /// 검색창에 표시할 목적지 문자열
  RxString destinationLocation = ''.obs;

  /// 경로선택
  RxString choose_route = ''.obs; 

  /// 경로의 좌표 리스트
  List<LatLng> paths = [];

  /// 분기(체크포인트) 정보를 담은 리스트
  List<BranchInfo> branchinfo = [];

  /// 시작 위치가 설정되었는지 여부
  RxBool isStart = false.obs;

  /// 시작 위치가 설정되었음을 나타내는 Reactive 변수
  RxBool isSetStartLocation = false.obs;

  /// 목적지 위치가 설정되었음을 나타내는 Reactive 변수
  RxBool isSetDestinationLocation = false.obs;

  /// 출발지와 목적지 사이의 남은 거리를 나타내는 변수
  late double remain_startpoint;

  /// 분기(체크포인트) 인덱스 관리 변수
  int currentIndex = 0;
  int targetIndex = 0;
  int branchTargetIndex = 0;

  /// 네이티브 위치 데이터 (디버깅용)
  late double s_latitude;
  late double s_longitude;
  late double s_accuracy;

  /// Flash 제어 서비스 (외부 플래시 장치 제어)
  final ControlFlash flashOnWithWeather = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_ON_WITH_WEATHER,
  );

  /// 위치 업데이트 타이머
  Timer? _locationUpdateTimer;

  /// 현재 위치 마커
  NMarker? _currentLocationMarker;

  /// 테스트용 마커 (분기/체크포인트 디버깅용)
  NMarker? _testMarker;

  /// 나침반 데이터 수신 완료 여부를 판단하기 위한 Completer
  Completer<void> compassReady = Completer<void>();

  // 가속도 관련 변수
  double preAccX = 0.0, preAccY = 0.0;
  double currentpreAccX = 0.0, currentpreAccY = 0.0;

  // 속도 관련 변수 (가속도 적분)
  double velocityX = 0.0, velocityY = 0.0, currentSpeed = 0.0;

  // 방향 관련 변수
  late double? heading;
  double? adjustment;
  double yawRate = 0.0,
      yawRate2 = 0.0,
      yawRatePerDt = 0.0,
      yawRateVelocity = 0.0;
  RxDouble compassValue = 0.0.obs;
  double yawRateTurn = 0.0,
      yawRateTurn2 = 0.0,
      turn = 0.0,
      firstBearingToPoint = 0.0;
  String clock = "";

  // 이동 거리 계산 변수
  double px = 0.0, py = 0.0;
  double distanceToPath = 0.0,
      circularDistance = 0.0,
      lineDistance = 0.0,
      nearestDistance = 0.0;

  // 초기 위치 (GPS 기준)
  double initialLatitude = 35.9078, initialLongitude = 127.7669;
  late double beforeLatitude, beforeLongitude;

  // 상수들
  double accFilteringValue = 0.06;
  double radianToAngle = (180 / math.pi);
  double angleToRadian = (math.pi / 180);
  double yawRateAccFilteringValue = 0.3;
  double detectiveRange = 0.5;
  double iphone12Filter = ((1 / 130) * (math.pi / 180));

  // 경계 및 재경로 검색 관련 변수들
  bool outOfBound = false;
  double boundary = 5;
  bool searchNewPath = false;
  double searchNewPathBoundary = 15;
  int searchNewPathTime = 0;
  double distanceToNextCheckpoint = double.maxFinite;
  int searchStartNewPathTime = 0;  //검색시작 새로운경로시간

  /// GPS 신호 사용 여부
  bool isGps = true;

  /// 앱 실행 후 GPS 수신도 낮을때 출발지 위치 조정 멘트(한번만)
  bool ShowLowGpsAlertOnce = false;
  RxBool showLowAccuracyDialog = false.obs;

  /// 커스텀 시작 지점 사용 여부
  RxBool isCustomStartPoint = false.obs;

  /// 경계 조건 문자열 (디버깅용)
  String checkBoudaryCondition = "";

  // IMU 데이터를 기반으로 계산된 새로운 위경도 값
  double newlatitude = 0.0, newlongitude = 0.0;

  /// 가중 이동평균 필터 인스턴스 (X축)
  final WeightedAverageFilter _filteringX =
      WeightedAverageFilter(5, [0.1, 0.2, 0.3, 0.4, 0.5]);

  /// 가중 이동평균 필터 인스턴스 (Y축)
  final WeightedAverageFilter _filteringY =
      WeightedAverageFilter(5, [0.1, 0.2, 0.3, 0.4, 0.5]);

  /// 센서 스트림 구독들을 보관하는 리스트입니다.
  final List<StreamSubscription<dynamic>> _streamSubscriptions = [];

  /// onInit: 컨트롤러 초기화 시 호출되며, 위치 업데이트, 센서 데이터 수집 등 초기 설정을 수행합니다.
  @override
  void onInit() {
    super.onInit();

    // _getLocation();
    // _initLocation();
    // startCollectingSensorData();

    // // 나침반 데이터 수신이 완료되면 다시 _initLocation 호출
    // compassReady.future.then((_) {
    //   _initLocation();
    // });
       _initializeLocationServices();
  }

  /// 위치 서비스 초기화를 안전하게 수행합니다.
  Future<void> _initializeLocationServices() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          // 기본 위치로 설정 (가톨릭대학교)
          current_latitude.value = 37.4865;
          current_longitude.value = 126.8018;
          isLoading.value = false;
          return;
        }
      }

      // 위치 서비스가 활성화되어 있는지 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('위치 서비스가 비활성화되어 있습니다.');
        current_latitude.value = 37.4865;
        current_longitude.value = 126.8018;
        isLoading.value = false;
        return;
      }

      await _initLocation();
      startCollectingSensorData();
    } catch (e) {
      debugPrint('위치 서비스 초기화 실패: $e');
      current_latitude.value = 37.4865;
      current_longitude.value = 126.8018;
      isLoading.value = false;
    }
  }

  /// addYawRateNoise: 센서 측정값에 포함된 잡음을 보정합니다.
  /// [addValue]: 보정 값.
  /// Returns the adjusted value.
  double addYawRateNoise(double addValue) {
    return addValue;
  }

  /// resetSpeedUtilsValue: 경로 재설정 시 속도, 방향, 위치 계산 관련 변수를 초기화합니다.
  void resetSpeedUtilsValue() {
    yawRatePerDt = 0;
    yawRate = compassValue * angleToRadian;
    px = 0.0;
    py = 0.0;
  }

  /// yawRateupdate: 자이로스코프 이벤트로부터 회전 속도를 계산하여 업데이트합니다.
  /// [event]: GyroscopeEvent 데이터.
  /// [sensorInterval]: 센서 업데이트 간격.
  void yawRateupdate(GyroscopeEvent event, Duration sensorInterval) {
    double dt = sensorInterval.inMilliseconds / 1000.0;
    if (event.z > yawRateAccFilteringValue * angleToRadian ||
        event.z < -yawRateAccFilteringValue * angleToRadian) {
      yawRatePerDt = (event.z * dt);
    }
    yawRate += -(yawRatePerDt + addYawRateNoise(0));
    if (yawRate >= 2 * math.pi || yawRate <= -2 * math.pi) {
      yawRate = 0;
    }
    yawRate2 += -(yawRatePerDt + addYawRateNoise(0));
    if (yawRate2 >= 2 * math.pi || yawRate2 <= -2 * math.pi) {
      yawRate2 = 0;
    }
    yawRateTurn2 = yawRate2 * radianToAngle;
  }

  /// positionUpdate: 가속도 이벤트를 기반으로 속도와 위치를 업데이트합니다.
  /// [event]: UserAccelerometerEvent 데이터.
  /// [sensorInterval]: 센서 업데이트 간격.
  void positionUpdate(UserAccelerometerEvent event, Duration sensorInterval) {
    double dt = sensorInterval.inMilliseconds / 1000.0;
    currentpreAccX = event.x;
    currentpreAccY = event.y;
    if (currentpreAccX > accFilteringValue ||
        currentpreAccX < -accFilteringValue) {
      velocityX += (currentpreAccX - preAccX) * dt;
      preAccX = currentpreAccX;
    } else {
      velocityX = 0;
    }
    if (currentpreAccY > accFilteringValue ||
        currentpreAccY < -accFilteringValue) {
      velocityY += (currentpreAccY - preAccY) * dt;
      preAccY = currentpreAccY;
    } else {
      velocityY = 0;
    }
    _filteringX.enqueue(velocityX);
    _filteringY.enqueue(velocityY);
    currentSpeed = math.sqrt(velocityX * velocityX + velocityY * velocityY);
    px += (currentSpeed * math.cos(yawRate));
    py += (currentSpeed * math.sin(yawRate));
    double distanceKm = math.sqrt(px * px + py * py) / 1000.0;
    double bearing = math.atan2(py, px) * radianToAngle;
    Map<String, double> latLng =
        calLatLng(initialLatitude, initialLongitude, bearing, distanceKm);
    newlatitude = latLng['latitude']!;
    newlongitude = latLng['longitude']!;
  }

  /// calLatLng: 시작 좌표, 베어링, 이동 거리를 기반으로 새로운 위경도를 계산합니다.
  /// [startLat]: 시작 위도.
  /// [startLng]: 시작 경도.
  /// [bearing]: 이동 방향 (도 단위).
  /// [distanceKm]: 이동 거리 (킬로미터).
  /// Returns a map with keys 'latitude' and 'longitude'.
  Map<String, double> calLatLng(
      double startLat, double startLng, double bearing, double distanceKm) {
    const double earthRadiusKm = 6371.0;
    double startLatRad = _degreesToRadians(startLat);
    double startLngRad = _degreesToRadians(startLng);
    double bearingRad = _degreesToRadians(bearing);
    double distanceRad = distanceKm / earthRadiusKm;
    double newLatRad = math.asin(math.sin(startLatRad) * math.cos(distanceRad) +
        math.cos(startLatRad) * math.sin(distanceRad) * math.cos(bearingRad));
    double newLngRad = startLngRad +
        math.atan2(
            math.sin(bearingRad) *
                math.sin(distanceRad) *
                math.cos(startLatRad),
            math.cos(distanceRad) -
                math.sin(startLatRad) * math.sin(newLatRad));
    double newLat = _radiansToDegrees(newLatRad);
    double newLng = _radiansToDegrees(newLngRad);
    return {'latitude': newLat, 'longitude': newLng};
  }

  /// _degreesToRadians: 도 단위를 라디안으로 변환합니다.
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// _radiansToDegrees: 라디안 단위를 도로 변환합니다.
  double _radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  /// onClose: 컨트롤러 종료 시 타이머 및 센서 스트림 구독을 취소합니다.
  @override
  void onClose() {
    _locationUpdateTimer?.cancel();
    _streamSubscriptions.forEach((subscription) => subscription.cancel());
    super.onClose();
  }

  /// _initLocation: GPS 및 IMU 데이터를 기반으로 초기 위치를 설정하고,
  /// 주기적으로 위치 업데이트를 수행하는 타이머를 시작합니다.
  Future<void> _initLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
    current_latitude.value = position.latitude;
    current_longitude.value = position.longitude;
    initialLatitude = current_latitude.value;
    initialLongitude = current_longitude.value;
    beforeLatitude = current_latitude.value;
    beforeLongitude = current_longitude.value;
    yawRate = compassValue.value * angleToRadian;
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      s_accuracy = position.accuracy;
      _getLocation();
    });
  }

  /// _getLocation: 현재 위치를 가져와 센서 데이터와 지도 업데이트를 수행합니다.
  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      // GPS 정확도에 따라 출발지 안내 멘트 유/무
      if (!ShowLowGpsAlertOnce && position.accuracy >= 15) {
      ShowLowGpsAlertOnce = true;    // 중복 표시 방지 플래그
      showLowAccuracyDialog.value = true;  // 알림 다이얼로그 표시 신호
    }

      if (position.accuracy >= 15) {
        isGps = false;      // GPS 신호 불량
        velocityX = _filteringX.calculateWeightedAverage();
        velocityY = _filteringY.calculateWeightedAverage();
        current_latitude.value = newlatitude; // 센서 계산 위도
        current_longitude.value = newlongitude; // 센서 계산 경도
        isLoading.value = false;
      } else {
        isGps = true;      // GPS 신호 정상
        current_latitude.value = position.latitude; //  GPS 위도
        current_longitude.value = position.longitude; //  GPS 경도
        initialLatitude = current_latitude.value;
        initialLongitude = current_longitude.value;
        resetSpeedUtilsValue();
        isLoading.value = false;
      }
      onSensorUpdate(
        current_latitude.value,
        current_longitude.value,
        compassValue.value,
        isGps,
      );
    } catch (e) {
      print("현위치 수신에러 $e");
      isLoading.value = false;
    }
  }

  // 경로 API 호출
  Future<void> loadPathData(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
    String choose_route,
  ) async {
    try {
      final responseData = await apiService.fetchPathData(
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
        choose_route: choose_route,
      );

      /// 데이터 파싱
      final parsedData = apiService.parsePathData(responseData);
      final parsedPath = parsedData['paths'] as List<LatLng>;
      final parsedBranchInfos = parsedData['branchInfo'] as List<BranchInfo>;

      /// 데이터 로깅
      debugPrint('paths: $parsedPath');
      debugPrint('branchInfoList: $parsedBranchInfos');

      // 브랜치 정보 업데이트 (각 브랜치 간의 방향 계산)
      // 주기적으로 Timer를 실행하기 전에 먼저 방향값을 초기화 해준다.
      // branchinfo 배열을 순회하면서 bearingTobranch 값을 변경합니다.
      for (int i = 0; i < parsedBranchInfos.length - 1; i++) {
        double newBearingValue = calculateBearing(
          parsedBranchInfos[i].point.latitude,
          parsedBranchInfos[i].point.longitude,
          parsedBranchInfos[i + 1].point.latitude,
          parsedBranchInfos[i + 1].point.longitude,
        );
        parsedBranchInfos[i].bearingToPoint = newBearingValue;
      }

      paths = parsedPath;
      branchinfo = parsedBranchInfos;

      yawRate2 = turnUpdate2(
              branchinfo[targetIndex].bearingToPoint, compassValue.value) *
          angleToRadian;

      await mapController!.clearOverlays(type: NOverlayType.marker);
      addOverlays(paths);
      addBranchMarkers();

      startNavigationTimer();
    } catch (e) {
      debugPrint('Failed to load path data : $e');
    }
  }

  /// addOverlays: 지도에 경로 오버레이를 추가합니다.
  /// [paths]: 경로를 나타내는 LatLng 리스트.
  void addOverlays(List<LatLng> paths) {
    if (mapController == null) return;
    Set<NAddableOverlay> overlays = {
      NMultipartPathOverlay(
        id: "path",
        paths: [
          NMultipartPath(
            coords: paths
                .map((coord) => NLatLng(coord.latitude, coord.longitude))
                .toList(),
            outlineColor: Colors.blue,
          ),
        ],
        outlineWidth: 3,
      ),
    };
    mapController!.addOverlayAll(overlays);
  }

  /// addBranchMarkers: 지도에 분기(체크포인트) 마커들을 추가합니다.
  void addBranchMarkers() async {
    if (mapController == null) return;
    Set<NAddableOverlay> markers = {};
    final iconImage = await NOverlayImage.fromWidget(
      widget: Icon(Icons.circle, color: Colors.green, size: 15),
      size: const Size(15, 15),
      context: navigatorKey.currentContext!,
    );
    for (var branch in branchinfo) {
      _testMarker = NMarker(
        id: 'checkPoint_${branchinfo.indexOf(branch)}',
        position: NLatLng(branch.point.latitude, branch.point.longitude),
        icon: iconImage,
      );
      markers.add(_testMarker!);
    }
    mapController!.addOverlayAll(markers);
  }

  /// calculateDistance: 두 지점 간의 거리를 haversine 공식을 사용하여 계산합니다.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0;
    double toRadians(double degree) => degree * math.pi / 180.0;
    double dLat = toRadians(lat2 - lat1);
    double dLon = toRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRadians(lat1)) *
            math.cos(toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// calculateBearing: 두 지점 간의 방향(베어링)을 계산합니다.
  double calculateBearing(double current_latitude, double current_longitude,
      double target_latitude, double target_longitude) {
    double lat1 = current_latitude * math.pi / 180;
    double lon1 = current_longitude * math.pi / 180;
    double lat2 = target_latitude * math.pi / 180;
    double lon2 = target_longitude * math.pi / 180;
    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x);
    double bearingDegrees = bearing * 180 / math.pi;
    if (bearingDegrees < 0) bearingDegrees += 360;
    return bearingDegrees;
  }

  /// _degToRad: 도 단위를 라디안으로 변환합니다.
  double _degToRad(double degrees) => degrees * math.pi / 180;

  /// _haversine: haversine 공식을 사용하여 두 지점 사이의 거리를 미터 단위로 계산합니다.
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  /// pointLineDistance: 한 점과 선분 사이의 최단 거리를 계산합니다.
  double pointLineDistance(double lat1, double lon1, double lat2, double lon2,
      double latP, double lonP) {
    double dist12 = _haversine(lat1, lon1, lat2, lon2);
    double dist1P = _haversine(lat1, lon1, latP, lonP);
    double dist2P = _haversine(lat2, lon2, latP, lonP);
    double A = dist1P / 6371e3, B = dist2P / 6371e3, C = dist12 / 6371e3;
    double angleP12 = math.acos((math.cos(A) - math.cos(B) * math.cos(C)) /
        (math.sin(B) * math.sin(C)));
    return math.sin(angleP12) * dist1P;
  }

  /// subscribeToSensor: 센서 스트림을 구독하고, 에러 발생 시 처리 후 내부 리스트에 추가합니다.
  void subscribeToSensor<T>({
    required Stream<T> sensorStream,
    required Function(T event) onEvent,
    required Function(dynamic error) onError,
  }) {
    var subscription =
        sensorStream.listen(onEvent, onError: onError, cancelOnError: true);
    _streamSubscriptions.add(subscription);
  }

  /// showErrorDialog: 센서가 지원되지 않을 때 기본 다이얼로그를 표시합니다.
  void showErrorDialog(String sensorName) {
    Get.defaultDialog(
      title: "$sensorName Sensor Not Found",
      middleText:
          "It seems that your device doesn't support the $sensorName sensor.",
    );
  }

  /// startCollectingSensorData: Compass, Accelerometer, Gyroscope 센서 데이터를 구독합니다.
  void startCollectingSensorData() {
    subscribeToSensor<CompassEvent>(
      sensorStream: FlutterCompass.events!,
      onEvent: (event) {
        heading = event.heading ?? 0.0;
        compassValue.value = heading!;
        if (!compassReady.isCompleted) {
          compassReady.complete();
        }
      },
      onError: (e) {
        showErrorDialog("Flutter_Compass");
      },
    );
    subscribeToSensor<UserAccelerometerEvent>(
      sensorStream: userAccelerometerEventStream(
          samplingPeriod: Duration(milliseconds: 20)),
      onEvent: (event) {
        positionUpdate(event, Duration(milliseconds: 20));
      },
      onError: (e) {
        showErrorDialog("userAccerometer Sensor");
      },
    );
    subscribeToSensor<GyroscopeEvent>(
      sensorStream:
          gyroscopeEventStream(samplingPeriod: Duration(milliseconds: 20)),
      onEvent: (GyroscopeEvent event) {
        yawRateupdate(event, Duration(milliseconds: 20));
      },
      onError: (e) {
        showErrorDialog("Gyroscope Sensor");
      },
    );
  }

  /// stopCollectingSensorData: 모든 센서 스트림 구독을 취소합니다.
  void stopCollectingSensorData() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
  }

  /// getCurrentWindow: branchinfo 리스트에서 현재 인덱스를 중심으로 주어진 창 크기의 서브셋을 반환합니다.
  /// [branchinfo]: 전체 branch 정보 리스트.
  /// [currentIndex]: 현재 인덱스.
  /// [windowsize]: 반환할 창의 크기.
  List<BranchInfo> getCurrentWindow(
      List<BranchInfo> branchinfo, int currentIndex, int windowsize) {
    int windowOffset = (windowsize - 1) ~/ 2;
    int start = currentIndex - windowOffset;
    int end = currentIndex + windowOffset;
    start = start < 0 ? 0 : start;
    end = end >= branchinfo.length ? branchinfo.length - 1 : end;
    List<BranchInfo> window = [];
    for (int i = start; i <= end; i++) {
      window.add(branchinfo[i]);
    }
    return window;
  }

  /// _distanceBetweenBranch: 두 branch 정보 지점 사이의 거리를 계산합니다.
  double _distanceBetweenBranch(
      List<BranchInfo> branchInfo, int currentIndex, int targetIndex) {
    double currentIndex_latitude = branchInfo[currentIndex].point.latitude;
    double currentIndex_longitude = branchInfo[currentIndex].point.longitude;
    double targetIndex_latitude = branchInfo[targetIndex].point.latitude;
    double targetIndex_longitude = branchInfo[targetIndex].point.longitude;
    return calculateDistance(currentIndex_latitude, currentIndex_longitude,
        targetIndex_latitude, targetIndex_longitude);
  }

  /// moveIndex: 현재 창 내에서 센서 데이터에 따라 가장 적합한 branch 인덱스를 반환합니다.
  int moveIndex(List<BranchInfo> currentWindow) {
    double beforeMin = double.maxFinite;
    int nearestIndex = currentIndex;
    double distanceBetweenBranch =
        _distanceBetweenBranch(branchinfo, currentIndex, targetIndex);
    if (distanceBetweenBranch == 0) {
      nearestIndex = targetIndex;
    }
    double currentDistance = 0.0;
    for (BranchInfo branchInfo in currentWindow) {
      currentDistance = calculateDistance(
        branchInfo.point.latitude,
        branchInfo.point.longitude,
        current_latitude.value,
        current_longitude.value,
      );
      double currentIndexDistance = calculateDistance(
        branchinfo[nearestIndex].point.latitude,
        branchinfo[nearestIndex].point.longitude,
        current_latitude.value,
        current_longitude.value,
      );
      if (currentDistance < beforeMin &&
          currentIndexDistance >=
              distanceBetweenBranch - (distanceBetweenBranch / 20)) {
        beforeMin = currentDistance;
        nearestIndex = branchinfo.indexOf(branchInfo);
      }
    }
    return nearestIndex;
  }

  /// indexUpdate: 현재 센서 데이터 기반으로 분기 인덱스를 업데이트합니다.
  void indexUpdate() {
    List<BranchInfo> currentWindow =
        getCurrentWindow(branchinfo, currentIndex, 5);
    int nearestIndex = moveIndex(currentWindow);
    if (nearestIndex >= 0 && nearestIndex < branchinfo.length && nearestIndex != currentIndex) {
      debugPrint('인덱스가 변경되었습니다. 새로운 인덱스: $nearestIndex');
      currentIndex = nearestIndex;
      yawRate2 = turnUpdate2(
              branchinfo[currentIndex].bearingToPoint, compassValue.value) *
          angleToRadian;
      debugPrint("각도 초기화");
    }
  }

  /// deg2rad: 도(degree)를 라디안(radian)으로 변환합니다.
  double deg2rad(double deg) => deg * (math.pi / 180);

  /// sphericalDistance: 두 점 사이의 구면 거리를 계산합니다.
  /// (구면 삼각법을 사용하여 계산합니다.)
  double sphericalDistance(
          double lat1, double lon1, double lat2, double lon2) =>
      math.acos(math.sin(lat1) * math.sin(lat2) +
          math.cos(lat1) * math.cos(lat2) * math.cos(lon2 - lon1));

  /// sphericalAngle: 구면 삼각법을 사용하여 세 변의 길이가 주어졌을 때 각도를 계산합니다.
  double sphericalAngle(double a, double b, double c) => math.acos(
      (math.cos(a) - math.cos(b) * math.cos(c)) / (math.sin(b) * math.sin(c)));

  /// rad2deg: 라디안(radian)을 도(degree)로 변환합니다.
  double rad2deg(double rad) => rad * (180 / math.pi);

  /// turnUpdate2: 목표 방향과 현재 나침반 값의 차이를 계산하여 회전 보정 값을 구합니다.
  double turnUpdate2(double bearingToPoint, double compassValue) {
    return compassValue - bearingToPoint;
  }

  /// latLonToXY: 위도 및 경도 차이를 기반으로 x, y 거리(미터)를 계산합니다.
  /// (평균 위도를 이용하여 단순 근사 계산)
  Map<String, double> latLonToXY(
      double currentIndexLatitude,
      double currentIndexLongitude,
      double targetIndexLatitude,
      double targetIndexLongitude) {
    double deltaLat = targetIndexLatitude - currentIndexLatitude;
    double deltaLon = targetIndexLongitude - currentIndexLongitude;
    double avgLat = (currentIndexLatitude + targetIndexLatitude) / 2.0;
    double x = deltaLon * 111320 * math.cos(avgLat * math.pi / 180);
    double y = deltaLat * 111320;
    return {'x': x, 'y': y};
  }

  /// checkLateralDeviation: 현재 지점에서 목표 지점까지의 벡터와 현재 지점에서 현재 위치까지의 벡터의 외적을 통해
  /// 좌우 편차(측면 이탈)를 판단합니다.
  /// 외적 값이 양이면 왼쪽, 음이면 오른쪽, 0이면 일직선입니다.
  int checkLateralDeviation(
      double currentIndexLatitude,
      double currentIndexLongitude,
      double targetIndexLatitude,
      double targetIndexLongitude,
      double currentLatitude,
      double currentLongitude) {
    Map<String, double> pathVector = latLonToXY(currentIndexLatitude,
        currentIndexLongitude, targetIndexLatitude, targetIndexLongitude);
    Map<String, double> currentVector = latLonToXY(currentIndexLatitude,
        currentIndexLongitude, currentLatitude, currentLongitude);
    double crossProduct = pathVector['x']! * currentVector['y']! -
        pathVector['y']! * currentVector['x']!;
    if (crossProduct > 0) return -1;
    if (crossProduct < 0) return 1;
    return 0;
  }

  /// breakPoint: 현재 지점(브랜치), 현재 위치, 목표 지점으로 이루어진 삼각형의 각도를 계산합니다.
  /// 반환값은 'breakPointAngleA', 'breakPointAngleB', 'breakPointAngleC'라는 키를 갖는 Map입니다.
  Map<String, double> breakPoint(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double current_latitude,
      double current_longitude) {
    double lat1 = deg2rad(currentIndexLatitude);
    double lon1 = deg2rad(currentIndexLongitude);
    double lat2 = deg2rad(current_latitude);
    double lon2 = deg2rad(current_longitude);
    double lat3 = deg2rad(targetIndexLatitude);
    double lon3 = deg2rad(targetIndexLongitude);
    double a = sphericalDistance(lat2, lon2, lat3, lon3);
    double b = sphericalDistance(lat3, lon3, lat1, lon1);
    double c = sphericalDistance(lat1, lon1, lat2, lon2);
    double A = sphericalAngle(a, b, c);
    double B = sphericalAngle(b, a, c);
    double C = sphericalAngle(c, a, b);
    return {
      'breakPointAngleA': A,
      'breakPointAngleB': B,
      'breakPointAngleC': C
    };
  }

  /// angleToTarget: 센서 데이터에 기반하여 목표 브랜치까지의 안내 각도를 계산합니다.
  /// [yawRateTurn2]: 센서 데이터에 의한 회전 보정 값.
  /// [bearingToPoint]: 현재 브랜치에서 목표 브랜치까지의 방향.
  /// [boundaryExit]: 측면 이탈 여부 (좌우 편차 결과).
  double angleToTarget(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double current_latitude,
      double current_longitude,
      double yawRateTurn2,
      double bearingToPoint,
      int boundaryExit) {
    Map<String, double> breakPointAngle = breakPoint(
        currentIndexLongitude,
        currentIndexLatitude,
        targetIndexLongitude,
        targetIndexLatitude,
        current_latitude,
        current_longitude);
    double guidanceAngle = 0.0;
    if (boundaryExit > 0) {
      double baseAngle = (breakPointAngle['breakPointAngleC']! * radianToAngle);
      guidanceAngle = (baseAngle + yawRateTurn2) % 360;
    } else {
      double baseAngle = (breakPointAngle['breakPointAngleC']! * radianToAngle);
      guidanceAngle = (baseAngle - yawRateTurn2) % 360;
    }
    return guidanceAngle;
  }

  /// getGuidanceDirection: 안내 각도를 기반으로 방향 라벨(예: "12시 방향")을 반환합니다.
  String getGuidanceDirection(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double current_latitude,
      double current_longitude,
      double yawRateTurn2,
      double bearingToPoint) {
    int boundaryExit = checkLateralDeviation(
        currentIndexLatitude,
        currentIndexLongitude,
        targetIndexLatitude,
        targetIndexLongitude,
        current_latitude,
        current_longitude);
    double guidanceAngle = angleToTarget(
        currentIndexLongitude,
        currentIndexLatitude,
        targetIndexLongitude,
        targetIndexLatitude,
        current_latitude,
        current_longitude,
        yawRateTurn2,
        bearingToPoint,
        boundaryExit);
    if (guidanceAngle > 180) guidanceAngle -= 360;
    int direction = ((guidanceAngle + 15) % 360) ~/ 30;
    List<String> directionLabels = (boundaryExit > 0)
        ? [
            '12시 방향',
            '11시 방향',
            '10시 방향',
            '9시 방향',
            '8시 방향',
            '7시 방향',
            '6시 방향',
            '5시 방향',
            '4시 방향',
            '3시 방향',
            '2시 방향',
            '1시 방향'
          ]
        : [
            '12시 방향',
            '1시 방향',
            '2시 방향',
            '3시 방향',
            '4시 방향',
            '5시 방향',
            '6시 방향',
            '7시 방향',
            '8시 방향',
            '9시 방향',
            '10시 방향',
            '11시 방향'
          ];
    return directionLabels[direction];
  }

  /// checkBoundary: 현재 위치가 경로(분기)로부터 얼마나 벗어났는지 확인합니다.
  /// 경로 이탈, 재경로 탐색 등의 조건을 판단합니다.
  void checkBoundary() {
    List<BranchInfo> currentWindow =
        getCurrentWindow(branchinfo, currentIndex, 5);
    double beforeMinDistanceToPath = double.maxFinite;
    for (int i = 0; i < currentWindow.length - 1; i++) {
      var currentWindowValue = currentWindow[i];
      targetIndex = currentIndex + 1;
      if (currentWindowValue.branch == true) {
        circularDistance = calculateDistance(
                currentWindowValue.point.latitude,
                currentWindowValue.point.longitude,
                current_latitude.value,
                current_longitude.value) *
            1000;
        checkBoudaryCondition = "정방향, 브랜치";
        lineDistance = pointLineDistance(
            currentWindowValue.point.latitude,
            currentWindowValue.point.longitude,
            currentWindow[i + 1].point.latitude,
            currentWindow[i + 1].point.longitude,
            current_latitude.value,
            current_longitude.value);
        checkBoudaryCondition = "정방향, 직선";
        distanceToPath = math.min(circularDistance, lineDistance);
      } else if (currentWindowValue.branch == false) {
        distanceToPath = pointLineDistance(
            currentWindowValue.point.latitude,
            currentWindowValue.point.longitude,
            currentWindow[i + 1].point.latitude,
            currentWindow[i + 1].point.longitude,
            current_latitude.value,
            current_longitude.value);
        checkBoudaryCondition = "정방향, 직선";
      }
      if (beforeMinDistanceToPath > distanceToPath) {
        beforeMinDistanceToPath = distanceToPath;
      }
      if (beforeMinDistanceToPath > boundary) {
        outOfBound = true;
      } else {
        outOfBound = false;
      }
      if (beforeMinDistanceToPath > searchNewPathBoundary) {
        searchNewPath = true;
      } else {
        searchNewPath = false;
      }
    }
  }

  /// updateMapPosition: 지도 카메라를 현재 위치 및 모드에 따라 업데이트합니다.
  /// [current_latitude]: 현재 위도.
  /// [current_longitude]: 현재 경도.
  /// [compassValue]: 현재 나침반 값.
  void updateMapPosition(
      double current_latitude, double current_longitude, double compassValue) {
    if (mapController == null) return;

    // on1 모드에서는 저장된 방향(_currentBearing)을 사용
    final targetBearing = mapMode.value == MapControlMode.on2
        ? compassValue
        : (mapMode.value == MapControlMode.on1 && _currentBearing != null)
            ? _currentBearing
            : 0.0;

    final zoomLevel = 18.5;
    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(current_latitude, current_longitude),
      zoom: zoomLevel,
      bearing: targetBearing,
    )..setAnimation(animation: NCameraAnimation.easing);
    mapController!.updateCamera(cameraUpdate);
  }

  /// updateCurrentLocationMarker: 지도 상의 현재 위치 마커를 업데이트합니다.
  /// [current_latitude]: 현재 위도.
  /// [current_longitude]: 현재 경도.
  /// [compassValue]: 현재 나침반 값.
  /// [isGps]: GPS 신호 사용 여부.
  Future<void> updateCurrentLocationMarker(double current_latitude,
      double current_longitude, double compassValue, bool isGps) async {
    if (mapController == null) return;
    final mapBearing =
        await mapController!.getCameraPosition().then((pos) => pos.bearing);
    double adjustedAngle = compassValue - mapBearing;
    if (adjustedAngle < 0) adjustedAngle += 360;
    final IconData icon = mapMode.value == MapControlMode.idle ||
            mapMode.value == MapControlMode.off
        ? Icons.circle
        : Icons.navigation;
    final Color markerColor = isGps ? Colors.blue : Colors.red;
    final iconImage = await NOverlayImage.fromWidget(
        widget: Transform.rotate(
          angle: adjustedAngle * (math.pi / 180),
          child: Icon(
            icon,
            color: markerColor,
            size: 25,
          ),
        ),
        size: const Size(25, 25),
        context: navigatorKey.currentContext!);
    _currentLocationMarker = NMarker(
      id: 'current_location',
      position: NLatLng(current_latitude, current_longitude),
      icon: iconImage,
    );
    mapController!.addOverlay(_currentLocationMarker!);
  }

  /// 출발지를 조정하기 위해 절대 좌표를 상대 좌표로 변환하여 px, py를 업데이트합니다.
  /// [baseLat], [baseLng]는 기준 좌표 (현재 위치), [targetLat], [targetLng]는 조정하려는 목표 좌표
  void updateRelativeCoordinates(double baseLat, double baseLng, double targetLat, double targetLng) {
    Map<String, double> relativePosition = latLonToXY(baseLat, baseLng, targetLat, targetLng);
    px = relativePosition['y']!;
    py = relativePosition['x']!;
    debugPrint('기준 좌표: ($baseLat, $baseLng)');
    debugPrint('목표 좌표: ($targetLat, $targetLng)');
    debugPrint('Relative Coordinates: px = $px, py = $py');
  }

  /// 지도 중심 좌표를 즉시 읽어와서 현재 위치 마커로 고정 설정 (IMU 기반일 때만)
  Future<void> setCustomStartLocationFromCamera() async {
    if (!isGps) {                       // GPS 신호 불량일 때만 활성화
      isCustomStartPoint.value = true;  // 커스텀 출발지 플래그 설정

    // 현재 카메라 중심을 바로 가져와서 저장
    final cameraPosition = await mapController!.getCameraPosition();
    final double targetLat = cameraPosition.target.latitude;
    final double targetLng = cameraPosition.target.longitude;

    cameraStartLat.value = targetLat;  // 카메라 중심 위도
    cameraStartLng.value = targetLng;  // 카메라 중심 경도

    // // 기준 좌표 = 기존 위치 (IMU 기준)
    // final double baseLat = current_latitude.value;
    // final double baseLng = current_longitude.value;

    // 상대좌표 계산 (IMU 위치 기준 → 사용자 선택 위치로 보정)
    updateRelativeCoordinates(
      current_latitude.value,
      current_longitude.value,
      cameraStartLat.value,
      cameraStartLng.value
    );

    // 현재 위치를 카메라 중심값으로 갱신
    current_latitude.value = targetLat;
    current_longitude.value = targetLng;

    // 출발지로 고정
    selectedStartLocation.value = GeoLocation(lat: targetLat, lng: targetLng);
    isSetStartLocation.value = true;

    // 마커도 즉시 지도에 반영
    await updateCurrentLocationMarker(targetLat, targetLng, compassValue.value, false);

    debugPrint("출발지 위치 수동 고정 완료: ($targetLat, $targetLng)");
  } else {
    debugPrint("GPS 사용 중이므로 수동 위치 설정 차단됨");
  }
}

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
        lat: current_latitude.value,  // 현재 GPS 위도
        lng: current_longitude.value, // 현재 GPS 경도
      );
      isSetStartLocation.value = true;
      debugPrint('출발지가 설정되지 않아 현위치를 출발지로 자동 설정됨: ${selectedStartLocation.value!.lat}, ${selectedStartLocation.value!.lng}');
    }
    // 경로 요청은 하지 않고 목적지만 설정
    debugPrint('목적지가 설정되었습니다. 경로 선택을 기다립니다.');
  }

  /// startNavigation: 경로 선택이 완료된 후 경로 탐색을 시작합니다.
  Future<void> startNavigation() async {
    if (isSetStartLocation.value && isSetDestinationLocation.value) {
      debugPrint('경로 선택 완료. 경로 탐색을 시작합니다.');
      await loadPathData(
        selectedStartLocation.value!.lat,
        selectedStartLocation.value!.lng,
        selectedDestLocation.value!.lat,
        selectedDestLocation.value!.lng,
        choose_route.value
      );
    } else {
      debugPrint('출발지 또는 목적지가 설정되지 않았습니다.');
    }
  }
// 업로드
  Timer? navigationTimer;

  /// startNavigationTimer: 경로 안내를 위한 타이머를 시작합니다.
  void startNavigationTimer() {
    debugPrint('startNavigationTimer()');
    navigationTimer?.cancel(); // 기존 타이머 제거
    navigationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      checkBoundary();
      indexUpdate();
      // 출발지(첫 번째 분기점)와 현재 위치 사이 거리 계산
      remain_startpoint = calculateDistance(
        current_latitude.value,
        current_longitude.value,
        branchinfo[0].point.latitude,
        branchinfo[0].point.longitude,
      );
      // 출발지와 현재 위치가 70m 이상 차이나면 재검색 준비
      if (remain_startpoint > 0.070) {
        searchStartNewPathTime++;
        if (searchStartNewPathTime > 14) { // 15초 이상 지속 시 경로 재검색
        debugPrint('출발지와 너무 멀어짐. 15초 후 자동으로 경로 재검색 수행');

        // 현재 위치를 새로운 출발지로 설정하고 지도 업데이트
        await loadPathData(
                current_latitude.value,
                current_longitude.value,
                selectedDestLocation.value!.lat,
                selectedDestLocation.value!.lng,
                choose_route.value,
              );
        speakText("출발지에 벗어나 새로운 경로로 안내합니다.");
        debugPrint('출발지를 현재 위치로 변경하고 지도 업데이트 완료');
        searchStartNewPathTime = 0; // 카운트 초기화
      }
    } else {
      searchStartNewPathTime = 0; // 다시 가까워지면 카운트 리셋
    }

      if (remain_startpoint < 0.015) {
        isStart.value = false;
      }
      if (!isStart.value) {
        if (branchinfo.isNotEmpty && targetIndex < branchinfo.length) {
          branchTargetIndex = targetIndex;
          while (branchTargetIndex < branchinfo.length &&
              !branchinfo[branchTargetIndex].branch) {
            branchTargetIndex++;
          }
          if (branchinfo[branchTargetIndex].branch) {
            remain_distance.value = calculateDistance(
              current_latitude.value,
              current_longitude.value,
              branchinfo[branchTargetIndex].point.latitude,
              branchinfo[branchTargetIndex].point.longitude,
            );
            clock = getGuidanceDirection(
              branchinfo[currentIndex].point.longitude,
              branchinfo[currentIndex].point.latitude,
              branchinfo[targetIndex].point.longitude,
              branchinfo[targetIndex].point.latitude,
              current_latitude.value,
              current_longitude.value,
              yawRateTurn2,
              branchinfo[currentIndex].bearingToPoint,
            );
          }
        } else {
          debugPrint("branchinfo 리스트가 비어 있거나 targetIndex가 유효하지 않습니다.");
        }
        if (remain_distance.value < 0.015) {
          if (branchinfo[currentIndex].crosswalk == true) {
            final result = await flashOnWithWeather(NoParams());
            if (result.isLeft()) {
              debugPrint('안전 경광등을 사용할 수 없습니다.');
            } else {
              debugPrint('안전 경광등이 켜졌습니다.');
            }
            speakText('잠시 후 횡단보도 입니다. 차량에 유의하세요!');
          }
          if (branchinfo[targetIndex].branch == true) {
            speakText('${branchinfo[targetIndex].description}하세요.');
          }
        }
        if (currentIndex > 0 &&
            ((branchinfo[currentIndex].bearingToPoint - compassValue.value)
                        .abs() <=
                    18 ||
                (branchinfo[currentIndex].bearingToPoint - compassValue.value)
                        .abs() >=
                    342)) {
          Vibration.vibrate(duration: 200);
          debugPrint(
              "경로내 진동 베어링 값 ${(branchinfo[currentIndex].bearingToPoint - compassValue.value)}");
        }
        if (outOfBound) {
          Vibration.vibrate(duration: 100);
          debugPrint('경계이탈');
          debugPrint('searchNewPath : ${searchNewPath}');
          speakText(clock);
          if (searchNewPath) {
            searchNewPathTime++;
            if (searchNewPathTime >= 5) {
              await loadPathData(
                current_latitude.value,
                current_longitude.value,
                selectedDestLocation.value!.lat,
                selectedDestLocation.value!.lng,
                choose_route.value,
              );
              speakText("경로를 이탈하여 새로운 경로로 안내합니다.");
              searchNewPathTime = 0;
            }
          } else {
            searchNewPathTime = 0;
          }
        }
      } else if (isStart.value) {
        speakText("출발지로 이동하세요.");
      }
    });
  }

  /// toggleMapMode: 지도 모드를 토글합니다.
  void toggleMapMode() {
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
        await updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps);
        updateMapPosition(latitude, longitude, compassValue);
        break;
      case MapControlMode.off:
        /// off 모드에서는 지도 이동은 자유롭게 하므로 카메라 업데이트 생략
        await updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps);
        break;
      case MapControlMode.on1:
        /// on1 모드에서는 지도 회전을 유지하고 마커만 회전
        /// 지도를 회전시키기 않기 위해 마지막 bearing 값으로 map을 업데이트
        if (mapController != null) {
          mapController!.getCameraPosition().then((position) {
            _currentBearing = position.bearing;
          });
        }
        await updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps);
        updateMapPosition(latitude, longitude, _currentBearing!);
        break;
      case MapControlMode.on2:
        /// 지도와 마커 모두 회전
        await updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps);
        updateMapPosition(latitude, longitude, compassValue);
        break;
    }
  }

  /// onSensorUpdate: 센서 업데이트 데이터(위치, 나침반)를 받아 지도 업데이트를 수행합니다.
  void onSensorUpdate(
      double latitude, double longitude, double compassVal, bool isGps) {
    current_latitude.value = latitude;
    current_longitude.value = longitude;
    compassValue.value = compassVal;
    updateMapByMode(latitude, longitude, compassVal, isGps);
  }

  /// handleMapDrag: 사용자가 지도를 드래그하면 지도 모드를 'off'로 전환합니다.
  void handleMapDrag() {
    if (mapMode.value != MapControlMode.off) {
      mapMode.value = MapControlMode.off;
    }
  }
}