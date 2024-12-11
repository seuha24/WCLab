// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

part of '../../framework/ui.dart';

/// 로그인 화면
class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final message = DI.get<Message>();

  @override
  Widget build(BuildContext context) {
    debugPrint('width : ${ScreenUtil().screenWidth}');

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.signInStatus == Status.success) {
          if (state.userName == null) {
            // 유저 닉네임이 미등록된 상태일 때
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SignupUserInput()));
          } else {
            // 유저 닉네임이 등록된 상태일 때
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainView()));
          }
        } else if (state.signInStatus == Status.failure) {
          showToast(
            message: "Login Failed",
            backgroundColor: Colors.red,
          );
        }
      },
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
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DutorialView(),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.read<AuthBloc>().add(SignInWithAppleEvent());
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
                      GestureDetector(
                        onTap: () {
                          context.read<AuthBloc>().add(SignInWithGoogleEvent());
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
                              child: (state.signInStatus == Status.inProgress)
                                  ? CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    )
                                  : Text(
                                      '로그인 없이 이용하기',
                                      style: TextStyle(fontSize: AppSizes.scaledFont(18)),
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
