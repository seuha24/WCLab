part of '../../framework/core.dart';

abstract class APIS {}

class WeatherAPI implements APIS {
  static String postionURL(double lat, double lon) =>
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=e5a7b17b215d3503ab23e2066fba37dc';
}

class CrosswalkAPI implements APIS {
  static List<Map<String, dynamic>> map = [];
}
