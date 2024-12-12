part of '../../../framework/controller.dart';

enum AuthType {
  google,
  apple,
  anonymous,
}

extension AuthTypeExtension on AuthType {
  static String getLabel(AuthType type) {
    switch (type) {
      case AuthType.google:
        return 'google';
      case AuthType.apple:
        return 'apple';
      case AuthType.anonymous:
        return 'anonymous';
      default:
        return 'anonymous';
    }
  }

  static AuthType getType(String? type) {
    switch (type) {
      case 'google':
        return AuthType.google;
      case 'apple':
        return AuthType.apple;
      case 'anonymous':
        return AuthType.anonymous;
      default:
        return AuthType.anonymous;
    }
  }
}

// #docregion Initialize
const List<String> scopes = <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly',
];

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final AuthService _authService = DI<AuthService>();

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(AuthState()) {
    on<SignInAnonymouslyEvent>(_handleSignInAnonymously);
    on<SignOutAnonymouslyEvent>(_handleSignOutAnonymously);
    on<SignInWithGoogleEvent>(_handleSignInWithGoogle);
    on<SignOutWithGoogleEvent>(_handleSignOutWithGoogle);
    on<SignInWithAppleEvent>(_handleSignInWithApple);
    on<SignOutWithAppleEvent>(_handleSignOutWithApple);
    on<SignOutAllEvent>(_handleSignOutAll);
    on<PatchUserInfoEvent>(_handlePatchUserInfo);
    on<GetUserInfoEvent>(_handleGetUserInfo);
  }

  Future<void> _handleSignInAnonymously(
      SignInAnonymouslyEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signInStatus: Status.inProgress, signOutStatus: Status.initial, userName: '익명 사용자'));
    final result = await _repository.signInAnonymously();
    result.fold(
      (failure) => emit(state.copyWith(signInStatus: Status.failure)),
      (_) => emit(state.copyWith(signInStatus: Status.success)),
    );
  }

  Future<void> _handleSignOutAnonymously(
      SignOutAnonymouslyEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signOutStatus: Status.inProgress));
    final result = await _repository.signOutAnonymously();
    result.fold(
      (failure) => emit(state.copyWith(signOutStatus: Status.failure)),
      (_) => emit(state.copyWith(signOutStatus: Status.success)),
    );
  }

  Future<void> _handleSignInWithGoogle(
      SignInWithGoogleEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signInStatus: Status.inProgress, signOutStatus: Status.initial, userName: null));

    try {
      // Google 로그인 및 서버로 토큰 전송
      final response = await _repository.signInWithGoogle();

      // 서버 응답 데이터 처리
      if (response.data!.isNotEmpty) {
        final userName = response.data?['data']?.userName;
        emit(state.copyWith(
          signInStatus: Status.success,
          userName: userName,
        ));
      } else {
        emit(state.copyWith(signInStatus: Status.failure));
      }
    } catch (e) {
      emit(state.copyWith(signInStatus: Status.failure));
    }
  }

  Future<void> _handleSignInWithApple(
      SignInWithAppleEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signInStatus: Status.inProgress, signOutStatus: Status.initial, userName: null));

    try {
      // Apple 로그인 및 서버로 토큰 전송
      final response = await _repository.signInWithApple();
      // 서버 응답 데이터 처리
      if (response.data!.isNotEmpty) {
        final userName = response.data?['data']?.userName;
        emit(state.copyWith(
          signInStatus: Status.success,
          userName: userName,
        ));
      } else {
        emit(state.copyWith(signInStatus: Status.failure));
      }
    } catch (e) {
      emit(state.copyWith(signInStatus: Status.failure));
    }
  }

  Future<void> _handleSignOutWithGoogle(
      SignOutWithGoogleEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signOutStatus: Status.inProgress));
    final result = await _repository.signOutWithGoogle();
    result.fold(
      (failure) => emit(state.copyWith(signOutStatus: Status.failure)),
      (_) => emit(state.copyWith(signOutStatus: Status.success)),
    );
  }

  Future<void> _handleSignOutWithApple(
      SignOutWithAppleEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signOutStatus: Status.inProgress));
    final result = await _repository.signOutWithApple();
    result.fold(
      (failure) => emit(state.copyWith(signOutStatus: Status.failure)),
      (_) => emit(state.copyWith(signOutStatus: Status.success)),
    );
  }

  Future<void> _handleSignOutAll(
      SignOutAllEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      signOutStatus: Status.inProgress,
    ));
    final result = await _repository.signOutAll();
    result.fold(
      (failure) => emit(state.copyWith(signOutStatus: Status.failure)),
      (_) => emit(state.copyWith(
        signOutStatus: Status.success,
        signInStatus: Status.initial,
        patchUserInfoStatus: Status.initial,
        getUserInfoStatus: Status.initial,
        sendTokenStatus: Status.initial,
        userName: null,
      )),
    );
  }

  Future<void> _handlePatchUserInfo(
      PatchUserInfoEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(patchUserInfoStatus: Status.inProgress));
    final result = await _repository.patchUserInfo(event.userName);
    result.fold(
      (failure) => emit(state.copyWith(patchUserInfoStatus: Status.failure)),
      (_) => emit(state.copyWith(patchUserInfoStatus: Status.success)),
    );
  }

  Future<void> _handleGetUserInfo(
      GetUserInfoEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(getUserInfoStatus: Status.inProgress));
    final result = await _repository.getUserInfo();
    result.fold(
      (failure) => emit(state.copyWith(getUserInfoStatus: Status.failure)),
      (data) => emit(state.copyWith(
          getUserInfoStatus: Status.success, userName: data['userName'])),
    );
  }
}
