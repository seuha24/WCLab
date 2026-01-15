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

  List<GlobalKey> keys = [GlobalKey(), GlobalKey()];
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

    // 패널이 열릴 때 자동으로 횡단보도 검색 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrosswalkBloc>().add(SearchInfiniteCrosswalkEvent());
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
                        if (state is SearchOn) ...[
                          // 1. BLE 횡단보도 찾는 중
                          _buildSearchingUI('BLE 횡단보도 찾는 중...', state.infinite),
                        ] else if (state is SearchOff) ...[
                          if (state.results.isEmpty) ...[
                            // 2. BLE 검색 실패
                            _buildEmptyResultUI(),
                          ] else ...[
                            // 3. BLE 검색 완료
                            _buildSearchResultsUI(state.results),
                          ],
                        ] else if (state is ConnectOn) ...[
                          // 4. 횡단보도와 연결 중
                          _buildConnectingUI(),
                        ] else if (state is ConnectOff) ...[
                          // 5. 횡단보도와 연결 완료 - 방향 안내
                          //   _buildDirectionalGuidanceUI(state),
                          // ] else if (state is CrosswalkError) ...[
                          //   // 에러 상태
                          //   _buildErrorUI(state.message),
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

  /// 검색 중 UI를 구성하는 메서드
  /// [message]: 표시할 메시지
  /// [isInfinite]: 무한 검색 모드 여부
  Widget _buildSearchingUI(String message, bool isInfinite) {
    return Column(
      children: [
        // 로딩 애니메이션 추가
        Semantics(
          label: '횡단보도 검색 중',
          child: CircularProgressIndicator(
            color: Colors.blue[600],
          ),
        ),
        const Gap(height: 20),

        // 상태 메시지 - 노란색으로 표시하여 진행 중임을 강조
        Text(
          isInfinite ? '자동으로 내 주변 횡단보도에 연결중입니다.' : 'BLE 횡단보도 찾는 중...',
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            color: isInfinite ? Colors.yellow[600] : Colors.blue[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(height: 20),

        // 중단 버튼 - 검색을 중단할 수 있는 버튼
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // 검색 중단 후 빈 결과로 상태 변경
              context.read<CrosswalkBloc>().add(SearchFiniteCrosswalkEvent());
            },
            icon: Icon(Icons.stop, color: Colors.white, size: 20),
            label: Text(
              '중단',
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

  /// 검색 실패 UI를 구성하는 메서드
  /// 검색 결과가 없을 때 표시되는 화면
  Widget _buildEmptyResultUI() {
    return Column(
      children: [
        // 실패 메시지 - 빨간색으로 표시하여 실패 상태임을 강조
        Text(
          '스마트 압버튼을 찾을 수 없습니다',
          style: TextStyle(
            fontSize: AppSizes.scaledFont(18),
            color: Colors.red[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(height: 20),

        // 다시 찾기 버튼 - 검색을 다시 시도할 수 있는 버튼
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // 무한 검색 이벤트를 발생시켜 검색 재시작
              context.read<CrosswalkBloc>().add(SearchInfiniteCrosswalkEvent());
            },
            icon: Icon(Icons.refresh, color: Colors.white, size: 20),
            label: Text(
              '다시찾기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
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

  /// 검색 완료 UI를 구성하는 메서드
  /// [results]: 찾은 횡단보도 목록
  Widget _buildSearchResultsUI(List<Crosswalk> results) {
    return ListView.separated(
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

          // 횡단보도 타입과 방향 표시
          title: results[index].type == ECrosswalk.UNKNOWN
              ? null
              : RichText(
                  text: TextSpan(
                    text: results[index].type == ECrosswalk.SINGLE_ROAD
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
                    children: [
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: results[index].dir ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

  /// 횡단보도 연결 옵션을 보여주는 모달
  /// [context]: BuildContext
  /// [crosswalk]: 연결할 횡단보도
  void _showConnectionOptions(BuildContext context, Crosswalk crosswalk) {
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
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    _renderSelectedMode(context, crosswalk),
                    _renderAfterModeSelected(context, crosswalk, 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() async {
      // HomeView와 동일한 완료 처리
      final flashOff = DI.get<ControlFlash>(
        instanceName: USECASE_CONTROL_FLASH_OFF,
      );
      flashOff(NoParams());
      context.read<CrosswalkBloc>().add(SearchInfiniteCrosswalkEvent());
    }).timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        Navigator.pop(context);
      },
    );
  }

  /// 연결 모드 선택 후 처리 화면을 렌더링하는 메서드
  /// HomeView의 _renderAfterModeSelected와 동일한 로직
  /// [context]: BuildContext
  /// [crosswalk]: 연결된 횡단보도 정보
  /// [index]: 횡단보도 인덱스 (사용되지 않지만 HomeView 호환성을 위해 유지)
  Container _renderAfterModeSelected(
      BuildContext context, Crosswalk crosswalk, int index) {
    return Container(
      key: keys[1],
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
        horizontal: SizeTheme.w_md,
      ),
      child: BlocConsumer<CrosswalkBloc, CrosswalkState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is ConnectOn) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is Error) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SingleChildRoundedCard(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: SizeTheme.h_lg),
                        child: Icon(
                          Icons.error_outline,
                          size: 80.w,
                          color: ColorTheme.highlight4,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: SizeTheme.h_lg),
                        child: const Center(child: Text('음향 신호기에 연결할 수 없습니다.')),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('종료'),
                  ),
                )
              ],
            );
          } else if (state is ConnectOff) {
            if (state.enableCompass && state.latLng != null) {
              return Compass(
                pos: crosswalk.pos!,
                latLng: state.latLng!,
                end: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('종료'),
                  ),
                ),
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SingleChildRoundedCard(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: SizeTheme.h_lg),
                        child: Icon(
                          Icons.check_circle_outline_outlined,
                          size: 80.w,
                          color: ColorTheme.highlight2,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: SizeTheme.h_lg),
                        child:
                            const Center(child: Text('음향신호기의 안내에 따라 보행하세요.')),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('종료'),
                  ),
                )
              ],
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }

  /// 연결 모드 선택 화면을 렌더링하는 메서드
  /// HomeView의 _renderSelectedMode와 동일한 로직
  /// [context]: BuildContext
  /// [crosswalk]: 선택할 횡단보도 정보
  Container _renderSelectedMode(BuildContext context, Crosswalk crosswalk) {
    return Container(
      key: keys[0],
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
        horizontal: SizeTheme.w_md,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: SizeTheme.h_md,
            ),
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
                // 스크롤 제거 - 현재 화면 유지
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: SizeTheme.h_md,
            ),
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
              onTap: () async {
                context
                    .read<CrosswalkBloc>()
                    .add(SendAcousticSignalEvent(crosswalk: crosswalk));
                // 스크롤 제거 - 현재 화면 유지
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: SizeTheme.h_md,
            ),
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
              onTap: () async {
                context
                    .read<CrosswalkBloc>()
                    .add(SendVoiceInductorEvent(crosswalk: crosswalk));
                // 스크롤 제거 - 현재 화면 유지
              },
            ),
          ),
        ],
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
