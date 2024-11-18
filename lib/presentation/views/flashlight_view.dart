// ignore_for_file: use_build_context_synchronously
part of ui;

/// 안전 경광등 화면
class FlashlightView extends StatefulWidget {
  final ControlFlash flashOn;
  final ControlFlash flashOff;

  const FlashlightView({
    super.key,
    required this.flashOn,
    required this.flashOff,
  });

  @override
  State<FlashlightView> createState() => _FlashlightViewState();
}

class _FlashlightViewState extends State<FlashlightView> {
  final tts = DI.get<TTS>();
  final message = DI.get<Message>();

  @override
  void dispose() {
    super.dispose();
    widget.flashOff(NoParams());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('안전 경광등'),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await widget.flashOn(NoParams());
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
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  backgroundColor: ColorTheme.highlight5,
                ),
                child: const Text('안전 경광등 켜기'),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await widget.flashOff(NoParams());
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
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  backgroundColor: ColorTheme.highlight1,
                ),
                child: const Text(
                  '안전 경광등 끄기',
                  style: TextStyle(
                    color: ColorTheme.highlight6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
