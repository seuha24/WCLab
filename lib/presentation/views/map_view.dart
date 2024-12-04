part of '../../framework/ui.dart';

class BranchInfo {
  LatLng point; // 모든 경로값
  String description; // 각 분기의 경로값
  double bearingToPoint; // 다음 경로까지의 방향값
  bool crosswalk; // branch 좌표가 횡단보도면 true, 아니면 false
  bool branch; // 해당 point가 branch 좌표라면 true, 아니면 false
  BranchInfo(
      // 생성자
      this.point,
      this.description,
      this.bearingToPoint,
      this.crosswalk,
      this.branch);

  @override
  String toString() {
    return 'BranchInfo{point: $point, : $branch, description: $description, bearingToBranch: $bearingToPoint, crosswalk: $crosswalk}';
  }
}

class WeightedAverageFilter {
  final List<double?> _queue;
  final List<double> _weights;
  int _front = 0;
  int _rear = 0;
  int _size = 0;

  WeightedAverageFilter(int capacity, List<double> weights)
      : _queue = List<double?>.filled(capacity, null),
        _weights = List<double>.from(weights);

  bool get isEmpty => _size == 0;
  bool get isFull => _size == _queue.length;

  //새로운 데이터 추가
  void enqueue(double element) {
    if (isFull) {
      dequeue();
    }
    _queue[_rear] = element;
    _rear = (_rear + 1) % _queue.length;
    _size++;
  }

  //제일 오래된 데이터 삭제
  double? dequeue() {
    if (isEmpty) {
      throw Exception("Queue is empty");
    }
    double? element = _queue[_front];
    _queue[_front] = null;
    _front = (_front + 1) % _queue.length;
    _size--;
    return element;
  }

  //데이터 조회
  double? peek() {
    if (isEmpty) {
      return null;
    }
    return _queue[_front];
  }

  //queue를 초기화
  void clear() {
    while (!isEmpty) {
      dequeue();
    }
  }

  //queue내의 요소의 평균을 계산
  double calculateWeightedAverage() {
    if (isEmpty) {
      return 0.0;
    }
    double weightedSum = 0.0;
    double weightSum = 0.0;
    for (int i = 0; i < _queue.length; i++) {
      double? element = _queue[(_front + i) % _queue.length];
      if (element != null) {
        weightedSum += element * _weights[i];
        weightSum += _weights[i];
      }
    }
    return weightSum == 0.0 ? 0.0 : weightedSum / weightSum;
  }
}

class NaverMapView extends StatefulWidget {
  const NaverMapView({super.key});

  @override
  State<NaverMapView> createState() => _NaverMapViewState();
}

class _NaverMapViewState extends State<NaverMapView> {
  final FlutterTts tts = FlutterTts();

  late double currentLatitude; // 현재 위치의 위도
  late double currentLongitude; // 현재 위치의 경도
  double remainDistance = double.infinity; // 다음 분기까지의 남은거리 (초기값: 무한대)

  GeoLocation? startSelectedLocation; // 시작 위치의 좌표값 객체
  bool isStart = false; // 출발지가 선택됐을 경우 true, 아닐경우 false
  late double remainStartpoint;

  int branchTargetIndex = 0;
  bool isLoading = true; // 로딩을 위한 T/F

  GeoLocation? selectedLocation; // 검색된 위치의 좌표값 객체
  late NaverMapController mapController;
  List<LatLng> paths = []; // 모든 경로의 좌표값을 담는 배열
  List<BranchInfo> branchinfo = []; // 분기의 객체 배열

  Map<String, dynamic>? _currentLocation;
  late double s_latitude; // 네이티브 위도 확인용
  late double s_longitude; // 네이티브 경도 확인용
  late double s_accuracy; // 네이티브 위치정확도 확인용

