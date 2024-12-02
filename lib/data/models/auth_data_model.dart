import 'package:safelight/domain/entities/auth.dart';

class AuthDataModel extends Auth {
  AuthDataModel({
    required super.accessToken,
    required super.refreshToken,
    this.userName,
  });

  final String? userName;

  factory AuthDataModel.fromMap(Map<String, dynamic> map) {
    final tokenData = map['token'] as Map<String, dynamic>;
    return AuthDataModel(
      accessToken: tokenData['accessToken'] as String,
      refreshToken: tokenData['refreshToken'] as String,
      userName: map['userName'] as String?, // userName 추가
    );
  }

  @override
  String toString() {
    return 'AuthDataModel(accessToken: $accessToken, refreshToken: $refreshToken, userName: $userName)';
  }
}
