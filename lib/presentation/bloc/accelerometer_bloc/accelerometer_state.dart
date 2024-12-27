part of '../../../framework/bloc.dart';

/// AccelerometerState
///
/// 이 추상 클래스는 AccelerometerBloc에서 관리되는 다양한 상태를 정의합니다.
/// 가속도계 데이터를 기반으로 애플리케이션의 상태를 나타내며, 초기 상태, 움직임 감지 상태,
/// 정지 상태 등을 포함합니다.
///
/// ### 주요 상태:
/// - `AccelerometerInitial`: 초기 상태로, Bloc이 초기화되었지만 센서 데이터를 아직 처리하지 않은 상태.
/// - `AccelerometerMoving`: 움직임을 감지한 상태로, x, y, z 좌표 값과 움직임 여부를 포함.
/// - `AccelerometerStationary`: 움직임이 없음을 감지한 상태로, x, y, z 좌표 값과 움직임 여부를 포함.
abstract class AccelerometerState extends Equatable {
  const AccelerometerState();

  @override
  List<Object> get props => [];
}

/// 초기 상태
///
/// Bloc이 초기화되었으며, 아직 센서 데이터를 처리하지 않은 상태를 나타냅니다.
class AccelerometerInitial extends AccelerometerState {}

/// 움직임 감지 상태
///
/// 가속도계를 통해 움직임이 감지되었을 때의 상태를 나타냅니다.
/// - `x`, `y`, `z`: 가속도계에서 수집된 x, y, z 좌표 값.
/// - `isMoving`: 현재 움직임 여부 (true).
class AccelerometerMoving extends AccelerometerState {
  final double x; // x축 가속도 값
  final double y; // y축 가속도 값
  final double z; // z축 가속도 값
  final bool isMoving; // 움직임 여부

  const AccelerometerMoving({
    required this.x,
    required this.y,
    required this.z,
    required this.isMoving,
  });

  @override
  List<Object> get props => [x, y, z, isMoving];
}

/// 정지 상태
///
/// 가속도계를 통해 움직임이 없음을 감지했을 때의 상태를 나타냅니다.
/// - `x`, `y`, `z`: 가속도계에서 수집된 x, y, z 좌표 값.
/// - `isMoving`: 현재 움직임 여부 (false).
class AccelerometerStationary extends AccelerometerState {
  final double x; // x축 가속도 값
  final double y; // y축 가속도 값
  final double z; // z축 가속도 값
  final bool isMoving; // 움직임 여부

  const AccelerometerStationary({
    required this.x,
    required this.y,
    required this.z,
    required this.isMoving,
  });

  @override
  List<Object> get props => [x, y, z, isMoving];
}

/// 에러 상태
///
/// 가속도계 처리 중 에러가 발생했을 때의 상태를 나타냅니다.
/// - `message`: 에러 메시지.
class AccelerometerError extends AccelerometerState {
  final String message; // 에러 메시지

  const AccelerometerError(this.message);

  @override
  List<Object> get props => [message];
}