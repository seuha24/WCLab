part of '../../framework/ui.dart';

class SettingPanelView extends StatefulWidget {
  const SettingPanelView({super.key});

  @override
  State<SettingPanelView> createState() => _SettingPanelViewState();
}

class _SettingPanelViewState extends State<SettingPanelView> {
  late DraggableScrollableController _controller;
  late SlidingPanelController _slidingController;
  late String? mode;
  late String? lightmode;
  late Box box;
  late Box flashbox;
  final AuthService _authService = DI<AuthService>();
  final message = DI.get<Message>();

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
    _controller = DraggableScrollableController();
    _slidingController = Get.find<SlidingPanelController>();

    // 설정 화면용 컨트롤러 등록
    _slidingController.registerPanel(
      'setting_panel',
      _controller,
      config: PanelConfig(
        minHeight: 0.0,
        maxHeight: 0.8,
        defaultHeight: 0.4,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
      ),
    );

    // 권한 상태 초기화
    context.read<BluetoothPermissionCubit>().getPermissionStatus();
    context.read<LocationPermissionCubit>().getPermissionStatus();

    // 설정 데이터 초기화
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.0,
      minChildSize: 0.0,
      maxChildSize: 0.8,
      controller: _controller,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 설정 내용
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 제목
                    Text(
                      '설정',
                      style: TextStyle(
                        fontSize: AppSizes.scaledFont(24),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Gap(height: 24),

                    // 사용자 정보 섹션
                    _buildUserInfoSection(),
                    const Gap(height: 24),

                    // 앱 내부 권한 섹션
                    _buildPermissionSection(),
                    const Gap(height: 24),

                    // 기타 섹션
                    _buildOtherSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사용자 정보',
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Gap(height: 16),

        // 사용자 정보 카드
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
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
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blue[700],
                    ),
                  ),
                  title: Text(
                    username,
                    style: TextStyle(
                      fontSize: AppSizes.scaledFont(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '계정 관리',
                    style: TextStyle(
                      fontSize: AppSizes.scaledFont(14),
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: () async {
                      debugPrint('onTap Logout');

                      context.read<AuthBloc>().add(SignOutAllEvent());
                      await _authService.clearAuthData();

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SignInView(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout,
                        size: 20,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '앱 내부 권한',
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Gap(height: 16),

        // 블루투스 권한
        BlocBuilder<BluetoothPermissionCubit, bool>(
          builder: (_, state) {
            return Semantics.fromProperties(
              properties: SemanticsProperties(
                hint: '앱의 블루투스 사용 허가를 위해 설정이 필요합니다.',
                checked: state,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
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
                  style: TextStyle(
                    fontSize: AppSizes.scaledFont(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: CupertinoSwitch(
                  value: state,
                  thumbColor: Colors.white,
                  trackColor: Colors.grey[300],
                  activeColor: Colors.green,
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

        // 위치 정보 권한
        BlocBuilder<LocationPermissionCubit, bool>(
          builder: (_, state) {
            return Semantics.fromProperties(
              properties: SemanticsProperties(
                hint: '앱의 사용자 위치 정보 사용 허가를 위해 설정이 필요합니다.',
                checked: state,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
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
                  style: TextStyle(
                    fontSize: AppSizes.scaledFont(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: CupertinoSwitch(
                  value: state,
                  thumbColor: Colors.white,
                  trackColor: Colors.grey[300],
                  activeColor: Colors.green,
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
    );
  }

  Widget _buildOtherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기타',
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Gap(height: 16),

        // 시스템 모드 설정
        Semantics.fromProperties(
          properties: SemanticsProperties(
            button: true,
            hint:
                '현재 적용된 설정은 ${mode == 'system' ? '시스템 모드' : mode == 'light' ? '라이트모드' : '다크모드'}입니다. 시스템 모드 설정을 변경하려면 이중 탭 하십시오.',
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '시스템 모드 설정',
              style: TextStyle(
                fontSize: AppSizes.scaledFont(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              mode == 'system'
                  ? '시스템설정 적용중'
                  : mode == 'light'
                      ? '라이트모드 적용중'
                      : '다크모드 적용중',
              style: TextStyle(
                fontSize: AppSizes.scaledFont(14),
                fontWeight: FontWeight.bold,
              ).apply(color: ColorTheme.highlight2),
              semanticsLabel: '',
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[600],
              size: 16,
            ),
            onTap: () => _showSystemModeSettings(),
          ),
        ),

        // 음성보조 설정
        ValueListenableBuilder(
          valueListenable: Hive.box(SystemTheme.themeBox).listenable(),
          builder: (context, Box box, widget) {
            TTS.enable = box.get('tts', defaultValue: false);
            return Semantics.fromProperties(
              properties: SemanticsProperties(
                hint: '설정을 킬 경우 횡단보도 검색 및 연결에서 보조 음성이 들리게 됩니다.',
                checked: TTS.enable,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  await box.put('tts', !TTS.enable);
                  setState(() {
                    TTS.enable = box.get('tts');
                  });
                },
                title: Text(
                  '음성보조 설정',
                  style: TextStyle(
                    fontSize: AppSizes.scaledFont(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: CupertinoSwitch(
                  value: TTS.enable,
                  thumbColor: Colors.white,
                  trackColor: Colors.grey[300],
                  activeColor: Colors.green,
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

        // 경광등 설정
        Semantics.fromProperties(
          properties: SemanticsProperties(
            button: true,
            hint:
                '현재 적용된 설정은 ${lightmode == 'alwayson' ? '항상 켜기 모드' : lightmode == 'weathers' ? '주변 환경에 따라 켜기 모드' : '항상 끄기 모드'}입니다. 경광등 설정을 변경하려면 이중 탭 하십시오.',
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '경광등 설정',
              style: TextStyle(
                fontSize: AppSizes.scaledFont(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[600],
              size: 16,
            ),
            onTap: () => _showFlashlightSettings(),
          ),
        ),

        // 외부라이센스
        Semantics.fromProperties(
          properties: const SemanticsProperties(
            button: true,
            hint: '외부 라이센스를 확인하려면 이중 탭 하십시오.',
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '외부라이센스',
              style: TextStyle(
                fontSize: AppSizes.scaledFont(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[600],
              size: 16,
            ),
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
          ),
        ),

        // 도움말
        Semantics.fromProperties(
          properties: const SemanticsProperties(
            button: true,
            hint: '도움말 페이지로 이동하려면 이중 탭 하십시오.',
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '도움말',
              style: TextStyle(
                fontSize: AppSizes.scaledFont(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[600],
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TutorialView(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSystemModeSettings() {
    showModalBottomSheet(
      barrierColor: Theme.of(context).colorScheme.onSecondary.withAlpha(100),
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).colorScheme.background,
      builder: (BuildContext context) {
        return SizedBox(
          height: 800.h,
          child: Board(
            title: '시스템 모드 설정',
            headerPadding: EdgeInsets.only(bottom: SizeTheme.h_sm, left: 2),
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
                                  color: ColorTheme.light.onPrimary,
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
    );
  }

  void _showFlashlightSettings() {
    showModalBottomSheet(
      barrierColor: Theme.of(context).colorScheme.onSecondary.withAlpha(100),
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).colorScheme.background,
      builder: (BuildContext context) {
        return SizedBox(
          height: 800.h,
          child: Board(
            title: '경광등 설정',
            headerPadding: EdgeInsets.only(bottom: SizeTheme.h_sm),
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
                final bool isSelected = lightmode == mode['lightModeValue'];
                return Padding(
                  padding: EdgeInsets.only(bottom: SizeTheme.h_md),
                  child: FlatCard(
                    title: mode['title'],
                    titleOnly: true,
                    bottomTitle: false,
                    isSelected: isSelected,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    backgroundColor: isSelected ? Colors.indigoAccent : null,
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
                            style:
                                Theme.of(context).textTheme.labelMedium!.apply(
                                      color: ColorTheme.light.onPrimary,
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
    );
  }
}
