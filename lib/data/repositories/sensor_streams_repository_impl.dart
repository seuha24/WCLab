part of repository;



class SensorStreamsImpl implements SensorStreams {
  final _accelController = StreamController<UserAccelerometerEvent>.broadcast();
  final _gyroController = StreamController<GyroscopeEvent>.broadcast();
  final _compassController = StreamController<double>.broadcast();
  double? _lastCompassDeg;
  
  @override
  Stream<UserAccelerometerEvent> get accel => _accelController.stream;

  @override
  Stream<GyroscopeEvent> get gyro => _gyroController.stream;

  @override
  Stream<double> get compass => _compassController.stream;

  
  @override
  double? get lastCompassDeg => _lastCompassDeg;

  @override
  void publishAccel(UserAccelerometerEvent event) {
    if (!_accelController.isClosed) _accelController.add(event);
  }

  @override
  void publishGyro(GyroscopeEvent event) {
    if (!_gyroController.isClosed) _gyroController.add(event);
  }

  @override
  void publishCompass(double heading) {
    _lastCompassDeg = heading;
    if (!_compassController.isClosed) _compassController.add(heading);
  }

  @override
  void dispose() {
    _accelController.close();
    _gyroController.close();
    _compassController.close();
  }
}