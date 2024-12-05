class ApiEndpoints {
  static const String baseUrl = 'https://backend.catholicuniv.pillowstudio.kr';

  // Auth 관련 엔드포인트
  static const String googleAuthToken = '$baseUrl/auth/google/token';
  static const String appleAuthToken = '$baseUrl/auth/apple/token';
  static const String refreshAuthToken = '$baseUrl/auth/refresh';

  // User 관련 엔드포인트
  static const String patchUserInfo = '$baseUrl/user/info';
  static const String getUserInfo = '$baseUrl/user/me';
}