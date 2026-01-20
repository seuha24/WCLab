part of '../../../framework/controller.dart';

@immutable
abstract class CrosswalkState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 초기 화면 상태 - 음향신호기 찾기 버튼 표시
class CrosswalkInitial extends CrosswalkState {}

class SearchOn extends CrosswalkState {
  final bool infinite;

  SearchOn({this.infinite = false});

  @override
  List<Object?> get props => [infinite];
}

class SearchOff extends CrosswalkState {
  final List<Crosswalk> results;

  SearchOff({required this.results});

  @override
  List<Object?> get props => results;
}

class CrosswalkError extends CrosswalkState {
  final String message;

  CrosswalkError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ConnectOn extends CrosswalkState {}

class ConnectOff extends CrosswalkState {}
