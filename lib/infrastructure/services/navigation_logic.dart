part of '../../framework/ui.dart';

class NavigationLogic {
  NavigationLogic(this.context, this.navigationBloc);

  late final BuildContext context;
  late final NavigationBloc navigationBloc;

  final FlutterTts tts = FlutterTts();

  // 네이티브 위치 확인용
  late double s_latitude;
  late double s_longitude;
  late double s_accuracy;

  // 좌표 관련된 변수
  late double gpsLatitude;
  late double gpsLongitude;

  // IMU 센서 관련 데이터
  late StreamSubscription<Position> positionStream;

  bool isAccRunning = false;
  double preAccX = 0.0, preAccY = 0.0, preAccZ = 0.0;
  double curAccX = 0.0, curAccY = 0.0, curAccZ = 0.0;
  double velocityX = 0.0, velocityY = 0.0, velocityZ = 0.0;
  double rotationX = 0.0, rotationY = 0.0, rotationZ = 0.0;
  double rotationXSum = 0.0, rotationYSum = 0.0, rotationZSum = 0.0;
  double imuLocationX = 0.0, imuLocationY = 0.0;
  double compassValue = 0.0, lastCompassValue = 0.0;
  double yawRate = 0.0;

  // imu로 계산된 위경도 변수
  double imuLatitude = 0.0, imuLongitude = 0.0;

  // 최종 위경도 변수
  late double finalLatitude;
  late double finalLongitude;

  // imu, gps 전환 플래그
  bool isGps = false;

  // 길안내 관련 변수
  double remainDistance = double.infinity; // 다음 분기까지의 남은거리 (초기값: 무한대)
  // bool isLoading = true; // 로딩을 위한 T/F

  // 상태를 관리하는 ValueNotifier
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  void updateLoadingState(bool value) {
    isLoading.value = value; // 상태 업데이트
  }


  GeoLocation? startSelectedLocation; // 시작 위치의 좌표값 객체
  bool isStart = false; // 출발지가 선택됐을 경우 true, 아닐경우 false
  late double remainStartPoint;

  int branchTargetIndex = 0;
  GeoLocation? selectedLocation; // 검색된 위치의 좌표값 객체
  NaverMapController? mapController;
  List<LatLng> paths = []; // 모든 경로의 좌표값을 담는 배열
  List<BranchInfo> branchInfo = []; // 분기의 객체 배열

