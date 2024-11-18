part of ui;

/// 블루투스 꺼짐 화면
class BlueOffView extends StatefulWidget {
  final BleStatus state;

  const BlueOffView({Key? key, required this.state}) : super(key: key);

  @override
  State<BlueOffView> createState() => _BlueOffViewState();
}

class _BlueOffViewState extends State<BlueOffView> {
  final tts = DI.get<TTS>();

  @override
  void initState() {
    super.initState();
    tts('블루투스가 꺼져 있습니다. 블루투스를 켜주세요.');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorTheme.highlight3,
            Theme.of(context).colorScheme.primary
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            '블루투스 상태 : ${widget.state != BleStatus.poweredOff ? '꺼짐' : ''}',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            children: [
              SizedBox(height: SizeTheme.h_lg),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: SizeTheme.h_lg),
                margin: EdgeInsets.all(SizeTheme.w_md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(SizeTheme.r_sm),
                  ),
                  color: const Color.fromARGB(29, 0, 0, 0),
                ),
                child: Center(
                  child: Text(
                    'SafeLight는 블루투스를 켜야 사용할 수 있습니다.',
                    semanticsLabel:
                        'SafeLight는 블루투스를 켜야 사용할 수 있습니다. 블루투스를 켜주세요.',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .apply(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ),
              SizedBox(height: SizeTheme.h_lg),
              Flexible(
                child: Semantics(
                  label: '블루투스 상태 화면 배경',
                  child: Lottie.asset(
                    Gif.LOTTIE_CHECK_BLUE,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
