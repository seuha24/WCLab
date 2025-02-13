part of '../../../framework/controller.dart';

/// Google API 인증에 필요한 OAuth 2.0 스코프 리스트입니다.
const List<String> scopes = <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly',
];

/// {@template auth_bloc}
/// [AuthBloc] 클래스는 인증 관련 상태 관리를 담당하는 Bloc 클래스입니다.
/// 익명 로그인, 구글 로그인, 애플 로그인 등 다양한 인증 이벤트를 처리하며,
/// 인증 상태 업데이트 및 인증 데이터 저장/삭제를 수행합니다.
/// {@endtemplate}
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// 인증 관련 비즈니스 로직을 수행하는 리포지토리입니다.
  final AuthRepository _repository;

  /// 인증 데이터 저장/삭제 등의 기능을 제공하는 서비스입니다.
  final AuthService _authService = DI<AuthService>();

  /// {@macro auth_bloc}
  ///
  /// [repository]를 받아 인증 리포지토리를 초기화하고, 이벤트 핸들러를 등록합니다.
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

  /// 익명 로그인 이벤트를 처리합니다.
  ///
  /// 로그인 진행 상태를 업데이트한 후,
  /// [_repository.signInAnonymously]를 호출하여 로그인 결과에 따라
  /// 상태를 성공 또는 실패로 업데이트합니다.
  Future<void> _handleSignInAnonymously(
      SignInAnonymouslyEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
        signInStatus: Status.inProgress,
        signOutStatus: Status.initial,
        userName: null));
    final result = await _repository.signInAnonymously();
    result.fold(
          (failure) => emit(state.copyWith(signInStatus: Status.failure)),
          (_) => emit(
          state.copyWith(signInStatus: Status.success, userName: '익명 사용자')),
    );
  }

  /// 익명 로그아웃 이벤트를 처리합니다.
  ///
  /// 로그아웃 진행 상태를 업데이트한 후,
  /// [_repository.signOutAnonymously]의 결과에 따라 상태를 성공 또는 실패로 업데이트합니다.
  Future<void> _handleSignOutAnonymously(
      SignOutAnonymouslyEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signOutStatus: Status.inProgress));
    final result = await _repository.signOutAnonymously();
    result.fold(
          (failure) => emit(state.copyWith(signOutStatus: Status.failure)),
          (_) => emit(state.copyWith(signOutStatus: Status.success)),
    );
  }

  /// 구글 로그인 이벤트를 처리합니다.
  ///
  /// 구글 로그인을 진행하고, 서버로부터 응답을 받아
  /// 인증 데이터를 [_authService]에 저장한 후 상태를 업데이트합니다.
  /// 만약 응답 데이터가 유효하지 않으면 실패 상태로 업데이트합니다.
  Future<void> _handleSignInWithGoogle(
      SignInWithGoogleEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
        signInStatus: Status.inProgress,
        signOutStatus: Status.initial,
        userName: null));
    try {
      // 구글 로그인 및 서버로 토큰 전송
      final response = await _repository.signInWithGoogle();

      // 서버 응답 데이터 처리
      if (response.data!.isNotEmpty && response.data != null) {
        final authData = response.data!['data'];
        final userName = authData!.userName;

        // 인증 데이터를 로컬에 저장
        await _authService.saveAuthData(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
          userName: authData.userName ?? '',
        );

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

  /// 애플 로그인 이벤트를 처리합니다.
  ///
  /// 애플 로그인을 진행하고, 서버로부터 받은 응답 데이터를 기반으로
  /// 인증 데이터를 저장한 후 상태를 업데이트합니다.
  /// 오류 발생 시 실패 상태로 업데이트합니다.
  Future<void> _handleSignInWithApple(
      SignInWithAppleEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
        signInStatus: Status.inProgress,
        signOutStatus: Status.initial,
        userName: null));

    try {
      // 애플 로그인 및 서버로 토큰 전송
      final response = await _repository.signInWithApple();
      // 서버 응답 데이터 처리
      if (response.data!.isNotEmpty && response.data != null) {
        final authData = response.data!['data'];
        final userName = authData!.userName;

        // 인증 데이터를 로컬에 저장
        await _authService.saveAuthData(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
          userName: authData.userName ?? '',
        );

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

  /// 구글 로그아웃 이벤트를 처리합니다.
  ///
  /// 로그아웃 진행 상태를 업데이트한 후,
  /// [_repository.signOutWithGoogle]의 결과에 따라 상태를 성공 또는 실패로 업데이트합니다.
  Future<void> _handleSignOutWithGoogle(
      SignOutWithGoogleEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signOutStatus: Status.inProgress));
    final result = await _repository.signOutWithGoogle();
    result.fold(
          (failure) => emit(state.copyWith(signOutStatus: Status.failure)),
          (_) => emit(state.copyWith(signOutStatus: Status.success)),
    );
  }

  /// 애플 로그아웃 이벤트를 처리합니다.
  ///
  /// 로그아웃 진행 상태를 업데이트한 후,
  /// [_repository.signOutWithApple]의 결과에 따라 상태를 성공 또는 실패로 업데이트합니다.
  Future<void> _handleSignOutWithApple(
      SignOutWithAppleEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(signOutStatus: Status.inProgress));
    final result = await _repository.signOutWithApple();
    result.fold(
          (failure) => emit(state.copyWith(signOutStatus: Status.failure)),
          (_) => emit(state.copyWith(signOutStatus: Status.success)),
    );
  }

  /// 전체 로그아웃 이벤트를 처리합니다.
  ///
  /// 모든 로그아웃 작업을 진행한 후,
  /// [_authService]를 통해 로컬에 저장된 인증 데이터를 삭제하고
  /// 관련 상태들을 초기 상태로 리셋합니다.
  Future<void> _handleSignOutAll(
      SignOutAllEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      signOutStatus: Status.inProgress,
    ));
    final result = await _repository.signOutAll();
    await result.fold(
          (failure) async {
        emit(state.copyWith(signOutStatus: Status.failure));
      },
          (_) async {
        await _authService.clearAuthData();

        emit(state.copyWith(
          signOutStatus: Status.success,
          signInStatus: Status.initial,
          patchUserInfoStatus: Status.initial,
          getUserInfoStatus: Status.initial,
          sendTokenStatus: Status.initial,
          userName: null,
        ));
      },
    );
  }

  /// 사용자 정보 업데이트 이벤트를 처리합니다.
  ///
  /// 서버에 새로운 사용자 이름을 전송하여 업데이트하고,
  /// 결과에 따라 상태를 성공 또는 실패로 업데이트합니다.
  Future<void> _handlePatchUserInfo(
      PatchUserInfoEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(patchUserInfoStatus: Status.inProgress));
    final result = await _repository.patchUserInfo(event.userName);
    result.fold(
          (failure) => emit(state.copyWith(patchUserInfoStatus: Status.failure)),
          (_) => emit(state.copyWith(patchUserInfoStatus: Status.success)),
    );
  }

  /// 사용자 정보 조회 이벤트를 처리합니다.
  ///
  /// 서버로부터 사용자 정보를 요청하여 받아온 후,
  /// 성공 시 상태를 업데이트하고, 실패 시 실패 상태로 업데이트합니다.
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