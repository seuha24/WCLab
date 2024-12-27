// ignore_for_file: use_build_context_synchronously

part of '../../framework/ui.dart';

/// 설정화면
class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  late String? mode;
  late String? lightmode;
  late Box box;
  late Box flashbox;
  final AuthService _authService = DI<AuthService>();

  final List<Map<String, dynamic>> modes = [
    {
      'title': '항상 켜기 모드',
      'flashMode': FlashMode.ALWAYS,
      'lightModeValue': 'alwayson',
    },
    {
      'title': '주변 환경에 따라 켜기 모드',
      'flashMode': FlashMode.WITH_WEATHER,
      'lightModeValue': 'weathers',
    },
    {
      'title': '항상 끄기 모드',
      'flashMode': FlashMode.NEVER_IN_USE,
      'lightModeValue': 'alwaysoff',
    },
  ];

  @override
  void initState() {
    super.initState();
    context.read<BluetoothPermissionCubit>().getPermissionStatus();
    context.read<LocationPermissionCubit>().getPermissionStatus();
    box = Hive.box(SystemTheme.themeBox);
    mode = box.get(SystemTheme.mode) ?? ThemeMode.system.name;
    flashbox = Hive.box<FlashMode>('flashmode');

    // 사용자가 여러명이어도 각자 설정에 맞게 저장되는지 확인 필요!
    if (flashbox.values.toList().isEmpty) {
      lightmode = 'alwayson';
    } else if (flashbox.values.toList()[0] == FlashMode.ALWAYS) {
      lightmode = 'alwayson';
    } else if (flashbox.values.toList()[0] == FlashMode.NEVER_IN_USE) {
      lightmode = 'alwaysoff';
    } else if (flashbox.values.toList()[0] == FlashMode.WITH_WEATHER) {
      lightmode = 'weathers';
    }

    context.read<AuthBloc>().add(GetUserInfoEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox.shrink(),
        flexibleSpace: Container(
          color: Theme.of(context).colorScheme.secondary,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + SizeTheme.h_lg,
          ),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final username = state.userName ?? '익명 사용자';
              return Semantics.fromProperties(
                properties: const SemanticsProperties(
                  button: true,
                  value: '사용자 정보',
                  hint:
                      '현재 익명 사용자 계정으로 로그인되어 있습니다. 로그아웃 후 로그인 페이지로 이동하려면 이중 탭 하십시오.',
                ),
                //  '로그인 화면 이동 버튼, 현재 로그인 상태',
                child: ListTile(
                  leading: SingleChildRoundedCard(
                    child: Container(
                      padding: EdgeInsets.all(AppSizes.scaledWidth(2)),
                      child: Icon(
                        Icons.person,
                        size: AppSizes.scaledWidth(30),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      username,
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                            fontSize: AppSizes.scaledFont(18),
                            fontWeight: FontWeight.bold,
                          ),
                      semanticsLabel: '',
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: () async {
                      debugPrint('onTap Logout');

                      context.read<AuthBloc>().add(SignOutAllEvent());
                      await _authService.clearAuthData();

                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const SignInView(),
                      ));
                    },
                    child: Icon(
                      Icons.logout,
                      size: AppSizes.scaledWidth(25),
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        toolbarHeight: AppSizes.scaledWidth(100),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Board(
              title: '앱 내 권한',
              titleStyle: TextStyle(
                  fontSize: AppSizes.scaledFont(16),
                  color: Theme.of(context).colorScheme.onBackground),
              body: Column(
                children: [
                  BlocBuilder<BluetoothPermissionCubit, bool>(
                    builder: (_, state) {
                      return Semantics.fromProperties(
                        properties: SemanticsProperties(
                          hint: '앱의 블루투스 사용 허가를 위해 설정이 필요합니다.',
                          checked: state,
                        ),
                        child: ListTile(
                          onTap: () async {
                            await context
                                .read<BluetoothPermissionCubit>()
                                .setPermissionStatus();
                            await context
                                .read<BluetoothPermissionCubit>()
                                .getPermissionStatus();
                          },
                          leading: const Icon(
                            Icons.bluetooth,
                            color: ColorTheme.highlight3,
                          ),
                          title: Text(
                            '블루투스 권한',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge!
                                .copyWith(
                                  fontSize: AppSizes.scaledFont(18),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          trailing: CupertinoSwitch(
                            value: state,
                            thumbColor: Theme.of(context).colorScheme.secondary,
                            trackColor: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.28),
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (bool? value) async {
                              await context
                                  .read<BluetoothPermissionCubit>()
                                  .setPermissionStatus();
                              await context
                                  .read<BluetoothPermissionCubit>()
                                  .getPermissionStatus();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  BlocBuilder<LocationPermissionCubit, bool>(
                    builder: (_, state) {
                      return Semantics.fromProperties(
                        properties: SemanticsProperties(
                          hint: '앱의 사용자 위치 정보 사용 허가를 위해 설정이 필요합니다.',
                          checked: state,
                        ),
                        child: ListTile(
                          onTap: () async {
                            await context
                                .read<LocationPermissionCubit>()
                                .setPermissionStatus();
                            await context
                                .read<LocationPermissionCubit>()
                                .getPermissionStatus();
                          },
                          leading: const Icon(
                            Icons.gps_fixed_rounded,
                            color: ColorTheme.highlight4,
                          ),
                          title: Text(
                            '사용자 위치 정보 권한',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge!
                                .copyWith(
                                  fontSize: AppSizes.scaledFont(18),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          trailing: CupertinoSwitch(
                            value: state,
                            thumbColor: Theme.of(context).colorScheme.secondary,
                            trackColor: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.28),
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (bool? value) async {
                              await context
                                  .read<LocationPermissionCubit>()
                                  .setPermissionStatus();
                              await context
                                  .read<LocationPermissionCubit>()
                                  .getPermissionStatus();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Board(
              title: '기타',
              titleStyle: TextStyle(
                  fontSize: AppSizes.scaledFont(18),
                  color: Theme.of(context).colorScheme.onBackground),
              body: Column(
                children: [
                  Semantics.fromProperties(
                    properties: SemanticsProperties(
                      button: true,
                      hint:
                          '현재 적용된 설정은 ${mode == 'system' ? '시스템 모드' : mode == 'light' ? '라이트모드' : '다크모드'}입니다. 시스템 모드 설정을 변경하려면 이중 탭 하십시오.',
                    ),
                    child: ListTile(
                      title: Text(
                        '시스템 모드 설정',
                        style:
                            Theme.of(context).textTheme.displayLarge!.copyWith(
                                  fontSize: AppSizes.scaledFont(18),
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      subtitle: Text(
                        mode == 'system'
                            ? '시스템설정 적용중'
                            : mode == 'light'
                                ? '라이트모드 적용중'
                                : '다크모드 적용중',
                        style: TextStyle(
                          fontSize: AppSizes.scaledFont(16),
                          fontWeight: FontWeight.bold,
                        ).apply(color: ColorTheme.highlight2),
                        semanticsLabel: '',
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      onTap: () => showModalBottomSheet(
                        barrierColor: Theme.of(context)
                            .colorScheme
                            .onSecondary
                            .withAlpha(100),
                        isScrollControlled: true,
                        context: context,
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        builder: (BuildContext context) {
                          return SizedBox(
                            height: 800.h,
                            child: Board(
                              title: '시스템 모드 설정',
                              headerPadding: EdgeInsets.only(
                                  bottom: SizeTheme.h_sm, left: 2),
                              padding: EdgeInsets.all(SizeTheme.h_sm),
                              titleStyle: TextStyle(
                                fontSize: AppSizes.scaledFont(18),
                                fontWeight: FontWeight.bold,
                              ),
                              trailing: TextButton(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 50.w),
                                  child: FittedBox(
                                    child: Text(
                                      '닫기',
                                      style: TextStyle(
                                        fontSize: AppSizes.scaledFont(16),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              body: Column(
                                children: List<Widget>.generate(3, (index) {
                                  final modes = ['system', 'dark', 'light'];
                                  final titles = ['시스템모드', '다크모드', '라이트모드'];
                                  final selectedMode = modes[index];

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: SizeTheme.h_md,
                                    ),
                                    child: FlatCard(
                                      title: titles[index],
                                      titleOnly: true,
                                      bottomTitle: false,
                                      isSelected: mode == selectedMode,
                                      backgroundColor: mode == selectedMode
                                          ? Colors.indigoAccent
                                          : null,
                                      shapeBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          4.sp,
                                        ),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);

                                        await box.put(
                                            SystemTheme.mode,
                                            selectedMode == 'system'
                                                ? ThemeMode.system.name
                                                : selectedMode == 'dark'
                                                    ? ThemeMode.dark.name
                                                    : ThemeMode.light.name);
                                        setState(() {
                                          mode = box.get(SystemTheme.mode);
                                        });
                                      },
                                      trailing: mode == selectedMode
                                          ? Text(
                                              '적용중',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge!
                                                  .apply(
                                                    color: ColorTheme
                                                        .light.onPrimary,
                                                  ),
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 경광등
                  Semantics.fromProperties(
                    properties: SemanticsProperties(
                      button: true,
                      hint:
                          // alwayson / weathers / alwaysoff
                          '현재 적용된 설정은 ${lightmode == 'alwayson' ? '항상 켜기 모드' : lightmode == 'weathers' ? '주변 환경에 따라 켜기 모드' : '항상 끄기 모드'}입니다. 경광등 설정을 변경하려면 이중 탭 하십시오.',
                    ),
                    child: ListTile(
                      title: Text(
                        '경광등 설정',
                        style:
                            Theme.of(context).textTheme.displayLarge!.copyWith(
                                  fontSize: AppSizes.scaledFont(18),
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      subtitle: Text(
                        lightmode == 'alwayson'
                            ? '항상 켜기 모드 적용중'
                            : lightmode == 'weathers'
                                ? '주변 환경에 따라 켜기 모드 적용중'
                                : '항상 끄기 모드 적용중',
                        style: TextStyle(
                          fontSize: AppSizes.scaledFont(16),
                          fontWeight: FontWeight.bold,
                        ).apply(color: ColorTheme.highlight2),
                        semanticsLabel: '',
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      onTap: () => showModalBottomSheet(
                        barrierColor: Theme.of(context)
                            .colorScheme
                            .onSecondary
                            .withAlpha(100),
                        isScrollControlled: true,
                        context: context,
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        builder: (BuildContext context) {
                          return SizedBox(
                            height: 800.h,
                            child: Board(
                              title: '경광등 설정',
                              headerPadding: EdgeInsets.only(
                                bottom: SizeTheme.h_sm,
                              ),
                              padding: EdgeInsets.all(SizeTheme.w_md),
                              titleStyle: TextStyle(
                                fontSize: AppSizes.scaledFont(18),
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              trailing: TextButton(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 50.w),
                                  child: FittedBox(
                                    child: Text(
                                      '닫기',
                                      style: TextStyle(
                                        fontSize: AppSizes.scaledFont(16),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              body: Column(
                                children: modes.map((mode) {
                                  final bool isSelected =
                                      lightmode == mode['lightModeValue'];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: SizeTheme.h_md,
                                    ),
                                    child: FlatCard(
                                      title: mode['title'],
                                      titleOnly: true,
                                      bottomTitle: false,
                                      isSelected: isSelected,
                                      shapeBorder: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4.sp),
                                      ),
                                      backgroundColor: isSelected
                                          ? Colors.indigoAccent
                                          : null,
                                      onTap: () async {
                                        Navigator.pop(context);

                                        await flashbox.clear();
                                        setState(() {
                                          flashbox.add(mode['flashMode']);
                                          if (flashbox.values.toList().first ==
                                              mode['flashMode']) {
                                            lightmode = mode['lightModeValue'];
                                          }
                                        });
                                      },
                                      trailing: isSelected
                                          ? Text(
                                              '적용중',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .apply(
                                                    color: ColorTheme
                                                        .light.onPrimary,
                                                  ),
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  ValueListenableBuilder(
                    valueListenable:
                        Hive.box(SystemTheme.themeBox).listenable(),
                    builder: (context, Box box, widget) {
                      TTS.enable = box.get('tts', defaultValue: false);
                      return Semantics.fromProperties(
                        properties: SemanticsProperties(
                          hint: '설정을 킬 경우 횡단보도 검색 및 연결에서 보조 음성이 들리게 됩니다.',
                          checked: TTS.enable,
                        ),
                        child: ListTile(
                          onTap: () async {
                            await box.put('tts', !TTS.enable);
                            setState(() {
                              TTS.enable = box.get('tts');
                            });
                          },
                          title: Text(
                            '음성 보조 설정',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge!
                                .copyWith(
                                  fontSize: AppSizes.scaledFont(18),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          trailing: CupertinoSwitch(
                            value: TTS.enable,
                            thumbColor: Theme.of(context).colorScheme.secondary,
                            trackColor: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.28),
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (bool? value) async {
                              await box.put('tts', !TTS.enable);
                              setState(() {
                                TTS.enable = box.get('tts');
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  Semantics.fromProperties(
                    properties: const SemanticsProperties(
                      button: true,
                      hint: '외부 라이센스를 확인하려면 이중 탭 하십시오.',
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LicensePage(
                              applicationName: 'SafeLight',
                            ),
                          ),
                        );
                      },
                      title: Text(
                        '외부 라이센스',
                        style:
                            Theme.of(context).textTheme.displayLarge!.copyWith(
                                  fontSize: AppSizes.scaledFont(18),
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ),
                  Semantics.fromProperties(
                    properties: const SemanticsProperties(
                      button: true,
                      hint: '도움말 페이지로 이동하려면 이중 탭 하십시오.',
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TutorialView(),
                          ),
                        );
                      },
                      title: Text(
                        '도움말',
                        style:
                            Theme.of(context).textTheme.displayLarge!.copyWith(
                                  fontSize: AppSizes.scaledFont(18),
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
