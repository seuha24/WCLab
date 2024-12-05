part of '../../../framework/controller.dart';

class AuthState extends Equatable {
  final Status signInStatus;
  final Status signOutStatus;
  final Status patchUserInfoStatus;
  final Status getUserInfoStatus;
  final String? userName;

  const AuthState({
    this.signInStatus = Status.initial,
    this.signOutStatus = Status.initial,
    this.patchUserInfoStatus = Status.initial,
    this.getUserInfoStatus = Status.initial,
    this.userName,
  });

  @override
  List<Object?> get props =>
      [
        signInStatus,
        signOutStatus,
        patchUserInfoStatus,
        getUserInfoStatus,
        userName,
      ];

  AuthState copyWith({
    Status? signInStatus,
    Status? signOutStatus,
    Status? patchUserInfoStatus,
    Status? getUserInfoStatus,
    String? userName,
  }) {
    return AuthState(
      signInStatus: signInStatus ?? this.signInStatus,
      signOutStatus: signOutStatus ?? this.signOutStatus,
      patchUserInfoStatus: patchUserInfoStatus ?? this.patchUserInfoStatus,
      getUserInfoStatus: getUserInfoStatus ?? this.getUserInfoStatus,
      userName: userName ?? this.userName,
    );
  }
}
