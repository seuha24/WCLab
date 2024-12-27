part of '../../../framework/bloc.dart';

/// AccelerometerEvent
///
/// 이 추상 클래스는 AccelerometerBloc에서 발생할 수 있는 다양한 이벤트를 정의합니다.
/// 이벤트는 가속도계 데이터를 처리하거나 상태를 업데이트하기 위한 트리거로 사용됩니다.
///
/// ### 주요 이벤트:
/// - `AccelerometerDataReceived`: 가속도계 데이터를 수신했을 때 발생하는 이벤트로, x, y, z 좌표 값을 포함합니다.
abstract class AccelerometerEvent extends Equatable {
  const AccelerometerEvent();

  @override
  List<Object> get props => [];
}

/// 가속도계 데이터 수신 이벤트
///
/// 가속도계에서 x, y, z 좌표 데이터를 수신했을 때 발생하는 이벤트입니다.
/// - `x`, `y`, `z`: 가속도계에서 수집된 x, y, z 좌표 값.
class AccelerometerDataReceived extends AccelerometerEvent {
  final double x; // x축 가속도 값
  final double y; // y축 가속도 값
  final double z; // z축 가속도 값

  /// 생성자
  ///
  /// x, y, z 값을 필수로 받아 이벤트를 생성합니다.
  const AccelerometerDataReceived({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  List<Object> get props => [x, y, z];
}