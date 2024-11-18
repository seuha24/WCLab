// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

part of '../../framework/ui.dart';

/// 로그인 화면
class SignInView extends StatefulWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final message = DI.get<Message>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('로그인 화면'),
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
                Divider(),
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
                        .labelLarge!
                        .apply(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: (){
                        // context.read<AuthBloc>().add(SignInWithAppleEvent());
                        print("애플로그인하기");                      },
                      child: Container(
                        padding: EdgeInsets.all(10.sp),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(width: 1),
                          color: Colors.black,
                        ),
                        child: Image(
                          width: 22.w,
                          height: 22.w,
                          image: AssetImage(
                            Images.AppleLogo,
                          ),
                        ),
                      ),
                    ),
                    Gap(),
                    InkWell(
                      onTap: (){
                        context.read<AuthBloc>().add(SignInWithGoogleEvent());
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.sp),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(width: 1)
                        ),
                        child: Image(
                          width: 22.w,
                          height: 22.w,
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
                    if (state is AuthError) {
                      Future.delayed(Duration.zero, () {
                        message.snackbar(context, text: state.message);
                      });
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding:
                          EdgeInsets.symmetric(horizontal: SizeTheme.h_lg),
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
                            child: (state is AuthLoading)
                                ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                              Theme.of(context).colorScheme.onPrimary,
                            )
                                : const Text('로그인 없이 이용하기'),
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
    );
  }
}
