import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:safelight/domain/entities/branch_info.dart';

/// 이 파일은 NavigationBloc에서 발생할 수 있는 다양한 상태를 정의합니다.
/// 상태는 내비게이션 처리의 다양한 단계를 나타내며, 로딩 중 상태, 경로 로드 성공 상태,
/// 내비게이션 진행 상태 및 실패 상태를 포함합니다.
///
/// 상태 설명:
/// - `NavigationInitial`: 내비게이션 시스템의 초기 상태를 나타냅니다.
/// - `NavigationLoading`: 경로를 로드하는 동안의 로딩 상태를 나타냅니다.
/// - `NavigationReady`: 내비게이션 경로 및 관련 데이터가 준비된 상태를 나타냅니다.
/// - `NavigationInProgress`: 내비게이션 세션이 진행 중인 상태로, 거리, 경계 이탈 여부 및 현재 인덱스를 추적합니다.
/// - `NavigationFailure`: 오류가 발생했을 때의 상태를 나타내며, 에러 메시지를 포함합니다.
abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object> get props => [];
}

class NavigationIdle extends NavigationState {}

class NavigationInitial extends NavigationState {}

class NavigationLoading extends NavigationState {}

class NavigationReady extends NavigationState {
  final List<LatLng> paths;
  final List<BranchInfo> branchInfoList;

  const NavigationReady(this.paths, this.branchInfoList);

  @override
  List<Object> get props => [paths, branchInfoList];
}

// class NavigationInProgress extends NavigationState {
//   final DateTime timestamp;
//   const NavigationInProgress({required this.timestamp});
// }

class LocationMarkerUpdated extends NavigationState {
  final double latitude;
  final double longitude;
  final bool isGps;

  const LocationMarkerUpdated({
    required this.latitude,
    required this.longitude,
    required this.isGps,
  });

  @override
  List<Object> get props => [latitude, longitude, isGps];
}

class MapPositionUpdated extends NavigationState {
  final double latitude;
  final double longitude;
  final double compassValue;

  const MapPositionUpdated({
    required this.latitude,
    required this.longitude,
    required this.compassValue,
  });

  @override
  List<Object> get props => [latitude, longitude, compassValue];
}

class NavigationFailure extends NavigationState {
  final String error;

  const NavigationFailure(this.error);

  @override
  List<Object> get props => [error];
}
