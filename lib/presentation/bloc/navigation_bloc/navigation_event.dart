import 'package:equatable/equatable.dart';
import 'package:safelight/framework/ui.dart';

/// 이 파일은 NavigationBloc에 전달될 수 있는 다양한 이벤트를 정의합니다.
/// 이 이벤트들은 Bloc 내에서 다양한 동작을 트리거하며, 경로 로드 또는 이동 중 상태 업데이트 등을 수행합니다.
///
/// 이벤트 설명:
/// - `LoadPath`: 시작 지점과 종료 지점의 좌표를 사용하여 내비게이션 경로를 로드합니다.
/// - `UpdateNavigation`: 현재의 위도와 경도를 사용하여 내비게이션 진행 상태를 업데이트합니다.
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class InitNavigation extends NavigationEvent {
  const InitNavigation();
}

class CloseNavigation extends NavigationEvent {
  const CloseNavigation();
}

class OnMapReady extends NavigationEvent {
  const OnMapReady();
}

class StartLoading extends NavigationEvent {
  const StartLoading();
}

class StopLoading extends NavigationEvent {
  const StopLoading();
}

class SetStartLocation extends NavigationEvent {
  final GeoLocation startLocation;

  const SetStartLocation(this.startLocation);
}

class SetDestinationLocation extends NavigationEvent {
  final GeoLocation destinationLocation;

  const SetDestinationLocation(this.destinationLocation);
}

class LoadPath extends NavigationEvent {
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;

  const LoadPath({
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
  });

  @override
  List<Object> get props =>
      [startLatitude, startLongitude, endLatitude, endLongitude];
}

// class UpdateNavigation extends NavigationEvent {
//   const UpdateNavigation();
// }

class UpdateLocationMarker extends NavigationEvent {
  final double latitude;
  final double longitude;
  final bool isGps;

  const UpdateLocationMarker({
    required this.latitude,
    required this.longitude,
    required this.isGps,
  });
}

class UpdateMapPosition extends NavigationEvent {
  final double latitude;
  final double longitude;
  final double compassValue;

  const UpdateMapPosition({
    required this.latitude,
    required this.longitude,
    required this.compassValue,
  });
}

class UpdateLocation extends NavigationEvent {
  final double latitude;
  final double longitude;
  final double compassValue;
  final bool isGps;

  const UpdateLocation({
    required this.latitude,
    required this.longitude,
    required this.compassValue,
    required this.isGps,
  });

  @override
  List<Object> get props => [latitude, longitude, compassValue, isGps];
}