  final ControlFlash flashOnWithWeather = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_ON_WITH_WEATHER,
  );

  NMarker? _currentLocationMarker;
  NMarker? _testMarker;

  String clock = "";

  // 거리
  double distanceToPath = 0.0;
  double circularDistance = 0.0;
  double lineDistance = 0.0;

  // 인덱스
  int currentIndex = 0; // 현재 인덱스
  int targetIndex = 0; // 향하고있는 인덱스

  // 경계이탈
  bool outOfBound = false;
  bool searchNewPath = false;

  // 추가
  double searchNewPathBoundary = 30;
  int searchNewPathTime = 0;

  String checkBoundaryCondition = "";


  void init() {
    _initTTS();
    _initLocation();
  }

  void dispose() {
    for (var subscription in _streamSubscriptions) {
      subscription.cancel(); // 각 구독 해제
    }
    _streamSubscriptions.clear(); // 리스트 클리어

    navigationBloc.close();
    navigationTimer?.cancel();
  }

  // 새로운 경로, 경로 재설정 시 속도, 방향, 위치, 체크포인트 메세지 초기화
  void _resetSpeedUtilsValue() {
    // debugPrint('resetSpeedUtilsValueFunc 실행');
    imuLatitude = 0.0;
    imuLongitude = 0.0;
    preAccX = 0.0;
    preAccY = 0.0;
    preAccZ = 0.0;
  }

  // 칼만필터 적용
  final kalmanX = SimpleKalman(errorMeasure: 2, errorEstimate: 2, q: 0.8);
  final kalmanY = SimpleKalman(errorMeasure: 2, errorEstimate: 2, q: 0.8);
  final kalmanZ = SimpleKalman(errorMeasure: 2, errorEstimate: 2, q: 0.8);

  // 위치 업데이트
  Future<void> _positionUpdate(Duration sensorInterval) async {
    double deltaTime = (sensorInterval.inMilliseconds / 1000.0)
        .toDouble(); // 가속도계가 작동될 때의 Duration 계산
    // debugPrint('deltaTime: $deltaTime, positionUpdateFunc 진행 중...1');
    final double accelerationMagnitude =
    math.sqrt(curAccX * curAccX + curAccY * curAccY);
    // debugPrint(
    //     'accelerationMagnitude: $accelerationMagnitude, curAccX: $curAccX, curAccY: $curAccY, curAccZ: $curAccZ, 실제 센서 값, positionUpdateFunc 진행 중...2');
    curAccX = kalmanX.filtered(curAccX);
    curAccY = kalmanY.filtered(curAccY);
    curAccZ = kalmanZ.filtered(curAccZ);
    // debugPrint(
    //     'curAccX: $curAccX, curAccY: $curAccY, curAccZ: $curAccZ, Kalman Filter 적용, positionUpdateFunc 진행 중...3');
    // 속도 계산
    velocityX = (curAccX - preAccX) * deltaTime;
    velocityY = (curAccY - preAccY) * deltaTime;
    velocityZ = (curAccZ - preAccZ) * deltaTime;
    // debugPrint(
    //     'velocityX: $velocityX, velocityY, $velocityY, velocityZ, $velocityZ, 속도 계산, positionUpdateFunc 진행 중...4');
    // 가중이동필터 적용
    final velocityXFilter = DI<MovingAverageFilter>(param1: 5);
    final velocityYFilter = DI<MovingAverageFilter>(param1: 5);
    final velocityZFilter = DI<MovingAverageFilter>(param1: 5);
    velocityX = velocityXFilter.filter(velocityX);
    velocityY = velocityYFilter.filter(velocityY);
    velocityZ = velocityZFilter.filter(velocityZ);
    // debugPrint(
    //     'velocityX: $velocityX, velocityY, $velocityY, velocityZ, $velocityZ, 이동필터 적용, positionUpdateFunc 진행 중...5');
    // Roll, Pitch 보정
    velocityX = velocityX * math.cos(rotationX);
    velocityY = velocityY * math.cos(rotationY);
    // 속력 계산
    final double currentSpeed =
    math.sqrt(velocityX * velocityX + velocityY * velocityY);
    // debugPrint('currentSpeed: $currentSpeed, positionUpdateFunc 진행 중...6');
    // 실제 이동 거리 계산
    imuLocationX -= (currentSpeed * math.cos(yawRate) * deltaTime);
    imuLocationY += (currentSpeed * math.sin(yawRate) * deltaTime);
    // debugPrint(
    //     'imuLocationX: $imuLocationX, imuLocationY, $imuLocationY, 실제 이동 거리, positionUpdateFunc 진행 중...7');
    double distanceKm = math.sqrt(
        (imuLocationX * imuLocationX + imuLocationY * imuLocationY) / 1000);
    double distanceRad = distanceKm / 6371.0;
    double pointingToRad = math.atan2(imuLocationY, imuLocationX);
    double startLongitudeRad = finalLongitude * math.pi / 180;
    double startLatitudeRad = finalLatitude * math.pi / 180;
    double newLatitudeRad = math.asin(
        math.sin(startLatitudeRad) * math.cos(distanceRad) +
            math.cos(startLongitudeRad) *
                math.sin(distanceRad) *
                math.cos(pointingToRad));
    double newLongitudeRad = startLongitudeRad +
        math.atan2(
            math.sin(pointingToRad) *
                math.sin(distanceRad) *
                math.cos(startLatitudeRad),
            math.cos(distanceRad) -
                math.sin(startLatitudeRad) * math.sin(newLatitudeRad));
    imuLatitude = newLatitudeRad * 180 / math.pi;
    imuLongitude = newLongitudeRad * 180 / math.pi;
    imuLocationX = 0.0;
    imuLocationY = 0.0;
    // 마지막 값 초기화
    preAccX = curAccX;
    preAccY = curAccY;
    preAccZ = curAccZ;
    // debugPrint(
    //     'imuLatitude: $imuLatitude, imuLongitude: $imuLongitude, positionUpdateFunc 진행 완료...8');
  }

  Future<void> _initTTS() async {
    await tts.setLanguage("ko-KR");
    await tts.setSpeechRate(0.7);
  }

  void _updateYawRate(double value) {
    yawRate += value;
    if (yawRate < 0 && yawRate >= -2 * math.pi) {
      yawRate += 2 * math.pi;
    }
  }

  Future<void> _initLocation() async {
    int gpsAccuracy = 14;
    Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 1));
    gpsLatitude = position.latitude;
    gpsLongitude = position.longitude;
    finalLatitude = gpsLatitude;
    finalLongitude = gpsLongitude;
    // debugPrint(
    //     'finalLatitude: $finalLatitude, finalLongitude: $finalLongitude, initLocation 실행 중');

    if (position.accuracy <= gpsAccuracy) {
      isGps = true;
      // isLoading = false;
      updateLoadingState(false);
    } else {
      isGps = false;
      // isLoading = false;
      updateLoadingState(false);
    }

    // setState(() {});

    // TODO: Setstate를 여기서만 호출
    void moveDot(importedLatitude, importedLongitude) {
      if (importedLatitude != finalLatitude ||
          importedLongitude != finalLongitude) {
        _updateCurrentLocationMarker(importedLatitude, importedLongitude);
        _updateMapPosition(importedLatitude, importedLongitude, compassValue);
        finalLatitude = importedLatitude;
        finalLongitude = importedLongitude;
        // debugPrint(
        //     'finalLatitude: $finalLatitude, finalLongitude: $finalLongitude, moveDotFunc 진행 완료');
      }
    }

    Future<void> moveByGps() async {
      isGps = true;
      position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high, distanceFilter: 1));
      gpsLatitude = position.latitude;
      gpsLongitude = position.longitude;
      s_latitude = position.latitude;
      s_longitude = position.longitude;
      s_accuracy = position.accuracy;
      moveDot(gpsLatitude, gpsLongitude);
      _resetSpeedUtilsValue();
      // debugPrint(
      //     'gpsLatitude: $gpsLatitude, gpsLongitude: $gpsLongitude, moveByGPS 진행 완료. 현재 GPS 정확도 : ${position.accuracy}');
    }

    Future<void> moveByImu(Duration sensorInterval) async {
      isGps = false;
      await _positionUpdate(sensorInterval);
      moveDot(imuLatitude, imuLongitude);
    }

    subscribeToSensor<UserAccelerometerEvent>(
        sensorStream: userAccelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval),
        onEvent: (event) async {
          curAccX = event.x;
          curAccY = event.y;
          curAccZ = event.z;
          double accelerationMagnitude = math
              .sqrt(curAccX * curAccX + curAccY * curAccY + curAccZ * curAccZ);
          if (accelerationMagnitude > 1.0 &&
              accelerationMagnitude < 10.0 &&
              !isAccRunning) {
            isAccRunning = true;
            // debugPrint('accelerationMagnitude: $accelerationMagnitude, subscribeToSensor<UserAccelerometerEvent> 트리거 됨');
            position = await Geolocator.getCurrentPosition(
                locationSettings: LocationSettings(
                    accuracy: LocationAccuracy.high, distanceFilter: 5));
            if (position.accuracy > gpsAccuracy) {
              // debugPrint(
              //     '가속도계 움직임 감지됨. 현재 GPS 정확도가 ${position.accuracy} 이기 때문에 moveByImuFunc 실행됨.');
              await moveByImu(SensorInterval.normalInterval);
            } else {
              await moveByGps();
            }
          }
          isAccRunning = false;
        },
        onError: (e) {
          debugPrint(e);
        });

    subscribeToSensor<CompassEvent>(
      sensorStream: FlutterCompass.events!,
      onEvent: (event) {
        if (!context.mounted) return; // 위젯이 제거된 경우 상태 업데이트 방지
        compassValue = event.heading ?? 0.0;
        yawRate = (compassValue * math.pi / 180);
        _updateYawRate(0);
        debugPrint('compassValue: $compassValue, yawRate: $yawRate,subscribeToSensor<CompassEvent> 진행 중');
        if ((compassValue - lastCompassValue).abs() >= 1.0) {
          lastCompassValue = compassValue;
          _updateMapPosition(finalLatitude, finalLongitude, compassValue);
        }
        s_accuracy = position.accuracy;
      },
      onError: (e) {
        debugPrint(e);
      },
    );

    subscribeToSensor<GyroscopeEvent>(
      sensorStream:
      gyroscopeEventStream(samplingPeriod: SensorInterval.normalInterval),
      onEvent: (GyroscopeEvent event) async {
        if (!context.mounted) return; // 위젯이 제거된 경우 상태 업데이트 방지

        final deltaTime =
            (SensorInterval.normalInterval).inMilliseconds / 1000.0;
        rotationX = event.x * deltaTime;
        rotationY = event.y * deltaTime;
        rotationZ = event.z * deltaTime;
        rotationXSum += rotationX;
        rotationYSum += rotationY;
        rotationZSum += rotationZ;
        // debugPrint(
        //     'rotationX: $rotationX, rotationY: $rotationY, rotationZ: $rotationZ, rotationXSum: $rotationXSum, rotationYSum: $rotationYSum, rotationZSum: $rotationZSum, subscribeToSensor<GyroscopeEvent> 실행됨');
      },
      onError: (e) {
        debugPrint(e);
      },
    );

    positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 1))
        .listen((Position position) async {
      if (position.accuracy <= gpsAccuracy) {
        await moveByGps();
      }
    });
  }

  // t맵에서 api 호출을 통해 경로 검색을 하는 비동기 함수
  void requestNewPath(double latitude, double longitude) {
    navigationBloc.add(LoadPath(
      startLatitude: latitude,
      startLongitude: longitude,
      endLatitude: selectedLocation!.lat,
      endLongitude: selectedLocation!.lng,
    ));
  }

  // 네이버맵에 경로를 포함한 overlays를 띄우기 위한 함수
  void addOverlays(List<LatLng> paths) {
    if (mapController == null) {
      // debugPrint('addOverlays() mapController is not initialized yet.');
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

  // 두 위경도 사이의 거리를 계산하는 함수.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0;
    double toRadians(double degree) {
      return degree * math.pi / 180.0;
    }

    double dLat = toRadians(lat2 - lat1);
    double dLon = toRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRadians(lat1)) *
            math.cos(toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    // 거리 계산 및 반환 (단위: km)
    double distance = earthRadius * c;
    return distance;
  }

  // 현재위치로부터 목표위경도로의 방향값을 계산해주는 함수
  double calculateBearing(double initialLatitude, double initialLongitude,
      double targetLatitude, double targetLongitude) {
    double lat1 = initialLatitude * math.pi / 180;
    double lon1 = initialLongitude * math.pi / 180;
    double lat2 = targetLatitude * math.pi / 180;
    double lon2 = targetLongitude * math.pi / 180;
    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x);
    double bearingDegrees = bearing * 180 / math.pi;
    if (bearingDegrees < 0) {
      bearingDegrees += 360; // 음수 값을 0에서 360도 사이의 양수 값으로 변환
    }
    return bearingDegrees;
  }

  // 특정 점과 두 지점 사이의 최단 거리 계산. 즉, 점과 직선사이의 최소거리를 반환하는 함수.
  double pointLineDistance(double lat1, double lon1, double lat2, double lon2,
      double latP, double lonP) {
    // 두 지점 간의 대원 거리 (미터) 계산
    double haversine(double lat1, double lon1, double lat2, double lon2) {
      // 위도와 경도를 라디안으로 변환
      double degToRad(double degrees) {
        return degrees * math.pi / 180;
      }

      const double R = 6371e3; // 지구 반지름 (미터)
      double dLat = degToRad(lat2 - lat1);
      double dLon = degToRad(lon2 - lon1);
      double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(degToRad(lat1)) *
              math.cos(degToRad(lat2)) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      return R * c;
    }

    // 두 지점 사이의 거리
    double dist12 = haversine(lat1, lon1, lat2, lon2);
    // 현재 위치와 첫 번째 지점 사이의 거리
    double dist1P = haversine(lat1, lon1, latP, lonP);
    // 현재 위치와 두 번째 지점 사이의 거리
    double dist2P = haversine(lat2, lon2, latP, lonP);

    // 세 점 사이의 각도를 구하기 위해 라디안으로 변환
    double A = dist1P / 6371e3; // R
    double B = dist2P / 6371e3; // R
    double C = dist12 / 6371e3; // R

    // 점과 직선 사이의 거리를 계산
    double angleP12 = math.acos((math.cos(A) - math.cos(B) * math.cos(C)) /
        (math.sin(B) * math.sin(C)));
    double distance = math.sin(angleP12) * dist1P;

    return distance;
  }

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  // 센서받아오는 부분
  void subscribeToSensor<T>(
      {required Stream<T> sensorStream,
        required Function(T event) onEvent,
        required Function(dynamic error) onError}) {
    var subscription = sensorStream.listen(
      onEvent,
      onError: onError,
      cancelOnError: true,
    );
    _streamSubscriptions.add(subscription);
  }

  //imu 함수
  List<BranchInfo> getCurrentWindow(
      List<BranchInfo> branchinfo, int currentIndex, int windowsize) {
    //windowsize는 언제나 홀수
    int windowOffset = (windowsize - 1) ~/ 2;
    // 윈도우의 시작과 끝 인덱스 계산
    int start = currentIndex - windowOffset;
    int end = currentIndex + windowOffset;
    // 시작 인덱스가 0보다 작지 않도록 조정
    start = start < 0 ? 0 : start;
    // 끝 인덱스가 리스트의 마지막 인덱스를 초과하지 않도록 조정
    end = end >= branchinfo.length ? branchinfo.length - 1 : end;
    // 슬라이딩 윈도우 내의 체크포인트들을 담을 리스트
    List<BranchInfo> window = [];
    // 시작 인덱스부터 끝 인덱스까지의 체크포인트들을 리스트에 추가
    for (int i = start; i <= end; i++) {
      window.add(branchinfo[i]);
    }
    return window;
  }

  void indexUpdate() {
    double distanceBetweenBranchFunc(
        List<BranchInfo> branchInfo, int currentIndex, int targetIndex) {
      double currentIndexLatitude = branchInfo[currentIndex].point.latitude;
      double currentIndexLongitude = branchInfo[currentIndex].point.longitude;
      double targetIndexLatitude = branchInfo[targetIndex].point.latitude;
      double targetIndexLongitude = branchInfo[targetIndex].point.longitude;
      return calculateDistance(currentIndexLatitude, currentIndexLongitude,
          targetIndexLatitude, targetIndexLongitude);
    }

    int moveIndex(List<BranchInfo> currentWindow) {
      double beforeMin = double.maxFinite; // window 내에 가장 가까운 값
      int nearestIndex = currentIndex; // 현재 인덱스
      double distanceBetweenBranch = distanceBetweenBranchFunc(
          branchInfo, currentIndex, targetIndex); //currentWindow-> branchinfo
      if (distanceBetweenBranch == 0) {
        nearestIndex = targetIndex;
      }
      double currentDistance = 0.0;
      for (BranchInfo window in currentWindow) {
        currentDistance = calculateDistance(window.point.latitude,
            window.point.longitude, finalLatitude, finalLongitude);

        double currentIndexDistance = calculateDistance(
            branchInfo[nearestIndex].point.latitude,
            branchInfo[nearestIndex].point.longitude,
            finalLatitude,
            finalLongitude);
        if (currentDistance < beforeMin &&
            currentIndexDistance >=
                distanceBetweenBranch - (distanceBetweenBranch / 20)) {
          beforeMin = currentDistance;
          nearestIndex =
              branchInfo.indexOf(window); // 가장 가까운 체크포인트의 인덱스를 찾습니다.
        }
      }
      return nearestIndex;
    }

    List<BranchInfo> currentWindow =
    getCurrentWindow(branchInfo, currentIndex, 5);
    int nearestIndex = moveIndex(currentWindow);

    if ((nearestIndex < currentWindow.length || nearestIndex > 0) &&
        nearestIndex != currentIndex) {
      currentIndex = nearestIndex;
    }
  }

  // 위도와 경도를 라디안으로 변환하는 함수
  double deg2rad(double deg) {
    return deg * (pi / 180);
  }

