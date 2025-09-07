part of '../../framework/core.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure([this.message = '']);
  
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = '서버 연결 오류']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = '캐시 오류']) : super(message);
}

// BLE 관련 에러 세분화
abstract class BlueFailure extends Failure {
  const BlueFailure(String message) : super(message);
}

class BlueScanFailure extends BlueFailure {
  const BlueScanFailure() : super('BLE 스캔 실패');
}

class BlueConnectionFailure extends BlueFailure {
  const BlueConnectionFailure() : super('BLE 연결 실패');
}

class BlueTimeoutFailure extends BlueFailure {
  const BlueTimeoutFailure() : super('응답 시간 초과');
}

class BlueNakFailure extends BlueFailure {
  const BlueNakFailure() : super('음향신호기가 명령을 거부했습니다');
}

class BlueInvalidDeviceFailure extends BlueFailure {
  const BlueInvalidDeviceFailure() : super('유효하지 않은 음향신호기입니다');
}

class BluePermissionFailure extends BlueFailure {
  const BluePermissionFailure() : super('블루투스 권한이 필요합니다');
}

class PermissionFailure extends Failure {
  const PermissionFailure([String message = '권한이 필요합니다']) : super(message);
}

class FlashFailure extends Failure {
  const FlashFailure([String message = '플래시 오류']) : super(message);
}

class ValidateFailure extends Failure {
  const ValidateFailure([String message = '유효성 검사 실패']) : super(message);
}
