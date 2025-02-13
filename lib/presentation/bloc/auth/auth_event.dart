part of '../../../framework/controller.dart';

/// 모든 인증 이벤트의 기본 클래스입니다.
/// [Equatable]을 상속받아 이벤트의 동등성 비교를 용이하게 합니다.
class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 익명 로그인을 트리거하는 이벤트입니다.
class SignInAnonymouslyEvent extends AuthEvent {}

/// 구글 로그인을 트리거하는 이벤트입니다.
class SignInWithGoogleEvent extends AuthEvent {}

/// 애플 로그인을 트리거하는 이벤트입니다.
class SignInWithAppleEvent extends AuthEvent {}

/// OAuth 토큰을 서버로 전송하는 이벤트입니다.
///
/// [token]은 OAuth 제공자로부터 받은 토큰을 나타내며,
/// [authType]은 인증 방식(예: Google, Apple)을 지정합니다.
class SendOAuthTokenToServerEvent extends AuthEvent {
  /// 서버로 전송할 OAuth 토큰입니다.
  final String token;

  /// 인증 방식입니다.
  final AuthType authType;

  /// [token]과 [authType]을 받아 [SendOAuthTokenToServerEvent]를 생성합니다.
  SendOAuthTokenToServerEvent({required this.token, required this.authType});

  @override
  List<Object?> get props => [token, authType];
}

/// 익명 로그아웃을 트리거하는 이벤트입니다.
class SignOutAnonymouslyEvent extends AuthEvent {}

/// 구글 로그아웃을 트리거하는 이벤트입니다.
class SignOutWithGoogleEvent extends AuthEvent {}

/// 애플 로그아웃을 트리거하는 이벤트입니다.
class SignOutWithAppleEvent extends AuthEvent {}

/// 모든 인증 공급자에서 로그아웃을 트리거하는 이벤트입니다.
class SignOutAllEvent extends AuthEvent {}

/// 사용자 정보를 수정(패치)하는 이벤트입니다.
///
/// [userName]은 업데이트할 사용자 이름을 나타냅니다.
class PatchUserInfoEvent extends AuthEvent {
  /// 업데이트할 사용자 이름입니다.
  final String userName;

  /// [userName]을 받아 [PatchUserInfoEvent]를 생성합니다.
  PatchUserInfoEvent(this.userName);
}

/// 사용자 정보를 조회하는 이벤트입니다.
class GetUserInfoEvent extends AuthEvent {}