part of '../../framework/controller.dart';

enum MapControlMode {
  idle, // 초기 상태 (초기 위치를 설정하기 위한 상태)
  off, // 자유롭게 지도 이동 (기본)
  on1, // 지도 고정, 회전하지 않음. marker에 방향 표시, 사용자가 회전하면 Marker의 화살표도 회전
  on2, // 사용자의 방향 회전에 따라 지도도 회전
}

// --- GetX Controller ---
class NaverMapViewController extends GetxController {
  // API 서비스
  final NavigationApiService apiService = DI.get<NavigationApiService>();

  // TTS 관련
  final TtsService ttsService = DI.get<TtsService>();

  Future<void> speakText(String text) async {
    await ttsService.speak(text);
  }

  // 지도 컨트롤러
  late NaverMapController? mapController;

  // 지도 모드 상태
  Rx<MapControlMode> mapMode = MapControlMode.idle.obs;

  // 로딩 상태
  RxBool isLoading = true.obs;

  // 위치 관련 (초기값 설정)
  RxDouble current_latitude = 35.9078.obs;
  RxDouble current_longitude = 127.7669.obs;
  RxDouble remain_distance = double.infinity.obs;

  // 출발지, 목적지, 경로 등
  Rxn<GeoLocation> selectedStartLocation = Rxn<GeoLocation>();
  Rxn<GeoLocation> selectedDestLocation = Rxn<GeoLocation>();

  RxString searchLocation = ''.obs;
  RxString destinationLocation = ''.obs;

  List<LatLng> paths = [];
  List<BranchInfo> branchinfo = [];

  RxBool isStart = false.obs;
  RxBool isSetStartLocation = false.obs;
  RxBool isSetDestinationLocation = false.obs;
  late double remain_startpoint;

  // 인덱스
  int currentIndex = 0;
  int targetIndex = 0;
  int branchTargetIndex = 0;

  // 네이티브 위치 데이터 (디버깅용)
  late double s_latitude;
  late double s_longitude;
  late double s_accuracy;

