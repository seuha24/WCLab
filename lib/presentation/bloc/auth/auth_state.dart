part of '../../../framework/controller.dart';

/// 애플리케이션의 인증 상태를 나타냅니다.
///
/// 이 상태는 로그인, 로그아웃, 사용자 정보 업데이트, 사용자 정보 조회 및 토큰 전송
/// 등의 인증 관련 작업 상태를 보유하며, 인증된 사용자의 이름도 저장할 수 있습니다.
class AuthState extends Equatable {
  /// 로그인 작업의 상태를 나타냅니다.
  final Status signInStatus;

  /// 로그아웃 작업의 상태를 나타냅니다.
  final Status signOutStatus;

  /// 사용자 정보 업데이트(패치) 작업의 상태를 나타냅니다.
  final Status patchUserInfoStatus;

  /// 사용자 정보 조회 작업의 상태를 나타냅니다.
  final Status getUserInfoStatus;

  /// 토큰 전송 작업의 상태를 나타냅니다.
  final Status sendTokenStatus;

  /// 인증된 사용자의 이름을 나타냅니다.
  final String? userName;

  /// [AuthState]의 생성자입니다.
  ///
  /// 모든 상태 값들은 기본적으로 [Status.initial]로 초기화되며,
  /// [userName]은 선택적으로 제공됩니다.
  const AuthState({
    this.signInStatus = Status.initial,
    this.signOutStatus = Status.initial,
    this.patchUserInfoStatus = Status.initial,
    this.getUserInfoStatus = Status.initial,
    this.sendTokenStatus = Status.initial,
    this.userName,
  });

  @override
  List<Object?> get props => [
    signInStatus,
    signOutStatus,
    patchUserInfoStatus,
    getUserInfoStatus,
    sendTokenStatus,
    userName,
  ];

  /// 현재 [AuthState]의 값을 기반으로 일부 필드만 변경하여 새 인스턴스를 생성합니다.
  ///
  /// 제공되지 않은 필드는 기존의 값을 유지합니다.
  AuthState copyWith({
    Status? signInStatus,
    Status? signOutStatus,
    Status? patchUserInfoStatus,
    Status? getUserInfoStatus,
    Status? sendTokenStatus,
    String? userName,
  }) {
    return AuthState(
      signInStatus: signInStatus ?? this.signInStatus,
      signOutStatus: signOutStatus ?? this.signOutStatus,
      patchUserInfoStatus: patchUserInfoStatus ?? this.patchUserInfoStatus,
      getUserInfoStatus: getUserInfoStatus ?? this.getUserInfoStatus,
      sendTokenStatus: sendTokenStatus ?? this.sendTokenStatus,
      userName: userName,
    );
  }
}