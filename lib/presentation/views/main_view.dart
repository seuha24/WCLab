part of ui;

/// 네비게이션 프레임
class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final bluetooth = DI.get<FlutterReactiveBle>();

  final List<Widget> _widgetOptions = const <Widget>[
    NaverMapView(),
    //desSearch(),
    SettingView(),
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    DI.get<FlutterTts>().stop();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BleStatus>(
      stream: bluetooth.statusStream,
      initialData: BleStatus.ready,
      builder: (context, snapshot) {
        if (snapshot.data != BleStatus.poweredOff) {
          return Scaffold(
            body: _widgetOptions[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              unselectedItemColor: Theme.of(context).colorScheme.surface,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home_rounded,
                    semanticLabel: '홈 화면 네비게이션 버튼',
                  ),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    semanticLabel: '설정 화면 네비게이션 버튼',
                  ),
                  label: '설정',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).colorScheme.onSecondary,
              onTap: (index) => _onItemTapped(index),
            ),
          );
        } else {
          return BlueOffView(state: snapshot.data!);
        }
      },
    );
  }
}
