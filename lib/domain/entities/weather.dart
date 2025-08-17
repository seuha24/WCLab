part of '../../framework/object.dart';

/// [Weather]는 날씨 객체이다.
///
/// 현재 날씨 정보를 담을 때 사용한다.
///
/// [Weather] 객체가 포함하는 정보는 아래와 같다.
///
/// |field||설명|
/// |:-------|-|:--------|
/// |[visibility]||시야 정보|
/// |[clouds]||구름 정보|
/// |[sunrise]||일출 시각 정보|
/// |[sunset]||일몰 시각 정보|
///
/// ---
/// see also :
///   * 해당 날씨 정보는 [open weather api](https://openweathermap.org/current)에 요청하는 정보이다.
class Weather extends Equatable {
  /// 육안으로 볼 수 있는 시야의 거리 정도를 나타내는 값이다.
  ///
  /// 기본 단위는 미터(m)이고 최대값은 10km 이다.
  final int visibility;

  /// 현재 하늘의 구름의 정도를 나타내는 값이다.
  ///
  /// 퍼센트(%) 값으로 100%의 경우 구름 낀 정도가 가장 심한 경우이다.
  final int clouds;

  /// 일출 시간을 나타내는 값이다.
  ///
  /// UTC로 표현되며, 아래와 같이 사용할 수 있다.
  /// 또한, 해당 데이터에 대한 자세한 사용은 `validator.dart` 에서 확인할 수 있다.
  ///
  /// ```dart
  /// int unixTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000; // 현재 시간, UTC
  /// if(unixTimestamp >= weather.sunrise) {...}
  /// ```
  final int sunrise;

  /// 일몰 시간을 나타내는 값이다.
  ///
  /// UTC로 표현되며, 아래와 같이 사용할 수 있다.
  /// 또한, 해당 데이터에 대한 자세한 사용은 `validator.dart` 에서 확인할 수 있다.
  ///
  /// ```dart
  /// int unixTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000; // 현재 시간, UTC
  /// if(unixTimestamp <= weather.sunset) {...}
  /// ```
  final int sunset;

  /// Default constructor로서 모든 parameter 값을 반드시 받아야 한다.
  ///
  /// 아래와 같이 사용할 수 있다.
  ///
  /// ```dart
  /// // After calling open weather api
  /// Weather weather = Weather(
  ///   visibility : api_visibility_data,
  ///   clouds : api_clouds_data,
  ///   sunrise : api_sunrise_data,
  ///   sunset : api_sunset_data,
  /// );
  /// ```
  ///
  final int id;

  const Weather({
    required this.visibility,
    required this.clouds,
    required this.sunrise,
    required this.sunset,
    required this.id,
  });

  @override
  List<Object?> get props => [];

  @override
  String toString() {
    return '{visibility : $visibility, clouds : $clouds, sunrise : $sunrise, sunset : $sunset, id : $id}';
  }
}
