part of repository;

class SensorControllerImpl implements SensorController {
  final List<StreamSubscription<dynamic>> _streamSubscriptions = [];
  final SensorStreams sensorStreams;
  

  bool _isStarted = false;

  SensorControllerImpl(this.sensorStreams);
  
  /// 센서 스트림 구독 헬퍼 (제네릭)
  void subscribeToSensor<T>({
    required Stream<T> sensorStream,
    required void Function(T event) onEvent,
    required void Function(dynamic error) onError,
  }) {
    var subscription = sensorStream.listen(
      onEvent,
      onError: onError,
      cancelOnError: true,
    );
    _streamSubscriptions.add(subscription);
  }
  
  @override
  void start() {
    if (_isStarted) return;
    _isStarted = true;
    
    // 나침반
    subscribeToSensor<CompassEvent>(
      sensorStream: FlutterCompass.events!,
      onEvent: (event) {
        if (event.heading != null) {
          sensorStreams.publishCompass(event.heading!);
        }
      },
      onError: (e) => debugPrint("[SensorController] Compass error: $e"),
    );
    // 가속도계
    subscribeToSensor<UserAccelerometerEvent>(
      sensorStream: userAccelerometerEventStream(
        samplingPeriod: Duration(milliseconds: 20)),
      onEvent: (event) => sensorStreams.publishAccel(event),
      onError: (e) => debugPrint("[SensorController] Accelerometer error: $e"),
    );
    // 자이로스코프
    subscribeToSensor<GyroscopeEvent>(
      sensorStream: gyroscopeEventStream(
        samplingPeriod: Duration(milliseconds: 20)),
      onEvent: (event) => sensorStreams.publishGyro(event),
      onError: (e) => debugPrint("[SensorController] Gyroscope error: $e"),
    );
  }

  @override
  void stop() {
    for (final sub in _streamSubscriptions) {
      sub.cancel();
    }
    _streamSubscriptions.clear();
    _isStarted = false;
  }
}