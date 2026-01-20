part of '../../../framework/controller.dart';

class CrosswalkBloc extends Bloc<CrosswalkEvent, CrosswalkState> {
  static Timer timer = Timer(Duration.zero, () {});
  final tts = DI.get<TtsService>();
  final SearchCrosswalk search2FiniteTimes;
  final SearchCrosswalk search2InfiniteTimes;
  final ConnectCrosswalk sendAcousticSignal;
  final ConnectCrosswalk sendVoiceInductor;
  final ConnectCrosswalk sendVoiceGuide;
  final ControlFlash controlFlashOnWithWeather;

  CrosswalkBloc({
    required this.search2FiniteTimes,
    required this.search2InfiniteTimes,
    required this.sendAcousticSignal,
    required this.sendVoiceInductor,
    required this.sendVoiceGuide,
    required this.controlFlashOnWithWeather,
  }) : super(CrosswalkInitial()) {
    on<SearchFiniteCrosswalkEvent>(_searchFiniteCrosswalkEvent);
    on<SearchInfiniteCrosswalkEvent>(_searchInfiniteCrosswalkEvent);
    on<StopScanEvent>(_stopScanEvent);
    on<SendAcousticSignalEvent>(_sendAcousticSignalEvent);
    on<SendVoiceInductorEvent>(_sendVoiceInductorEvent);
    on<SendVoiceGuideEvent>(_sendVoiceGuideEvent);
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
    tts.speakAutoScanStarted();
    timer.cancel();
    emit(SearchOn(infinite: true));
    await search2InfiniteTimes(NoParams());

    timer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      await search2InfiniteTimes(NoParams());
    });
  }

  /// 스캔 중단 핸들러 - 초기 화면으로 돌아감
  Future _stopScanEvent(
    StopScanEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    if (BlueNativeDataSourceImpl.subscription != null) {
      BlueNativeDataSourceImpl.subscription!.cancel();
    }
    timer.cancel();
    emit(CrosswalkInitial());
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
          debugPrint('📍 횡단보도 스캔 완료: ${results!.length}개 발견');
          tts.speakSmartButtonsFound(results.length);
          emit(SearchOff(results: results));
          debugPrint('📍 SearchOff 상태로 전환 완료');
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
      tts.speakRequestSignalGuide(event.crosswalk.name);
      emit(ConnectOn());
      if (!Platform.isAndroid) {
        await controlFlashOnWithWeather(NoParams());
      }

      await sendAcousticSignal(event.crosswalk);

      tts.speakCommandSent();
      emit(ConnectOff());
    } catch (e) {
      tts.speakConnectionFailed();
      emit(CrosswalkError(message: 'connect failure'));
    }
  }

  Future _sendVoiceInductorEvent(
    SendVoiceInductorEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    try {
      tts.speakConnectingTo(event.crosswalk.name);
      emit(ConnectOn());
      if (!Platform.isAndroid) {
        await controlFlashOnWithWeather(NoParams());
      }

      await sendVoiceInductor(event.crosswalk);

      tts.speakCommandSent();
      emit(ConnectOff());
    } catch (e) {
      emit(CrosswalkError(message: 'connect failure'));
    }
  }

  Future _sendVoiceGuideEvent(
    SendVoiceGuideEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    try {
      tts.speakRequestVoiceGuide(event.crosswalk.name);
      emit(ConnectOn());
      if (!Platform.isAndroid) {
        await controlFlashOnWithWeather(NoParams());
      }

      await sendVoiceGuide(event.crosswalk);

      tts.speakCommandSent();
      emit(ConnectOff());
    } catch (e) {
      emit(CrosswalkError(message: 'connect failure'));
    }
  }
}
