part of 'main.dart';

Future<void> init() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await injection.init();
  await Hive.initFlutter();
  Hive.registerAdapter<Setting>(SettingAdapter());
  Hive.registerAdapter<ColorMode>(ColorModeAdapter());
  Hive.registerAdapter<FlashMode>(FlashModeAdapter());
  await Hive.openBox(SystemTheme.themeBox);
  await Hive.openBox<FlashMode>('flashmode');

  final firestore = DI.get<FirebaseFirestore>();
  CollectionReference collectionRef = firestore.collection('safelight_db');
  QuerySnapshot querySnapshot = await collectionRef.get();
  CrosswalkAPI.map = querySnapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .toList();

  FlutterTts flutterTts = DI.get<FlutterTts>();
  await flutterTts.awaitSpeakCompletion(true);
  await flutterTts.setSharedInstance(true);
  await flutterTts.setVolume(1.0);
  await flutterTts.setIosAudioCategory(
    IosTextToSpeechAudioCategory.playback,
    [IosTextToSpeechAudioCategoryOptions.duckOthers],
  );

  await requestPermissions();
}

Future<void> requestPermissions() async {
  // Step 1: Location 권한 요청 (When in Use → Always)
  final locationWhenInUseStatus = await Permission.locationWhenInUse.request();

  if (locationWhenInUseStatus.isGranted) {
    final locationAlwaysStatus = await Permission.locationAlways.request();

    if (!locationAlwaysStatus.isGranted) {
      debugPrint('Location Always permission denied');
    }
  } else {
    debugPrint('Location When in Use permission denied');
  }

  // Step 2: Bluetooth 권한 요청
  final bluetoothPermissions = await [
    Permission.bluetooth,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
  ].request();

  // Bluetooth 권한 상태 확인
  if (bluetoothPermissions.values.every((status) => status.isGranted)) {
    debugPrint('All Bluetooth permissions granted');
  } else {
    debugPrint('One or more Bluetooth permissions denied');
  }
}