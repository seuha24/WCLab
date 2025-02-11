part of '../../../framework/controller.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  String startLocation = '';
  String destinationLocation = '';

  SearchBloc() : super(const SearchState()) {
    on<SearchStartLocationRequested>(_onSearchStartLocationRequested);
    on<SearchDestinationRequested>(_onSearchDestinationRequested);
  }

  FutureOr<void> _onSearchStartLocationRequested(
    SearchStartLocationRequested event,
    Emitter<SearchState> emit,
  ) async {
    try {
      emit(SearchState(
        searchStartLocation: event.searchLocation,
        searchDestinationLocation: state.searchDestinationLocation,
      ));
    } on Exception catch (e, stacktrace) {
      addError(e, stacktrace);
    }
  }

  FutureOr<void> _onSearchDestinationRequested(
    SearchDestinationRequested event,
    Emitter<SearchState> emit,
  ) async {
    try {
      emit(SearchState(
        searchStartLocation: state.searchStartLocation,
        searchDestinationLocation: event.searchDestination,
      ));
    } on Exception catch (e, stacktrace) {
      addError(e, stacktrace);
    }
  }
}
