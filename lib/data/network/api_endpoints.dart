class ApiEndpoints {
  /// BASE URL
  static const String API_BASE_URL = 'http://aws2.cuksl.xyz:3003'; //메인 서버
  static const String API_SUB_BASE_URL = 'http://cuksl.xyz:3306'; //서브 서버
  static const String AUTH_BASE_URL = 'http://aws2.cuksl.xyz:3333'; //로그인 서버

  /// Auth 관련 엔드포인트
  static const String googleAuthToken = '$AUTH_BASE_URL/auth/google/token';
  static const String appleAuthToken = '$AUTH_BASE_URL/auth/apple/token';
  static const String refreshAuthToken = '$AUTH_BASE_URL/auth/refresh';

  /// User 관련 엔드포인트
  static const String patchUserInfo = '$AUTH_BASE_URL/user/info';
  static const String getUserInfo = '$AUTH_BASE_URL/user/me';

  /// 출입구 관련 엔드포인트
  // 주소, 위도, 경도로 출입구 정보를 조회하는 엔드포인트 (GET) 0-1
  static String getBuildingEntrance(
      String encodedAddr, double longitude, double latitude) {
    return '$API_BASE_URL/api/entrances/search'
        '?address=$encodedAddr&lon=$longitude&lat=$latitude';
  }

  // 출입구 좌표 등록 (POST) 0-2
  static const String saveBuildingEntrance = '$API_BASE_URL/api/entrances/save';

  /// 즐겨찾기 관련 엔드포인트
  // 지점 즐겨찾기 조회 1-1
  static String getFavoritePoints(String loginMethod, String userId) {
    return '$API_BASE_URL/api/favorites/points/search'
        '?login_method=$loginMethod&uuid=$userId';
  }

  // 지점 즐겨찾기 등록 1-2
  static const String addFavoritePoint =
      '$API_BASE_URL/api/favorites/points/save';
  // 지점 즐겨찾기 삭제 1-3
  static String deleteFavoritePoint(String userId, String favIdx) {
    return '$API_BASE_URL/api/favorites/points/delete'
        '?uuid=$userId&idx=$favIdx';
  }

  // 지점 즐겨찾기 수정 1-4
  static const String updateFavoritePoint =
      '$API_BASE_URL/api/favorites/points/alter';

  // 경로 즐겨찾기 조회 1-5
  static String getFavoriteRoutes(String loginMethod, String userId) {
    return '$API_BASE_URL/api/favorites/routes/search'
        '?login_method=$loginMethod&uuid=$userId';
  }

  // 경로 즐겨찾기 등록 1-6
  static const String addFavoriteRoute =
      '$API_BASE_URL/api/favorites/routes/save';
  // 경로 즐겨찾기 삭제 1-7
  static String deleteFavoriteRoute(String userId, String favIdx) {
    return '$API_BASE_URL/api/favorites/routes/delete'
        '?uuid=$userId&idx=$favIdx';
  }

  // 경로 즐겨찾기 수정 1-8
  static const String updateFavoriteRoute =
      '$API_BASE_URL/api/favorites/routes/alter';

  /// C-ITS 관련 엔드포인트
  // C-ITS 교차로 정보 조회 2-1
  static String getCitsJunctionNearest(double longitude, double latitude) {
    return '$API_BASE_URL/api/location/junctions/nearest'
        '?lon=$longitude&lat=$latitude';
  }

  // C-ITS 교차로 정보 다운로드 2-2
  static const String downloadCitsJunctions =
      '$API_BASE_URL/api/location/junctions/download';

  // C-ITS 동기화 2-3
  static const String syncCitsVersion = '$API_BASE_URL/api/location/sync';

  // C-ITS 음향신호기 정보 조회 2-4
  static String getCitsCrosswalkNearest(double longitude, double latitude) {
    return '$API_BASE_URL/api/location/crosswalk/nearest'
        '?lon=$longitude&lat=$latitude';
  }

  // C-ITS 음향신호기 정보 다운로드 2-5
  static const String downloadCitsCrosswalk =
      '$API_BASE_URL/api/location/crosswalk/download';
}
