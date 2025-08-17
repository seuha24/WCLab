part of '../../framework/ui.dart';

/// 홈화면
class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final tts = DI.get<TTS>();
  final message = DI.get<Message>();
  bool flashSelected = false;

  List<GlobalKey> keys = [GlobalKey(), GlobalKey()];
  final ControlFlash flashOn = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_ON,
  );
  final ControlFlash flashOff = DI.get<ControlFlash>(
    instanceName: USECASE_CONTROL_FLASH_OFF,
  );
  //아이콘 변경
  IconData getFlashlightIcon() {
    return flashSelected ? Icons.flash_on_rounded : Icons.flash_off_rounded;
  }

//색깔 변경
  Color getFlashlightIconColor() {
    return flashSelected ? Colors.yellow : Colors.black;
  }

  @override
  void initState() {
    super.initState();
    context.read<CrosswalkBloc>().add(SearchInfiniteCrosswalkEvent());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(SizeTheme.r_sm)),
            child: Image(
              semanticLabel: '홈 화면',
              width: 90.w,
              height: 60.h,
              image: AssetImage(Images.AppTitle),
            ),
          ),
          actions: [
            // 설정뷰의 경광등 설정에 따라 값 조절하는 방법
            Semantics(
              child: IconButton(
                onPressed: () {
                  String lightmode = '';
                  Box flashbox = Hive.box<FlashMode>('flashmode');
                  if (flashbox.values.toList().isEmpty) {
                    lightmode = 'alwayson';
                  } else if (flashbox.values.toList()[0] == FlashMode.ALWAYS) {
                    lightmode = 'alwayson';
                  } else if (flashbox.values.toList()[0] ==
                      FlashMode.NEVER_IN_USE) {
                    lightmode = 'alwaysoff';
                  } else if (flashbox.values.toList()[0] ==
                      FlashMode.WITH_WEATHER) {
                    lightmode = 'weathers';
                  }
                  debugPrint('라이트 모드 변경: $lightmode');
                },
                icon: const Icon(Icons.settings),
              ),
            ),
            Semantics(
              label: '자동 스캔 켜기',
              child: IconButton(
                onPressed: () {
                  context
                      .read<CrosswalkBloc>()
                      .add(SearchInfiniteCrosswalkEvent());
                },
                icon: const Icon(Icons.refresh),
              ),
            ),
            Visibility(
              visible: !Platform.isAndroid,
              child: Semantics(
                label: '안전 경광등 페이지 이동',
                child: IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlashlightView(
                        flashOn: DI.get<ControlFlash>(
                          instanceName: USECASE_CONTROL_FLASH_ON,
                        ),
                        flashOff: DI.get<ControlFlash>(
                          instanceName: USECASE_CONTROL_FLASH_OFF,
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.flashlight_on_outlined),
                ),
              ),
            ),

            // 수정 라이트
            Visibility(
              visible: !Platform.isAndroid,
              child: Semantics(
                label: '안전 경광등 페이지 이동',
                child: IconButton(
                    icon: Icon(
                      flashSelected
                          ? Icons.flash_on_rounded //켜졌을때 아이콘 모양
                          : Icons.flashlight_off_outlined, //꺼졌을때 아이콘 모양
                      color: getFlashlightIconColor(), // 켜지고 꺼지는거에 따라 색깔 변경
                    ),
                    onPressed: () async {
                      var FLV = FlashlightView(
                        flashOn: DI.get<ControlFlash>(
                          instanceName: USECASE_CONTROL_FLASH_ON,
                        ),
                        flashOff: DI.get<ControlFlash>(
                          instanceName: USECASE_CONTROL_FLASH_OFF,
                        ),
                      );
                      if (flashSelected == false) {
                        final result = await FLV.flashOn(NoParams());
                        if (result.isLeft()) {
                          tts('안전 경광등을 사용할 수 없습니다.');
                          message.snackbar(
                            context,
                            text: '안전 경광등을 사용할 수 없습니다.',
                            position: SnackBarBehavior.fixed,
                          );
                        } else {
                          tts('안전 경광등이 켜졌습니다.');
                          message.snackbar(
                            context,
                            text: '안전 경광등이 켜졌습니다.',
                            position: SnackBarBehavior.fixed,
                          );
                          setState(() {
                            flashSelected = true;
                          });
                        }
                      } else {
                        final result = await FLV.flashOff(NoParams());
                        if (result.isLeft()) {
                          tts('안전 경광등을 사용할 수 없습니다.');
                          message.snackbar(
                            context,
                            text: '안전 경광등을 사용할 수 없습니다.',
                            position: SnackBarBehavior.fixed,
                          );
                        } else {
                          tts('안전 경광등이 꺼졌습니다.');
                          message.snackbar(
                            context,
                            text: '안전 경광등이 꺼졌습니다.',
                            position: SnackBarBehavior.fixed,
                          );
                          setState(() {
                            flashSelected = false;
                          });
                        }
                      }
                    }),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Flexible(
              child: Board(
                title: '내 주변 횡단보도',
                body: Expanded(
                  child: BlocConsumer<CrosswalkBloc, CrosswalkState>(
                    listener: (context, state) {
                      if (state is SearchOn) {
                        if (state.infinite) {
                          message.snackbar(
                            context,
                            text: '자동으로 내 주변 횡단보도에 연결중입니다.',
                            margin: EdgeInsets.only(
                              bottom: 90.h,
                            ),
                          );
                        }
                      } else if (state is SearchOff) {
                        if (state.results.isEmpty) {
                          message.snackbar(
                            context,
                            text: '주변에 스마트압버튼이 없습니다.',
                            margin: EdgeInsets.only(
                              bottom: 90.h,
                            ),
                          );
                        } else {
                          message.snackbar(
                            context,
                            text: '${state.results.length} 개의 스마트 압버튼을 찾았습니다.',
                            margin: EdgeInsets.only(
                              bottom: 90.h,
                            ),
                          );
                        }
                      } else if (state is CrosswalkError) {
                        message.snackbar(
                          context,
                          text: state.message,
                          margin: EdgeInsets.only(
                            bottom: 90.h,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is SearchOn) {
                        if (state.infinite) {
                          return resultBody(
                            context: context,
                            title: '자동으로 내 주변 횡단보도에 연결중입니다.',
                            chip: Align(
                              alignment: Alignment.topLeft,
                              child: Chip(
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                avatar: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: CupertinoActivityIndicator(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                label: Text(
                                  '자동 스캔',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .apply(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ),
                            ),
                            image: Semantics(
                              label: '자동 스캔 이미지',
                              child: Lottie.asset(
                                Gif.LOTTIE_SEARCH,
                              ),
                            ),
                          );
                        } else {
                          return Shimmer.fromColors(
                            baseColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(80),
                            highlightColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(120),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemBuilder: (_, __) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: SizeTheme.h_lg,
                                  vertical: SizeTheme.w_sm,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: SizeTheme.w_sm,
                                      ),
                                    ),
                                    Container(
                                      width: 62.w,
                                      height: 62.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(SizeTheme.r_sm),
                                        ),
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 230.w,
                                          height: 16.h,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(SizeTheme.r_sm),
                                            ),
                                            color: Colors.white,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5.h),
                                        ),
                                        Container(
                                          width: 143.w,
                                          height: 16.h,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(SizeTheme.r_sm),
                                            ),
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              itemCount: 3,
                            ),
                          );
                        }
                      } else if (state is SearchOff) {
                        if (state.results.isEmpty) {
                          return resultBody(
                            context: context,
                            title: '주변에 스마트 압버튼이 없습니다.',
                            image: Semantics(
                              label: '압버튼 없음',
                              child: Lottie.asset(
                                Gif.LOTTIE_EMPTY,
                                fit: BoxFit.fill,
                                repeat: false,
                              ),
                            ),
                          );
                        } else {
                          return ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(
                              horizontal: SizeTheme.w_md,
                            ),
                            itemCount: state.results.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: SizeTheme.w_sm,
                                  horizontal: SizeTheme.h_lg,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    SizeTheme.r_sm,
                                  ),
                                ),
                                onTap: () {
                                  showModalBottomSheet(
                                    isScrollControlled: true,
                                    barrierColor: Theme.of(context)
                                        .colorScheme
                                        .onSecondary
                                        .withAlpha(100),
                                    context: context,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    isDismissible: false,
                                    builder: (BuildContext context) {
                                      return SizedBox(
                                        height: 700.h,
                                        child: Board(
                                          title: '안전 리모콘',
                                          headerPadding: EdgeInsets.all(
                                            SizeTheme.w_md,
                                          ),
                                          titleStyle: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                          trailing: TextButton(
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxWidth: 50.w),
                                              child: const FittedBox(
                                                  child: Text('닫기')),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          body: Expanded(
                                            child: SizedBox(
                                              height: 600.h,
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: ListView(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                scrollDirection:
                                                    Axis.horizontal,
                                                children: <Widget>[
                                                  _renderSelectedMode(
                                                    context,
                                                    state.results[index],
                                                    index,
                                                  ),
                                                  _renderAfterModeSelected(
                                                    context,
                                                    state.results[index],
                                                    index,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ).whenComplete(() async {
                                    flashOff(NoParams());

                                    this
                                        .context
                                        .read<CrosswalkBloc>()
                                        .add(SearchInfiniteCrosswalkEvent());
                                  }).timeout(
                                    const Duration(minutes: 3),
                                    onTimeout: () {
                                      Navigator.pop(this.context);
                                    },
                                  );
                                },
                                leading: state.results[index].type ==
                                        ECrosswalk.UNKNOWN
                                    ? null
                                    : SingleChildRoundedCard(
                                        child: Image(
                                          width: 42.w,
                                          height: 42.w,
                                          image: AssetImage(
                                            state.results[index].type ==
                                                    ECrosswalk.SINGLE_ROAD
                                                ? Images.TrafficSingle
                                                : state.results[index].type ==
                                                        ECrosswalk.INTERSECTION
                                                    ? Images.TrafficCross
                                                    : Images.TrafficYellow,
                                          ),
                                        ),
                                      ),
                                title: state.results[index].type ==
                                        ECrosswalk.UNKNOWN
                                    ? null
                                    : RichText(
                                        text: TextSpan(
                                          text: state.results[index].type ==
                                                  ECrosswalk.SINGLE_ROAD
                                              ? '단일 신호등 지역'
                                              : state.results[index].type ==
                                                      ECrosswalk.INTERSECTION
                                                  ? '교차로 지역'
                                                  : '점멸 신호등 지역',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .apply(
                                                color: state.results[index]
                                                            .type ==
                                                        ECrosswalk.SINGLE_ROAD
                                                    ? ColorTheme.highlight3
                                                    : state.results[index]
                                                                .type ==
                                                            ECrosswalk
                                                                .INTERSECTION
                                                        ? ColorTheme.highlight2
                                                        : ColorTheme.highlight1,
                                              ),
                                          children: [
                                            const TextSpan(text: ' '),
                                            TextSpan(
                                              text: state.results[index].dir ??
                                                  '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                subtitle: Text(
                                  state.results[index].name,
                                  style:
                                      Theme.of(context).textTheme.headlineLarge,
                                ),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return SizedBox(height: SizeTheme.h_sm);
                            },
                          );
                        }
                      } else if (state is CrosswalkError) {
                        return resultBody(
                          context: context,
                          title: state.message,
                          image: Semantics(
                            label: '에러 이미지',
                            child: Lottie.asset(
                              Gif.LOTTIE_STOP_SIGN,
                              fit: BoxFit.fill,
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 35.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                minimumSize: Size(double.maxFinite, 90.h),
                maximumSize: Size(double.maxFinite, 90.h),
              ),
              onPressed: () {
                context.read<CrosswalkBloc>().add(SearchFiniteCrosswalkEvent());
              },
              icon: BlocBuilder<CrosswalkBloc, CrosswalkState>(
                builder: (_, state) {
                  if (state is SearchOn) {
                    return const Icon(Icons.stop_circle_outlined);
                  } else if (state is SearchOff) {
                    return const Icon(Icons.search);
                  } else {
                    return const Icon(Icons.pause_circle_outline);
                  }
                },
              ),
              label: FittedBox(
                child: Text(
                  '횡단보도 압버튼 찾기',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .apply(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container resultBody({
    required BuildContext context,
    required String title,
    required Widget image,
    Widget? chip,
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: SizeTheme.w_md,
        right: SizeTheme.w_md,
        bottom: SizeTheme.w_md,
      ),
      padding: EdgeInsets.all(SizeTheme.w_sm),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(
          SizeTheme.r_sm,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          chip ?? const SizedBox(),
          Flexible(
            child: image,
          ),
          Container(
            constraints: BoxConstraints(maxHeight: 70.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(
                SizeTheme.r_sm,
              ),
            ),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: SizeTheme.h_md,
            ),
            child: Center(
              child: FittedBox(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .apply(color: Theme.of(context).colorScheme.onSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _renderAfterModeSelected(
      BuildContext context, Crosswalk crosswalk, int index) {
    return Container(
      key: keys[1],
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
        horizontal: SizeTheme.w_md,
      ),
      child: BlocConsumer<CrosswalkBloc, CrosswalkState>(
        listener: (context, state) {
          if (state is CrosswalkError) {
            message.snackbar(
              context,
              text: state.message,
              duration: const Duration(seconds: 4),
            );
          } else if (state is ConnectOff) {
            if (state.enableCompass && state.latLng != null) {
              message.snackbar(
                context,
                text: '진동이 울리지 않는 방향으로 보행하세요.',
                duration: const Duration(seconds: 4),
              );
            } else {
              message.snackbar(
                context,
                text: '음향신호기의 안내에 따라 보행하세요.',
                duration: const Duration(seconds: 4),
              );
            }
          }
        },
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

  Container _renderSelectedMode(
      BuildContext context, Crosswalk crosswalk, int index) {
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
              title: '음성 유도',
              titleOnly: true,
              leading: const Icon(
                Icons.location_pin,
                color: ColorTheme.highlight3,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onTap: () {
                this
                    .context
                    .read<CrosswalkBloc>()
                    .add(SendVoiceInductorEvent(crosswalk: crosswalk));
                Scrollable.ensureVisible(
                  keys[1].currentContext!,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: SizeTheme.h_md,
            ),
            child: FlatCard(
              title: '압버튼 누르기',
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
                this
                    .context
                    .read<CrosswalkBloc>()
                    .add(SendAcousticSignalEvent(crosswalk: crosswalk));
                Scrollable.ensureVisible(
                  keys[1].currentContext!,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
