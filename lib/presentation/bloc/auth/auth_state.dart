part of '../../../framework/controller.dart';

class AuthState extends Equatable {
  final Status googleSignInStatus;
  final Status googleSignOutStatus;
  final Status guestSignInStatus;
  final Status guestSignOutStatus;

  const AuthState({
    this.googleSignInStatus = Status.initial,
    this.googleSignOutStatus = Status.initial,
    this.guestSignInStatus = Status.initial,
    this.guestSignOutStatus = Status.initial,
  });

  @override
  List<Object?> get props => [
        googleSignInStatus,
        googleSignOutStatus,
        guestSignInStatus,
        guestSignOutStatus,
      ];

  AuthState copyWith({
    Status? googleSignInStatus,
    Status? googleSignOutStatus,
    Status? guestSignInStatus,
    Status? guestSignOutStatus,
  }) {
    return AuthState(
      googleSignInStatus: googleSignInStatus ?? this.googleSignInStatus,
      googleSignOutStatus: googleSignOutStatus ?? this.googleSignOutStatus,
      guestSignInStatus: guestSignInStatus ?? this.guestSignInStatus,
      guestSignOutStatus: guestSignOutStatus ?? this.guestSignOutStatus,
    );
  }
}
