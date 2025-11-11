part of '../../framework/repository.dart';

abstract class PdrCalculator{
  // 읽기 전용 속성(좌표/위치값)
  double get px;
  double get py;
  double get newlatitude;
  double get newlongitude;
  double get yawRatePerDt;
  double get deviationYaw;
  double get deviationYawTurn;


  // 업데이트 메서드
  void orientationUpdate(GyroscopeEvent event, Duration sensorInterval);
  void positionUpdate(UserAccelerometerEvent event, Duration sensorInterval);
  void calculateCurrentSpeed(UserAccelerometerEvent event, Duration sensorInterval);

  //값 변경
  void setInitialPosition(double lat, double lng);
  void resetValue(double yawRatePerDt, double yawRate,double px, double py);
  void setRelativePositionValue(double px, double py);
  void setVelocityValue(double velocityX, double velocityY);
  void setPdrYaw(double yawRate);
  void setDeviationYaw(double deviationYaw);
  void moveRelativePosition(double px, double py);
  void resetPdrCalculator();

  

}