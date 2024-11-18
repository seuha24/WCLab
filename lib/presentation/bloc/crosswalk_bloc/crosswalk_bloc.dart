part of controller;

class CrosswalkBloc extends Bloc<CrosswalkEvent, CrosswalkState> {
  static Timer timer = Timer(Duration.zero, () {});
  final tts = DI.get<TTS>();
  final SearchCrosswalk search2FiniteTimes;
  final SearchCrosswalk search2InfiniteTimes;
  final ConnectCrosswalk sendAcousticSignal;
  final ConnectCrosswalk sendVoiceInductor;
  final GetPosition getCurrentPosition;
  final ControlFlash controlFlashOnWithWeather;

  CrosswalkBloc({
    required this.search2FiniteTimes,
    required this.search2InfiniteTimes,
    required this.sendAcousticSignal,
    required this.sendVoiceInductor,
    required this.getCurrentPosition,
    required this.controlFlashOnWithWeather,
  }) : super(SearchOff(results: const [])) {
    on<SearchFiniteCrosswalkEvent>(_searchFiniteCrosswalkEvent);
    on<SearchInfiniteCrosswalkEvent>(_searchInfiniteCrosswalkEvent);
    on<SendAcousticSignalEvent>(_sendAcousticSignalEvent);
    on<SendVoiceInductorEvent>(_sendVoiceInductorEvent);
  }

  Future _searchInfiniteCrosswalkEvent(
    SearchInfiniteCrosswalkEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    if (BlueNativeDataSourceImpl.subscription != null) {
      BlueNativeDataSourceImpl.subscription!.cancel();
    }
    if (BlueNativeDataSourceImpl.subscription != null) {
      BlueNativeDataSourceImpl.subscription!.cancel();
    }
    tts('자동 스캔이 시작됩니다.');
    timer.cancel();
    emit(SearchOn(infinite: true));
    await search2InfiniteTimes(NoParams());

    timer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      await search2InfiniteTimes(NoParams());
    });
  }

  Future _searchFiniteCrosswalkEvent(
    SearchFiniteCrosswalkEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    try {
      if (BlueNativeDataSourceImpl.subscription != null) {
        BlueNativeDataSourceImpl.subscription!.cancel();
      }
      timer.cancel();
      emit(SearchOn());

      final results = await search2FiniteTimes(NoParams());

      results.fold(
        (failure) {
          if (failure is BlueFailure) {
            emit(CrosswalkError(message: '블루투스 스캔 실패, 다시 시도해주세요.'));
          } else if (failure is ServerFailure) {
            emit(CrosswalkError(message: '앱 내 블루투스와 위치 권한을 확인해주세요.'));
          }
        },
        (results) {
          tts('${results!.length} 개의 스마트 압버튼을 찾았습니다.');
          emit(SearchOff(results: results));
        },
      );
    } catch (e) {
      emit(CrosswalkError(message: '블루투스 스캔 실패, 다시 시도해주세요.'));
    }
  }

  Future _sendAcousticSignalEvent(
    SendAcousticSignalEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    try {
      tts('${event.crosswalk.name}에 연결합니다.');
      emit(ConnectOn());
      if (!Platform.isAndroid) {
        await controlFlashOnWithWeather(NoParams());
      }
      if (event.crosswalk.pos != null) {
        final results = await getCurrentPosition(NoParams());
        results.fold(
          (failure) {
            emit(ConnectOff(enableCompass: false));
          },
          (latLng) async {
            tts('진동이 울리지 않는 방향으로 보행하세요.');
            bool enableCompass = true;
            if (Platform.isAndroid) {
              enableCompass = false;
            }
            emit(ConnectOff(enableCompass: enableCompass, latLng: latLng));
          },
        );
      } else {
        emit(ConnectOff(enableCompass: false));
      }

      await sendAcousticSignal(event.crosswalk);
    } catch (e) {
      emit(CrosswalkError(message: 'connect failure'));
    }
  }

  Future _sendVoiceInductorEvent(
    SendVoiceInductorEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    try {
      tts('${event.crosswalk.name}에 연결합니다.');
      emit(ConnectOn());
      if (!Platform.isAndroid) {
        await controlFlashOnWithWeather(NoParams());
      }
      if (event.crosswalk.pos != null) {
        final results = await getCurrentPosition(NoParams());
        results.fold(
          (failure) {
            emit(ConnectOff(enableCompass: false));
          },
          (latLng) async {
            tts('진동이 울리지 않는 방향으로 보행하세요.');
            bool enableCompass = true;
            if (Platform.isAndroid) {
              enableCompass = false;
            }
            emit(ConnectOff(enableCompass: enableCompass, latLng: latLng));
          },
        );
      } else {
        emit(ConnectOff(enableCompass: false));
      }
      await sendVoiceInductor(event.crosswalk);
    } catch (e) {
      emit(CrosswalkError(message: 'connect failure'));
    }
  }
}
