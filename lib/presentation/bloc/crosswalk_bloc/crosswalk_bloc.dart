part of '../../../framework/controller.dart';

class CrosswalkBloc extends Bloc<CrosswalkEvent, CrosswalkState> {
  static Timer timer = Timer(Duration.zero, () {});
  final tts = DI.get<TtsService>();
  final SearchCrosswalk search2FiniteTimes;
  final SearchCrosswalk search2InfiniteTimes;
  final ConnectCrosswalk sendAcousticSignal;
  final ConnectCrosswalk sendVoiceInductor;
  final ConnectCrosswalk sendVoiceGuide;
  final GetPosition getCurrentPosition;
  final ControlFlash controlFlashOnWithWeather;

  CrosswalkBloc({
    required this.search2FiniteTimes,
    required this.search2InfiniteTimes,
    required this.sendAcousticSignal,
    required this.sendVoiceInductor,
    required this.sendVoiceGuide,
    required this.getCurrentPosition,
    required this.controlFlashOnWithWeather,
  }) : super(SearchOff(results: const [])) {
    on<SearchFiniteCrosswalkEvent>(_searchFiniteCrosswalkEvent);
    on<SearchInfiniteCrosswalkEvent>(_searchInfiniteCrosswalkEvent);
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
    tts.speak('자동 스캔이 시작됩니다.');
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
          debugPrint('📍 횡단보도 스캔 완료: ${results!.length}개 발견');
          tts.speak('${results.length} 개의 스마트 압버튼을 찾았습니다.');
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
      tts.speak('${event.crosswalk.name}에 신호안내를 요청합니다.');
      emit(ConnectOn());
      if (!Platform.isAndroid) {
        await controlFlashOnWithWeather(NoParams());
      }

      // 명령 전송
      await sendAcousticSignal(event.crosswalk);

      // 명령 전송 후 상태 유지 (화면 전환 방지)
      if (event.crosswalk.pos != null) {
        final results = await getCurrentPosition(NoParams());
        results.fold(
          (failure) {
            emit(ConnectOff(enableCompass: false));
          },
          (latLng) async {
            tts.speak('명령이 전송되었습니다.');
            bool enableCompass = true;
            if (Platform.isAndroid) {
              enableCompass = false;
            }
            emit(ConnectOff(enableCompass: enableCompass, latLng: latLng));
          },
        );
      } else {
        tts.speak('명령이 전송되었습니다.');
        emit(ConnectOff(enableCompass: false));
      }
    } catch (e) {
      tts.speak('연결 실패했습니다.');
      emit(CrosswalkError(message: 'connect failure'));
    }
  }

  Future _sendVoiceInductorEvent(
    SendVoiceInductorEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    try {
      tts.speak('${event.crosswalk.name}에 연결합니다.');
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
            tts.speak('진동이 울리지 않는 방향으로 보행하세요.');
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

  Future _sendVoiceGuideEvent(
    SendVoiceGuideEvent event,
    Emitter<CrosswalkState> emit,
  ) async {
    try {
      tts.speak('${event.crosswalk.name}에 음성안내를 요청합니다.');
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
            tts.speak('음향신호기 설치 위치 정보를 안내합니다.');
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
      await sendVoiceGuide(event.crosswalk);
    } catch (e) {
      emit(CrosswalkError(message: 'connect failure'));
    }
  }
}
