part of '../../../framework/controller.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signInAnonymously;
  final SignOut signOutAnonymously;
  final SignIn signInWithGoogle;
  final SignOut signOutWithGoogle;

  AuthBloc({
    required this.signInAnonymously,
    required this.signOutAnonymously,
    required this.signInWithGoogle,
    required this.signOutWithGoogle,
  }) : super(AuthDone()) {
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
      emit(AuthLoading());

      final result = await signInAnonymously(null);
      result.fold(
        (failure) {
          if (failure is ServerFailure) {
            emit(AuthError(message: '인터넷 연결 안됨'));
          }
        },
        (success) {
          emit(AuthDone());
        },
      );
    } catch (e) {
      emit(AuthError(message: '로그인 실패, 다시 시도해주세요.'));
    }
  }

  Future _signOutAnonymouslyEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final result = await signOutAnonymously(NoParams());
      result.fold(
        (failure) {
          if (failure is ServerFailure) {
            emit(AuthError(message: '인터넷 연결 안됨'));
          }
        },
        (success) {
          emit(AuthDone());
        },
      );
    } catch (e) {
      emit(AuthError(message: '로그아웃 실패, 다시 시도해주세요.'));
    }
  }

  Future _signInWithGoogleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final result = await signInWithGoogle(null);
      result.fold(
        (failure) {
          if (failure is ServerFailure) {
            emit(AuthError(message: '인터넷 연결 안됨'));
          }
        },
        (success) {
          emit(AuthDone());
        },
      );
    } catch (e) {
      emit(AuthError(message: '로그인 실패, 다시 시도해주세요.'));
    }
  }

  Future _signOutWithGoogleEvent(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final result = await signOutWithGoogle(NoParams());
      result.fold(
        (failure) {
          if (failure is ServerFailure) {
            emit(AuthError(message: '인터넷 연결 안됨'));
          }
        },
        (success) {
          emit(AuthDone());
        },
      );
    } catch (e) {
      emit(AuthError(message: '로그아웃 실패, 다시 시도해주세요.'));
    }
  }
}
