part of '../../../framework/controller.dart';

abstract class SearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchStartLocationRequested extends SearchEvent {}

class SearchDestinationRequested extends SearchEvent {}
