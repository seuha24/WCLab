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

    // 첫 화면(지도)의 패널을 표시하기 위해
    // 충분한 지연 후 실행 (Sheet가 완전히 준비될 때까지)
    Future.delayed(const Duration(milliseconds: 500), () {
      // 초기 선택된 탭이 0(지도)이고 위젯이 마운트된 상태면 패널 표시
      if (mounted && _selectedIndex == 0) {
        final slidingController = Get.find<SlidingPanelController>();
        slidingController.expandSlidingBar('map_panel');
      }
    });
  }

  /// 하단바 탭 선택 시 호출되는 콜백 함수
  void _onItemTapped(int index) {
    // 음성 안내 중지 (예: TTS가 말하는 도중 탭을 전환하면 중단)
    DI.get<FlutterTts>().stop();

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

    // 슬라이딩 패널 제어: 화면에 따라 슬라이딩바를 열거나 무시
    try {
      final slidingController = Get.find<SlidingPanelController>();

      switch (index) {
        case 0: // 지도 화면
          slidingController.expandSlidingBar('map_panel'); // 슬라이딩 바 열기
          break;
        case 1: // 즐겨찾기 화면
          slidingController.expandSlidingBar('favorite_panel');
          break;
        case 2: // 횡단보도 화면
          slidingController.expandSlidingBar('crosswalk_panel');
          break;
        case 3: // 출입구 등록 화면
          slidingController.expandSlidingBar('entrance_panel');
          break;
        case 4: // 설정 화면
          slidingController.expandSlidingBar('setting_panel');
          break;
        default:
          // 나머지 화면에서는 슬라이딩바를 사용하지 않음
          break;
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
