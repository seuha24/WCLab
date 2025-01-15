part of '../../framework/ui.dart';

/// NavigationService
///
/// 이 클래스는 애플리케이션의 내비게이션 관련 기능을 관리합니다.
/// 위치 추적, 센서 데이터 처리, 경로 계산 및 길 안내 기능을 통합하여 실시간 내비게이션 지원을 제공합니다.
///
/// ### 주요 역할:
/// - **위치 관리**:
///   - GPS 및 IMU 센서를 사용하여 현재 위치를 추적합니다.
///   - 사용자의 위치를 업데이트하고 GPS와 IMU 데이터 소스 간 전환을 처리합니다.
///
/// - **경로 계산**:
///   - 사용자 위치와 목표 경로 간 거리, 방위각, 경계 이탈 여부를 계산합니다.
///   - 다음 경로 포인트로의 안내 방향(예: "12시 방향", "3시 방향")을 제공합니다.
///
/// - **센서 통합**:
///   - 가속도계, 나침반, 자이로스코프 스트림을 구독하여 고급 위치 업데이트를 수행합니다.
///   - 칼만 필터 및 가중 이동 평균을 적용하여 센서 데이터를 보정합니다.
///
/// - **지도 및 시각화**:
///   - 지도 컨트롤러와 상호 작용하여 경로, 마커 및 기타 시각적 요소를 표시합니다.
///   - 지도 카메라 위치를 업데이트하고 분기점 및 경유지 마커를 추가합니다.
///
/// - **길 안내 및 알림**:
///   - 텍스트 음성 변환(TTS)을 사용하여 음성 길 안내를 제공합니다.
///   - 경계 이탈 또는 방향 조정을 위해 진동 피드백을 트리거합니다.
///   - 타이머를 관리하여 주기적으로 내비게이션 안내를 업데이트합니다.
///
/// - **동적 경로 업데이트**:
///   - 계획된 경로에서의 이탈 여부를 모니터링합니다.
///   - 경로 이탈이 감지되면 새로운 경로를 요청합니다.
///
/// ### 주요 기능:
/// - 가속도계 및 자이로스코프 데이터를 사용한 센서 기반 위치 추정.
/// - GPS와 IMU 데이터를 실시간으로 통합하여 내비게이션 정확도를 향상시킵니다.
class NavigationService {
  NavigationService(this.ttsService);

  late final TtsService ttsService;

  /// Stream Controllers
  ///
  /// Loading Stream Controller
  final _loadingController = StreamController<bool>.broadcast();

  Stream<bool> get loadingStream => _loadingController.stream;

  void initLoadingState() {
    _loadingController.add(true);
  }

  void updateLoadingState(bool isLoading) {
    _loadingController.add(isLoading);
  }

  /// Path Stream Controller
  final StreamController<Map<String, dynamic>> _pathStreamController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get pathStream => _pathStreamController.stream;

  /// Location Marker Stream Controller
  final StreamController<Map<String, dynamic>> _locationMarkerController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get locationMarkerStream =>
      _locationMarkerController.stream;

  /// Map Position Stream Controller
  final StreamController<Map<String, dynamic>> _mapPositionController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get mapPositionStream =>
      _mapPositionController.stream;

  // 네이티브 위치 확인용
  late double s_latitude;
  late double s_longitude;
  late double s_accuracy;

  // 좌표 관련된 변수
  late double gpsLatitude;
  late double gpsLongitude;

  // IMU 센서 포지션
  late StreamSubscription<Position> positionStream;

  // GPS 포지션
  late Position position;

  bool isAccRunning = false;
  double preAccX = 0.0, preAccY = 0.0, preAccZ = 0.0;
  double curAccX = 0.0, curAccY = 0.0, curAccZ = 0.0;
  double velocityX = 0.0, velocityY = 0.0, velocityZ = 0.0;
  double rotationX = 0.0, rotationY = 0.0, rotationZ = 0.0;
  double rotationXSum = 0.0, rotationYSum = 0.0, rotationZSum = 0.0;
  double imuLocationX = 0.0, imuLocationY = 0.0;
  double compassValue = 0.0, lastCompassValue = 0.0;
  double yawRate = 0.0,
      yawRate2 = 0.0,
      yawRatePerDt = 0.0,
      yawRateTurn2 = 0.0,
      yawRateAccFilteringValue = 0.3;

