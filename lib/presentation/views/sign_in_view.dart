// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

part of '../../framework/ui.dart';

/// 로그인 화면을 위한 StatefulWidget입니다.
/// 이 위젯은 사용자가 다양한 로그인 방식을 선택할 수 있도록 UI를 제공합니다.
class SignInView extends StatefulWidget {
  /// 생성자
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

/// [SignInView]의 상태를 관리하는 클래스입니다.
class _SignInViewState extends State<SignInView> {
  /// 의존성 주입을 통해 메시지 관련 인스턴스를 가져옵니다.
  final message = DI.get<Message>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // AuthBloc의 상태 변화에 따라 화면 전환 또는 오류 메시지 표시를 처리합니다.
      listener: (context, state) {
        if (state.signInStatus == Status.success) {
          if (state.userName == null) {
            // 로그인은 성공했으나, 사용자 닉네임이 등록되지 않은 경우 닉네임 설정 화면으로 이동합니다.
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SignupUserInput()),
            );
          } else {
            // 로그인 성공 및 닉네임 등록이 완료된 경우 메인 화면으로 이동합니다.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainView()),
            );
          }
        } else if (state.signInStatus == Status.failure) {
          // 로그인 실패 시, 토스트 메시지로 실패 알림을 표시합니다.
          showToast(
            message: "Login Failed",
            backgroundColor: Colors.red,
          );
        }
      },
      // 이전과 현재 상태의 로그인 상태가 달라진 경우에만 리스너를 호출합니다.
      listenWhen: (previous, current) {
        return previous.signInStatus != current.signInStatus;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            '로그인',
            style: TextStyle(fontSize: AppSizes.scaledFont(24)),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 현재 기기의 밝기 설정에 따라 다른 배경 애니메이션을 표시합니다.
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? Semantics(
                label: '로그인 화면 배경',
                child: Lottie.asset(
                  Gif.LOTTIE_ENTER_BACKGROUND_LIGHT,
                  fit: BoxFit.fill,
                  repeat: false,
                ),
              )
                  : Semantics(
                label: '로그인 화면 배경',
                child: Lottie.asset(
                  Gif.LOTTIE_ENTER_BACKGROUND_DARK,
                  fit: BoxFit.fill,
                  repeat: false,
                ),
              ),
              Column(
                children: [
                  // '처음 사용하시나요?' 버튼을 눌러 튜토리얼 화면으로 이동합니다.
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TutorialView(),
                      ),
                    ),
                    child: Text(
                      '처음 사용하시나요?',
                      style: TextStyle(
                        fontSize: AppSizes.scaledFont(18),
                        fontWeight: FontWeight.bold,
                      ).apply(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 애플 및 구글 로그인 버튼을 포함하는 Row 위젯입니다.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 애플 로그인 버튼
                      GestureDetector(
                        onTap: () {
                          context
                              .read<AuthBloc>()
                              .add(SignInWithAppleEvent());
                          debugPrint("애플로그인하기");
                        },
                        child: Container(
                          padding: EdgeInsets.all(2.sp),
                          child: Image(
                            width: AppSizes.scaledWidth(60),
                            height: AppSizes.scaledWidth(60),
                            image: AssetImage(
                              Images.AppleLogo,
                            ),
                          ),
                        ),
                      ),
                      Gap(),
                      // 구글 로그인 버튼
                      GestureDetector(
                        onTap: () {
                          context
                              .read<AuthBloc>()
                              .add(SignInWithGoogleEvent());
                        },
                        child: Container(
                          padding: EdgeInsets.all(2.sp),
                          child: Image(
                            width: AppSizes.scaledWidth(60),
                            height: AppSizes.scaledWidth(60),
                            image: AssetImage(
                              Images.GoogleLogo,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(),
                  // 익명 로그인 버튼과 진행 상태 표시를 포함하는 BlocBuilder입니다.
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          const SizedBox(height: 14),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeTheme.h_lg),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 60.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(6.r),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                context
                                    .read<AuthBloc>()
                                    .add(SignInAnonymouslyEvent());
                              },
                              // 로그인 진행 중에는 로딩 인디케이터를 표시합니다.
                              child: (state.signInStatus == Status.inProgress)
                                  ? CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary,
                              )
                                  : Text(
                                '로그인 없이 이용하기',
                                style: TextStyle(
                                  fontSize: AppSizes.scaledFont(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}