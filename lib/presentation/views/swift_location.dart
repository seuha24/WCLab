part of '../../framework/ui.dart';

class SwiftLocationView extends StatefulWidget {
  const SwiftLocationView({super.key});

  @override
  _SwiftLocationState createState() => _SwiftLocationState();
}

class _SwiftLocationState extends State<SwiftLocationView> {
  Map<String, dynamic>? _currentLocation;

  @override
  void initState() {
    super.initState();
    LocationPlugin.locationStream.listen((locationData) {
      setState(() {
        _currentLocation = locationData;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Stream')),
      body: Center(
        child: _currentLocation == null
            ? CircularProgressIndicator()
            : Text(
                'Latitude: ${_currentLocation!['latitude']}\n'
                'Longitude: ${_currentLocation!['longitude']}\n'
                'Accuracy: ${_currentLocation!['horizontalAccuracy']}\n'
                'Time: ${DateTime.fromMillisecondsSinceEpoch((_currentLocation!['time'] * 1000).toInt())}\n',
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}
