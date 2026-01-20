part of '../../framework/ui.dart';

/// 횡단보도 패널 뷰
/// BLE를 통해 주변 횡단보도를 검색하고 결과를 표시하는 드래그 가능한 패널
class CrosswalkPanelView extends StatefulWidget {
  const CrosswalkPanelView({super.key});

  @override
  State<CrosswalkPanelView> createState() => _CrosswalkPanelViewState();
}

class _CrosswalkPanelViewState extends State<CrosswalkPanelView> {
  // TTS(Text-to-Speech) 서비스 인스턴스
  final tts = DI.get<TtsService>();
  // 스낵바 메시지 표시를 위한 메시지 서비스 인스턴스
  final message = DI.get<Message>();

  // 드래그 가능한 스크롤 시트의 높이와 위치를 제어하는 컨트롤러
  late DraggableScrollableController _controller;
  // 패널의 슬라이딩 애니메이션을 제어하는 컨트롤러
  late SlidingPanelController _slidingController;

  // 연결 타임아웃을 위한 타이머
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    // 드래그 가능한 스크롤 시트 컨트롤러 초기화
    _controller = DraggableScrollableController();
    // GetX를 통해 슬라이딩 패널 컨트롤러 가져오기
    _slidingController = Get.find<SlidingPanelController>();

    // 횡단보도 화면용 패널 설정 등록
    // 패널의 최소/최대 높이, 기본 높이, 애니메이션 설정을 구성
    _slidingController.registerPanel(
      'crosswalk_panel', // 패널 식별자
      _controller, // 드래그 컨트롤러
      config: PanelConfig(
        minHeight: 0.0, // 최소 높이 (완전히 숨김)
        maxHeight: 0.8, // 최대 높이 (화면의 80%)
        defaultHeight: 0.4, // 기본 높이 (화면의 40%)
        animationDuration: const Duration(milliseconds: 300), // 애니메이션 지속 시간
        animationCurve: Curves.easeInOut, // 애니메이션 곡선
      ),
    );

