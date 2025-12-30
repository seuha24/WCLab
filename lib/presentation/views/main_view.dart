part of '../../framework/ui.dart';

/// 메인 뷰: 지도 고정 + 슬라이딩 카드 + 하단 네비게이션 탭
class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  // BLE 상태를 스트림으로 감지하기 위한 인스턴스 (DI로 주입)
  final bluetooth = DI.get<FlutterReactiveBle>();

  // TTS 서비스 인스턴스
  final tts = DI.get<TtsService>();

  int _selectedIndex = 0; // 초기 선택된 탭 인덱스 (지도)
  int _previousIndex = 0; // 이전에 선택된 탭 인덱스 (중복 음성 방지용)

  // 하단바 메뉴 이름 리스트
  final List<String> menuNames = ['지도', '즐겨찾기', '횡단보도', '출입구 등록', '설정'];

  @override
  void initState() {
    super.initState();
    // 컨트롤러들을 미리 초기화
    Get.put(NaverMapViewController());
    Get.put(SlidingPanelController());

    // 초기 상태: 패널 접힌 상태로 시작
    // activePanelId만 설정하고 패널은 펼치지 않음
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _selectedIndex == 0) {
        final slidingController = Get.find<SlidingPanelController>();
        slidingController.activePanelId.value = 'map_panel';
      }
    });
  }

  /// 하단바 탭 선택 시 호출되는 콜백 함수
  void _onItemTapped(int index) {
    // 음성 안내 중지 (예: TTS가 말하는 도중 탭을 전환하면 중단)
    DI.get<FlutterTts>().stop();

    // 같은 탭을 다시 터치했는지 확인
    final isSameTab = index == _selectedIndex;

    // 선택된 탭 인덱스를 갱신하여 화면 전환
    setState(() {
      _selectedIndex = index;
    });

    // 다른 메뉴로 전환할 때만 음성 안내 (같은 메뉴 중복 클릭 방지)
    if (index != _previousIndex) {
      final selectedMenu =
          index < menuNames.length ? menuNames[index] : menuNames[0];
      tts.speakWithChannel('${selectedMenu}을 선택하셨습니다.',
          channel: ETtsChannel.FEEDBACK,
          cooldownKey: 'menu_selection',
          cooldown: Duration(seconds: 0));
      _previousIndex = index; // 현재 선택된 인덱스를 이전 인덱스로 업데이트
    }

    // 슬라이딩 패널 제어: 화면에 따라 슬라이딩바를 열거나 토글
    try {
      final slidingController = Get.find<SlidingPanelController>();

      // 패널 ID 매핑
      final panelIds = [
        'map_panel',
        'favorite_panel',
        'crosswalk_panel',
        'entrance_panel',
        'setting_panel',
      ];

      if (index < panelIds.length) {
        final panelId = panelIds[index];
        final selectedMenu = menuNames[index];

        if (isSameTab) {
          // 같은 탭이면 토글 (열림↔닫힘)
          final isExpanded = slidingController.isPanelExpanded(panelId);
          slidingController.toggleSlidingBar(panelId);

          // 패널 상태에 따라 TTS 안내
          if (isExpanded) {
            tts.speakWithChannel('$selectedMenu 패널을 접었습니다.',
                channel: ETtsChannel.FEEDBACK,
                cooldownKey: 'panel_toggle',
                cooldown: Duration(seconds: 0));
          } else {
            tts.speakWithChannel('$selectedMenu 패널을 펼쳤습니다.',
                channel: ETtsChannel.FEEDBACK,
                cooldownKey: 'panel_toggle',
                cooldown: Duration(seconds: 0));
          }
        } else {
          // 다른 탭이면 열기
          slidingController.expandSlidingBar(panelId);
        }
      }
    } catch (e) {
      // 컨트롤러가 등록되지 않은 경우 대비한 예외 처리
      debugPrint('슬라이딩 패널 컨트롤러를 찾을 수 없습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final slidingController = Get.find<SlidingPanelController>();

    return StreamBuilder<BleStatus>(
      stream: bluetooth.statusStream, // BLE 상태 변화를 감지
      initialData: BleStatus.ready, // 초기값 설정

      builder: (context, snapshot) {
        if (snapshot.data != BleStatus.poweredOff) {
          // BLE가 켜져 있는 경우: 앱 정상 동작
          return Scaffold(
            body: Stack(
              children: [
                const NaverMapView(), // 항상 고정된 지도

                // Obx를 사용하여 활성화된 패널에 따라 동적으로 패널 뷰 표시
                Obx(() {
                  final activePanelId = slidingController.activePanelId.value;

                  if (activePanelId == 'map_panel') {
                    return const MapPanelView();
                  } else if (activePanelId == 'favorite_panel') {
                    return const FavoriteMainPanelView();
                  } else if (activePanelId == 'crosswalk_panel') {
                    return const CrosswalkPanelView();
                  } else if (activePanelId == 'entrance_panel') {
                    return const EntrancePanelView();
                  } else if (activePanelId == 'setting_panel') {
                    return const SettingPanelView();
                  }
                  // ... (필요한 모든 패널 추가)
                  else {
                    return const SizedBox.shrink(); // 활성화된 패널이 없으면 아무것도 보여주지 않음
                  }
                }),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              type: BottomNavigationBarType.fixed, // 탭이 5개이므로 fixed로 설정
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home,
                    semanticLabel: '지도 화면 네비게이션 버튼',
                  ),
                  label: '지도',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.bookmark_border,
                    semanticLabel: '즐겨찾기 화면 네비게이션 버튼',
                  ),
                  label: '즐겨찾기',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.directions_walk,
                    semanticLabel: '횡단보도 화면 네비게이션 버튼',
                  ),
                  label: '횡단보도',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.edit_document,
                    semanticLabel: '출입구 등록 화면 네비게이션 버튼',
                  ),
                  label: '출입구 등록',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.settings,
                    semanticLabel: '설정 화면 네비게이션 버튼',
                  ),
                  label: '설정',
                ),
              ],
              currentIndex: _selectedIndex, // 현재 선택된 탭 인덱스
              selectedItemColor:
                  Theme.of(context).colorScheme.onSecondary, // 선택된 아이템 색
              selectedLabelStyle: TextStyle(
                fontSize: AppSizes.scaledFont(16),
                fontWeight: FontWeight.bold,
              ),
              unselectedItemColor:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.28),
              unselectedLabelStyle: TextStyle(
                fontSize: AppSizes.scaledFont(16),
              ),
              onTap: _onItemTapped, // 탭 클릭 시 호출
            ),
          );
        } else {
          // BLE가 꺼져 있는 경우: 안내 화면으로 전환
          return BlueOffView(state: snapshot.data!);
        }
      },
    );
  }
}
