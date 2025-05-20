part of '../../../framework/controller.dart';

class EntranceBloc extends Bloc<EntranceEvent, EntranceState> {
  final GetBuildingEntrancesUseCase getBuildingEntrancesUseCase;

  EntranceBloc({required this.getBuildingEntrancesUseCase}) : super(EntranceInitial()) {
    on<FetchBuildingEntrances>(_onFetchBuildingEntrances);
  }

  Future<void> _onFetchBuildingEntrances(
    FetchBuildingEntrances event,
    Emitter<EntranceState> emit,
  ) async {
    emit(EntranceLoading());

    try {
      // 주소 인코딩
      final encodedAddr = Uri.encodeComponent(event.address);
      
      debugPrint('=== 출입구 정보 요청 ===');
      debugPrint('인코딩된 주소: $encodedAddr');
      debugPrint('위도: ${event.latitude}');
      debugPrint('경도: ${event.longitude}');

      final result = await getBuildingEntrancesUseCase(
        encodedAddr: encodedAddr,
        longitude: event.longitude,
        latitude: event.latitude,
      );

      result.fold(
        (failure) {
          debugPrint('출입구 정보 요청 실패: $failure');
          emit(EntranceError(errorMessage: "Failed to fetch entrances"));
        },
        (response) {
          if (response.entrances.isEmpty) {
            emit(EntranceError(errorMessage: "No entrances found. Proceeding with regular route search."));
          } else {
            debugPrint('출입구 정보 요청 성공: ${response.buildingName}');
            debugPrint('출입구 개수: ${response.entrances.length}');
            emit(EntranceLoaded(buildingResponse: response));
          }
        },
      );
    } catch (e) {
      debugPrint('출입구 정보 요청 중 에러 발생: $e');
      emit(EntranceError(errorMessage: "Failed to process address"));
    }  
  }
}
