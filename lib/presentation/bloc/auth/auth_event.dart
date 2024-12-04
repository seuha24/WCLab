part of '../../../framework/controller.dart';

class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignInAnonymouslyEvent extends AuthEvent {}

class SignOutAnonymouslyEvent extends AuthEvent {}

class SignInWithGoogleEvent extends AuthEvent {}

class SignOutWithGoogleEvent extends AuthEvent {}

class SignInWithAppleEvent extends AuthEvent {}

class SignOutWithAppleEvent extends AuthEvent {}

class PatchUserInfoEvent extends AuthEvent {
  final String userName;
  PatchUserInfoEvent(this.userName);
}

class GetUserInfoEvent extends AuthEvent {}


