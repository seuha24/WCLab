part of '../../framework/repository.dart';

/// PositionCalculator의 실제 구현체
class PdrCalculatorImpl implements PdrCalculator{
  // --- 회전(방향) 관련 변수 ---
  double _pdrYaw = 0.0;
  double _deviationYaw = 0.0;
  double _yawRatePerDt = 0.0;
  double yawRateVelocity = 0.0;
  double pdrYawTurn = 0.0;
  double _deviationYawTurn = 0.0;
  double turn = 0.0;

  // --- 속도/위치 관련 변수 ---
  double preAccX = 0.0;
  double preAccY = 0.0;
  double currentpreAccX = 0.0;
  double currentpreAccY = 0.0;
  double velocityX = 0.0;
  double velocityY = 0.0;
  double currentSpeed = 0.0;
  double _px = 0.0;
  double _py = 0.0;
  double _newlatitude = 0.0;
  double _newlongitude = 0.0;

  // --- 상수/설정값 ---
  final double yawRateAccFilteringValue;
  final double accFilteringValue;
  double initialLatitude;
  double initialLongitude;

  // --- 필터 ---
  final WeightedAverageFilter filteringX;
  final WeightedAverageFilter filteringY;

  // --- 각도 변환 상수 ---
  static const double angleToRadian = math.pi / 180;
  static const double radianToAngle = 180 / math.pi;
  // static const double addFilteringValue = ((1 / 130) * (math.pi / 180));
  static const double addFilteringValue = 0;

