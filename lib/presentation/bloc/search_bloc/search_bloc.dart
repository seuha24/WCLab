part of '../../../framework/controller.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  String startLocation = '';
  String destinationLocation = '';

  SearchBloc() : super(const SearchState()) {
    // 출발지 설정 이벤트 핸들링 등록
    on<SearchStartLocationRequested>(_onSearchStartLocationRequested);

    // 목적지 설정 이벤트 핸들링 등록
    on<SearchDestinationRequested>(_onSearchDestinationRequested);

    // 검색 결과 초기화 이벤트 핸들링 등록
    on<SearchResetRequested>(_onSearchResetRequested);
  }

  // 출발지 설정 이벤트 처리 함수
  FutureOr<void> _onSearchStartLocationRequested(
    SearchStartLocationRequested event,
    Emitter<SearchState> emit,
  ) async {
    try {
      emit(
        SearchState(
          searchStartLocation: event.searchLocation,                  // 새로운 출발지 문자열 설정
          searchDestinationLocation: state.searchDestinationLocation, // 기존 도착지 유지
          destinationGeoLocation: state.destinationGeoLocation,       // 기존 도착지 좌표 유지
          startEntrance: event.entrance,                              // 새로운 출발지 출입구 정보 설정
          destinationEntrance: state.destinationEntrance,            // 기존 목적지 출입구 유지
        ),
      );
    } on Exception catch (e, stacktrace) {
      addError(e, stacktrace);
    }
  }

  // 목적지 설정 이벤트 처리 함수
  FutureOr<void> _onSearchDestinationRequested(
    SearchDestinationRequested event,
    Emitter<SearchState> emit,
  ) async {
    try {
      emit(
        SearchState(
          searchStartLocation: state.searchStartLocation,     // 기존 출발지 유지
          searchDestinationLocation: event.searchDestination, // 새로운 도착지 문자열 설정
          destinationGeoLocation: event.geoLocation,          // 새로운 도착지 좌표 설정 (지도 선택용)
          startEntrance: state.startEntrance,                 // 기존 출발지 출입구 유지
          destinationEntrance: event.entrance,                // 새로운 목적지 출입구 정보 설정
        ),
      );
    } on Exception catch (e, stacktrace) {
      addError(e, stacktrace);
    }
  }

  /// 검색 결과 초기화 이벤트 처리 함수
  FutureOr<void> _onSearchResetRequested(
    SearchResetRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchState()); // 모든 값을 초기 상태로 초기화
  }
}