// 두 점 사이의 중심 각도 계산
  double sphericalDistance(double lat1, double lon1, double lat2, double lon2) {
    return math.acos(math.sin(lat1) * math.sin(lat2) +
        math.cos(lat1) * math.cos(lat2) * math.cos(lon2 - lon1));
  }

// 구면 삼각법을 이용하여 각도 계산
  double sphericalAngle(double a, double b, double c) {
    return math.acos((math.cos(a) - math.cos(b) * math.cos(c)) /
        (math.sin(b) * math.sin(c)));
  }

// 라디안 값을 도(degree)로 변환
  double rad2deg(double rad) {
    return rad * (180 / pi);
  }

  Map<String, double> latLonToXY(
      double currentIndexLatitude,
      double currentIndexLongitude,
      double targetIndexLatitude,
      double targetIndexLongitude) {
    // 위도 차이
    double deltaLat = targetIndexLatitude - currentIndexLatitude;

    // 경도 차이
    double deltaLon = targetIndexLongitude - currentIndexLongitude;

    // 위도에 따른 경도 길이 보정 (cos(latitude) 적용)
    double avgLat = (currentIndexLatitude + targetIndexLatitude) / 2.0;
    double x = deltaLon * 111320 * math.cos(avgLat * math.pi / 180);

    // 위도에 따른 y 좌표 (111320m는 위도 1도의 길이)
    double y = deltaLat * 111320;

    return {'x': x, 'y': y};
  }

