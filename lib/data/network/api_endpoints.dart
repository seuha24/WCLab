class ApiEndpoints {
  //static const String baseUrl = 'https://backend.catholicuniv.pillowstudio.kr';
  static const String baseUrl = 'http://aws2.cuksl.xyz:3333'; //로그인 서버
  static const String baseUrl2 = 'http://cuksl.xyz:3306'; //연결 없음
  //static const String baseUrl3 = 'http://aws.cuksl.xyz:3333'; //출입구 조회_aws
  static const String baseUrl3 = 'http://cuksl.xyz:3306'; //출입구 조회_학교

  // Auth 관련 엔드포인트
  static const String googleAuthToken = '$baseUrl/auth/google/token';
  static const String appleAuthToken = '$baseUrl/auth/apple/token';
  static const String refreshAuthToken = '$baseUrl/auth/refresh';

  // User 관련 엔드포인트
  static const String patchUserInfo = '$baseUrl/user/info';
  static const String getUserInfo = '$baseUrl/user/me';

  // 출입구 관련 엔드포인트

  // 출입구 좌표 등록 (POST)
  static const String saveBuildingEntrance = '$baseUrl3/save/entrances';

  /// 주소, 위도, 경도로 출입구 정보를 조회하는 엔드포인트 (GET)
  static String getBuildingEntrance(String encodedAddr, double longitude, double latitude) {
    return '$baseUrl3/$encodedAddr/$longitude/$latitude';
  }
}