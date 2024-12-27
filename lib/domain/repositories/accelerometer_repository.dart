part of '../../framework/repository.dart';

abstract class AccelerometerRepository {
  /// 가속도계 데이터를 스트림으로 반환
  Stream<UserAccelerometerEvent> getAccelerometerStream();
}