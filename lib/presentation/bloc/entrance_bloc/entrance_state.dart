part of '../../../framework/controller.dart';

abstract class EntranceState extends Equatable {
  const EntranceState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class EntranceInitial extends EntranceState {}

/// 로딩 상태
class EntranceLoading extends EntranceState {}

/// 데이터 로드 성공
class EntranceLoaded extends EntranceState {
  final BuildingResponse buildingResponse;

  const EntranceLoaded({required this.buildingResponse});

  @override
  List<Object?> get props => [buildingResponse];
}

/// 에러 상태
class EntranceError extends EntranceState {
  final String errorMessage;

  const EntranceError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
