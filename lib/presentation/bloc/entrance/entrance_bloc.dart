part of '../../../framework/controller.dart';

class EntranceBloc extends Bloc<EntranceEvent, EntranceState> {
  final GetBuildingEntrancesUseCase getBuildingEntrancesUseCase;

  EntranceBloc({required this.getBuildingEntrancesUseCase}) : super(EntranceInitial()) {
    on<FetchBuildingEntrances>(_onFetchBuildingEntrances);
    on<SelectEntrance>(_onSelectEntrance);
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
        latitude: event.latitude,
        longitude: event.longitude,
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

  Future<void> _onSelectEntrance(
    SelectEntrance event,
    Emitter<EntranceState> emit,
  ) async {
    try {
      if (state is EntranceLoaded) {
        final currentState = state as EntranceLoaded;
        final selectedEntrance = currentState.buildingResponse.entrances.firstWhere(
          (entrance) => entrance.location.latitude == event.latitude && 
                       entrance.location.longitude == event.longitude,
        );
        
        // 선택된 출입구의 위경도로 업데이트된 BuildingResponse 생성
        final updatedResponse = currentState.buildingResponse.copyWith(
          entrances: [selectedEntrance],
        );
        
        emit(EntranceLoaded(buildingResponse: updatedResponse));
      }
    } catch (e) {
      emit(EntranceError(errorMessage: e.toString()));
    }
  }
}