  PdrCalculatorImpl({
    required this.filteringX,
    required this.filteringY,
    required this.yawRateAccFilteringValue,
    required this.accFilteringValue,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  // Getter로 외부에서 위치/위도/경도 사용 가능하게 함
  @override
  double get px => _px;
  @override
  double get py => _py;
  @override
  double get newlatitude => _newlatitude;
  @override
  double get newlongitude => _newlongitude;
  @override
  double get yawRatePerDt=> _yawRatePerDt;
  @override
  double get deviationYaw => _deviationYaw;
  @override
  double get deviationYawTurn => _deviationYawTurn;
 

    double _updateRotationValue(double value, double valuePerDt, double addValue) {
    value += -(valuePerDt + addValue);
    if (value >= 2 * math.pi || value <= -2 * math.pi) {
      value = 0;
    }
    return value;
  }

  /// GyroscopeEvent 기반 방향(회전) 갱신
  @override
  void orientationUpdate(GyroscopeEvent event, Duration sensorInterval) {
    final dt = sensorInterval.inMilliseconds / 1000.0;
    double yawRatePerDt = 0.0;
    if (event.z > yawRateAccFilteringValue * angleToRadian || event.z < -yawRateAccFilteringValue * angleToRadian) {
      yawRatePerDt = (event.z * dt);
    }
    _pdrYaw = _updateRotationValue(_pdrYaw, yawRatePerDt, addFilteringValue);
    

    _deviationYaw = _updateRotationValue(_deviationYaw, yawRatePerDt, addFilteringValue);

    _deviationYawTurn = _deviationYaw * radianToAngle;

  }



    double _updateVelocityValue(
      double currentpreAcc, double preAcc, double velocity, double dt, double accFilteringValue, void Function(double) updatePrev) {
    if (currentpreAcc > accFilteringValue || currentpreAcc < -accFilteringValue) {
      velocity += (currentpreAcc - preAcc) * dt;
      updatePrev(currentpreAcc);
    } else {
      velocity = 0;
    }
    return velocity;
  }

  /// AccelerometerEvent 기반 속도 계산
  @override
  void calculateCurrentSpeed(UserAccelerometerEvent event, Duration sensorInterval) {
    final dt = sensorInterval.inMilliseconds / 1000.0;
    currentpreAccX = event.x;
    currentpreAccY = event.y;
    velocityX = _updateVelocityValue(currentpreAccX, preAccX, velocityX, dt, accFilteringValue, (v) => preAccX = v);
    velocityY = _updateVelocityValue(currentpreAccY, preAccY, velocityY, dt, accFilteringValue, (v) => preAccY = v);
    filteringX.enqueue(velocityX);
    filteringY.enqueue(velocityY);
    currentSpeed = math.sqrt(velocityX * velocityX + velocityY * velocityY);
  }



  /// 위치 누적 + 위경도 변환
  @override
  void positionUpdate(UserAccelerometerEvent event, Duration sensorInterval) {
    calculateCurrentSpeed(event, sensorInterval);
    _px += (currentSpeed * math.cos(_pdrYaw));
    _py += (currentSpeed * math.sin(_pdrYaw));
    final distanceKm = math.sqrt(_px * _px + _py * _py) / 1000.0;
    final bearing = math.atan2(_py, _px) * radianToAngle;

    final latLng = _calLatLng(initialLatitude, initialLongitude, bearing, distanceKm);
    _newlatitude = latLng['latitude']!;
    _newlongitude = latLng['longitude']!;
  }

  Map<String, double> _calLatLng(double startLat, double startLng, double bearing, double distanceKm) {
    const double earthRadiusKm = 6371.0;
    double _degreesToRadians(double degrees) => degrees * math.pi / 180;
    double _radiansToDegrees(double radians) => radians * 180 / math.pi;

    final startLatRad = _degreesToRadians(startLat);
    final startLngRad = _degreesToRadians(startLng);
    final bearingRad = _degreesToRadians(bearing);
    final distanceRad = distanceKm / earthRadiusKm;
    final newLatRad = math.asin(math.sin(startLatRad) * math.cos(distanceRad) +
        math.cos(startLatRad) * math.sin(distanceRad) * math.cos(bearingRad));
    final newLngRad = startLngRad +
        math.atan2(
            math.sin(bearingRad) * math.sin(distanceRad) * math.cos(startLatRad),
            math.cos(distanceRad) - math.sin(startLatRad) * math.sin(newLatRad));
    final newLat = _radiansToDegrees(newLatRad);
    final newLng = _radiansToDegrees(newLngRad);
    return {'latitude': newLat, 'longitude': newLng};
  }

  @override
  /// 출발지를 조정하기 위해 절대 좌표를 상대 좌표로 변환하여 px, py를 업데이트합니다.
  /// [baseLat], [baseLng]는 기준 좌표 (현재 위치), [targetLat], [targetLng]는 조정하려는 목표 좌표
  void updateRelativeCoordinates(
      double baseLat, double baseLng, double targetLat, double targetLng) {
    Map<String, double> relativePosition =
        Calculators.latLonToXY(baseLat, baseLng, targetLat, targetLng);
    moveRelativePosition(relativePosition['y']!, relativePosition['x']!);
    debugPrint('기준 좌표: ($baseLat, $baseLng)');
    debugPrint('목표 좌표: ($targetLat, $targetLng)');
    debugPrint('Relative Coordinates: px = $px, py = $py');
  }
  

  /// (선택) 초기 좌표 재설정
  @override
  void setInitialPosition(double latitude, double longitude) {
    initialLatitude = latitude;
    initialLongitude = longitude;
  }
  
  @override
  void resetValue(double yawRatePerDt, double yawRate,double px, double py){
    _yawRatePerDt = yawRatePerDt;
    _pdrYaw = yawRate;
    _px = px;
    _py = py;
  }

  @override
  void setRelativePositionValue(double px, double py){
    _px = px;
    _py = py;
  }

  @override
  void setVelocityValue(double velocityX, double velocityY){
    this.velocityX = velocityX;
    this.velocityY = velocityY;
  }

  @override
  void setPdrYaw(double yawRate) {
    _pdrYaw = yawRate;
  }
  @override
  void setDeviationYaw(double deviationYaw){
    _deviationYaw = deviationYaw;
  }

  @override
  void moveRelativePosition(double px, double py){
    _px += px;
    _py += py;
  }

  /// 계산값/상태 초기화 메서드
  @override
  void resetPdrCalculator() {
    _pdrYaw = 0.0;
    _deviationYaw = 0.0;
    _yawRatePerDt = 0.0;
    yawRateVelocity = 0.0;
    pdrYawTurn = 0.0;
    _deviationYawTurn = 0.0;
    turn = 0.0;

    preAccX = 0.0;
    preAccY = 0.0;
    currentpreAccX = 0.0;
    currentpreAccY = 0.0;
    velocityX = 0.0;
    velocityY = 0.0;
    currentSpeed = 0.0;
    _px = 0.0;
    _py = 0.0;
    _newlatitude = initialLatitude;
    _newlongitude = initialLongitude;

    filteringX.clear();
    filteringY.clear();
  }
}
