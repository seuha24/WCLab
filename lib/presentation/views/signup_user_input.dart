// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:safelight/core/utils/status_enum.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/ui.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.patchUserInfoStatus == Status.success ||
            state.patchUserInfoStatus == Status.success) {
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
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            '회원가입',
            style: TextStyle(fontSize: 20),
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
                              final userName = _userNameTextController.text;
                              context
                                  .read<AuthBloc>()
                                  .add(PatchUserInfoEvent(userName));
                            },
                            child: (state.patchUserInfoStatus ==
                                    Status.inProgress)
                                ? CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  )
                                : const Text(
                                    '닉네임 변경하기',
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
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 8.sp, top: 20.sp),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.sp),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Gap(),
                      Text(
                        '이름 입력',
                        style: Theme.of(context).textTheme.labelLarge!.apply(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSizeDelta: 2),
                      ),
                    ],
                  ),
                ),
                Gap(),
                TextField(
                  controller: _userNameTextController,
                  focusNode: _focusNode,
                  style: TextStyle(color: Colors.black),
                  onChanged: (query) {},
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '이름 입력',
                    hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide(
                        color: Colors.grey, // Border color when focused
                        width: 1.0, // Border width when focused
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide(
                        color: Colors.grey, // Border color when focused
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
    );
  }
}
