part of '../../../framework/controller.dart';

enum OAuthType {
  google,
  apple,
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
        _googleSignIn = GoogleSignIn(scopes: scopes),
        _repository = repository,
        super(AuthState()) {
    on<SignInAnonymouslyEvent>(_signInAnonymouslyEvent);
    on<SignOutAnonymouslyEvent>(_signOutAnonymouslyEvent);
    on<SignInWithGoogleEvent>(_signInWithGoogleEvent);
    on<SignOutWithGoogleEvent>(_signOutWithGoogleEvent);
    on<SignInWithAppleEvent>(_signInWithAppleEvent);
    // on<SignOutWithAppleEvent>(_signOutWithAppleEvent);
  }

  /// 비회원 로그인
  Future _signInAnonymouslyEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(guestSignInStatus: Status.inProgress));
      UserCredential userCredential = await _auth.signInAnonymously();
      emit(state.copyWith(guestSignInStatus: Status.success));
    } catch (e) {
      emit(state.copyWith(guestSignInStatus: Status.failure));
    }
  }

  /// 비회원 로그아웃
  Future _signOutAnonymouslyEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(guestSignOutStatus: Status.inProgress));
      await _auth.signOut();
      emit(state.copyWith(guestSignOutStatus: Status.success));
    } catch (e) {
      emit(state.copyWith(guestSignOutStatus: Status.failure));
    }
  }

  /// 구글 로그인
  Future _signInWithGoogleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('Call _signInWithGoogleEvent()');
    try {
      emit(state.copyWith(googleSignInStatus: Status.inProgress));
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(state.copyWith(googleSignInStatus: Status.failure));
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;

      if (accessToken != null) {
        await _sendOAuthTokenToServer(accessToken, OAuthType.google);
        emit(state.copyWith(googleSignInStatus: Status.success));
      } else {
        emit(state.copyWith(googleSignInStatus: Status.failure));
      }
    } catch (e) {
      log('Google Sign-In Error: $e');
      emit(state.copyWith(googleSignInStatus: Status.failure));
    }
  }

  /// 구글 로그아웃
  Future _signOutWithGoogleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(googleSignOutStatus: Status.inProgress));
      await _googleSignIn.signOut();
      await _auth.signOut();
      emit(state.copyWith(googleSignOutStatus: Status.success));
    } catch (e) {
      emit(state.copyWith(googleSignOutStatus: Status.failure));
    }
  }

  /// 애플 로그인
  Future _signInWithAppleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(appleSignInStatus: Status.inProgress));

      final appleProvider = AppleAuthProvider();
      final UserCredential userCredential;
      // Firebase Sign-In
      userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);

      // Apple accessToken 가져오기
      final accessToken = userCredential.credential?.accessToken;

      debugPrint('accessToken : $accessToken');

      if (accessToken != null) {
        // 서버로 OAuth 토큰 전송
        await _sendOAuthTokenToServer(accessToken, OAuthType.apple);

        emit(state.copyWith(appleSignInStatus: Status.success));
      } else {
        log('Apple Sign-In failed: Missing accessToken');
        emit(state.copyWith(appleSignInStatus: Status.failure));
      }
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuthException: ${e.message}');
      if (e.code == 'canceled') {
        log('User canceled the sign-in process.');
      } else {
        log('Authentication error: ${e.code}');
      }
      emit(state.copyWith(appleSignInStatus: Status.failure));
    } catch (e) {
      log('Unhandled error during Apple Sign-In: $e');
      // emit(state.copyWith(appleSignInStatus: Status.failure));
    }
  }

  Future<void> _sendOAuthTokenToServer(
      String accessToken, OAuthType oauthType) async {

    debugPrint('Call _sendOAuthTokenToServer()');
    try {
      final response = oauthType == OAuthType.google
          ? await _repository.sendGoogleOAuthTokenToServer(accessToken)
          : await _repository.sendAppleOAuthTokenToServer(accessToken);

      response.fold(
        (failure) {
          // 실패 처리
          log('Failed to send token to server: $failure');
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
          log('accessToken : ${loadedAuthData['accessToken']}');
          log('refreshToken : ${loadedAuthData['refreshToken']}');
          // log('userName : ${loadedAuthData['userName']}');
        },
      );
    } catch (e) {
      log('Error sending OAuth Token to Server: $e');
    }
  }
}
