part of '../../framework/core.dart';

class ServerException implements Exception {
  final String? message;
  ServerException([this.message]);
}

class CacheException implements Exception {
  final String? message;
  CacheException([this.message]);
}

// BLE 관련 예외 세분화
abstract class BlueException implements Exception {
  final String? message;
  BlueException([this.message]);
}

class BlueScanException extends BlueException {
  BlueScanException([super.message]);
}

class BlueConnectionException extends BlueException {
  BlueConnectionException([super.message]);
}

class BlueTimeoutException extends BlueException {
  BlueTimeoutException([super.message]);
}

class BlueNakException extends BlueException {
  BlueNakException([super.message]);
}

class BlueInvalidDeviceException extends BlueException {
  BlueInvalidDeviceException([super.message]);
}

class PermissionException implements Exception {
  final String? message;
  PermissionException([this.message]);
}

class FlashException implements Exception {
  final String? message;
  FlashException([this.message]);
}
