part of '../../../framework/controller.dart';

class AuthState extends Equatable {
  final Status googleSignInStatus;
  final Status googleSignOutStatus;
  final Status appleSignInStatus;
  final Status appleSignOutStatus;
  final Status guestSignInStatus;
  final Status guestSignOutStatus;

  const AuthState({
    this.googleSignInStatus = Status.initial,
    this.googleSignOutStatus = Status.initial,
    this.appleSignInStatus = Status.initial,
    this.appleSignOutStatus = Status.initial,
    this.guestSignInStatus = Status.initial,
    this.guestSignOutStatus = Status.initial,
  });

  @override
  List<Object?> get props => [
        googleSignInStatus,
        googleSignOutStatus,
        appleSignInStatus,
        appleSignOutStatus,
        guestSignInStatus,
        guestSignOutStatus,
      ];

  AuthState copyWith({
    Status? googleSignInStatus,
    Status? googleSignOutStatus,
    Status? appleSignInStatus,
    Status? appleSignOutStatus,
    Status? guestSignInStatus,
    Status? guestSignOutStatus,
  }) {
    return AuthState(
      googleSignInStatus: googleSignInStatus ?? this.googleSignInStatus,
      googleSignOutStatus: googleSignOutStatus ?? this.googleSignOutStatus,
      appleSignInStatus: appleSignInStatus ?? this.appleSignInStatus,
      appleSignOutStatus: appleSignOutStatus ?? this.appleSignOutStatus,
      guestSignInStatus: guestSignInStatus ?? this.guestSignInStatus,
      guestSignOutStatus: guestSignOutStatus ?? this.guestSignOutStatus,
    );
  }
}
