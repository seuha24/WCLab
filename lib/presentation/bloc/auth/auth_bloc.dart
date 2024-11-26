part of '../../../framework/controller.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  AuthBloc()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(),
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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      emit(state.copyWith(googleSignInStatus: Status.success));
    } catch (e) {
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
}
