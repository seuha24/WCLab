part of '../../framework/core.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure([this.message = '']);
  
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = '서버 연결 오류']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '네트워크 연결 오류']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = '캐시 오류']);
}

// BLE 관련 에러 세분화
abstract class BlueFailure extends Failure {
  const BlueFailure(super.message);
}

class BlueScanFailure extends BlueFailure {
  const BlueScanFailure() : super('음향신호기 스캔 실패');
}

class BlueConnectionFailure extends BlueFailure {
  const BlueConnectionFailure() : super('음향신호기 연결 실패');
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
  const PermissionFailure([super.message = '권한이 필요합니다']);
}

class FlashFailure extends Failure {
  const FlashFailure([super.message = '플래시 오류']);
}

class ValidateFailure extends Failure {
  const ValidateFailure([super.message = '유효성 검사 실패']);
}