  // imu로 계산된 위경도 변수
  double imuLatitude = 0.0, imuLongitude = 0.0;

  // 최종 위경도 변수
  late double finalLatitude;
  late double finalLongitude;

  // imu, gps 전환 플래그
  bool isGps = false;

  // 길안내 관련 변수
  double remainDistance = double.infinity; // 다음 분기까지의 남은거리 (초기값: 무한대)

  GeoLocation? selectedStartLocation; // 시작 위치의 좌표값 객체
  bool isSetStart = false; // 출발지가 선택됐을 경우 true, 아닐경우 false
  bool isSetDestination = false; // 목적지가 선택됐을 경우 true, 아닐경우 false
  bool onStartPoint = false; // 출발지 도착 여부
  late double remainStartPoint;

  int branchTargetIndex = 0;
  GeoLocation? selectedDestinationLocation; // 검색된 위치의 좌표값 객체
  List<LatLng> paths = []; // 모든 경로의 좌표값을 담는 배열
  List<BranchInfo> branchInfoList = []; // 분기의 객체 배열

  double turnUpdate2(double bearingToPoint, double compassValue) {
    // 방위각 차이 계산
    return compassValue - bearingToPoint;
  }

  final ControlFlash flashOnWithWeather = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_ON_WITH_WEATHER,
  );

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

  /// 초기화 메서드.
  /// 내비게이션 서비스를 초기화하고 위치 데이터를 설정합니다.
  void init() {
    // debugPrint('NavigationService init()');
    initLoadingState();
    _initLocation();
  }

  /// 자원 해제 메서드.
  /// 센서 스트림 및 타이머를 정리하고 필요한 모든 서비스를 종료합니다.
  void dispose() {
    for (var subscription in _streamSubscriptions) {
      subscription.cancel(); // 각 구독 해제
    }
    _streamSubscriptions.clear(); // 리스트 클리어

    navigationTimer?.cancel();

    ttsService.stop();
  }

  /// 속도 및 센서 데이터를 초기화하는 메서드.
  /// 새로운 경로나 경로 재설정 시 호출됩니다.
  void _resetSpeedUtilsValue() {
    // debugPrint('resetSpeedUtilsValueFunc 실행');
    imuLatitude = 0.0;
    imuLongitude = 0.0;
    preAccX = 0.0;
    preAccY = 0.0;
    preAccZ = 0.0;
    yawRatePerDt = 0;
    yawRate = compassValue * math.pi / 180;
  }

  /// 칼만필터 적용
  final kalmanX = SimpleKalman(errorMeasure: 2, errorEstimate: 2, q: 0.8);
  final kalmanY = SimpleKalman(errorMeasure: 2, errorEstimate: 2, q: 0.8);
  final kalmanZ = SimpleKalman(errorMeasure: 2, errorEstimate: 2, q: 0.8);

  /// Bloc에 전달하기 위한 최종 데이터 계산 메서드.
  Map<String, dynamic> finalCoordinates() {
    return {
      'latitude': finalLatitude,
      'longitude': finalLongitude,
      'compassValue': compassValue,
    };
  }

  /// 위치를 업데이트하는 메서드.
  /// IMU 센서를 기반으로 현재 위치를 계산합니다.
  /// [sensorInterval]: 센서의 업데이트 간격.
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

  /// Yaw rate를 업데이트하는 메서드.
  /// [value]: 추가될 Yaw 값.
  void _updateYawRate(double value) {
    yawRate += value;
    if (yawRate < 0 && yawRate >= -2 * math.pi) {
      yawRate += 2 * math.pi;
    }
  }

  void _updateYawRate2() {
    if (yawRate >= 2 * math.pi || yawRate <= -2 * math.pi) {
      yawRate = 0;
    }
    yawRate2 -= yawRatePerDt;
    yawRateTurn2 = yawRate2 * 180 / math.pi;
  }

  /// GPS를 통해 초기 위치를 설정하는 메서드.
  /// GPS 정확도와 상태를 기반으로 초기 위치를 설정합니다.
  Future<void> _initLocation() async {
    // debugPrint('initLocation()');
    int gpsAccuracy = 20;

    position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 1));
    gpsLatitude = position.latitude;
    gpsLongitude = position.longitude;
    finalLatitude = gpsLatitude;
    finalLongitude = gpsLongitude;

    // debugPrint('position.accuracy: ${position.accuracy}');

    if (position.accuracy <= gpsAccuracy) {
      isGps = true;
      updateLoadingState(false);
    } else {
      isGps = false;
      updateLoadingState(false);
    }

    // 가속도계 이벤트 처리
    subscribeToSensor<UserAccelerometerEvent>(
      sensorStream: userAccelerometerEventStream(
        samplingPeriod: SensorInterval.normalInterval,
      ),
      onEvent: (event) async {
        // debugPrint('userAccelerometerEvent: $event');
        curAccX = event.x;
        curAccY = event.y;
        curAccZ = event.z;
        double accelerationMagnitude = math
            .sqrt(curAccX * curAccX + curAccY * curAccY + curAccZ * curAccZ);
        if (accelerationMagnitude > 1.0 &&
            accelerationMagnitude < 10.0 &&
            !isAccRunning) {
          isAccRunning = true;
          position = await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(
                  accuracy: LocationAccuracy.high, distanceFilter: 5));
          if (position.accuracy > gpsAccuracy) {
            // debugPrint('UserAccelerometerEvent moveByImu()');
            await moveByImu();
          } else {
            // debugPrint('UserAccelerometerEvent moveByGps()');
            await moveByGps();
          }
        }
        isAccRunning = false;
      },
      onError: (e) => debugPrint(e),
    );

    // 나침반 이벤트 처리
    subscribeToSensor<CompassEvent>(
      sensorStream: FlutterCompass.events!,
      onEvent: (event) {
        // debugPrint('compassEvent: $event');
        compassValue = event.heading ?? 0.0;
        yawRate = (compassValue * math.pi / 180);
        _updateYawRate(0);

        if ((compassValue - lastCompassValue).abs() >= 1.0) {
          lastCompassValue = compassValue;
          _mapPositionController.add({
            'latitude': finalLatitude,
            'longitude': finalLongitude,
            'compassValue': compassValue,
          });
        }
        s_accuracy = position.accuracy;
      },
      onError: (e) => debugPrint(e),
    );

    // 자이로스코프 이벤트 처리
    subscribeToSensor<GyroscopeEvent>(
      sensorStream: gyroscopeEventStream(
        samplingPeriod: SensorInterval.normalInterval,
      ),
      onEvent: (GyroscopeEvent event) {
        // debugPrint('gyroscopeEvent: $event');
        final deltaTime =
            (SensorInterval.normalInterval).inMilliseconds / 1000.0;
        rotationX = event.x * deltaTime;
        rotationY = event.y * deltaTime;
        rotationZ = event.z * deltaTime;
        rotationXSum += rotationX;
        rotationYSum += rotationY;
        rotationZSum += rotationZ;
        if (event.z > yawRateAccFilteringValue * math.pi / 180 ||
            event.z < -yawRateAccFilteringValue * math.pi / 180) {
          yawRatePerDt = (event.z *
              (SensorInterval.normalInterval.inMilliseconds /
                  1000.0)); // 회전 각도 계산
        }
        _updateYawRate2();
      },
      onError: (e) => debugPrint(e),
    );

    // 위치 스트림 처리
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    )
        .throttleTime(SensorInterval.normalInterval)
        .listen((Position position) async {
      // debugPrint('positionStream: $position');
      if (position.accuracy <= gpsAccuracy) {
        await moveByGps();
        // await moveByImu();
      }
    });
  }

  void moveDot(importedLatitude, importedLongitude, isGps) {
    debugPrint('moveDot()');
    // debugPrint('moveDot() - importedLatitude: $importedLatitude, importedLongitude: $importedLongitude');
    // debugPrint('moveDot() - finalLatitude: $finalLatitude, finalLongitude: $finalLongitude');
    if (importedLatitude != finalLatitude ||
        importedLongitude != finalLongitude) {
      finalLatitude = importedLatitude;
      finalLongitude = importedLongitude;

      // debugPrint('_navigationStreamController.add()');
      // Stream에 데이터 전송
      _locationMarkerController.add({
        'latitude': importedLatitude,
        'longitude': importedLongitude,
        'isGps': isGps,
      });

      _mapPositionController.add({
        'latitude': importedLatitude,
        'longitude': importedLongitude,
        'compassValue': compassValue,
      });

      // debugPrint(
      //     'finalLatitude: $finalLatitude, finalLongitude: $finalLongitude, moveDotFunc 진행 완료');
    }
  }

  Future<void> moveByGps() async {
    // debugPrint('moveByGps');
    isGps = true;
    position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 1));
    gpsLatitude = position.latitude;
    gpsLongitude = position.longitude;
    s_latitude = position.latitude;
    s_longitude = position.longitude;
    s_accuracy = position.accuracy;
    moveDot(gpsLatitude, gpsLongitude, true);
    _resetSpeedUtilsValue();
    // debugPrint(
    //     'gpsLatitude: $gpsLatitude, gpsLongitude: $gpsLongitude, moveByGPS 진행 완료. 현재 GPS 정확도 : ${position.accuracy}');
  }

  Future<void> moveByImu() async {
    // debugPrint('moveByImu');
    isGps = false;
    await _positionUpdate(SensorInterval.normalInterval);
    moveDot(imuLatitude, imuLongitude, false);
  }

  /// t맵에서 api 호출을 통해 경로 검색을 하는 비동기 함수
  /// [latitude]: 시작 위도.
  /// [longitude]: 시작 경도.
  void requestNewPath({
    required double startLat,
    required double startLng,
    double? endLat,
    double? endLng,
  }) {
    // debugPrint('requestNewPath()');
    // Stream에 데이터 전송
    _pathStreamController.add({
      'startLatitude': startLat,
      'startLongitude': startLng,
      'endLatitude': endLat ?? selectedDestinationLocation!.lat,
      'endLongitude': endLng ?? selectedDestinationLocation!.lng,
    });
  }


  /// 현재 위치에서 목표 지점까지의 방위각을 계산하는 메서드.
  /// [initialLatitude], [initialLongitude]: 시작 위치의 위경도.
  /// [targetLatitude], [targetLongitude]: 목표 위치의 위경도.
  /// 반환값: 방위각 (도).
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

  /// 특정 점과 두 지점 간의 최단 거리를 계산하는 메서드.
  /// [lat1], [lon1]: 첫 번째 지점의 위경도.
  /// [lat2], [lon2]: 두 번째 지점의 위경도.
  /// [latP], [lonP]: 점의 위경도.
  /// 반환값: 점과 선 사이의 최단 거리 (m).
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

  /// 센서를 구독하는 메서드.
  /// [sensorStream]: 센서 이벤트 스트림.
  /// [onEvent]: 이벤트 발생 시 호출할 함수.
  /// [onError]: 오류 발생 시 호출할 함수.
  void subscribeToSensor<T>(
      {required Stream<T> sensorStream,
      required Function(T event) onEvent,
      required Function(dynamic error) onError}) {
    var subscription =
        sensorStream.throttleTime(Duration(milliseconds: 200)).listen(
              onEvent,
              onError: onError,
              cancelOnError: true,
            );
    _streamSubscriptions.add(subscription);
  }

  /// 주어진 인덱스를 기준으로 경로의 현재 윈도우를 반환하는 메서드.
  /// [branchInfoList]: 경로 분기 정보 리스트.
  /// [currentIndex]: 현재 경로의 인덱스.
  /// [windowSize]: 슬라이딩 윈도우의 크기.
  /// 반환값: 현재 인덱스 주변의 분기 정보 리스트.
  List<BranchInfo> getCurrentWindow(
      List<BranchInfo> branchInfoList, int currentIndex, int windowSize) {
    //windowSize는 언제나 홀수
    int windowOffset = (windowSize - 1) ~/ 2;
    // 윈도우의 시작과 끝 인덱스 계산
    int start = currentIndex - windowOffset;
    int end = currentIndex + windowOffset;
    // 시작 인덱스가 0보다 작지 않도록 조정
    start = start < 0 ? 0 : start;
    // 끝 인덱스가 리스트의 마지막 인덱스를 초과하지 않도록 조정
    end = end >= branchInfoList.length ? branchInfoList.length - 1 : end;
    // 슬라이딩 윈도우 내의 체크포인트들을 담을 리스트
    List<BranchInfo> window = [];
    // 시작 인덱스부터 끝 인덱스까지의 체크포인트들을 리스트에 추가
    for (int i = start; i <= end; i++) {
      window.add(branchInfoList[i]);
    }
    return window;
  }

  Future<void> indexUpdate() async {
    debugPrint('indexUpdate()');
    // debugPrint('currentIndex: $currentIndex, targetIndex: $targetIndex');
    // debugPrint('branchInfoList.length: ${branchInfoList.length}');

    yawRate2 =
        turnUpdate2(branchInfoList[currentIndex].bearingToPoint, compassValue) *
            math.pi /
            180;

    List<BranchInfo> currentWindow =
        getCurrentWindow(branchInfoList, currentIndex, 5);
    int nearestIndex = await moveIndex(currentWindow);

    // targetIndex 업데이트 (순환 처리)
    targetIndex = (targetIndex + 1) % branchInfoList.length;

    debugPrint('nearestIndex: $nearestIndex, currentIndex: $currentIndex');

    if ((nearestIndex < currentWindow.length || nearestIndex > 0) &&
        nearestIndex != currentIndex) {
      currentIndex = nearestIndex;
    }
  }

  Future<double> distanceBetweenBranchFunc(List<BranchInfo> branchInfoList,
      int currentIndex, int targetIndex) async {
    double currentIndexLatitude = branchInfoList[currentIndex].point.latitude;
    double currentIndexLongitude = branchInfoList[currentIndex].point.longitude;
    double targetIndexLatitude = branchInfoList[targetIndex].point.latitude;
    double targetIndexLongitude = branchInfoList[targetIndex].point.longitude;
    return await calculateDistanceInIsolate(currentIndexLatitude,
        currentIndexLongitude, targetIndexLatitude, targetIndexLongitude, '1');
  }

  Future<int> moveIndex(List<BranchInfo> currentWindow) async {
    double beforeMin = double.maxFinite; // window 내에 가장 가까운 값
    int nearestIndex = currentIndex; // 현재 인덱스
    double distanceBetweenBranch = await distanceBetweenBranchFunc(
        branchInfoList,
        currentIndex,
        targetIndex); //currentWindow-> branchInfoList
    if (distanceBetweenBranch == 0) {
      nearestIndex = targetIndex;
    }
    double currentDistance = 0.0;
    for (BranchInfo window in currentWindow) {
      debugPrint('window :$window');
      currentDistance = await calculateDistanceInIsolate(window.point.latitude,
          window.point.longitude, finalLatitude, finalLongitude, '2');

      double currentIndexDistance = await calculateDistanceInIsolate(
          branchInfoList[nearestIndex].point.latitude,
          branchInfoList[nearestIndex].point.longitude,
          finalLatitude,
          finalLongitude,
          '3');
      if (currentDistance < beforeMin &&
          currentIndexDistance >=
              distanceBetweenBranch - (distanceBetweenBranch / 20)) {
        beforeMin = currentDistance;
        nearestIndex =
            branchInfoList.indexOf(window); // 가장 가까운 체크포인트의 인덱스를 찾습니다.
      }
    }
    return nearestIndex;
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
      double adjustedCompassValue,
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

    // 목표 방향으로 안내 각도 계산
    double baseAngle = (breakPointAngle['breakPointAngleC']! * (180 / math.pi));

    // 목표 지까지의 각도를 계산
    // adjustedCompassValue를 사용해 나침반 값 보정
    double guidanceAngle = (baseAngle + adjustedCompassValue) % 360;

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
      double yawRateTurn2,
      double bearingToPoint) {
    int boundaryExit = checkLateralDeviation(
      currentIndexLatitude,
      currentIndexLongitude,
      targetIndexLatitude,
      targetIndexLongitude,
      finalLatitude,
      finalLongitude,
    );

    // 현재 스마트폰 방향을 기준으로 나침반 값 보정
    double adjustedCompassValue = compassValue; // 기본 나침반 값
    if (compassValue >= 0 && compassValue <= 360) {
      // 보정 로직 추가
      adjustedCompassValue = (compassValue + yawRateTurn2) % 360;
    }

    double guidanceAngle = angleToTarget(
        currentIndexLongitude,
        currentIndexLatitude,
        targetIndexLongitude,
        targetIndexLatitude,
        finalLatitude,
        finalLongitude,
        adjustedCompassValue,
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
  //branch일 경우의 branchInfoList[currentIndex]를 전부 currentWindowValue로 바꿈
  Future<void> checkBoundary() async {
    debugPrint('checkBoundary()');
    List<BranchInfo> currentWindow =
        getCurrentWindow(branchInfoList, currentIndex, 5);
    double beforeMinDistanceToPath = double.maxFinite;
    //점과 직선 최소거리
    for (int i = 0; i < currentWindow.length - 1; i++) {
      var currentWindowValue = currentWindow[i];
      // debugPrint("Index: $i");

      targetIndex = currentIndex + 1;

      if (currentWindowValue.branch == true) {
        circularDistance = await calculateDistanceInIsolate(
                currentWindowValue.point.latitude,
                currentWindowValue.point.longitude,
                finalLatitude,
                finalLongitude,
                '4') *
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

  Timer? navigationTimer;

  /// 내비게이션 타이머를 시작하는 메서드.
  /// 2초 간격으로 내비게이션 상태를 업데이트하고, 안내 음성 및 경로 이탈 로직을 실행합니다.
  void startNavigationTimer() {
    debugPrint('startNavigationTimer()');
    navigationTimer?.cancel(); // 기존 타이머 제거
    navigationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      debugPrint('navigationTimer: $timer');
      // debugPrint('onStartPoint: onStartPoint');

      _handleNavigationLogic();
    });
  }

  Future<void> _handleNavigationLogic() async {
    try {
      // 현 위치로부터 다음 목표 위경도까지의 거리를 계산하여 remainDistance 변수에 삽입
      await checkBoundary(); //경계이탈, 인덱스
      await indexUpdate();

      remainStartPoint = await calculateDistanceInIsolate(
          finalLatitude,
          finalLongitude,
          branchInfoList[0].point.latitude,
          branchInfoList[0].point.longitude,
          '5');

      debugPrint(
          'remainStartPoint: $remainStartPoint, onStartPoint: $isSetStart');

      if (remainStartPoint < 0.015) {
        onStartPoint = true;
      }

      if (onStartPoint == true) {
        _handleOnStartPointLogic();
      } else if (onStartPoint == false) {
        speakTTS("출발지로 이동하세요.");
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in indexUpdate: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> _handleOnStartPointLogic() async {
    if (branchInfoList.isNotEmpty && targetIndex < branchInfoList.length) {
      branchTargetIndex = targetIndex;

      while (branchTargetIndex < branchInfoList.length &&
          !branchInfoList[branchTargetIndex].branch) {
        branchTargetIndex++;
      }
      if (branchInfoList[branchTargetIndex].branch) {
        remainDistance = await calculateDistanceInIsolate(
            finalLatitude,
            finalLongitude,
            branchInfoList[branchTargetIndex].point.latitude,
            branchInfoList[branchTargetIndex].point.longitude,
            '6');

        // FIXME : 디바이스의 헤딩과 '12시 방향' 이 일치하지 않는 이슈 수정 필요
        clock = getGuidanceDirection(
          branchInfoList[currentIndex].point.longitude,
          branchInfoList[currentIndex].point.latitude,
          branchInfoList[targetIndex].point.longitude,
          branchInfoList[targetIndex].point.latitude,
          finalLatitude,
          finalLongitude,
          yawRateTurn2,
          branchInfoList[currentIndex].bearingToPoint,
        );

        await _handleBranchLogic();
      }
    }
  }

  Future<void> _handleBranchLogic() async {
    // 목표지점까지의 남은 거리가 15m 이내라면
    //반복되어서 안내문이 나오는 이유
    if (remainDistance < 0.015) {
      // 만약 그 목표 지점이 횡단보도라면
      if (branchInfoList[currentIndex].crosswalk == true) {
        // 경광등을 켜라.
        final result = await flashOnWithWeather(NoParams());
        if (result.isLeft()) {
          debugPrint('안전 경광등을 사용할 수 없습니다.');
        } else {
          debugPrint('안전 경광등이 켜졌습니다.');
        }
        speakTTS('잠시 후 횡단보도 입니다. 차량에 유의하세요!');
      }

      if (branchInfoList[targetIndex].branch == true) {
        speakTTS('${branchInfoList[targetIndex].description}하세요.');
      }
    }
    if (currentIndex > 0 &&
        (branchInfoList[currentIndex].bearingToPoint - compassValue)
            .abs() <=
            18 ||
        (branchInfoList[currentIndex].bearingToPoint - compassValue)
            .abs() >=
            342) {
      Vibration.vibrate(duration: 200);
      debugPrint(
          "경로내 진동 베어링 값 ${(branchInfoList[currentIndex].bearingToPoint - compassValue)}");
    }

    // 경로 이탈 시 경로이탈 안내
    if (outOfBound) {
      Vibration.vibrate(duration: 100);
      speakTTS(clock);
      // 경로 재검색 로직 추가
      if (searchNewPath) {
        searchNewPathTime++;
        if (searchNewPathTime >= 5) {
          requestNewPath(
            startLat: finalLatitude,
            startLng: finalLongitude,
          ); // 새로운 목적지로 지도 업데이트

          speakTTS('경로를 이탈하여 새로운 경로로 안내합니다.');
          searchNewPathTime = 0;
        }
      } else {
        searchNewPathTime = 0;
      }
    }
  }

  /// TTS를 통해 안내 메시지를 출력하는 메서드.
  /// [message]: 출력할 메시지.
  Future<void> speakTTS(String message) async {
    // debugPrint('speakTTS: $message');
    // Future.delayed(Duration(milliseconds: 500), () {
      ttsService.speak(message);
    // });
  }
}


/// 두 위경도 간의 거리를 계산하는 메서드.
/// [lat1], [lon1]: 첫 번째 점의 위경도.
/// [lat2], [lon2]: 두 번째 점의 위경도.
/// 반환값: 두 점 사이의 거리 (km).

/// - 위경도 계산은 삼각 함수 연산을 포함하므로, 반복 호출 시 메인 스레드에 부하를 줄 수 있음.
/// - isolate를 활용하여 연산 작업을 별도의 스레드에서 수행함으로써 UI 성능을 개선.
Future<double> calculateDistanceInIsolate(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    String word,
    ) async {
  debugPrint('word: $word');
  debugPrint(
      'calculateDistanceInIsolate() lat1: $lat1, lon1: $lon1, lat2: $lat2, lon2: $lon2');

  final args = [lat1, lon1, lat2, lon2];
  return await compute(_calculateDistance, args);
}

double _calculateDistance(List<double> args) {
  debugPrint('calculateDistance() args: $args');

  const double earthRadius = 6371.0;
  double toRadians(double degree) {
    return degree * math.pi / 180.0;
  }

  double lat1 = args[0];
  double lon1 = args[1];
  double lat2 = args[2];
  double lon2 = args[3];

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

