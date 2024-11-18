part of '../../../framework/controller.dart';
//
// class SearchBloc extends Bloc<SearchEvent, SearchState> {
//   SearchBloc({required CivilisPlusRepository civilisPlusRepository})
//       : _civilisPlusRepository = civilisPlusRepository,
//   super(const SearchState()) {
//     on<SearchStartLocationRequested>(_onSearchStartLocationRequested);
//     on<SearchDestinationRequested>(_onSearchDestinationRequested);
//   }
//   FutureOr<void> _onSearchStartLocationRequested(
//       SearchStartLocationRequested event,
//       Emitter<SearchState> emit,
//       ) async {
//     try {
//       emit(state.copyWith(searchStartLocationStatus: Status.inProgress));
//
//     } on Exception catch (e, stacktrace) {
//       addError(e, stacktrace);
//     }
//   }
//   FutureOr<void> _onSearchDestinationRequested(
//       SearchDestinationRequested event,
//       Emitter<SearchState> emit,
//       ) async {
//     try {
//       emit(state.copyWith(searchDestinationStatus: Status.inProgress));
//
//     } on Exception catch (e, stacktrace) {
//       addError(e, stacktrace);
//     }
//   }
// }