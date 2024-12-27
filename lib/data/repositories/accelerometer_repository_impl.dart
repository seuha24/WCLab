part of '../../framework/repository.dart';

class AccelerometerRepositoryImpl implements AccelerometerRepository {
  @override
  Stream<UserAccelerometerEvent> getAccelerometerStream() {
    return userAccelerometerEventStream();
  }
}