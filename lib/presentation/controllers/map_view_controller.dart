import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:location_plugin/location_plugin.dart';
import 'package:safelight/framework/ui.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:get/get.dart';
import 'package:safelight/framework/usecase.dart';
import 'package:safelight/injection.dart';

// --- 데이터 클래스들 ---
// BranchInfo
class BranchInfo {
  LatLng point; // 모든 경로값
  String description; // 각 분기의 경로값
  double bearingToPoint; // 다음 경로까지의 방향값
  bool crosswalk; // 횡단보도 여부
  bool branch; // 체크포인트(분기) 여부

  BranchInfo(
    this.point,
    this.description,
    this.bearingToPoint,
    this.crosswalk,
    this.branch,
  );

  @override
  String toString() {
    return 'BranchInfo{point: $point, branch: $branch, description: $description, bearingToPoint: $bearingToPoint, crosswalk: $crosswalk}';
  }
}

// WeightedAverageFilter
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

  void enqueue(double element) {
    if (isFull) {
      dequeue();
    }
    _queue[_rear] = element;
    _rear = (_rear + 1) % _queue.length;
    _size++;
  }

  double? dequeue() {
    if (isEmpty) throw Exception("Queue is empty");
    double? element = _queue[_front];
    _queue[_front] = null;
    _front = (_front + 1) % _queue.length;
    _size--;
    return element;
  }

  double? peek() {
    if (isEmpty) return null;
    return _queue[_front];
  }

  void clear() {
    while (!isEmpty) {
      dequeue();
    }
  }

  double calculateWeightedAverage() {
    if (isEmpty) return 0.0;
    double weightedSum = 0.0, weightSum = 0.0;
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

// --- GetX Controller ---
class NaverMapViewController extends GetxController {

  late BuildContext _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  // TTS 관련
  final FlutterTts tts = FlutterTts();

  // 지도 컨트롤러
  late NaverMapController mapController;

  // 로딩 상태
  RxBool isLoading = true.obs;

  // 위치 관련 (초기값 설정)
  RxDouble current_latitude = 35.9078.obs;
  RxDouble current_longitude = 127.7669.obs;
  RxDouble remain_distance = double.infinity.obs;

  // 출발지, 목적지, 경로 등
  Rxn<GeoLocation> selectedLocation = Rxn<GeoLocation>();
  Rxn<GeoLocation> startSelectedLocation = Rxn<GeoLocation>();

  RxString searchLocation = ''.obs;
  RxString destinationLocation = ''.obs;

  List<LatLng> paths = [];
  List<BranchInfo> branchinfo = [];

  RxBool isStart = false.obs;
  late double remain_startpoint;

  // 인덱스
  int currentIndex = 0;
  int targetIndex = 0;
  int branchTargetIndex = 0;

  // 네이티브 위치 데이터 (디버깅용)
  Map<String, dynamic>? currentLocation;
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

  static const Duration _ignoreDuration = Duration(milliseconds: 20);
  UserAccelerometerEvent? _userAccelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  int? _userAccelerometerLastInterval, _gyroscopeLastInterval;
  DateTime? _userAccelerometerUpdateTime, _gyroscopeUpdateTime;
  final List<StreamSubscription<dynamic>> _streamSubscriptions = [];

  @override
  void onInit() {
    super.onInit();

    _initTTS();
    _getLocation();
    _initLocation();
    startCollectingSensorData();

    LocationPlugin.locationStream.listen((locationData) {
      currentLocation = locationData;
    });

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

  // TTS 초기화
  Future<void> _initTTS() async {
    await tts.setLanguage("ko-KR");
    await tts.setSpeechRate(0.7);
  }

  Future<void> speakText(String text) async {
    await tts.speak(text);
  }

  // 위치 초기화 (GPS 및 IMU)
  Future<void> _initLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    current_latitude.value = position.latitude;
    current_longitude.value = position.longitude;
    initialLatitude = current_latitude.value;
    initialLongitude = current_longitude.value;
    beforeLatitude = current_latitude.value;
    beforeLongitude = current_longitude.value;
    yawRate = compassValue.value * angleToRadian;
    Timer.periodic(Duration(seconds: 1), (timer) {
      s_accuracy = position.accuracy;
      _getLocation();
    });
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
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
      updateMapPosition(
          current_latitude.value, current_longitude.value, compassValue.value);
      _updateCurrentLocationMarker(
          current_latitude.value, current_longitude.value);
    } catch (e) {
      print("현위치 수신에러 $e");
      isLoading.value = false;
    }
  }

  // 경로 검색 (T맵 API)
  Future<void> getGeometry(double c_lat, double c_lng) async {
    const String apiUrl =
        'https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&callback=function';
    final Map<String, dynamic> requestData = {
      "startX": c_lng,
      "startY": c_lat,
      "angle": 20,
      "speed": 30,
      "endPoiId": "10001",
      "endX": selectedLocation.value!.lng,
      "endY": selectedLocation.value!.lat,
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
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      List<dynamic> features = responseData['features'];
      paths.clear();
      branchinfo.clear();
      currentIndex = 0;
      targetIndex = 0;
      for (var feature in features) {
        List<dynamic> coordinates = feature['geometry']['coordinates'];
        if (feature['geometry']['type'] == 'LineString') {
          paths.addAll(coordinates.map((coord) => LatLng(coord[1], coord[0])));
          for (var coord in coordinates) {
            LatLng point = LatLng(coord[1], coord[0]);
            if (branchinfo.isNotEmpty && branchinfo.last.point == point)
              continue;
            branchinfo.add(BranchInfo(point, '', 0.0,
                int.parse(feature['properties']['facilityType']) == 15, false));
          }
        }
        if (feature['geometry']['type'] == 'Point' && branchinfo.isNotEmpty) {
          double latitude = coordinates[1];
          double longitude = coordinates[0];
          String description = feature['properties']['description'];
          for (var branch in branchinfo) {
            if (branch.point.latitude == latitude &&
                branch.point.longitude == longitude) {
              branch.branch = true;
              branch.description = description;
              break;
            }
          }
        }
      }
      print(branchinfo);
      addOverlays(paths);
      addBranchMarkers();
    } else {
      print('Failed to load data. Status code: ${response.statusCode}');
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
    mapController.addOverlayAll(overlays);
  }

  // 분기(체크포인트) 마커 추가
  void addBranchMarkers() async {
    if (mapController == null) return;
    Set<NAddableOverlay> markers = {};
    final iconImage = await NOverlayImage.fromWidget(
      widget: Icon(Icons.circle, color: Colors.green, size: 15),
      size: const Size(15, 15),
      context: _context,
    );
    for (var branch in branchinfo) {
      _testMarker = NMarker(
        id: 'checkPoint_${branchinfo.indexOf(branch)}',
        position: NLatLng(branch.point.latitude, branch.point.longitude),
        icon: iconImage,
      );
      markers.add(_testMarker!);
    }
    mapController.addOverlayAll(markers);
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
        final now = DateTime.now();
        positionUpdate(event, Duration(milliseconds: 20));
        _userAccelerometerEvent = event;
        if (_userAccelerometerUpdateTime != null) {
          final interval = now.difference(_userAccelerometerUpdateTime!);
          if (interval > _ignoreDuration) {
            _userAccelerometerLastInterval = interval.inMilliseconds;
          }
        }
        _userAccelerometerUpdateTime = now;
      },
      onError: (e) {
        showErrorDialog("userAccerometer Sensor");
      },
    );
    subscribeToSensor<GyroscopeEvent>(
      sensorStream:
          gyroscopeEventStream(samplingPeriod: Duration(milliseconds: 20)),
      onEvent: (GyroscopeEvent event) {
        final now = DateTime.now();
        yawRateupdate(event, Duration(milliseconds: 20));
        _gyroscopeEvent = event;
        if (_gyroscopeUpdateTime != null) {
          final interval = now.difference(_gyroscopeUpdateTime!);
          if (interval > _ignoreDuration) {
            _gyroscopeLastInterval = interval.inMilliseconds;
          }
        }
        _gyroscopeUpdateTime = now;
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
      print('인덱스가 변경되었습니다. 새로운 인덱스: $nearestIndex');
      currentIndex = nearestIndex;
      yawRate2 = turnUpdate2(
              branchinfo[currentIndex].bearingToPoint, compassValue.value) *
          angleToRadian;
      print("각도 초기화");
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
    debugPrint(
        'updateMapPosition: $current_latitude, $current_longitude, $compassValue');
    if (mapController == null) return;
    final zoomLevel = 18.5;
    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(current_latitude, current_longitude),
      zoom: zoomLevel,
      bearing: compassValue,
    );
    mapController.updateCamera(cameraUpdate);
  }

  void _updateCurrentLocationMarker(
      double current_latitude, double current_longitude) async {
    debugPrint(
        '_updateCurrentLocationMarker: $current_latitude, $current_longitude');
    if (mapController == null) return;
    // if (_currentLocationMarker != null) {
    //   try {
    //     mapController.deleteOverlay(
    //       NOverlayInfo(type: NOverlayType.marker, id: 'current_location'),
    //     );
    //   } catch (e) {
    //     print("오버레이 삭제 중 에러 발생: $e");
    //   }
    // } else {
    //   print("삭제할 마커가 없습니다.");
    // }
    final Color markerColor = isGps ? Colors.blue : Colors.red;

    final iconImage = await NOverlayImage.fromWidget(
        widget: Icon(Icons.circle, color: markerColor, size: 25),
        size: const Size(25, 25),
        context: _context);
    debugPrint('iconImage: $iconImage');
    _currentLocationMarker = NMarker(
      id: 'current_location',
      position: NLatLng(current_latitude, current_longitude),
      icon: iconImage,
    );
    debugPrint('_currentLocationMarker: $_currentLocationMarker');
    mapController.addOverlay(_currentLocationMarker!);
  }
}
