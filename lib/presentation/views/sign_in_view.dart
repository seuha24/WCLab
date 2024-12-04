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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        debugPrint('state ::::: $state');
        if (state.signInStatus == Status.success) {
          debugPrint('state.signInStatus : ${state.signInStatus}');
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SignupUserInput()));
          // Navigator.of(context).pushReplacement(
          //     MaterialPageRoute(builder: (context) => const MainView()));
        } else if (state.signInStatus == Status.failure) {
          showToast(
            message: "Login Failed",
            backgroundColor: Colors.red,
          );
        }
      },
      listenWhen: (previous, current) {
        debugPrint('state previous : $previous');
        debugPrint('state current : $current');
        debugPrint('previous.signInStatus : ${previous.signInStatus}');
        debugPrint('current.signInStatus : ${current.signInStatus}');

        return previous.signInStatus != current.signInStatus ||
            previous.signOutStatus != current.signInStatus;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            '로그인',
            style: TextStyle(fontSize: 20),
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
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .apply(color: Theme.of(context).colorScheme.primary),
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
                            width: 60.w,
                            height: 60.w,
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
                            width: 60.w,
                            height: 60.w,
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
                                  : const Text(
                                      '로그인 없이 이용하기',
                                      style: TextStyle(fontSize: 16),
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
