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

    // C-ITS 데이터 동기화 (다이얼로그 표시)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSyncDialog();
    });
  }

  /// C-ITS 동기화 다이얼로그 표시
  Future<void> _showSyncDialog() async {
    // 동기화 상태 변수
    String? currentJunctionFile;
    String? serverJunctionFile;
    bool junctionUpdated = false;
    bool junctionIsLatest = false; // 최신 상태 플래그

    String? currentCrosswalkFile;
    String? serverCrosswalkFile;
    bool crosswalkUpdated = false;
    bool crosswalkIsLatest = false; // 최신 상태 플래그

    bool isLoading = true;
    bool syncStarted = false; // 중복 실행 방지 플래그

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // 동기화를 한 번만 시작
          if (isLoading && !syncStarted) {
            syncStarted = true;

            // 다음 프레임에서 동기화 시작 (빌드 중 setState 방지)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _syncCitsDataForDialog(
                onJunctionUpdate: (current, server, updated, isLatest) {
                  if (!mounted) return;
                  setState(() {
                    currentJunctionFile = current;
                    serverJunctionFile = server;
                    junctionUpdated = updated;
                    junctionIsLatest = isLatest;
                  });
                },
                onCrosswalkUpdate: (current, server, updated, isLatest) {
                  if (!mounted) return;
                  setState(() {
                    currentCrosswalkFile = current;
                    serverCrosswalkFile = server;
                    crosswalkUpdated = updated;
                    crosswalkIsLatest = isLatest;
                  });
                },
              ).then((_) {
                if (!mounted) return;
                setState(() {
                  isLoading = false;
                });
              }).catchError((error) {
                // 에러 발생 시에도 로딩 종료
                if (!mounted) return;
                setState(() {
                  isLoading = false;
                });
              });
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text('C-ITS 데이터 동기화'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 교차로 정보 카드
                        _buildSyncInfoCard(
                          icon: '🚦',
                          title: '교차로 정보',
                          currentFile: currentJunctionFile,
                          serverFile: serverJunctionFile,
                          isUpdated: junctionUpdated,
                          isLatest: junctionIsLatest,
                        ),
                        const SizedBox(height: 16),
                        // 음향신호기 정보 카드
                        _buildSyncInfoCard(
                          icon: '🔊',
                          title: '음향신호기 정보',
                          currentFile: currentCrosswalkFile,
                          serverFile: serverCrosswalkFile,
                          isUpdated: crosswalkUpdated,
                          isLatest: crosswalkIsLatest,
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 동기화 정보 카드 위젯
  Widget _buildSyncInfoCard({
    required String icon,
    required String title,
    String? currentFile,
    String? serverFile,
    required bool isUpdated,
    required bool isLatest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 현재 파일
          _buildInfoRow('현재 파일', currentFile ?? '없음'),
          const SizedBox(height: 8),
          // 서버 파일
          _buildInfoRow('서버 파일', serverFile ?? '확인 중...'),
          const SizedBox(height: 8),
          // 업데이트 상태
          Row(
            children: [
              const Text(
                '업데이트',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              if (isUpdated) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                const Text(
                  '업데이트됨',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (isLatest) ...[
                const Icon(Icons.check, color: Colors.blue, size: 18),
                const SizedBox(width: 4),
                const Text(
                  '최신 상태',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// C-ITS 데이터 동기화 (다이얼로그용)
  Future<void> _syncCitsDataForDialog({
    required Function(String?, String, bool, bool) onJunctionUpdate,
    required Function(String?, String, bool, bool) onCrosswalkUpdate,
  }) async {
    try {
      // 1. 서버 버전 조회
      final getCitsVersions = DI.get<GetCitsVersions>();
      final versionResult = await getCitsVersions(NoParams());

      await versionResult.fold(
        (failure) async {
          // 서버 연결 실패 - 로컬 데이터만 표시
          final localJunctionVersion = await _getLocalJunctionVersion();
          final localCrosswalkVersion = await _getLocalCrosswalkVersion();

          onJunctionUpdate(
            localJunctionVersion != null ? 'seoul_intersection_$localJunctionVersion.csv' : null,
            '서버 연결 실패',
            false,
            false,
          );
          onCrosswalkUpdate(
            localCrosswalkVersion != null ? 'seoul_crosswalk_$localCrosswalkVersion.csv' : null,
            '서버 연결 실패',
            false,
            false,
          );
        },
        (serverVersions) async {
          // 2. 교차로 동기화
          final junctionResult = await _syncJunctionForDialog(serverVersions.junctionsVersion);
          onJunctionUpdate(
            junctionResult['current'],
            junctionResult['server']!,
            junctionResult['updated']!,
            junctionResult['isLatest']!,
          );

          // 3. 음향신호기 동기화
          final crosswalkResult = await _syncCrosswalkForDialog(serverVersions.crosswalkVersion);
          onCrosswalkUpdate(
            crosswalkResult['current'],
            crosswalkResult['server']!,
            crosswalkResult['updated']!,
            crosswalkResult['isLatest']!,
          );

          // 4. 메모리에 로드 (캐싱)
          await _loadCitsDataFromLocal();
        },
      );
    } catch (e) {
      // 에러 발생 - 로컬 데이터 표시
      final localJunctionVersion = await _getLocalJunctionVersion();
      final localCrosswalkVersion = await _getLocalCrosswalkVersion();

      onJunctionUpdate(
        localJunctionVersion != null ? 'seoul_intersection_$localJunctionVersion.csv' : null,
        '오류 발생',
        false,
        false,
      );
      onCrosswalkUpdate(
        localCrosswalkVersion != null ? 'seoul_crosswalk_$localCrosswalkVersion.csv' : null,
        '오류 발생',
        false,
        false,
      );
    }
  }

  /// 로컬 교차로 버전 조회
  Future<int?> _getLocalJunctionVersion() async {
    try {
      final getLocalVersion = DI.get<GetLocalCitsJunctionsVersion>();
      final result = await getLocalVersion(NoParams());
      return result.fold((_) => null, (version) => version);
    } catch (e) {
      return null;
    }
  }

  /// 로컬 음향신호기 버전 조회
  Future<int?> _getLocalCrosswalkVersion() async {
    try {
      final getLocalVersion = DI.get<GetLocalCitsCrosswalksVersion>();
      final result = await getLocalVersion(NoParams());
      return result.fold((_) => null, (version) => version);
    } catch (e) {
      return null;
    }
  }

  /// 교차로 동기화 (다이얼로그용)
  Future<Map<String, dynamic>> _syncJunctionForDialog(int serverVersion) async {
    try {
      final localVersion = await _getLocalJunctionVersion();
      final currentFile = localVersion != null ? 'seoul_intersection_$localVersion.csv' : null;
      final serverFile = 'seoul_intersection_$serverVersion.csv';

      if (localVersion == null || localVersion < serverVersion) {
        // 다운로드 필요
        final syncJunctions = DI.get<SyncCitsJunctions>();
        final syncResult = await syncJunctions(
          SyncCitsJunctionsParams(version: serverVersion),
        );

        return syncResult.fold(
          (failure) => {
            'current': currentFile,
            'server': serverFile,
            'updated': false,
            'isLatest': false,
          },
          (_) => {
            'current': currentFile,
            'server': serverFile,
            'updated': true,
            'isLatest': false,
          },
        );
      } else {
        // 최신 상태
        return {
          'current': currentFile,
          'server': serverFile,
          'updated': false,
          'isLatest': true,
        };
      }
    } catch (e) {
      return {
        'current': null,
        'server': 'seoul_intersection_$serverVersion.csv',
        'updated': false,
        'isLatest': false,
      };
    }
  }

  /// 음향신호기 동기화 (다이얼로그용)
  Future<Map<String, dynamic>> _syncCrosswalkForDialog(int serverVersion) async {
    try {
      final localVersion = await _getLocalCrosswalkVersion();
      final currentFile = localVersion != null ? 'seoul_crosswalk_$localVersion.csv' : null;
      final serverFile = 'seoul_crosswalk_$serverVersion.csv';

      if (localVersion == null || localVersion < serverVersion) {
        // 다운로드 필요
        final syncCrosswalks = DI.get<SyncCitsCrosswalks>();
        final syncResult = await syncCrosswalks(
          SyncCitsCrosswalksParams(version: serverVersion),
        );

        return syncResult.fold(
          (failure) => {
            'current': currentFile,
            'server': serverFile,
            'updated': false,
            'isLatest': false,
          },
          (_) => {
            'current': currentFile,
            'server': serverFile,
            'updated': true,
            'isLatest': false,
          },
        );
      } else {
        // 최신 상태
        return {
          'current': currentFile,
          'server': serverFile,
          'updated': false,
          'isLatest': true,
        };
      }
    } catch (e) {
      return {
        'current': null,
        'server': 'seoul_crosswalk_$serverVersion.csv',
        'updated': false,
        'isLatest': false,
      };
    }
  }

  /// 로컬에서 C-ITS 데이터 로드 (메모리 캐싱)
  Future<void> _loadCitsDataFromLocal() async {
    try {
      // 교차로 데이터 로드
      final loadJunctions = DI.get<LoadAllCitsJunctions>();
      await loadJunctions(NoParams());

      // 음향신호기 데이터 로드
      final loadCrosswalks = DI.get<LoadAllCitsCrosswalks>();
      await loadCrosswalks(NoParams());
    } catch (e) {
      // 로드 실패는 무시 (UI에는 영향 없음)
    }
  }

  /// 하단바 탭 선택 시 호출되는 콜백 함수
  void _onItemTapped(int index) {
    // 음성 안내 중지 (예: TTS가 말하는 도중 탭을 전환하면 중단)
    DI.get<FlutterTts>().stop();

    // 같은 탭을 다시 터치했는지 확인
    final isSameTab = index == _selectedIndex;
    final selectedMenu = index < menuNames.length ? menuNames[index] : menuNames[0];

    // 선택된 탭 인덱스를 갱신하여 화면 전환
    setState(() {
      _selectedIndex = index;
    });

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

        if (isSameTab) {
          // 같은 탭이면 토글 (열림↔닫힘)
          final isExpanded = slidingController.isPanelExpanded(panelId);
          slidingController.toggleSlidingBar(panelId);

          // 패널 상태에 따라 TTS 안내
          final stateMessage = isExpanded ? '접었습니다' : '펼쳤습니다';
          tts.speakPanelToggle(selectedMenu, stateMessage);
        } else {
          // 다른 탭으로 전환: 새 패널 열기
          // activePanelId 변경으로 이전 패널은 자동으로 교체됨
          slidingController.expandSlidingBar(panelId);

          // 통합된 TTS 메시지: "즐겨찾기 패널로 이동합니다"
          tts.speakPanelSwitch(selectedMenu);
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
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.28),
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
