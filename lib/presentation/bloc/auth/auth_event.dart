part of '../../../framework/controller.dart';

class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignInAnonymouslyEvent extends AuthEvent {}

class SignInWithGoogleEvent extends AuthEvent {}

class SignInWithAppleEvent extends AuthEvent {}

class SendOAuthTokenToServerEvent extends AuthEvent {
  final String token;
  final AuthType authType;

  SendOAuthTokenToServerEvent({required this.token, required this.authType});

  @override
  List<Object?> get props => [token, authType];
}

class SignOutAnonymouslyEvent extends AuthEvent {}

class SignOutWithGoogleEvent extends AuthEvent {}

class SignOutWithAppleEvent extends AuthEvent {}

class SignOutAllEvent extends AuthEvent {}

class PatchUserInfoEvent extends AuthEvent {
  final String userName;
  PatchUserInfoEvent(this.userName);
}

class GetUserInfoEvent extends AuthEvent {}


