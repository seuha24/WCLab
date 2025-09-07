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
  BlueScanException([String? message]) : super(message);
}

class BlueConnectionException extends BlueException {
  BlueConnectionException([String? message]) : super(message);
}

class BlueTimeoutException extends BlueException {
  BlueTimeoutException([String? message]) : super(message);
}

class BlueNakException extends BlueException {
  BlueNakException([String? message]) : super(message);
}

class BlueInvalidDeviceException extends BlueException {
  BlueInvalidDeviceException([String? message]) : super(message);
}

class PermissionException implements Exception {
  final String? message;
  PermissionException([this.message]);
}

class FlashException implements Exception {
  final String? message;
  FlashException([this.message]);
}
