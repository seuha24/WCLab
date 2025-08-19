part of '../../framework/ui.dart';

class TestView extends StatefulWidget {
  const TestView({Key? key}) : super(key: key);

  @override
  _TestViewState createState() => _TestViewState();
}

class _TestViewState extends State<TestView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈 화면'),
        centerTitle: true,
      ),
      body: Center(
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          padding: EdgeInsets.all(20),
          children: [
            _buildButton(context, '길안내', Colors.red, NaverMapView()),
            _buildButton(context, 'BLE', Colors.blue, HomeView()),
           // _buildButton(context, 'BLE', Colors.blue, BlueOffView(state: BleStatus.poweredOff)),
            _buildButton(context, '경광등', Colors.yellow, FlashlightView(flashOn: DI.get<ControlFlash>(instanceName: USECASE_CONTROL_FLASH_ON), flashOff: DI.get<ControlFlash>(instanceName: USECASE_CONTROL_FLASH_OFF))),
            _buildButton(context, '설정', Colors.green, SettingView()),
            _buildButton(context, '출입구 등록', Colors.purple, EntranceRegistrationView()),
          ],
        ),
      ),
    );
  }

  // 버튼 위젯 생성 함수
  Widget _buildButton(BuildContext context, String label, Color color, Widget nextView) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextView),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.accessibility, // 아이콘을 각 버튼에 맞게 조정 가능
              size: 40,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationGuideView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('길안내 화면')),
      body: Center(child: Text('길안내 화면 내용')),
    );
  }
}

class BleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BLE 화면')),
      body: Center(child: Text('BLE 화면 내용')),
    );
  }
}

class FlashLightView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('경광등 화면')),
      body: Center(child: Text('경광등 화면 내용')),
    );
  }
}

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('설정 화면')),
      body: Center(child: Text('설정 화면 내용')),
    );
  }
}
