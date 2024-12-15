import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:safelight/domain/entities/branch_info.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object> get props => [];
}

class NavigationInitial extends NavigationState {}

class NavigationLoading extends NavigationState {}

class NavigationReady extends NavigationState {
  final List<LatLng> paths;
  final List<BranchInfo> branchInfo;

  const NavigationReady(this.paths, this.branchInfo);

  @override
  List<Object> get props => [paths, branchInfo];
}

class NavigationInProgress extends NavigationState {
  final double remainDistance;
  final bool outOfBound;
  final int currentIndex;

  const NavigationInProgress({
    required this.remainDistance,
    required this.outOfBound,
    required this.currentIndex,
  });

  @override
  List<Object> get props => [remainDistance, outOfBound, currentIndex];
}

class NavigationFailure extends NavigationState {
  final String error;

  const NavigationFailure(this.error);

  @override
  List<Object> get props => [error];
}
