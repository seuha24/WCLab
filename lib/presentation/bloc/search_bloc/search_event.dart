part of '../../../framework/controller.dart';

abstract class SearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchStartLocationRequested extends SearchEvent {
  final String searchLocation;

  SearchStartLocationRequested({
    required this.searchLocation,
  });
}

class SearchDestinationRequested extends SearchEvent {
  final String searchDestination;

  SearchDestinationRequested({
    required this.searchDestination,
  });
}
