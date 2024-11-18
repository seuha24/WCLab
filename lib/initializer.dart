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

  await [
    Permission.location,
    Permission.locationAlways,
    Permission.locationWhenInUse,
    Permission.bluetooth,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.bluetoothScan
  ].request();

  await [
    Permission.bluetooth,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.bluetoothScan
  ].request();
}
