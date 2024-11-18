part of core;

abstract class Validator {}

class WeatherValidator implements Validator {
  Either<Failure, bool> checkFlashEnabled(
      Weather weather, AmbientLightLevel ambientLightLevel) {
    try {
      int unixTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      String lightmode = '';
      Box flashbox = Hive.box<FlashMode>('flashmode');
      if (flashbox.values.toList().isEmpty) {
        lightmode = 'alwayson';
      } else if (flashbox.values.toList()[0] == FlashMode.ALWAYS) {
        lightmode = 'alwayson';
        print("항상 켜짐");
        return const Right(true);
      } else if (flashbox.values.toList()[0] == FlashMode.NEVER_IN_USE) {
        lightmode = 'alwaysoff';
        print("항상 꺼짐");
        return const Right(false);
      } else if (flashbox.values.toList()[0] == FlashMode.WITH_WEATHER) {
        lightmode = 'weathers';
        print("날씨, 조도");
        if (!(unixTimestamp >= weather.sunrise &&
                unixTimestamp <= weather.sunset) ||
            (weather.visibility < 500) ||
            (weather.id <= 622 && weather.id >= 200) ||
            (weather.id == 804) ||
            (ambientLightLevel.ambientLightLevel! <= 1.2)) {
          // print(weather.id);
          // print("ambi ${ambientLightLevel.ambientLightLevel}");
          return const Right(true);
        }
      }
      print(lightmode);
      return const Right(false);
    } catch (e) {
      return Left(ValidateFailure());
    }
  }
}
