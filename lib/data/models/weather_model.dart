part of object;

class WeatherModel extends Weather {
  const WeatherModel({
    required super.visibility,
    required super.clouds,
    required super.sunrise,
    required super.sunset,
    required super.id,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      visibility: json['visibility'],
      clouds: json['clouds']['all'],
      sunrise: json['sys']['sunrise'],
      sunset: json['sys']['sunset'],
      id: json['weather'][0]['id'],
    );
  }
}
