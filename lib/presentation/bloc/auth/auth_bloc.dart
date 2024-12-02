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

  AuthBloc({required AuthRepository repository})
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(scopes: scopes),
        _repository = repository,
        super(AuthState()) {
    on<SignInAnonymouslyEvent>(_signInAnonymouslyEvent);
    on<SignOutAnonymouslyEvent>(_signOutAnonymouslyEvent);
    on<SignInWithGoogleEvent>(_signInWithGoogleEvent);
    on<SignOutWithGoogleEvent>(_signOutWithGoogleEvent);
  }

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

  Future _signInWithGoogleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
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

  Future<void> _sendOAuthTokenToServer(
      String accessToken, OAuthType oauthType) async {
    try {
      final response = oauthType == OAuthType.google
          ? await _repository.sendGoogleOAuthTokenToServer(accessToken)
          : await _repository.sendAppleOAuthTokenToServer(accessToken);

      debugPrint('response :::: $response');

      // if (response.response.statusCode == 201) {
      //   final AuthDataModel authData = response.data.data;
      //
      //   // AccessToken 및 RefreshToken 저장
      //   await _service.saveTokens(authData.accessToken, authData.refreshToken);
      //
      //   log('Token 저장 완료');
      // } else {
      //   log('Server Error: ${response.response.statusCode}');
      // }
    } catch (e) {
      log('Error sending OAuth Token to Server: $e');
    }
  }
}