// 두 좌표 사이의 외적을 이용하여 좌우 판단
  int checkLateralDeviation(
      double currentIndexLatitude,
      double currentIndexLongitude,
      double targetIndexLatitude,
      double targetIndexLongitude,
      double finalLatitude,
      double finalLongitude) {
    // 출발점과 목표 지점을 평면 좌표계로 변환 (출발점이 원점)
    Map<String, double> pathVector = latLonToXY(currentIndexLatitude,
        currentIndexLongitude, targetIndexLatitude, targetIndexLongitude);

    // 출발점과 현재 위치를 평면 좌표계로 변환 (출발점이 원점)
    Map<String, double> currentVector = latLonToXY(currentIndexLatitude,
        currentIndexLongitude, finalLatitude, finalLongitude);

    // 외적 계산 (pathVector x currentVector)
    double crossProduct = pathVector['x']! * currentVector['y']! -
        pathVector['y']! * currentVector['x']!;

    // 외적 부호에 따라 좌우 판단
    if (crossProduct > 0) {
      return -1; // 왼쪽 경계 이탈
    } else if (crossProduct < 0) {
      return 1; // 오른쪽 경계 이탈
    } else {
      return 0; // 경로 상에 있음
    }
  }

  // yaw rate를 고려하여 타겟까지의 최종 각도를 계산하는 함수
  double angleToTarget(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double finalLatitude,
      double finalLongitude,
      double bearingToPoint,
      int boundaryExit) {
    Map<String, double> breakPoint(
        double currentIndexLongitude,
        double currentIndexLatitude,
        double targetIndexLongitude,
        double targetIndexLatitude,
        double finalLatitude,
        double finalLongitude,
        ) {
      // 주어진 위경도를 라디안으로 변환

      //현재 인덱스
      double lat1 = deg2rad(currentIndexLatitude);
      double lon1 = deg2rad(currentIndexLongitude);

      //현재 위치
      double lat2 = deg2rad(finalLatitude);
      double lon2 = deg2rad(finalLongitude);

      //타겟인덱스
      double lat3 = deg2rad(targetIndexLatitude);
      double lon3 = deg2rad(targetIndexLongitude);

      // 변 AB, BC, CA의 중심 각도
      double a = sphericalDistance(lat2, lon2, lat3, lon3);
      double b = sphericalDistance(lat3, lon3, lat1, lon1);
      double c = sphericalDistance(lat1, lon1, lat2, lon2);

      // 각도 계산
      double A = sphericalAngle(a, b, c);
      double B = sphericalAngle(b, a, c);
      double C = sphericalAngle(c, a, b);
      // 각도를 도 단위로 변환하여 출력

      return {
        'breakPointAngleA': A,
        'breakPointAngleB': B,
        'breakPointAngleC': C
      };
    }

    Map<String, double> breakPointAngle = breakPoint(
        currentIndexLongitude,
        currentIndexLatitude,
        targetIndexLongitude,
        targetIndexLatitude,
        finalLatitude,
        finalLongitude);
    double guidanceAngle = 0.0;
    double baseAngle = (breakPointAngle['breakPointAngleC']! * (180 / math.pi));
    // 목표 지까지의 각도를 계산 (기존 breakPointB + yaw rate 고려)
    guidanceAngle = baseAngle % 360;
    return guidanceAngle;
  }

  // 유도각도 -> 12시, 1시, 2시... 방향으로 안내
  String getGuidanceDirection(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double finalLatitude,
      double finalLongitude,
      double bearingToPoint) {
    int boundaryExit = checkLateralDeviation(
      currentIndexLatitude,
      currentIndexLongitude,
      targetIndexLatitude,
      targetIndexLongitude,
      finalLatitude,
      finalLongitude,
    );

    double guidanceAngle = angleToTarget(
        currentIndexLongitude,
        currentIndexLatitude,
        targetIndexLongitude,
        targetIndexLatitude,
        finalLatitude,
        finalLongitude,
        bearingToPoint,
        boundaryExit);

    if (guidanceAngle > 180) {
      guidanceAngle -= 360; // 180도 초과 시 -180도 범위로 변환
    }

    // 각도를 30도로 나누고 0~11 사이의 인덱스로 변환
    int direction = ((guidanceAngle + 15) % 360) ~/ 30;
    List<String> directionLabels = [];
    if (boundaryExit > 0) {
      // 시계방향 기준으로 12시, 1시, 2시, ... 방향을 문자열로 변환
      directionLabels = [
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
      ];
    } else {
      directionLabels = [
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
    }
    return directionLabels[direction];
  }

  // 좌표점을 확인하여 해당 좌표에 도달했는지 여부를 확인하는 메서드입니다.
  //branch일 경우의 branchinfo[currentIndex]를 전부 currentWindowValue로 바꿈
  void checkBoundary() {
    List<BranchInfo> currentWindow =
    getCurrentWindow(branchInfo, currentIndex, 5);
    double beforeMinDistanceToPath = double.maxFinite;
    //점과 직선 최소거리
    for (int i = 0; i < currentWindow.length - 1; i++) {
      var currentWindowValue = currentWindow[i];
      // print("Index: $i");

      targetIndex = currentIndex + 1;

      if (currentWindowValue.branch == true) {
        circularDistance = calculateDistance(
            currentWindowValue.point.latitude,
            currentWindowValue.point.longitude,
            finalLatitude,
            finalLongitude) *
            1000;

        checkBoundaryCondition = "정방향, 브랜치";

        lineDistance = pointLineDistance(
            currentWindowValue.point.latitude,
            currentWindowValue.point.longitude,
            currentWindow[i + 1].point.latitude,
            currentWindow[i + 1].point.longitude,
            finalLatitude,
            finalLongitude);
        checkBoundaryCondition = "정방향, 직선";

        distanceToPath = math.min(circularDistance, lineDistance);
      } else if (currentWindowValue.branch == false) {
        distanceToPath = pointLineDistance(
            currentWindowValue.point.latitude,
            currentWindowValue.point.longitude,
            currentWindow[i + 1].point.latitude,
            currentWindow[i + 1].point.longitude,
            finalLatitude,
            finalLongitude);
        checkBoundaryCondition = "정방향, 직선";
      }

      if (beforeMinDistanceToPath > distanceToPath) {
        beforeMinDistanceToPath = distanceToPath;
      }

      //boudndary = 5m
      if (beforeMinDistanceToPath > 5) {
        //오른쪽으로 경계이탈
        outOfBound = true;
      } else {
        // 안전 경계 내에 있는 경우
        outOfBound = false;
      }

      //searchNewPathBoundary = 30m
      if (beforeMinDistanceToPath > searchNewPathBoundary) {
        searchNewPath = true;
      } else {
        searchNewPath = false;
      }
    }
  }

  void _updateMapPosition(latitude, longitude, compassValue) {
    if (mapController == null) {
      // debugPrint('addOverlays() mapController is not initialized yet.');
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

  void _updateCurrentLocationMarker(latitude, longitude) async {
    // debugPrint(':::::::::::::::_updateCurrentLocationMarker');
    if (mapController == null) {
      // debugPrint('addOverlays() mapController is not initialized yet.');
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
        icon: iconImage);

    mapController!.addOverlay(_currentLocationMarker!);
  }

  void addBranchMarkers() async {
    if (mapController == null) {
      // debugPrint('addOverlays() mapController is not initialized yet.');
      return;
    }

    Set<NAddableOverlay> markers = {}; // 마커들을 담을 Set

    final iconImage = await NOverlayImage.fromWidget(
        widget: Icon(
          Icons.circle,
          color: Colors.green,
          size: 15,
        ),
        size: const Size(15, 15),
        context: context);

    for (var branch in branchInfo) {
      _testMarker = NMarker(
          id: 'checkPoint_${branchInfo.indexOf(branch)}', // 각 마커의 고유 ID
          position: NLatLng(
              branch.point.latitude, branch.point.longitude), // 마커의 좌표 설정
          icon: iconImage);

      markers.add(_testMarker!);
    }

    // 맵에 마커 추가
    mapController!.addOverlayAll(markers);
  }

  Timer? navigationTimer;

  void _updateNavigation(double currentLat, double currentLng) {
    navigationBloc.add(UpdateNavigation(currentLat, currentLng)); // 이벤트 호출
  }

  // 안내음 타이머
  void startNavigationTimer() {
    navigationTimer?.cancel(); // 기존 타이머 제거
    navigationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      // 현 위치로부터 다음 목표 위경도까지의 거리를 계산하여 remainDistance 변수에 삽입
      _updateNavigation(finalLatitude, finalLongitude);

      final state = navigationBloc.state;
      if (state is NavigationInProgress) {
        remainStartPoint = calculateDistance(finalLatitude, finalLongitude,
            branchInfo[0].point.latitude, branchInfo[0].point.longitude);

        if (remainStartPoint < 0.015) {
          isStart = false;
        }
        if (isStart == false) {
          if (branchInfo.isNotEmpty && targetIndex < branchInfo.length) {
            branchTargetIndex = targetIndex;

            while (branchTargetIndex < branchInfo.length &&
                !branchInfo[branchTargetIndex].branch) {
              branchTargetIndex++;
            }
            if (branchInfo[branchTargetIndex].branch) {
              remainDistance = calculateDistance(
                  finalLatitude,
                  finalLongitude,
                  branchInfo[branchTargetIndex].point.latitude,
                  branchInfo[branchTargetIndex].point.longitude);
              clock = getGuidanceDirection(
                  branchInfo[currentIndex].point.longitude,
                  branchInfo[currentIndex].point.latitude,
                  branchInfo[targetIndex].point.longitude,
                  branchInfo[targetIndex].point.latitude,
                  finalLatitude,
                  finalLongitude,
                  branchInfo[currentIndex].bearingToPoint);
            }

            // 추가적인 로직
          } else {
            // branchinfo가 비어 있거나 targetIndex가 유효하지 않을 때의 처리 로직
          }

          // 목표지점까지의 남은 거리가 15m 이내라면
          //반복되어서 안내문이 나오는 이유
          if (remainDistance < 0.015) {
            // 만약 그 목표 지점이 횡단보도라면
            if (branchInfo[currentIndex].crosswalk == true) {
              // 경광등을 켜라.
              final result = await flashOnWithWeather(NoParams());
              if (result.isLeft()) {
                print('안전 경광등을 사용할 수 없습니다.');
              } else {
                print('안전 경광등이 켜졌습니다.');
              }
              await tts.speak('잠시 후 횡단보도 입니다. 차량에 유의하세요!');
            }

            if (branchInfo[targetIndex].branch == true) {
              await tts.speak('${branchInfo[targetIndex].description}하세요.');
            }
          }
          if (currentIndex > 0 &&
              (branchInfo[currentIndex].bearingToPoint - compassValue)
                  .abs() <=
                  18 ||
              (branchInfo[currentIndex].bearingToPoint - compassValue).abs() >=
                  342) {
            Vibration.vibrate(duration: 200);
            print(
                "경로내 진동 베어링 값 ${(branchInfo[currentIndex].bearingToPoint - compassValue)}");
          }
          //임시 주석
          // 경로 이탈 시 경로이탈 안내
          if (state.outOfBound) {
            Vibration.vibrate(duration: 100);
            await tts.speak(clock);
            // 경로 재검색 로직 추가
            if (searchNewPath) {
              searchNewPathTime++;
              if (searchNewPathTime >= 5) {
                requestNewPath(
                    finalLatitude, finalLongitude); // 새로운 목적지로 지도 업데이트

                await tts.speak('경로를 이탈하여 새로운 경로로 안내합니다.');
                searchNewPathTime = 0;
              }
            } else {
              searchNewPathTime = 0;
            }
          }
        } else if (isStart == true) {
          await tts.speak("출발지로 이동하세요.");
        }
      }
    });
  }


}