  // Flash 제어 (DI 사용)
  final ControlFlash flashOnWithWeather = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_ON_WITH_WEATHER,
  );

  Timer? _locationUpdateTimer;
  NMarker? _currentLocationMarker;
  NMarker? _testMarker;

  // 나침반 값 수신 체크
  Completer<void> compassReady = Completer<void>();

  // 가속도 관련
  double preAccX = 0.0, preAccY = 0.0;
  double currentpreAccX = 0.0, currentpreAccY = 0.0;

  // 속도 관련
  double velocityX = 0.0, velocityY = 0.0, currentSpeed = 0.0;

  // 방향 관련
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

  // 거리 관련
  double px = 0.0, py = 0.0;
  double distanceToPath = 0.0,
      circularDistance = 0.0,
      lineDistance = 0.0,
      nearestDistance = 0.0;

  // 초기 위치값
  double initialLatitude = 35.9078, initialLongitude = 127.7669;
  late double beforeLatitude, beforeLongitude;

  // 상수들
  double accFilteringValue = 0.06;
  double radianToAngle = (180 / math.pi);
  double angleToRadian = (math.pi / 180);
  double yawRateAccFilteringValue = 0.3;
  double detectiveRange = 0.5;
  double iphone12Filter = ((1 / 130) * (math.pi / 180));

  // 경계, 검색 관련
  bool outOfBound = false;
  double boundary = 5;
  bool searchNewPath = false;
  double searchNewPathBoundary = 30;
  int searchNewPathTime = 0;
  double distanceToNextCheckpoint = double.maxFinite;

  bool isGps = true;
  String checkBoudaryCondition = "";

  // IMU로 계산된 위경도
  double newlatitude = 0.0, newlongitude = 0.0;

  // 가중 이동평균필터 인스턴스
  final WeightedAverageFilter _filteringX =
      WeightedAverageFilter(5, [0.1, 0.2, 0.3, 0.4, 0.5]);
  final WeightedAverageFilter _filteringY =
      WeightedAverageFilter(5, [0.1, 0.2, 0.3, 0.4, 0.5]);

  final List<StreamSubscription<dynamic>> _streamSubscriptions = [];

  @override
  void onInit() {
    super.onInit();

    _getLocation();
    _initLocation();
    startCollectingSensorData();

    // 나침반 값이 설정된 후 _initLocation 호출
    compassReady.future.then((_) {
      _initLocation();
    });
  }

  // yawRate(z축회전 속도) 노이즈 조정
  double addYawRateNoise(double addValue) {
    return addValue;
  }

  // 새로운 경로, 경로 재설정 시 속도, 방향, 위치, 체크포인트 메세지 초기화
  void resetSpeedUtilsValue() {
    // 방향 초기화
    yawRatePerDt = 0;
    yawRate = compassValue * angleToRadian;

    // 위치 초기화
    px = 0.0;
    py = 0.0;
  }

  // yawRate 계산 - 자이로스코프 회전속도계산
  void yawRateupdate(GyroscopeEvent event, Duration sensorInterval) {
    double dt = sensorInterval.inMilliseconds / 1000.0;

    // 설정한 임계값(0.3) 초과 시 회전 속도 계산 - 잡음 필터링
    if (event.z > yawRateAccFilteringValue * angleToRadian ||
        event.z < -yawRateAccFilteringValue * angleToRadian) {
      yawRatePerDt = (event.z * dt); // 회전 각도 계산
    }

    // addYawRateNoise - 휴대기기 필터링 적용(보정)
    yawRate += -(yawRatePerDt + addYawRateNoise(0));

    // 360도가 넘으면 yawRate를 0으로 초기화(0도~360도 값 유지)
    if (yawRate >= 2 * math.pi || yawRate <= -2 * math.pi) {
      yawRate = 0;
    }

    // addYawRateNoise - 휴대기기 필터링 적용(보정)
    yawRate2 += -(yawRatePerDt + addYawRateNoise(0));

    // 360도가 넘으면 yawRate를 0으로 초기화(0도~360도 값 유지)
    if (yawRate2 >= 2 * math.pi || yawRate2 <= -2 * math.pi) {
      yawRate2 = 0;
    }

    // turn 변수에 회전각도 변수 저장
    yawRateTurn2 = yawRate2 * radianToAngle;
  }

  // 이동경로 계산, 가속도 -> 속도계산
  void positionUpdate(UserAccelerometerEvent event, Duration sensorInterval) {
    double dt = sensorInterval.inMilliseconds / 1000.0;
    // 현재 방향과 목표 방향 사이의 각도 차이 알려주며 목표방향으로 얼마나 회전해야 하는지 결정

    // 가속도 x, y 값을 변수에 저장
    currentpreAccX = event.x;
    currentpreAccY = event.y;
    // Velocity(속도) 계산 -> 벡터(크기, 방향)
    // X 속도: 특정 임계값(0.06) 초과하면 속도 계산(필터링) - 가속도 * dt(적분)
    if (currentpreAccX > accFilteringValue ||
        currentpreAccX < -accFilteringValue) {
      velocityX += (currentpreAccX - preAccX) * dt;
      preAccX = currentpreAccX;
    } else {
      velocityX = 0;
    }
    // Y 속도: 특정 임계값(0.06) 초과하면 속도 계산(필터링) - 가속도 * dt(적분)
    if (currentpreAccY > accFilteringValue ||
        currentpreAccY < -accFilteringValue) {
      velocityY += (currentpreAccY - preAccY) * dt;
      preAccY = currentpreAccY;
    } else {
      velocityY = 0;
    }
    //velocity 값을 wma필터에 넣음
    _filteringX.enqueue(velocityX);
    _filteringY.enqueue(velocityY);

    // 속력: 벡터의 크기 계산 -> 스칼라(크기)
    currentSpeed = math.sqrt(velocityX * velocityX + velocityY * velocityY);

    // 현재 위치 좌표점 계산 - 속력 * 방향 = 위치
    px += (currentSpeed * math.cos(yawRate));
    py += (currentSpeed * math.sin(yawRate));

    // px와 py를 사용하여 거리를 계산
    double distanceKm = math.sqrt(px * px + py * py) / 1000.0;
    double bearing = math.atan2(py, px) * radianToAngle; // 방향 이 부분 수정
    Map<String, double> latLng =
        calLatLng(initialLatitude, initialLongitude, bearing, distanceKm);
    newlatitude = latLng['latitude']!;
    newlongitude = latLng['longitude']!;
  }

  // 함수 정의
  Map<String, double> calLatLng(
      double startLat, double startLng, double bearing, double distanceKm) {
    const double earthRadiusKm = 6371.0;

    // 위도, 경도를 라디안으로 변환
    double startLatRad = _degreesToRadians(startLat);
    double startLngRad = _degreesToRadians(startLng);
    double bearingRad = _degreesToRadians(bearing);

    // 이동 거리를 라디안으로 변환
    double distanceRad = distanceKm / earthRadiusKm;

    // 새로운 위도 계산
    double newLatRad = math.asin(math.sin(startLatRad) * math.cos(distanceRad) +
        math.cos(startLatRad) * math.sin(distanceRad) * math.cos(bearingRad));

    // 새로운 경도 계산
    double newLngRad = startLngRad +
        math.atan2(
            math.sin(bearingRad) *
                math.sin(distanceRad) *
                math.cos(startLatRad),
            math.cos(distanceRad) -
                math.sin(startLatRad) * math.sin(newLatRad));

    // 라디안을 다시 도로 변환
    double newLat = _radiansToDegrees(newLatRad);
    double newLng = _radiansToDegrees(newLngRad);

    // 결과 반환
    return {'latitude': newLat, 'longitude': newLng};
  }

  // 도를 라디안으로 변환하는 함수
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // 라디안을 도로 변환하는 함수
  double _radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  @override
  void onClose() {
    _locationUpdateTimer?.cancel();
    _streamSubscriptions.forEach((subscription) => subscription.cancel());

    super.onClose();
  }

  // 위치 초기화 (GPS 및 IMU)
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

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (position.accuracy >= 15) {
        isGps = false;
        velocityX = _filteringX.calculateWeightedAverage();
        velocityY = _filteringY.calculateWeightedAverage();
        current_latitude.value = newlatitude;
        current_longitude.value = newlongitude;
        isLoading.value = false;
      } else {
        isGps = true;
        current_latitude.value = position.latitude;
        current_longitude.value = position.longitude;
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
  ) async {
    try {
      final responseData = await apiService.fetchPathData(
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
      );

      // 데이터 파싱
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

      addOverlays(paths);
      addBranchMarkers();

      startNavigationTimer();
    } catch (e) {
      debugPrint('Failed to load path data : $e');
    }
  }

  // 지도 Overlay 추가
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

  // 분기(체크포인트) 마커 추가
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

  // 거리 및 각도 계산 함수들
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

  double _degToRad(double degrees) => degrees * math.pi / 180;

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

  // 센서 관련
  void subscribeToSensor<T>(
      {required Stream<T> sensorStream,
      required Function(T event) onEvent,
      required Function(dynamic error) onError}) {
    var subscription =
        sensorStream.listen(onEvent, onError: onError, cancelOnError: true);
    _streamSubscriptions.add(subscription);
  }

  void showErrorDialog(String sensorName) {
    Get.defaultDialog(
      title: "$sensorName Sensor Not Found",
      middleText:
          "It seems that your device doesn't support the $sensorName sensor.",
    );
  }

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

  void stopCollectingSensorData() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
  }

  // 인덱스 관련 함수들
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

  double _distanceBetweenBranch(
      List<BranchInfo> branchInfo, int currentIndex, int targetIndex) {
    double currentIndex_latitude = branchInfo[currentIndex].point.latitude;
    double currentIndex_longitude = branchInfo[currentIndex].point.longitude;

    double targetIndex_latitude = branchInfo[targetIndex].point.latitude;
    double targetIndex_longitude = branchInfo[targetIndex].point.longitude;

    return calculateDistance(currentIndex_latitude, currentIndex_longitude,
        targetIndex_latitude, targetIndex_longitude);
  }

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

  void indexUpdate() {
    List<BranchInfo> currentWindow =
        getCurrentWindow(branchinfo, currentIndex, 5);
    int nearestIndex = moveIndex(currentWindow);
    if ((nearestIndex < currentWindow.length || nearestIndex > 0) &&
        nearestIndex != currentIndex) {
      debugPrint('인덱스가 변경되었습니다. 새로운 인덱스: $nearestIndex');
      currentIndex = nearestIndex;
      yawRate2 = turnUpdate2(
              branchinfo[currentIndex].bearingToPoint, compassValue.value) *
          angleToRadian;
      debugPrint("각도 초기화");
    }
  }

  double deg2rad(double deg) => deg * (math.pi / 180);

  double sphericalDistance(
          double lat1, double lon1, double lat2, double lon2) =>
      math.acos(math.sin(lat1) * math.sin(lat2) +
          math.cos(lat1) * math.cos(lat2) * math.cos(lon2 - lon1));

  double sphericalAngle(double a, double b, double c) => math.acos(
      (math.cos(a) - math.cos(b) * math.cos(c)) / (math.sin(b) * math.sin(c)));

  double rad2deg(double rad) => rad * (180 / math.pi);

  double turnUpdate2(double bearingToPoint, double compassValue) {
    return compassValue - bearingToPoint;
  }

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

  void updateMapPosition(
      double current_latitude, double current_longitude, double compassValue) {
    if (mapController == null) return;
    final zoomLevel = 18.5;
    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(current_latitude, current_longitude),
      zoom: zoomLevel,
      bearing: mapMode.value == MapControlMode.on2 ? compassValue : 0.0,
    )..setAnimation(animation: NCameraAnimation.easing);

    mapController!.updateCamera(cameraUpdate);
  }

  Future<void> updateCurrentLocationMarker(double current_latitude,
      double current_longitude, double compassValue, bool isGps) async {
    if (mapController == null) return;

    // 지도 회전 값 가져오기
    final mapBearing =
        await mapController!.getCameraPosition().then((pos) => pos.bearing);

    // 마커의 방향 계산
    double adjustedAngle = compassValue - mapBearing;
    // 0° ~ 360° 범위로 조정
    if (adjustedAngle < 0) adjustedAngle += 360;

    final IconData icon = mapMode.value == MapControlMode.idle ||
            mapMode.value == MapControlMode.off
        ? Icons.circle
        : Icons.navigation;

    final Color markerColor = isGps ? Colors.blue : Colors.red;

    final iconImage = await NOverlayImage.fromWidget(
        widget: Transform.rotate(
          angle: adjustedAngle * (math.pi / 180), // 라디안 변환
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

  // 출발지 설정 후
  Future<void> handleStartLocationSelection(GeoLocation newStart) async {
    selectedStartLocation.value = newStart;
    isStart.value = true;
    isSetStartLocation.value = true;

    if (isSetDestinationLocation.value) {
      debugPrint('목적지가 설정되어 있으므로 경로 요청');
      await loadPathData(
        selectedStartLocation.value!.lat,
        selectedStartLocation.value!.lng,
        selectedDestLocation.value!.lat,
        selectedDestLocation.value!.lng,
      );
    }
  }

  // 목적지 설정 후 경로 안내 시작
  Future<void> handleDestinationLocationSelection(GeoLocation newDest) async {
    selectedDestLocation.value = newDest;
    isSetDestinationLocation.value = true;

    if (isSetStartLocation.value) {
      debugPrint('출발지가 설정되어 있으므로 경로 요청');
      await loadPathData(
        selectedStartLocation.value!.lat,
        selectedStartLocation.value!.lng,
        selectedDestLocation.value!.lat,
        selectedDestLocation.value!.lng,
      );
    }

  }

  Timer? navigationTimer;

  void startNavigationTimer() {
    debugPrint('startNavigationTimer()');
    navigationTimer?.cancel(); // 기존 타이머 제거
    navigationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      checkBoundary();
      indexUpdate();
      remain_startpoint = calculateDistance(
        current_latitude.value,
        current_longitude.value,
        branchinfo[0].point.latitude,
        branchinfo[0].point.longitude,
      );
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
                selectedStartLocation.value!.lat,
                selectedStartLocation.value!.lng,
                selectedDestLocation.value!.lat,
                selectedDestLocation.value!.lng,
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

  // 모드 토글 메서드
  void toggleMapMode() {
    // idle 상태를 건너뛰고 off부터 시작하도록
    if (mapMode.value == MapControlMode.idle) {
      mapMode.value = MapControlMode.off;
    }

    // 다음 모드 인덱스 계산 (idle이 나오면 건너뜀)
    int nextIndex = (mapMode.value.index + 1) % MapControlMode.values.length;
    if (MapControlMode.values[nextIndex] == MapControlMode.idle) {
      nextIndex = (nextIndex + 1) % MapControlMode.values.length;
    }
    mapMode.value = MapControlMode.values[nextIndex];

    debugPrint("모드 전환: ${mapMode.value}");
  }

  /// 지도 업데이트를 모드에 따라 한번에 처리하는 함수
  /// 현재 지도 모드에 따라 지도와 마커를 업데이트하는 메서드
  Future<void> updateMapByMode(double latitude, double longitude,
      double compassValue, bool isGps) async {
    if (mapController == null) return;

    switch (mapMode.value) {
      case MapControlMode.idle:
        await updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps);
        updateMapPosition(latitude, longitude, compassValue);
        break;
      case MapControlMode.off:
        await updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps);
        // off 모드에서는 지도 이동은 자유롭게 하므로 카메라 업데이트 생략 가능
        break;
      case MapControlMode.on1:
        final mapBearing =
            await mapController!.getCameraPosition().then((pos) => pos.bearing);
        await updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps);
        updateMapPosition(latitude, longitude, mapBearing); // 지도 회전은 유지
        break;
      case MapControlMode.on2:
        await updateCurrentLocationMarker(
            latitude, longitude, compassValue, isGps);
        updateMapPosition(latitude, longitude, compassValue); // 지도와 마커 모두 회전
        break;
    }
  }

  void onSensorUpdate(
      double latitude, double longitude, double compassVal, bool isGps) {
    current_latitude.value = latitude;
    current_longitude.value = longitude;
    compassValue.value = compassVal;
    updateMapByMode(latitude, longitude, compassVal, isGps);
  }

  /// 사용자가 지도를 드래그했을 때 호출되는 메서드
  /// 드래그 시 모드를 off로 전환
  void handleMapDrag() {
    if (mapMode.value != MapControlMode.off) {
      mapMode.value = MapControlMode.off;
    }
  }
}
