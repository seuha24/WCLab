import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
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

class UpdateNavigation extends NavigationEvent {
  final double currentLat;
  final double currentLng;

  const UpdateNavigation(this.currentLat, this.currentLng);

  @override
  List<Object> get props => [currentLat, currentLng];
}
