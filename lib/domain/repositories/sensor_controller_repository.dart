part of repository;

/// 센서 컨트롤러의 역할(추상화)
abstract class SensorController {
  /// 센서 구독 시작
  void start();

  /// 센서 구독 해제
  void stop();
}