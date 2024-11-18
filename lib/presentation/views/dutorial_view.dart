part of ui;

/// 도움말 화면
class DutorialView extends StatefulWidget {
  const DutorialView({super.key});

  @override
  State<DutorialView> createState() => _DutorialViewState();
}

class _DutorialViewState extends State<DutorialView> {
  int _currentIndex = 0;

  List<GlobalKey> keys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도움말'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Flexible(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: [
                buildPage1(context),
                buildPage2(context),
                buildPage3(context),
                buildPage4(context),
                buildPage5(context),
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(minHeight: 110.h),
            child: Row(
              children: [
                Visibility(
                  visible: _currentIndex != 0,
                  child: Flexible(
                    child: InkWell(
                      onTap: () {
                        if (_currentIndex != 0) {
                          setState(() {
                            Scrollable.ensureVisible(
                              keys[--_currentIndex].currentContext!,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            );
                          });
                        }
                      },
                      child: Container(
                        color: ColorTheme.highlight1,
                        padding: EdgeInsets.only(bottom: SizeTheme.h_sm),
                        constraints: BoxConstraints(minHeight: 110.h),
                        child: Center(
                          child: Text(
                            '이전',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge!
                                .apply(color: const Color(0xff2A2C41)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: true,
                  child: Flexible(
                    child: InkWell(
                      onTap: () async {
                        if (_currentIndex == keys.length - 1) {
                          Navigator.pop(context);
                        } else {
                          await Scrollable.ensureVisible(
                            keys[++_currentIndex].currentContext!,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                          );
                          setState(() {});
                        }
                      },
                      child: Container(
                        color: Theme.of(context).colorScheme.primary,
                        constraints: BoxConstraints(minHeight: 110.h),
                        padding: EdgeInsets.only(bottom: SizeTheme.h_sm),
                        child: Center(
                          child: Text(
                            _currentIndex == keys.length - 1 ? '종료' : '다음',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge!
                                .apply(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container buildPage5(BuildContext context) {
    return Container(
      key: keys[4],
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(bottom: SizeTheme.w_md),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Board(
              title: 'Q. 안전 경광등은 무엇인가요?',
              titleStyle: Theme.of(context).textTheme.titleLarge,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
                child: SingleChildRoundedCard(
                  padding: EdgeInsets.all(SizeTheme.w_md),
                  width: double.infinity,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Column(
                    children: [
                      Text(
                        ' 안전 경광등은 시야가 확보되지 않는 상황에서 보행자의 위치를 알려주는 기능입니다.\n\n스마트폰의 카메라 후래쉬를 주기적으로 켜고 끔으로서 보행자의 스마트 폰을 경광등처럼 사용할 수 있습니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: SizeTheme.h_lg),
                      Image.network(
                        'https://github.com/WclLab/safelight-storage/blob/master/4.png?raw=true',
                        fit: BoxFit.fitHeight,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Board(
              title: 'Q. 안전 경광등은 언제 사용할 수 있나요?',
              titleStyle: Theme.of(context).textTheme.titleLarge,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
                child: SingleChildRoundedCard(
                  padding: EdgeInsets.all(SizeTheme.w_md),
                  width: double.infinity,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Column(
                    children: [
                      Text(
                        ' 안전 경광등은 안전 리모콘의 음성 유도, 압버튼 누르기 버튼을 누를 때, 경광등 알고리즘에 의해 시야가 확보되지 않는 상황이라 판단되면 자동적으로 켜지게 됩니다.\n\n 또한 홈 화면 오른쪽 상단의 버튼을 눌러 안전 경광등 기능만 따로 사용할 수 있습니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container buildPage4(BuildContext context) {
    return Container(
      key: keys[3],
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(bottom: SizeTheme.w_md),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Board(
              title: 'Q. 안전 나침반은 무엇인가요?',
              titleStyle: Theme.of(context).textTheme.titleLarge,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
                child: SingleChildRoundedCard(
                  padding: EdgeInsets.all(SizeTheme.w_md),
                  width: double.infinity,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Column(
                    children: [
                      Text(
                        ' 안전 나침반은 점자 블록이 없는 횡단보도 위에서 보행자가 반대편으로 안전하게 건널 수 있게 도와줍니다. 보행자가 걸어가야 하는 방향을 진동과 나침반 UI를 통해 나타냅니다.\n\n잘못된 방향으로 걸어갈 경우 진동이 울리게 되며, 진동이 울리지 않는 방향으로 보행하도록 유도합니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: SizeTheme.h_sm),
                      TextButton(
                        onPressed: () {
                          if (Platform.isAndroid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Semantics.fromProperties(
                                  properties: SemanticsProperties(
                                    liveRegion: true,
                                  ),
                                  child: Text('안드로이드에서는 사용할 수 없습니다.'),
                                ),
                              ),
                            );
                          } else {
                            final tts = DI.get<TTS>();
                            tts('안전 나침반이 켜집니다. 진동이 울리지 않는 방향으로 보행하세요.');
                            showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              builder: (context) {
                                return SizedBox(
                                  height: 680.h,
                                  child: Scaffold(
                                    body: Padding(
                                      padding: EdgeInsets.all(SizeTheme.w_md),
                                      child: Compass(
                                        latLng: LatLng(0, 0),
                                        pos: LatLng(90, 90),
                                        end: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('종료'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                        child: Text(
                          '안전 나침반 체험하기',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge!
                              .apply(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      SizedBox(height: SizeTheme.h_sm),
                      Image.network(
                        'https://github.com/WclLab/safelight-storage/blob/master/5.png?raw=true',
                        fit: BoxFit.fitHeight,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container buildPage3(BuildContext context) {
    return Container(
      key: keys[2],
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(bottom: SizeTheme.w_md),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Board(
              title: 'Q. 안전 리모콘은 무엇인가요?',
              titleStyle: Theme.of(context).textTheme.titleLarge,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
                // padding: EdgeInsets.zero,
                child: SingleChildRoundedCard(
                  padding: EdgeInsets.all(SizeTheme.w_md),
                  width: double.infinity,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Column(
                    children: [
                      Text(
                        ' 검색된 횡단보도를 누르면 안전 리모콘 창이 뜨게 됩니다. 안전 리모콘에서 음향 신호기에 음성 유도와 압버튼 누르기 기능을 사용할 수 있습니다.\n\n 음성 유도 버튼이나 압버튼 누르기 버튼을 누를 경우, 날씨에 따라 안전 경광등 기능이 켜지게 됩니다. 또한 안전 나침반 기능이 자동으로 켜지게 됩니다',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: SizeTheme.h_lg),
                      Image.network(
                        'https://github.com/WclLab/safelight-storage/blob/master/3.png?raw=true',
                        fit: BoxFit.fitHeight,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Board(
              title: 'Q. 안전 리모콘은 어떤 기능이 있나요?',
              titleStyle: Theme.of(context).textTheme.titleLarge,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
                // padding: EdgeInsets.zero,
                child: SingleChildRoundedCard(
                  padding: EdgeInsets.all(SizeTheme.w_md),
                  width: double.infinity,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Column(
                    children: [
                      Text(
                        ' 안전 리모콘은 음성 유도와 압버튼 나누기 기능이 있습니다.\n\n음성 유도는 음향 신호기 유도, 압버튼 누르기는 해당 횡단보도의 압버튼을 누르는 기능을 하게 됩니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container buildPage2(BuildContext context) {
    return Container(
      key: keys[1],
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(bottom: SizeTheme.w_md),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Board(
              title: 'Q. 주변 음향신호기는 어떻게 찾나요?',
              titleStyle: Theme.of(context).textTheme.titleLarge,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
                child: SingleChildRoundedCard(
                  padding: EdgeInsets.all(SizeTheme.w_md),
                  width: double.infinity,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Column(
                    children: [
                      Text(
                        ' 홈화면 하단에 횡단보도 압버튼 찾기 버튼을 눌러 내 주변 음향신호기를 찾을 수 있습니다.\n\n검색된 횡단보도는 홈화면에 출력되게 됩니다. 출력된 횡단보도를 눌러 안전 리모컨 기능을 사용할 수 있습니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: SizeTheme.h_lg),
                      Image.network(
                        'https://github.com/WclLab/safelight-storage/blob/master/2.png?raw=true',
                        // height: 300,
                        fit: BoxFit.fitHeight,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container buildPage1(BuildContext context) {
    return Container(
      key: keys[0],
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(bottom: SizeTheme.w_md),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Board(
              title: 'Q. SafeLight란 무엇인가요?',
              titleStyle: Theme.of(context).textTheme.titleLarge,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
                // padding: EdgeInsets.zero,
                child: SingleChildRoundedCard(
                  padding: EdgeInsets.all(SizeTheme.w_md),
                  width: double.infinity,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Column(
                    children: [
                      Text(
                        ' 오늘도 걷는 당신을 위한 등대, SafeLight는 시각장애인의 안전한 횡단보도 보행을 돕는 보행 보조 앱입니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: SizeTheme.h_lg),
                      Image.network(
                        'https://github.com/WclLab/safelight-storage/blob/master/1.png?raw=true',
                        // height: 300,
                        fit: BoxFit.fitHeight,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Board(
              title: 'Q. 어떤 기능이 있나요?',
              titleStyle: Theme.of(context).textTheme.titleLarge,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeTheme.w_md),
                // padding: EdgeInsets.zero,
                child: SingleChildRoundedCard(
                  padding: EdgeInsets.all(SizeTheme.w_md),
                  width: double.infinity,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Text(
                      ' SafeLight의 주요 기능은 주변 횡단보도의 음향신호기를 찾고, 동작시키는 안전 리모컨 기능입니다.\n\n v1.2 에서는 기존 시각장애인용 리모컨의 기능을 앱을 통해 수행할 수 있습니다. 또한, 시야가 확보되지 않는 밤길 안전을 위한 안전 경광등 기능과 횡단보도 보행 중 정확한 방향을 잡아주는 안전 나침반 기능도 사용할 수 있습니다.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
