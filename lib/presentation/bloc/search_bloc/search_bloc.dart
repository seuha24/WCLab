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
      startLocation = event.searchLocation;
    } on Exception catch (e, stacktrace) {
      addError(e, stacktrace);
    }
  }

  FutureOr<void> _onSearchDestinationRequested(
    SearchDestinationRequested event,
    Emitter<SearchState> emit,
  ) async {
    try {
      destinationLocation = event.searchDestination;
    } on Exception catch (e, stacktrace) {
      addError(e, stacktrace);
    }
  }
}