  final ControlFlash flashOnWithWeather = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_ON_WITH_WEATHER,
  );

  Timer? _locationUpdateTimer;
  NMarker? _currentLocationMarker;
  NMarker? _testMarker;

  //compass값을 받아왔는지 체크
  Completer<void> compassReady = Completer<void>();

  // 가속도
  double preAccX = 0.0;
  double preAccY = 0.0;
  double currentpreAccX = 0.0;
  double currentpreAccY = 0.0;

  // 속도
  double velocityX = 0.0;
  double velocityY = 0.0;
  double currentSpeed = 0.0;

  // 방향
  double? heading = 0.0;
  double? adjustment;
  double yawRate = 0.0;
  double yawRate2 = 0.0;
  double yawRatePerDt = 0.0;
  double yawRateVelocity = 0.0;
  double compassValue = 0.0;
  double yawRateTurn = 0.0;
  double yawRateTurn2 = 0.0;
  double turn = 0.0;
  double firstBearingToPoint = 0.0;
  String clock = "";

  // 거리
  double px = 0.0;
  double py = 0.0;
  double distanceToPath = 0.0;
  double circularDistance = 0.0;
  double lineDistance = 0.0;

  //추가
  double nearestDistance = 0.0;

  //

  double initialLatitude = 35.9078;
  double initialLongitude = 127.7669;

  late double beforeLatitude;
  late double beforeLongitude;

  // 상수
  double accFilteringValue = 0.06;
  double radianToAngle = (180 / math.pi);
  double angleToRadian = (math.pi / 180);

  double yawRateAccFilteringValue = 0.3;
  double detectiveRange = 0.5; // 감지 범위
  double iphone12Filter = ((1 / 130) * (math.pi / 180));

  // 인덱스
  int currentIndex = 0; // 현재 인덱스
  int targetIndex = 0; // 향하고있는 인덱스

  // 경계이탈
  bool outOfBound = false;
  double boundary = 5; // 안전경계 범위
  bool searchNewPath = false;

  //추가
  double searchNewPathBoundary = 30;
  int searchNewPathTime = 0;

  // imu, gps 전환 플래그
  bool isGps = false;

  String checkBoudaryCondition = "";

  //imu로 계산된 위경도 변수
  double ImuLatitude = 0.0;
  double ImuLongitude = 0.0;

  //가중이동평균필터 인스턴스 생성
  final WeightedAverageFilter _filteringX =
      WeightedAverageFilter(5, [0.1, 0.2, 0.3, 0.4, 0.5]);
  final WeightedAverageFilter _filteringY =
      WeightedAverageFilter(5, [0.1, 0.2, 0.3, 0.4, 0.5]);

  @override
  void initState() {
    super.initState();
    _initTTS();
    _initLocation();
    LocationPlugin.locationStream.listen((locationData) {
      setState(() {
        _currentLocation = locationData;
      });
    });
  }

  // yawRate(z축회전 속도) 노이즈 조정
  double addYawRateNoise(double addValue) {
    return addValue;
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

  // 새로운 경로, 경로 재설정 시 속도, 방향, 위치, 체크포인트 메세지 초기화
  void resetSpeedUtilsValue() {
    // 방향 초기화
    yawRatePerDt = 0;
    yawRate = compassValue * angleToRadian;

    // 위치 초기화
    px = 0.0;
    py = 0.0;
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
    ImuLatitude = latLng['latitude']!;
    ImuLongitude = latLng['longitude']!;
  }

  // 함수 정의
  Map<String, double> calLatLng(
      double startLat, double startLng, double bearing, double distanceKm) {
    const double earthRadiusKm = 6371.0;
    // 도를 라디안으로 변환하는 함수
    double degreesToRadians(double degrees) {
      return degrees * math.pi / 180;
    }

    // 라디안을 도로 변환하는 함수
    double radiansToDegrees(double radians) {
      return radians * 180 / math.pi;
    }

    // 위도, 경도를 라디안으로 변환
    double startLatRad = degreesToRadians(startLat);
    double startLngRad = degreesToRadians(startLng);
    double bearingRad = degreesToRadians(bearing);
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
    double newLat = radiansToDegrees(newLatRad);
    double newLng = radiansToDegrees(newLngRad);
    // 결과 반환
    return {'latitude': newLat, 'longitude': newLng};
  }

  Future<void> _initTTS() async {
    await tts.setLanguage("ko-KR");
    await tts.setSpeechRate(0.7);
  }

  Future<void> _speakText(String text) async {
    await tts.speak(text);
  }

  double? _lastDirection; // 마지막 방향 값
  final double _threshold = 1.0; // 방향 변화 임계값 (단위: 도)
  late StreamSubscription<Position> positionStream;

  Future<void> _initLocation() async {
    int gpsAccuracy = 15;
    final now = DateTime.now();
    Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5
      ));

    if (position.accuracy <= gpsAccuracy) {
      setState(() {
        isGps = true;
        isLoading = false;
      });
    } else {
      setState(() {
        isGps = false;
        isLoading = false;
      });
    }
    
    currentLatitude = position.latitude;
    currentLongitude = position.longitude;
    initialLatitude = currentLatitude;
    initialLongitude = currentLongitude;
    beforeLatitude = currentLatitude;
    beforeLongitude = currentLongitude;
    yawRate = compassValue * angleToRadian;

    // 센서받아오는 부분
    void subscribeToSensor<T>({
      required Stream<T> sensorStream,
      required Function(T event) onEvent,
      required Function(dynamic error) onError,
    }) {
      var subscription = sensorStream.listen(
        onEvent,
        onError: onError,
        cancelOnError: true,
      );
      _streamSubscriptions.add(subscription);
    }

    void moveDot() {
      if (beforeLatitude != currentLatitude || beforeLongitude != currentLongitude) {
        _updateCurrentLocationMarker(currentLatitude, currentLongitude);
        _updateMapPosition(currentLatitude, currentLongitude, compassValue);
        beforeLatitude = currentLatitude;
        beforeLongitude = currentLongitude;
        debugPrint('점 움직임');
      } else {
        debugPrint('점 움직이지 않음');
      }
    }

    Future<void> moveByGps() async {
      setState(() {
        isGps = true;
      });
      position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5
      ));
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
      s_accuracy = position.accuracy;
      moveDot();
      resetSpeedUtilsValue();
    }

    Future<void> moveByImu(event) async {
      setState(() {
        isGps = false;
      });
      _userAccelerometerEvent = event;
      final double accelerationMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (accelerationMagnitude > 1.5) { // 원하는 기준값 설정 (단위: m/s²)
        velocityX = _filteringX.calculateWeightedAverage(); //필터링된 x속도
        velocityY = _filteringY.calculateWeightedAverage(); //필터링된 y속도
        positionUpdate(event, Duration(seconds: 1));
        currentLatitude = ImuLatitude;
        currentLongitude = ImuLongitude;
        moveDot();
      }
      final interval = now.difference(_userAccelerometerUpdateTime!);
      if (interval > Duration(milliseconds: 20)) {
        _userAccelerometerLastInterval = interval.inSeconds;
      }
      _userAccelerometerUpdateTime = now;
    }

    // 나침반계에서 이벤트 올 때만 지도 방향 리프레시 하도록 변경
    // 추후 Geolocator의 getHeadingStream()으로 변경해봐도 좋음
    subscribeToSensor<CompassEvent>(
      sensorStream: FlutterCompass.events!,
      onEvent: (event) {
        heading = event.heading ?? 0.0;
        compassValue = heading!;
        if (_lastDirection == null || (heading! - _lastDirection!).abs() >= _threshold) {
          _lastDirection = heading; // 마지막 방향 업데이트
          _updateMapPosition(currentLatitude, currentLongitude, compassValue);
          yawRate = compassValue * angleToRadian;
        }
        s_accuracy = position.accuracy;
        if (!compassReady.isCompleted) {
          compassReady.complete();
        }
      },
      onError: (e) {
        debugPrint(e);
      },
    );

    // GPS 값 변화가 있을 때
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high, distanceFilter: 5))
    .listen((Position position) {
      if(position.accuracy <= gpsAccuracy) {
        debugPrint('moveByGPS 실행됨. 현재 GPS 정확도 : ${position.accuracy}');
        moveByGps();
      }
    });

    // 가속도계가 작동할 때
    subscribeToSensor<UserAccelerometerEvent>(
      sensorStream: userAccelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval),
      onEvent: (event) async {
        position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5
        ));
        if(position.accuracy > gpsAccuracy) {
          debugPrint('moveByImu 실행됨. 현재 GPS 정확도 : ${position.accuracy}');
          moveByImu(event);
        } else {
          debugPrint('가속도 센서가 작동했지만 moveByGPS 실행됨. 현재 GPS 정확도 : ${position.accuracy}');
          moveByGps();
        }
      },
      onError: (e) {
        debugPrint(e);
      });
  }

  // t맵에서 api 호출을 통해 경로 검색을 하는 비동기 함수
  Future<void> _getGeometry(c_lat, c_lng) async {
    const String apiUrl =
        'https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&callback=function'; // api url 주소

    final Map<String, dynamic> requestData = {
      "startX": c_lng, // 현재 위치의 경도값
      "startY": c_lat, // 현재 위치의 위도값
      "angle": 20,
      "speed": 30,
      "endPoiId": "10001",
      "endX": selectedLocation!.lng, // 도착지의 경도값
      "endY": selectedLocation!.lat, // 도착지의 위도값
      "reqCoordType": "WGS84GEO",
      "startName": "%EC%B6%9C%EB%B0%9C",
      "endName": "%EB%8F%84%EC%B0%A9",
      "searchOption": "0",
      "resCoordType": "WGS84GEO",
      "sort": "index"
    };

    final Map<String, String> headers = {
      'accept': 'application/json',
      'appKey': 'QKrZQE7KkR6MtxXBFx49A6gmY1a8TN3y8IyQ0qjh',
      'content-type': 'application/json',
    };

    final response = await http.post(Uri.parse(apiUrl),
        headers: headers, body: jsonEncode(requestData));

    if (response.statusCode == 200) {
      // 통신 성공했을 때 처리 로직
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      List<dynamic> features = responseData['features'];
      paths.clear(); // 경로 추가 전에 기존 paths배열 초기화
      branchinfo.clear(); // 경로 추가 전에 기존 branchinfo배열 초기화
      currentIndex = 0;
      targetIndex = 0;

      // api로 받은 Json 값을 순회하여 원하는 정보값을 추출하기 위한 for문
      for (var feature in features) {
        List<dynamic> coordinates = feature['geometry']['coordinates'];
        if (feature['geometry']['type'] == 'LineString') {
          paths.addAll(coordinates.map((coord) => LatLng(coord[1], coord[0])));
          for (var coord in coordinates) {
            LatLng point = LatLng(coord[1], coord[0]);
            if (branchinfo.isNotEmpty &&
                branchinfo[branchinfo.length - 1].point == point) {
              continue;
            }
            branchinfo.add(BranchInfo(
              point,
              '', // 설명
              0.0, // `bearingToPoint`는 항상 0.0으로 설정
              int.parse(feature['properties']['facilityType']) == 15,
              false, // `branch`는 기본적으로 false로 설정
            ));
          }
        }
        if (feature['geometry']['type'] == 'Point' && branchinfo.isNotEmpty) {
          double latitude = coordinates[1]; // branch 의 위도
          double longitude = coordinates[0]; // branch 의 경도
          String description = feature['properties']['description'];
          for (var branch in branchinfo) {
            if (branch.point.latitude == latitude &&
                branch.point.longitude == longitude) {
              // 일치하는 BranchInfo 객체를 찾으면
              branch.branch = true; // branch 속성을 true로 변경
              branch.description = description; // description 업데이트
              break; // 일치하는 객체를 찾았으므로 루프 종료
            }
          }
        }
      }
      print(branchinfo);
      addOverlays(paths); // 전체 보행자 좌표 띄우기
      addBranchMarkers(); // 마커를 지도에 추가하는 함수 호출
    } else {
      print('Failed to load data. Status code: ${response.statusCode}');
    }
  }

  // 네이버맵에 경로를 포함한 overlays를 띄우기 위한 함수
  void addOverlays(List<LatLng> paths) {
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
    mapController.addOverlayAll(overlays);
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
  double calculateBearing(double currentLatitude, double currentLongitude, double targetLatitude, double targetLongitude) {
    double lat1 = currentLatitude * math.pi / 180;
    double lon1 = currentLongitude * math.pi / 180;
    double lat2 = targetLatitude * math.pi / 180;
    double lon2 = targetLongitude * math.pi / 180;
    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x);
    double bearingDegrees = bearing * 180 / math.pi;
    if (bearingDegrees < 0) {
      bearingDegrees += 360; // 음수 값을 0에서 360도 사이의 양수 값으로 변환
    }
    return bearingDegrees;
  }

  // 두 지점 간의 대원 거리 (미터) 계산
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
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

  // 특정 점과 두 지점 사이의 최단 거리 계산. 즉, 점과 직선사이의 최소거리를 반환하는 함수.
  double pointLineDistance(double lat1, double lon1, double lat2, double lon2,
      double latP, double lonP) {
    // 두 지점 사이의 거리
    double dist12 = _haversine(lat1, lon1, lat2, lon2);
    // 현재 위치와 첫 번째 지점 사이의 거리
    double dist1P = _haversine(lat1, lon1, latP, lonP);
    // 현재 위치와 두 번째 지점 사이의 거리
    double dist2P = _haversine(lat2, lon2, latP, lonP);

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

  static const Duration _ignoreDuration = Duration(milliseconds: 20);

  UserAccelerometerEvent? _userAccelerometerEvent;

  int? _userAccelerometerLastInterval;
  int? _gyroscopeLastInterval;

  DateTime? _userAccelerometerUpdateTime;
  DateTime? _gyroscopeUpdateTime;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

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
      double currentindexLatitude = branchInfo[currentIndex].point.latitude;
      double currentindexLongitude = branchInfo[currentIndex].point.longitude;
      double targetindexLatitude = branchInfo[targetIndex].point.latitude;
      double targetindexLongitude = branchInfo[targetIndex].point.longitude;
      return calculateDistance(currentindexLatitude, currentindexLongitude, targetindexLatitude, targetindexLongitude);
    }

    int moveIndex(List<BranchInfo> currentWindow) {
      double beforeMin = double.maxFinite; // window 내에 가장 가까운 값
      int nearestIndex = currentIndex; // 현재 인덱스
      double distanceBetweenBranch = distanceBetweenBranchFunc(
          branchinfo, currentIndex, targetIndex); //currentWindow-> branchinfo
      if (distanceBetweenBranch == 0) {
        nearestIndex = targetIndex;
      }
      double currentDistance = 0.0;
      for (BranchInfo branchInfo in currentWindow) {
        currentDistance = calculateDistance(branchInfo.point.latitude,
            branchInfo.point.longitude, currentLatitude, currentLongitude);

        double currentIndexDistance = calculateDistance(
            branchinfo[nearestIndex].point.latitude,
            branchinfo[nearestIndex].point.longitude,
            currentLatitude,
            currentLongitude);
        if (currentDistance < beforeMin &&
            currentIndexDistance >=
                distanceBetweenBranch - (distanceBetweenBranch / 20)) {
          beforeMin = currentDistance;
          nearestIndex =
              branchinfo.indexOf(branchInfo); // 가장 가까운 체크포인트의 인덱스를 찾습니다.
        }
      }
      return nearestIndex;
    }
    List<BranchInfo> currentWindow =
        getCurrentWindow(branchinfo, currentIndex, 5);
    int nearestIndex = moveIndex(currentWindow);

    if ((nearestIndex < currentWindow.length || nearestIndex > 0) &&
        nearestIndex != currentIndex) {
      print('인덱스가 변경되었습니다. 새로운 인덱스: $nearestIndex');
      currentIndex = nearestIndex;
      yawRate2 =
          turnUpdate2(branchinfo[currentIndex].bearingToPoint, compassValue) *
              angleToRadian;
      print("각도 초기화");
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

  double turnUpdate2(
    double bearingToPoint,
    double compassValue,
  ) {
    double compassTurn = compassValue - bearingToPoint;

    return compassTurn;
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
      double currentLatitude,
      double currentLongitude) {
    // 출발점과 목표 지점을 평면 좌표계로 변환 (출발점이 원점)
    Map<String, double> pathVector = latLonToXY(currentIndexLatitude,
        currentIndexLongitude, targetIndexLatitude, targetIndexLongitude);

    // 출발점과 현재 위치를 평면 좌표계로 변환 (출발점이 원점)
    Map<String, double> currentVector = latLonToXY(currentIndexLatitude,
        currentIndexLongitude, currentLatitude, currentLongitude);

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

  Map<String, double> breakPoint(
    double currentIndexLongitude,
    double currentIndexLatitude,
    double targetIndexLongitude,
    double targetIndexLatitude,
    double currentLatitude,
    double currentLongitude,
  ) {
    // 주어진 위경도를 라디안으로 변환

    //현재 인덱스
    double lat1 = deg2rad(currentIndexLatitude);
    double lon1 = deg2rad(currentIndexLongitude);

    //현재 위치
    double lat2 = deg2rad(currentLatitude);
    double lon2 = deg2rad(currentLongitude);

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

  //목표까지의 각도 계산
  // yaw rate를 고려하여 타겟까지의 최종 각도를 계산하는 함수
  double angleToTarget(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double currentLatitude,
      double currentLongitude,
      double yawRateTurn2,
      double bearingToPoint,
      int boundaryExit) {
    Map<String, double> breakPointAngle = breakPoint(
      currentIndexLongitude,
      currentIndexLatitude,
      targetIndexLongitude,
      targetIndexLatitude,
      currentLatitude,
      currentLongitude,
    );

    double guidanceAngle = 0.0;
    if (boundaryExit > 0) {
      double baseAngle = (breakPointAngle['breakPointAngleC']! * radianToAngle);

      // 목표 지까지의 각도를 계산 (기존 breakPointB + yaw rate 고려)

      guidanceAngle = (baseAngle + yawRateTurn2) % 360;
    } else {
      double baseAngle = (breakPointAngle['breakPointAngleC']! * radianToAngle);

      // 목표 지까지의 각도를 계산 (기존 breakPointB + yaw rate 고려)

      guidanceAngle = (baseAngle - yawRateTurn2) % 360;
    }

    return guidanceAngle;
  }

  // 유도각도 -> 12시, 1시, 2시... 방향으로 안내
  String getGuidanceDirection(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double currentLatitude,
      double currentLongitude,
      double yawRateTurn2,
      double bearingToPoint) {
    int boundaryExit = checkLateralDeviation(
      currentIndexLatitude,
      currentIndexLongitude,
      targetIndexLatitude,
      targetIndexLongitude,
      currentLatitude,
      currentLongitude,
    );

    double guidanceAngle = angleToTarget(
        currentIndexLongitude,
        currentIndexLatitude,
        targetIndexLongitude,
        targetIndexLatitude,
        currentLatitude,
        currentLongitude,
        yawRateTurn2,
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
        getCurrentWindow(branchinfo, currentIndex, 5);
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
                currentLatitude,
                currentLongitude) *
            1000;

        checkBoudaryCondition = "정방향, 브랜치";

        lineDistance = pointLineDistance(
            currentWindowValue.point.latitude,
            currentWindowValue.point.longitude,
            currentWindow[i + 1].point.latitude,
            currentWindow[i + 1].point.longitude,
            currentLatitude,
            currentLongitude);
        checkBoudaryCondition = "정방향, 직선";

        distanceToPath = math.min(circularDistance, lineDistance);
      } else if (currentWindowValue.branch == false) {
        distanceToPath = pointLineDistance(
            currentWindowValue.point.latitude,
            currentWindowValue.point.longitude,
            currentWindow[i + 1].point.latitude,
            currentWindow[i + 1].point.longitude,
            currentLatitude,
            currentLongitude);
        checkBoudaryCondition = "정방향, 직선";
      }

      if (beforeMinDistanceToPath > distanceToPath) {
        beforeMinDistanceToPath = distanceToPath;
      }

      //boudndary = 5m
      if (beforeMinDistanceToPath > boundary) {
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

  void _updateMapPosition(currentLatitude, currentLongitude, compassValue) {
    // 원하는 줌 레벨을 설정합니다. 예를 들어, 줌 레벨을 15로 설정
    final zoomLevel = 18.5;
    // 현재 위치를 기준으로 카메라 위치를 설정
    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(currentLatitude, currentLongitude),
      zoom: zoomLevel,
      bearing: compassValue,
    );

    // 카메라 업데이트 적용
    mapController.updateCamera(cameraUpdate);
  }

  void _updateCurrentLocationMarker(currentLatitude, currentLongitude) async {
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
    setState(() {
      _currentLocationMarker = NMarker(
          id: 'current_location',
          position: NLatLng(currentLatitude, currentLongitude),
          icon: iconImage);
    });
    mapController.addOverlay(_currentLocationMarker!);
  }

  void addBranchMarkers() async {
    Set<NAddableOverlay> markers = {}; // 마커들을 담을 Set

    final iconImage = await NOverlayImage.fromWidget(
        widget: Icon(
          Icons.circle,
          color: Colors.green,
          size: 15,
        ),
        size: const Size(15, 15),
        context: context);

    for (var branch in branchinfo) {
      _testMarker = NMarker(
          id: 'checkPoint_${branchinfo.indexOf(branch)}', // 각 마커의 고유 ID
          position: NLatLng(
              branch.point.latitude, branch.point.longitude), // 마커의 좌표 설정
          icon: iconImage);

      markers.add(_testMarker!);
    }

    // 맵에 마커 추가
    mapController.addOverlayAll(markers);
  }

  @override
  Widget build(BuildContext context) {
    final searchLocation = context.watch<SearchBloc>().startLocation;
    final destinationLocation = context.watch<SearchBloc>().destinationLocation;
    return Scaffold(
      body: isLoading
          ? Center(
              // 데이터를 로딩하는 동안 로딩 표시기를 표시합니다.
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                NaverMap(
                  options: NaverMapViewOptions(
                    indoorEnable: true,

                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(currentLatitude, currentLongitude),
                      zoom: 18.5, // 지도의 확대 정도
                      bearing: compassValue, // 지도의 방향
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
                    mapController = controller;
                    _updateCurrentLocationMarker(currentLatitude, currentLongitude);
                    _updateMapPosition(currentLatitude, currentLongitude, compassValue);
                  },
                  // 지도를 클릭했을 때 실행할 이벤트를 추가하는 곳
                  onMapTapped: (NPoint point, NLatLng latLng) {
                    // 지도를 클릭했을 때 tts로 남은 거리 알려주기
                    int meters = (remainDistance * 1000).round();
                    _speakText('다음 안내까지 ${meters}미터 남았습니다.');

                    s_latitude = _currentLocation!['latitude'];
                    s_longitude = _currentLocation!['longitude'];
                  },
                ),
                Positioned(
                  top: 65.0,
                  left: 20.0,
                  right: 20.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 190, 164, 164),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        GeoLocation? newstartSelectedLocation =
                            await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    StartSearch(
                              searchValue: searchLocation,
                            ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
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

                        // Navigator.push가 완료된 후에만 setState()를 호출

                        if (newstartSelectedLocation != null) {
                          setState(() {
                            startSelectedLocation = newstartSelectedLocation;

                            isStart = true;
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
                                        fontSize: 17, color: Colors.grey),
                                  )
                                : Text(
                                    searchLocation,
                                    style: TextStyle(
                                        fontSize: 17, color: Colors.black),
                                  ),
                            Spacer(),
                            Icon(Icons.search),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 122.0,
                  left: 20.0,
                  right: 20.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 190, 164, 164),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        GeoLocation? newSelectedLocation = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    DesSearch(
                              destinationValue: destinationLocation,
                            ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
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
                            selectedLocation = newSelectedLocation;
                          });
                          if (isStart == true) {
                            await _getGeometry(startSelectedLocation!.lat,
                                startSelectedLocation!.lng); // 새로운 목적지로 지도 업데이트
                          } else if (isStart == false) {
                            await _getGeometry(currentLatitude,
                                currentLongitude); // 새로운 목적지로 지도 업데이트
                          }

                          // 주기적으로 Timer를 실행하기 전에 먼저 방향값을 초기화 해준다.
                          // branchinfo 배열을 순회하면서 bearingTobranch 값을 변경합니다.
                          for (int i = 0; i < branchinfo.length - 1; i++) {
                            // 변경할 값으로 갱신합니다.
                            double newBearingValue = calculateBearing(
                                branchinfo[i].point.latitude,
                                branchinfo[i].point.longitude,
                                branchinfo[i + 1].point.latitude,
                                branchinfo[i + 1].point.longitude);
                            // bearingTobranch 값을 변경합니다.
                            branchinfo[i].bearingToPoint = newBearingValue;
                          }

                          yawRate2 = turnUpdate2(
                                  branchinfo[targetIndex].bearingToPoint,
                                  compassValue) *
                              angleToRadian;
                          // print("compassValue: $compassValue");
                          // print("yawRateTurn2: $yawRateTurn2");
                          // print("각도 초기화");

                          // 주기적으로 거리계산, 경로이탈 탐지를 위한 계산을 하는 곳.

                          Timer.periodic(Duration(seconds: 2), (timer) async {
                            // 현 위치로부터 다음 목표 위경도까지의 거리를 계산하여 remainDistance 변수에 삽입
                            checkBoundary(); //경계이탈, 인덱스
                            indexUpdate();

                            remainStartpoint = calculateDistance(
                                currentLatitude,
                                currentLongitude,
                                branchinfo[0].point.latitude,
                                branchinfo[0].point.longitude);

                            // print("yawRateTurn2 : $yawRateTurn2");
                            // print("currentLatitude : $currentLatitude");
                            // print("currentLongitude : $currentLongitude");

                            if (remainStartpoint < 0.015) {
                              isStart = false;
                            }
                            if (isStart == false) {
                              if (branchinfo.isNotEmpty &&
                                  targetIndex < branchinfo.length) {
                                branchTargetIndex = targetIndex;

                                while (branchTargetIndex < branchinfo.length &&
                                    !branchinfo[branchTargetIndex].branch) {
                                  branchTargetIndex++;
                                }
                                if (branchinfo[branchTargetIndex].branch) {
                                  remainDistance = calculateDistance(
                                      currentLatitude,
                                      currentLongitude,
                                      branchinfo[branchTargetIndex]
                                          .point
                                          .latitude,
                                      branchinfo[branchTargetIndex]
                                          .point
                                          .longitude);
                                  clock = getGuidanceDirection(
                                      branchinfo[currentIndex].point.longitude,
                                      branchinfo[currentIndex].point.latitude,
                                      branchinfo[targetIndex].point.longitude,
                                      branchinfo[targetIndex].point.latitude,
                                      currentLatitude,
                                      currentLongitude,
                                      yawRateTurn2,
                                      branchinfo[currentIndex].bearingToPoint);
                                }

                                // 추가적인 로직
                              } else {
                                // branchinfo가 비어 있거나 targetIndex가 유효하지 않을 때의 처리 로직
                                print(
                                    "branchinfo 리스트가 비어 있거나 targetIndex가 유효하지 않습니다.");
                              }

                              // 목표지점까지의 남은 거리가 15m 이내라면
                              //반복되어서 안내문이 나오는 이유
                              if (remainDistance < 0.015) {
                                // 만약 그 목표 지점이 횡단보도라면
                                if (branchinfo[currentIndex].crosswalk ==
                                    true) {
                                  // 경광등을 켜라.
                                  final result =
                                      await flashOnWithWeather(NoParams());
                                  if (result.isLeft()) {
                                    print('안전 경광등을 사용할 수 없습니다.');
                                  } else {
                                    print('안전 경광등이 켜졌습니다.');
                                  }
                                  _speakText('잠시 후 횡단보도 입니다. 차량에 유의하세요!');
                                }

                                if (branchinfo[targetIndex].branch == true) {
                                  _speakText(
                                      '${branchinfo[targetIndex].description}하세요.');
                                }
                              }
                              if (currentIndex > 0 &&
                                      (branchinfo[currentIndex].bearingToPoint -
                                                  compassValue)
                                              .abs() <=
                                          18 ||
                                  (branchinfo[currentIndex].bearingToPoint -
                                              compassValue)
                                          .abs() >=
                                      342) {
                                Vibration.vibrate(duration: 200);
                                print(
                                    "경로내 진동 베어링 값 ${(branchinfo[currentIndex].bearingToPoint - compassValue)}");
                              }
                              //임시 주석
                              // 경로 이탈 시 경로이탈 안내
                              if (outOfBound) {
                                Vibration.vibrate(duration: 100);
                                // _speakText("경계이탈");
                                print('경계이탈');
                                print(searchNewPath);
                                _speakText(clock);
                                // 경로 재검색 로직 추가
                                if (searchNewPath) {
                                  searchNewPathTime++;
                                  if (searchNewPathTime >= 5) {
                                    await _getGeometry(currentLatitude,
                                        currentLongitude); // 새로운 목적지로 지도 업데이트

                                    _speakText("경로를 이탈하여 새로운 경로로 안내합니다.");
                                    searchNewPathTime = 0;
                                  }
                                } else {
                                  searchNewPathTime = 0;
                                }
                              } else {}
                            } else if (isStart == true) {
                              _speakText("출발지로 이동하세요.");
                            }
                          });
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
                                        fontSize: 17, color: Colors.grey),
                                  )
                                : Text(
                                    destinationLocation,
                                    style: TextStyle(fontSize: 17),
                                  ),
                            Spacer(),
                            Icon(Icons.search),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}