part of object;

/// [User]는 사용자 객체이다.
///
/// *현재로서는 사용하지 않는 값이다.*
/// *[User]는 익명 로그인 외에 추가적인 로그인 로직을 구현할 때 사용을 권장한다.*
/// *이에 대한 설명은 `lib/domain/usecases/auth_usecase.dart`에 기재되어 있다.
///
/// [User] 객체가 포함하는 정보는 아래와 같다.
///
/// |field||설명|
/// |:-------|-|:--------|
/// |[id]||사용자 아이디|
/// |[pw]||사용자 비밀번호|
class User extends Equatable {
  // final String? id;
  // final String? pw;
  final UserCredential? credential;

  const User({
    // this.id,
    // this.pw,
    this.credential,
  });

  @override
  List<Object?> get props => [credential];
}
