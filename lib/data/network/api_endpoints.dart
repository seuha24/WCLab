class ApiEndpoints {
  static const String baseUrl = 'https://backend.catholicuniv.pillowstudio.kr';
  static const String baseUrl2 = 'http://cuksl.xyz:3306';

  // Auth 관련 엔드포인트
  static const String googleAuthToken = '$baseUrl/auth/google/token';
  static const String appleAuthToken = '$baseUrl/auth/apple/token';
  static const String refreshAuthToken = '$baseUrl/auth/refresh';

  // User 관련 엔드포인트
  static const String patchUserInfo = '$baseUrl/user/info';
  static const String getUserInfo = '$baseUrl/user/me';

  // 출입구 관련 엔드포인트
  static const String saveBuildingEntrance = '$baseUrl/api/buildings/save';
  static String getBuildingEntrance(String buildingName) {
    return '$baseUrl/api/buildings/$buildingName/entrances/coordinates';
  }
  // static const String getBuildingEntrance = '$baseUrl/api/buildings/홍대입구/entrances/coordinates';
}

//   // 출입구 관련 엔드포인트
//   static const String saveEntrance = '$baseUrl2/encodedAddr/lon/lat';
//   /// 주소, 위도, 경도로 출입구 정보를 조회하는 엔드포인트
//   static String getEntranceByAddress(String encodedAddr, double lon, double lat) {
//     return '$baseUrl2/$encodedAddr/$lon/$lat';
//     //return '$baseUrl2/$encodedAddr/coordinates';
//   }
// }