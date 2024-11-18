part of '../../../framework/controller.dart';

class SearchState extends Equatable {
  final Status searchStartLocationStatus;
  final Status searchDestinationStatus;
  final String? errorMessage;
  final String? searchStartLocation;
  final String? searchDestinationLocation;

  const SearchState({
    this.searchStartLocationStatus = Status.initial,
    this.searchDestinationStatus = Status.initial,
    this.searchStartLocation,
    this.searchDestinationLocation,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    searchStartLocation,
    searchDestinationLocation,
    searchStartLocationStatus,
    searchDestinationStatus,
    errorMessage,
  ];

  SearchState copyWith({
    Status? searchStartLocationStatus,
    Status? searchDestinationStatus,
    String? errorMessage,
    String? searchStartLocation,
    String? searchDestinationLocation,
  }) {
    return SearchState(
      searchStartLocationStatus: searchStartLocationStatus ?? this.searchStartLocationStatus,
      searchDestinationStatus: searchDestinationStatus ?? this.searchDestinationStatus,
      searchStartLocation: searchStartLocation ?? this.searchStartLocation,
      searchDestinationLocation:  searchDestinationLocation ?? this.searchDestinationLocation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}