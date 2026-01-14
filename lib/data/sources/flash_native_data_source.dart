part of '../../framework/data_source.dart';

abstract class FlashNativeDataSource {
  Future on({bool infinite = false, int count = 10});
  Future off();
}

class FlashNativeDataSourceImpl implements FlashNativeDataSource {
  final tts = DI.get<TtsService>();
  Timer timer = Timer(Duration.zero, () {});

  @override
  Future on({bool infinite = false, int count = 30}) async {
    try {
      bool available = await TorchLight.isTorchAvailable();
      if (!available) {
        throw FlashException();
      }

      await off();
      timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (!infinite && timer.tick == count) {
          timer.cancel();
        }
        await TorchLight.enableTorch();
        await Future.delayed(const Duration(milliseconds: 1000));
        await TorchLight.disableTorch();

        if (infinite && timer.tick % 15 == 0) {
          // 30초 간격으로 알림 & 무한으로 켜짐
          tts.speak(TtsMessages.flashLightCurrentlyOn);
          debugPrint("경광등이 켜져 있습니다.");
        }
      });
    } on FlashException {
      throw FlashException();
    } catch (e) {
      throw FlashException();
    }
  }

  @override
  Future off() async {
    try {
      timer.cancel();
      await TorchLight.disableTorch();
    } catch (e) {
      throw FlashException();
    }
  }
}
