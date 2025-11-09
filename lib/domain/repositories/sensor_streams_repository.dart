part of '../../framework/repository.dart';

/// 센서 데이터 이벤트 허브의 역할을 추상화
abstract class SensorStreams {
  Stream<UserAccelerometerEvent> get accel;
  Stream<GyroscopeEvent> get gyro;
  Stream<double> get compass;
  double? get lastCompassDeg;
  
  void publishAccel(UserAccelerometerEvent event);
  void publishGyro(GyroscopeEvent event);
  void publishCompass(double heading);

  void dispose();
}