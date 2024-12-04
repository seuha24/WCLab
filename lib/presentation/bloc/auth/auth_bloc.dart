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
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final AuthRepository _repository;
  final AuthService _authService = DI<AuthService>();

  AuthBloc({required AuthRepository repository})
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(
          scopes: scopes,
          clientId: Platform.isIOS
              ? DefaultFirebaseOptions.currentPlatform.iosClientId
              : DefaultFirebaseOptions.currentPlatform.androidClientId,
        ),
        _repository = repository,
        super(AuthState()) {
    on<SignInAnonymouslyEvent>(_signInAnonymouslyEvent);
    on<SignOutAnonymouslyEvent>(_signOutAnonymouslyEvent);
    on<SignInWithGoogleEvent>(_signInWithGoogleEvent);
    on<SignOutWithGoogleEvent>(_signOutWithGoogleEvent);
    on<SignInWithAppleEvent>(_signInWithAppleEvent);
    on<SignOutWithAppleEvent>(_signOutWithAppleEvent);
    on<PatchUserInfoEvent>(_patchUserInfoEvent);
    on<GetUserInfoEvent>(_getUserInfoEvent);
  }

  /// 비회원 로그인
  Future<void> _signInAnonymouslyEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(signInStatus: Status.inProgress));
      await _auth.signInAnonymously();
      _authService.saveAuthType(authType: AuthType.anonymous);
      emit(state.copyWith(signInStatus: Status.success));
    } catch (e) {
      emit(state.copyWith(signInStatus: Status.failure));
    }
  }

  /// 비회원 로그아웃
  Future<void> _signOutAnonymouslyEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(signOutStatus: Status.inProgress));
      await _auth.signOut();
      emit(state.copyWith(signOutStatus: Status.success));
    } catch (e) {
      emit(state.copyWith(signOutStatus: Status.failure));
    }
  }

  /// 구글 로그인
  Future<void> _signInWithGoogleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('Call _signInWithGoogleEvent()');
    emit(state.copyWith(signInStatus: Status.initial));

    try {
      emit(state.copyWith(signInStatus: Status.inProgress));
      // final GoogleSignIn googleSignIn = GoogleSignIn(
      //   clientId: Platform.isIOS
      //       ? firebaseOptions.iosClientId
      //       : firebaseOptions.androidClientId,
      // );

      GoogleSignInAccount? googleUser;
      googleUser = await _googleSignIn.signIn();

      debugPrint('googleUser : $googleUser');

      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      final googleToken = googleAuth.accessToken;

      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // debugPrint('googleUser : $googleUser');
      // if (googleUser == null) {
      //   emit(state.copyWith(googleSignInStatus: Status.failure));
      //   return;
      // }
      //
      // final GoogleSignInAuthentication googleAuth =
      // await googleUser.authentication;
      //
      // final String? googleToken = googleAuth.accessToken;

      debugPrint('googleToken :::::: $googleToken');
      if (googleToken != null) {
        final getAccessToken =
            await _sendOAuthTokenToServer(googleToken, AuthType.google);

        if (getAccessToken) {
          await _authService.saveAuthType(authType: AuthType.google);

          emit(state.copyWith(signInStatus: Status.success));
        } else {
          emit(state.copyWith(signInStatus: Status.failure));
        }
      } else {
        emit(state.copyWith(signInStatus: Status.failure));
      }
    } catch (e) {
      log('Google Sign-In Error: $e');
      emit(state.copyWith(signInStatus: Status.failure));
    }
  }

  /// 구글 로그아웃
  Future<void> _signOutWithGoogleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(signOutStatus: Status.inProgress));
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _authService.clearAuthData();
      emit(state.copyWith(signOutStatus: Status.success));
    } catch (e) {
      emit(state.copyWith(signOutStatus: Status.failure));
    }
  }

  /// 애플 로그인
  Future<void> _signInWithAppleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(signInStatus: Status.initial));

    try {
      emit(state.copyWith(signInStatus: Status.inProgress));

      final appleProvider = AppleAuthProvider();
      final UserCredential userCredential;
      // Firebase Sign-In
      await FirebaseAuth.instance.signOut();
      userCredential = await _auth.signInWithProvider(appleProvider);

      // final appleToken = userCredential.credential.providerId;
      // debugPrint('ID Token: $appleToken');

      // debugPrint('userCredential : $userCredential');

      // debugPrint('userCredential.credential : ${userCredential.credential}');

      final user = userCredential.user;
      debugPrint('user: $user');
      final idToken = await user?.getIdToken();
      debugPrint('idToken: $idToken');
      final appleAccessToken = Platform.isIOS
          ? userCredential.credential?.accessToken
          : await user?.getIdToken();

      debugPrint('userCredential.credential : ${userCredential.credential}');

      // Apple accessToken 가져오기
      // final appleAccessToken = userCredential.credential?.accessToken;

      debugPrint('idToken : $idToken');
      debugPrint('appleAccessToken : $appleAccessToken');

      if (appleAccessToken != null) {
        // 서버로 OAuth 토큰 전송
        final getAccessToken =
            await _sendOAuthTokenToServer(appleAccessToken!, AuthType.apple);

        debugPrint('getAccessToken : $getAccessToken');

        if (getAccessToken) {
          await _authService.saveAuthType(authType: AuthType.apple);
          // debugPrint('authType : ${await _authService.loadAuthType()}');

          emit(state.copyWith(signInStatus: Status.success));
          debugPrint('state::::::${state.signInStatus}');
        } else {
          emit(state.copyWith(signInStatus: Status.failure));
        }
      } else {
        log('Apple Sign-In failed: Missing accessToken');
        emit(state.copyWith(signInStatus: Status.failure));
      }
    } catch (e) {
      log('Unhandled error during Apple Sign-In: $e');
      emit(state.copyWith(signInStatus: Status.failure));
    }
  }

  /// 애플 로그아웃
  Future<void> _signOutWithAppleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(signOutStatus: Status.inProgress));
      await _auth.signOut();
      await _authService.clearAuthData();
      emit(state.copyWith(signOutStatus: Status.success));
    } catch (e) {
      emit(state.copyWith(signOutStatus: Status.failure));
    }
  }

  Future<bool> _sendOAuthTokenToServer(
      String accessToken, AuthType oauthType) async {
    debugPrint('Call _sendOAuthTokenToServer()');
    try {
      final response = oauthType == AuthType.google
          ? await _repository.sendGoogleOAuthTokenToServer(accessToken)
          : await _repository.sendAppleOAuthTokenToServer(accessToken);

      return response.fold(
        (failure) {
          // 실패 처리
          log('Failed to send token to server: $failure');
          return false;
        },
        (authData) async {
          // 성공 처리
          // AccessToken, RefreshToken, userName 저장
          await _authService.saveAuthData(
            accessToken: authData.accessToken,
            refreshToken: authData.refreshToken,
            userName: authData.userName ?? '',
          );

          // log('::::저장된 토큰::::');
          final loadedAuthData = await _authService.loadAuthData();
          debugPrint('accessToken : ${loadedAuthData['accessToken']}');
          debugPrint('refreshToken : ${loadedAuthData['refreshToken']}');
          debugPrint('userName : ${loadedAuthData['userName']}');

          return true;
        },
      );
    } catch (e) {
      log('Error sending OAuth Token to Server: $e');
      return false;
    }
  }

  /// 유저 닉네임 변경
  Future<void> _patchUserInfoEvent(
    PatchUserInfoEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(patchUserInfoStatus: Status.inProgress));
      final response = await _repository.patchUserInfo(event.userName);

      debugPrint('response : $response');

      response.fold(
        (failure) {
          // 실패 처리
          log('Failed to patch user info: $failure');
          emit(state.copyWith(patchUserInfoStatus: Status.failure));
        },
        (result) {
          // 성공 처리
          emit(state.copyWith(patchUserInfoStatus: Status.success));
        },
      );
    } catch (e) {
      emit(state.copyWith(patchUserInfoStatus: Status.failure));
    }
  }

  /// 유저 정보 가져오기
  Future<void> _getUserInfoEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(getUserInfoStatus: Status.inProgress));
      final response = await _repository.getUserInfo();
      response.fold(
        (failure) {
          // 실패 처리
          log('Failed to get user info: $failure');
          emit(state.copyWith(patchUserInfoStatus: Status.failure));
        },
        (result) {
          // 성공 처리
          emit(state.copyWith(patchUserInfoStatus: Status.success));
        },
      );
      emit(state.copyWith(getUserInfoStatus: Status.success));
    } catch (e) {
      emit(state.copyWith(getUserInfoStatus: Status.failure));
    }
  }
}
