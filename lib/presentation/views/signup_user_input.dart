// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:safelight/core/utils/app_sizes.dart';
import 'package:safelight/core/utils/status_enum.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/ui.dart';
import 'package:safelight/infrastructure/services/auth_service.dart';
import 'package:safelight/main.dart';

import '../../framework/controller.dart';
import '../../injection.dart';
import '../widgets/custom_toast.dart';
import '../widgets/gap.dart';

/// 로그인 화면
class SignupUserInput extends StatefulWidget {
  const SignupUserInput({super.key});

  @override
  State<SignupUserInput> createState() => _SignupUserInputState();
}

class _SignupUserInputState extends State<SignupUserInput> {
  final message = DI.get<Message>();
  final TextEditingController _userNameTextController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = DI<AuthService>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.patchUserInfoStatus == Status.success ||
            state.patchUserInfoStatus == Status.success) {

          final loadedAuthData = await _authService.loadAuthData();

          await _authService.saveAuthData(
            accessToken: loadedAuthData['accessToken']!,
            refreshToken: loadedAuthData['refreshToken']!,
            userName: _userNameTextController.text,
          );

          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainView()));
        } else if (state.patchUserInfoStatus == Status.failure) {
          showToast(
            message: "User Name Set Failed",
            backgroundColor: Colors.red,
          );
        }
      },
      listenWhen: (previous, current) =>
      previous.patchUserInfoStatus != current.patchUserInfoStatus,
      child: PopScope(
        canPop: true,
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            debugPrint('didPop : $didPop');
            context.read<AuthBloc>().add(SignOutAllEvent());
            await _authService.clearAuthData();

            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const SignInView(),
            ));
          }
        },
        child: Scaffold(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .secondary,
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              '회원가입',
              style: TextStyle(fontSize: AppSizes.scaledFont(24)),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                context.read<AuthBloc>().add(SignOutAllEvent());
                await _authService.clearAuthData();

                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const SignInView(),
                ));
              },
            ),
          ),
          bottomNavigationBar: SizedBox(
            height: 100,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.sp),
              child: Column(
                children: [
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return Column(
                        children: [
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
                                final userName = _userNameTextController.text;
                                context
                                    .read<AuthBloc>()
                                    .add(PatchUserInfoEvent(userName));
                              },
                              child: (state.patchUserInfoStatus ==
                                  Status.inProgress)
                                  ? CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .onPrimary,
                              )
                                  : Text(
                                '닉네임 변경하기',
                                style: TextStyle(
                                    fontSize: AppSizes.scaledFont(18)),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.scaledWidth(40)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSizes.scaledWidth(8),
                      // top: AppSizes.scaledHeight(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSizes.scaledWidth(6)),
                          decoration: BoxDecoration(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .surface,
                            borderRadius: BorderRadius.circular(
                                AppSizes.scaledRadius(8)),
                          ),
                          child: Icon(
                            Icons.person,
                            size: AppSizes.scaledWidth(30),
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary,
                          ),
                        ),
                        Gap(),
                        Text(
                          '이름 입력',
                          style: TextStyle(
                            fontSize: AppSizes.scaledFont(18),
                            color: Theme
                                .of(context)
                                .colorScheme
                                .onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap(height: 10,),
                  TextField(
                    controller: _userNameTextController,
                    focusNode: _focusNode,
                    style: TextStyle(color: Colors.black, height: 1),
                    onChanged: (query) {},
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: AppSizes.scaledWidth(11.5),
                          horizontal: AppSizes.scaledWidth(13)),
                      hintText: '이름 입력',
                      hintStyle: TextStyle(
                          fontSize: AppSizes.scaledFont(18),
                          height: 20 / 16,
                          color: Colors.grey),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.0),
                        borderSide: BorderSide(
                          color: Color(0xffE4E4E7),
                          width: 1.0, // Border width when focused
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.0),
                        borderSide: BorderSide(
                          color: Color(0xffE4E4E7),
                          width: 1.0, // Border width when focused
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.0),
                        borderSide: BorderSide(
                          color: Color(0xffE4E4E7),
                          width: 1.0, // Border width when focused
                        ),
                      ),
                    ),
                  ),
                  Gap(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