    // 패널이 열릴 때 초기 상태로 리셋 및 TTS 안내
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // bloc 상태를 초기 화면으로 리셋 (이전 상태가 남아있을 수 있음)
      context.read<CrosswalkBloc>().add(StopScanEvent());
      tts.speakBleScanPrompt();
    });
  }

  @override
  void dispose() {
    // 패널 컨트롤러 정리: Map에서 제거하여 다음 mount 시 새로 등록되도록 함
    _slidingController.removeController('crosswalk_panel');
    // 컨트롤러 리소스 해제
    _controller.dispose();
    // 타이머 해제
    _connectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.0, // 초기에는 숨겨진 상태
      minChildSize: 0.0, // 최소 크기 (완전히 숨김)
      maxChildSize: 0.8, // 최대 크기 (화면의 80%)
      controller: _controller, // 드래그 제어를 위한 컨트롤러
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white, // 흰색 배경
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20)), // 상단 모서리 둥글게
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15), // 그림자 효과
                blurRadius: 10,
                offset: const Offset(0, -4), // 위쪽으로 그림자
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들 - 사용자가 패널을 드래그할 수 있음을 표시
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(height: 16),

              // 횡단보도 내용 영역
              Expanded(
                child: BlocConsumer<CrosswalkBloc, CrosswalkState>(
                  listener: (context, state) {
                    if (state is ConnectOff) {
                      _handleConnectionSuccess();
                    } else if (state is CrosswalkError) {
                      _connectionTimer?.cancel();
                      _connectionTimer = null;
                    }
                  },

                  // 상태에 따라 UI 구성
                  builder: (context, state) {
                    return ListView(
                      controller: scrollController, // 스크롤 제어
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 제목
                        Text(
                          '횡단보도',
                          style: TextStyle(
                            fontSize: AppSizes.scaledFont(24),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Gap(height: 16),

                        // 상태에 따른 UI 렌더링
                        if (state is CrosswalkInitial) ...[
                          // 1. 초기 화면 - BLE 찾기 버튼
                          _buildInitialUI(),
                        ] else if (state is SearchOn) ...[
                          // 2. BLE 횡단보도 찾는 중
                          _buildSearchingUI(),
                        ] else if (state is SearchOff) ...[
                          if (state.results.isEmpty) ...[
                            // 3. BLE 검색 결과 없음
                            _buildEmptyResultUI(),
                          ] else ...[
                            // 4. BLE 검색 완료 - 리스트 표시
                            _buildSearchResultsUI(state.results),
                          ],
                        ] else if (state is ConnectOn) ...[
                          // 5. 횡단보도와 연결 중
                          _buildConnectingUI(),
                        ] else if (state is CrosswalkError) ...[
                          // 6. 에러 상태
                          _buildErrorUI(state.message),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 초기 화면 UI - BLE 찾기 버튼
  Widget _buildInitialUI() {
    return Column(
      children: [
        const Gap(height: 40),

        // 안내 메시지
        Icon(
          Icons.bluetooth_searching,
          size: 60,
          color: Colors.blue[600],
        ),
        const Gap(height: 20),

        Text(
          '주변 음향신호기를 찾으려면\n아래 버튼을 눌러주세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(height: 30),

        // BLE 찾기 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              tts.speakBleScanning();
              context.read<CrosswalkBloc>().add(SearchFiniteCrosswalkEvent());
            },
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
            label: const Text(
              'BLE 찾기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  /// 검색 중 UI를 구성하는 메서드
  Widget _buildSearchingUI() {
    return Column(
      children: [
        const Gap(height: 20),

        // 로딩 애니메이션
        Semantics(
          label: '횡단보도 검색 중',
          child: CircularProgressIndicator(
            color: Colors.blue[600],
          ),
        ),
        const Gap(height: 20),

        // 상태 메시지
        Text(
          '주변 음향신호기를 찾는 중...',
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            color: Colors.blue[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(height: 30),

        // 중단 버튼 - StopScanEvent 발생
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<CrosswalkBloc>().add(StopScanEvent());
            },
            icon: const Icon(Icons.stop, color: Colors.white, size: 20),
            label: const Text(
              '중단',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  /// 검색 결과 없음 UI를 구성하는 메서드
  Widget _buildEmptyResultUI() {
    // TTS 안내
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tts.speakBleNotFound();
    });

    return Column(
      children: [
        const Gap(height: 40),

        // 실패 아이콘
        Icon(
          Icons.search_off,
          size: 60,
          color: Colors.red[400],
        ),
        const Gap(height: 20),

        // 실패 메시지
        Text(
          '주변에서 음향신호기를\n찾을 수 없습니다',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            color: Colors.red[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(height: 30),

        // 다시 찾기 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              tts.speakBleScanning();
              context.read<CrosswalkBloc>().add(SearchFiniteCrosswalkEvent());
            },
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            label: const Text(
              '다시찾기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  /// 검색 완료 UI를 구성하는 메서드
  /// [results]: 찾은 횡단보도 목록
  Widget _buildSearchResultsUI(List<Crosswalk> results) {
    return Column(
      children: [
        // 결과 리스트
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: SizeTheme.w_md,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return ListTile(
              contentPadding: EdgeInsets.symmetric(
                vertical: SizeTheme.w_sm,
                horizontal: SizeTheme.h_lg,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeTheme.r_sm),
              ),
              onTap: () {
                // 모달 바텀시트로 안전 리모콘 표시
                _showConnectionOptions(context, results[index]);
              },

              // 횡단보도 타입별 아이콘 표시
              leading: results[index].type == ECrosswalk.UNKNOWN
                  ? null
                  : SingleChildRoundedCard(
                      child: Image(
                        width: 42.w,
                        height: 42.w,
                        image: AssetImage(
                          results[index].type == ECrosswalk.SINGLE_ROAD
                              ? Images.TrafficSingle // 단일 신호등
                              : results[index].type == ECrosswalk.INTERSECTION
                                  ? Images.TrafficCross // 교차로
                                  : Images.TrafficYellow, // 점멸 신호등
                        ),
                        semanticLabel: results[index].type == ECrosswalk.SINGLE_ROAD
                            ? '단일 신호등'
                            : results[index].type == ECrosswalk.INTERSECTION
                                ? '교차로 신호등'
                                : '점멸 신호등',
                      ),
                    ),

              // 횡단보도 타입 표시
              title: results[index].type == ECrosswalk.UNKNOWN
                  ? null
                  : Text(
                      results[index].type == ECrosswalk.SINGLE_ROAD
                          ? '단일 신호등 지역'
                          : results[index].type == ECrosswalk.INTERSECTION
                              ? '교차로 지역'
                              : '점멸 신호등 지역',
                      style: Theme.of(context).textTheme.bodyMedium!.apply(
                            color: results[index].type == ECrosswalk.SINGLE_ROAD
                                ? ColorTheme.highlight3
                                : results[index].type == ECrosswalk.INTERSECTION
                                    ? ColorTheme.highlight2
                                    : ColorTheme.highlight1,
                          ),
                    ),

              // 횡단보도 이름 표시
              subtitle: Text(
                results[index].name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            );
          },
          separatorBuilder: (context, index) {
            return SizedBox(height: SizeTheme.h_sm);
          },
        ),

        const Gap(height: 20),

        // 다시찾기 버튼
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                tts.speakBleScanning();
                context.read<CrosswalkBloc>().add(SearchFiniteCrosswalkEvent());
              },
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              label: const Text(
                '다시찾기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 횡단보도와 연결 중일 때의 UI를 구성하는 메서드
  Widget _buildConnectingUI() {
    return Column(
      children: [
        // 연결 중 애니메이션
        Semantics(
          label: '연결 중 이미지',
          child: Lottie.asset(
            Gif.LOTTIE_RADAR,
            height: 200.h,
            width: 200.w,
          ),
        ),
        const Gap(height: 20),

        // 연결 중 메시지
        Text(
          '횡단보도와 연결 중...',
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            color: Colors.blue[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(height: 20),

        // 연결 중단 버튼
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // 연결 중단 시 타이머 정리
              _connectionTimer?.cancel();
              _connectionTimer = null;

              // 유한 검색 이벤트를 발생시켜 검색 중단
              context.read<CrosswalkBloc>().add(SearchFiniteCrosswalkEvent());
            },
            icon: Icon(Icons.stop, color: Colors.white, size: 20),
            label: Text(
              '연결 중단',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  /// 에러 UI를 구성하는 메서드
  Widget _buildErrorUI(String errorMessage) {
    return Column(
      children: [
        const Gap(height: 40),

        // 에러 아이콘
        Icon(
          Icons.error_outline,
          size: 60,
          color: Colors.red[400],
        ),
        const Gap(height: 20),

        // 에러 메시지
        Text(
          errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSizes.scaledFont(16),
            color: Colors.red[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(height: 30),

        // 다시 시도 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<CrosswalkBloc>().add(StopScanEvent());
            },
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            label: const Text(
              '처음으로',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  /// 횡단보도 연결 옵션을 보여주는 모달
  /// [context]: BuildContext
  /// [crosswalk]: 연결할 횡단보도
  void _showConnectionOptions(BuildContext context, Crosswalk crosswalk) {
    // 모달이 닫힌 후에도 bloc에 접근할 수 있도록 미리 캡처
    final crosswalkBloc = context.read<CrosswalkBloc>();

    showModalBottomSheet(
      isScrollControlled: true,
      barrierColor: Theme.of(context).colorScheme.onSecondary.withAlpha(100),
      context: context,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      isDismissible: false,
      builder: (BuildContext context) {
        return SizedBox(
          height: 700.h,
          child: Board(
            title: '안전 리모콘',
            headerPadding: EdgeInsets.all(
              SizeTheme.w_md,
            ),
            titleStyle: Theme.of(context).textTheme.titleLarge,
            trailing: TextButton(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 50.w),
                child: const FittedBox(child: Text('닫기')),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            body: Expanded(
              child: SizedBox(
                height: 600.h,
                width: MediaQuery.of(context).size.width,
                child: _renderCommandButtons(context, crosswalk),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() async {
      // 경광등 끄기
      final flashOff = DI.get<ControlFlash>(
        instanceName: USECASE_CONTROL_FLASH_OFF,
      );
      flashOff(NoParams());
      // 초기 화면으로 돌아감 (캡처된 bloc 참조 사용)
      crosswalkBloc.add(StopScanEvent());
    }).timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        Navigator.pop(context);
      },
    );
  }

  /// 명령 버튼 UI를 렌더링하는 메서드 (통합)
  /// [context]: BuildContext
  /// [crosswalk]: 연결할 횡단보도 정보
  Widget _renderCommandButtons(BuildContext context, Crosswalk crosswalk) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
      child: BlocBuilder<CrosswalkBloc, CrosswalkState>(
        builder: (context, state) {
          // 연결 중 - 로딩 표시
          if (state is ConnectOn) {
            return Column(
              children: [
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
                // 종료 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('종료'),
                  ),
                ),
              ],
            );
          }

          // 에러 상태
          if (state is CrosswalkError) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60.w,
                  color: ColorTheme.highlight4,
                ),
                SizedBox(height: SizeTheme.h_md),
                Text(
                  '음향 신호기에 연결할 수 없습니다.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: SizeTheme.h_lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('종료'),
                  ),
                ),
              ],
            );
          }

          // 기본 상태 및 ConnectOff - 명령 버튼 표시
          return Column(
            children: [
              // 연결 성공 메시지 (ConnectOff 상태일 때만)
              if (state is ConnectOff) ...[
                SingleChildRoundedCard(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Padding(
                    padding: EdgeInsets.all(SizeTheme.w_md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_outlined,
                          size: 24.w,
                          color: ColorTheme.highlight2,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '명령 전송 완료',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: SizeTheme.h_md),
              ],

              // 위치 안내 버튼 (0x31 0x00 0x01)
              Padding(
                padding: EdgeInsets.only(bottom: SizeTheme.h_md),
                child: FlatCard(
                  title: '위치 안내',
                  titleOnly: true,
                  leading: const Icon(
                    Icons.volume_up,
                    color: ColorTheme.highlight3,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onTap: () {
                    context
                        .read<CrosswalkBloc>()
                        .add(SendVoiceGuideEvent(crosswalk: crosswalk));
                  },
                ),
              ),

              // 신호 안내 버튼 (0x31 0x00 0x02)
              Padding(
                padding: EdgeInsets.only(bottom: SizeTheme.h_md),
                child: FlatCard(
                  title: '신호 안내',
                  titleOnly: true,
                  leading: const Icon(
                    Icons.traffic,
                    color: ColorTheme.highlight1,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onTap: () {
                    context
                        .read<CrosswalkBloc>()
                        .add(SendAcousticSignalEvent(crosswalk: crosswalk));
                  },
                ),
              ),

              // 음성 안내 버튼 (0x31 0x00 0x03)
              Padding(
                padding: EdgeInsets.only(bottom: SizeTheme.h_md),
                child: FlatCard(
                  title: '음성 안내',
                  titleOnly: true,
                  leading: const Icon(
                    Icons.directions_walk_rounded,
                    color: ColorTheme.highlight2,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onTap: () {
                    context
                        .read<CrosswalkBloc>()
                        .add(SendVoiceInductorEvent(crosswalk: crosswalk));
                  },
                ),
              ),

              // 종료 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('종료'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 연결 성공 시 타이머 정리
  void _handleConnectionSuccess() {
    // 타이머 정리
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }
}
