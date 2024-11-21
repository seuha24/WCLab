part of '../../../framework/controller.dart';

class SearchState extends Equatable {
  final String? searchStartLocation;
  final String? searchDestinationLocation;

  const SearchState({
    this.searchStartLocation,
    this.searchDestinationLocation,
  });

  @override
  List<Object?> get props => [
    searchStartLocation,
    searchDestinationLocation,
  ];

  SearchState copyWith({
    String? searchStartLocation,
    String? searchDestinationLocation,
  }) {
    return SearchState(
      searchStartLocation: searchStartLocation ?? this.searchStartLocation,
      searchDestinationLocation:  searchDestinationLocation ?? this.searchDestinationLocation,
    );
  }
}