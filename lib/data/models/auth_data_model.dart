import 'package:safelight/domain/entities/auth.dart';

class AuthDataModel extends Auth {
  AuthDataModel({
    required super.accessToken,
    required super.refreshToken,
    this.userName,
    this.id,
  });

  final String? userName;
  final String? id;

  factory AuthDataModel.fromMap(Map<String, dynamic> map) {
    final tokenData = map['token'] as Map<String, dynamic>;
    return AuthDataModel(
      accessToken: tokenData['accessToken'] as String,
      refreshToken: tokenData['refreshToken'] as String,
      userName: map['userName'] as String?, // userName 추가
      id: map['id'] as String?, // id 추가
    );
  }

  @override
  String toString() {
    return 'AuthDataModel(accessToken: $accessToken, refreshToken: $refreshToken, userName: $userName, id: $id)';
  }
}
