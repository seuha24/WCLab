class ApiEndpoints {
  // 즐겨찾기 관련 엔드포인트
  static const String favBaseUrl = 'http://aws2.cuksl.xyz:3003'; //즐겨찾기
  static const String baseUrl = 'http://aws2.cuksl.xyz:3333'; //로그인 서버
  static const String baseUrl2 = 'http://aws2.cuksl.xyz:3003'; //출입구 조회
  /// 학교 서버: 'http://cuksl.xyz:3306'
  // Auth 관련 엔드포인트
  static const String googleAuthToken = '$baseUrl/auth/google/token';
  static const String appleAuthToken = '$baseUrl/auth/apple/token';
  static const String refreshAuthToken = '$baseUrl/auth/refresh';

  // User 관련 엔드포인트
  static const String patchUserInfo = '$baseUrl/user/info';
  static const String getUserInfo = '$baseUrl/user/me';

  // 출입구 관련 엔드포인트

  // 출입구 좌표 등록 (POST)
  static const String saveBuildingEntrance = '$baseUrl2/save/entrances';

  /// 주소, 위도, 경도로 출입구 정보를 조회하는 엔드포인트 (GET)
  static String getBuildingEntrance(String encodedAddr, double longitude, double latitude) {
    return '$baseUrl2/$encodedAddr/$longitude/$latitude';
  }

  // 즐겨찾기 지점 조회
  static String getFavoritePoints(String loginMethod, String userId) {
    return '$favBaseUrl/fav_point/$loginMethod/$userId';
  }

  // 즐겨찾기 경로 조회
  static String getFavoriteRoutes(String loginMethod, String userId) {
    return '$favBaseUrl/fav_route/$loginMethod/$userId';
  }

  // 즐겨찾기 지점 등록
  static const String addFavoritePoint = '$favBaseUrl/save/fav/point';

  // 즐겨찾기 경로 등록
  static const String addFavoriteRoute = '$favBaseUrl/save/fav/route';
}