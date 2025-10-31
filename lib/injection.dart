// ignore_for_file: non_constant_identifier_names, constant_identifier_names
library;

import 'dart:io';
import 'package:dio/dio.dart';

// Firebase Firestore 제거 - BLE 직접 연결
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong2/latlong.dart';
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/data/services/navigation_api_service.dart';
import 'package:safelight/data/services/tts_service.dart';
import 'package:safelight/firebase_options.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/data_source.dart';
import 'package:safelight/framework/repository.dart';
import 'package:safelight/framework/usecase.dart';
import 'package:safelight/framework/controller.dart';
import 'package:safelight/data/services/auth_service.dart';

final DI = GetIt.instance;

const String BLOC_BLUE_SEARCH_FINITE = 'BLOC_BLUE_SEARCH_FINITE';
const String BLOC_BLUE_SEARCH_INFINITE = 'BLOC_BLUE_SEARCH_INFINITE';
const String USECASE_SEARCH_CROSSWALK_FINITE =
    'USECASE_SEARCH_CROSSWALK_FINITE';
const String USECASE_SEARCH_CROSSWALK_INFINITE =
    'USECASE_SEARCH_CROSSWALK_INFINITE';
const String USECASE_CONTROL_FLASH_ON = 'USECASE_CONTROL_FLASH_ON';
const String USECASE_CONTROL_FLASH_OFF = 'USECASE_CONTROL_FLASH_OFF';
const String USECASE_SEND_ACOUSTIC_SIGNAL = 'USECASE_SEND_ACOUSTIC_SIGNAL';
const String USECASE_SEND_VOICE_INDUCTOR = 'USECASE_SEND_VOICE_INDUCTOR';
const String USECASE_SEND_VOICE_GUIDE = 'USECASE_SEND_VOICE_GUIDE';
const String USECASE_SIGN_IN_ANONYMOUSLY = 'USECASE_SIGN_IN_ANONYMOUSLY';
const String USECASE_SIGN_OUT_ANONYMOUSLY = 'USECASE_SIGN_OUT_ANONYMOUSLY';

const String USECASE_SIGN_IN_WITH_GOOGLE = 'USECASE_SIGN_IN_WITH_GOOGLE';
const String USECASE_SIGN_OUT_WITH_GOOGLE = 'USECASE_SIGN_OUT_WITH_GOOGLE';

const String USECASE_CONTROL_FLASH_ON_WITH_WEATHER =
    'USECASE_CONTROL_FLASH_ON_WITH_WEATHER';
const String USECASE_SET_BLUETOOTH_PERMISSION =
    'USECASE_SET_BLUETOOTH_PERMISSION';
const String USECASE_SET_LOCATION_PERMISSION =
    'USECASE_SET_LOCATION_PERMISSION';
const String USECASE_GET_BLUETOOTH_PERMISSION =
    'USECASE_GET_BLUETOOTH_PERMISSION';
const String USECASE_GET_LOCATION_PERMISSION =
    'USECASE_GET_LOCATION_PERMISSION';

Future<void> init() async {
  // bloc injection area
  DI.registerLazySingleton(
    () => BluetoothPermissionCubit(
      getPermission: DI(instanceName: USECASE_GET_BLUETOOTH_PERMISSION),
      setPermission: DI(instanceName: USECASE_SET_BLUETOOTH_PERMISSION),
    ),
  );

  DI.registerLazySingleton(
    () => LocationPermissionCubit(
      getPermission: DI(instanceName: USECASE_GET_LOCATION_PERMISSION),
      setPermission: DI(instanceName: USECASE_SET_LOCATION_PERMISSION),
    ),
  );

  DI.registerLazySingleton(
    () => AuthBloc(repository: DI.get<AuthRepository>()),
  );

  DI.registerFactory(
    () => CrosswalkBloc(
      search2FiniteTimes: DI(instanceName: USECASE_SEARCH_CROSSWALK_FINITE),
      search2InfiniteTimes: DI(instanceName: USECASE_SEARCH_CROSSWALK_INFINITE),
      sendAcousticSignal: DI(instanceName: USECASE_SEND_ACOUSTIC_SIGNAL),
      sendVoiceInductor: DI(instanceName: USECASE_SEND_VOICE_INDUCTOR),
      sendVoiceGuide: DI(instanceName: USECASE_SEND_VOICE_GUIDE),
      getCurrentPosition: DI(),
      controlFlashOnWithWeather:
          DI(instanceName: USECASE_CONTROL_FLASH_ON_WITH_WEATHER),
    ),
    instanceName: BLOC_BLUE_SEARCH_FINITE,
  );

  // usecase injection area

  DI.registerLazySingleton<SetPermission>(
    () => SetBluetoothPermission(repository: DI()),
    instanceName: USECASE_SET_BLUETOOTH_PERMISSION,
  );

  DI.registerLazySingleton<SetPermission>(
    () => SetLocationPermission(repository: DI()),
    instanceName: USECASE_SET_LOCATION_PERMISSION,
  );

  DI.registerLazySingleton<GetPermission>(
    () => GetBluetoothPermission(repository: DI()),
    instanceName: USECASE_GET_BLUETOOTH_PERMISSION,
  );

  DI.registerLazySingleton<GetPermission>(
    () => GetLocationPermission(repository: DI()),
    instanceName: USECASE_GET_LOCATION_PERMISSION,
  );

  DI.registerLazySingleton<SignIn>(
    () => SignInAnonymously(repository: DI()),
    instanceName: USECASE_SIGN_IN_ANONYMOUSLY,
  );

  DI.registerLazySingleton<UseCase>(
    () => SignInWithGoogle(repository: DI()),
    instanceName: USECASE_SIGN_IN_WITH_GOOGLE,
  );

  DI.registerLazySingleton<SignOut>(
    () => SignOutAnonymously(repository: DI()),
    instanceName: USECASE_SIGN_OUT_ANONYMOUSLY,
  );

  DI.registerLazySingleton<SignOut>(
    () => SignOutWithGoogle(repository: DI()),
    instanceName: USECASE_SIGN_OUT_WITH_GOOGLE,
  );

  DI.registerLazySingleton<ConnectCrosswalk>(
    () => SendAcousticSignal(repository: DI()),
    instanceName: USECASE_SEND_ACOUSTIC_SIGNAL,
  );
  DI.registerLazySingleton<ConnectCrosswalk>(
    () => SendVoiceInductor(repository: DI()),
    instanceName: USECASE_SEND_VOICE_INDUCTOR,
  );
  DI.registerLazySingleton<ConnectCrosswalk>(
    () => SendVoiceGuide(repository: DI()),
    instanceName: USECASE_SEND_VOICE_GUIDE,
  );
  DI.registerLazySingleton<ControlFlash>(
    () => ControlFlashOn(repository: DI()),
    instanceName: USECASE_CONTROL_FLASH_ON,
  );
  DI.registerLazySingleton<ControlFlash>(
    () => ControlFlashOff(repository: DI()),
    instanceName: USECASE_CONTROL_FLASH_OFF,
  );
  DI.registerLazySingleton<ControlFlash>(
    () => ControlFlashOnWithWeather(repository: DI()),
    instanceName: USECASE_CONTROL_FLASH_ON_WITH_WEATHER,
  );

  DI.registerLazySingleton<SearchCrosswalk>(
    () => Search2FiniteTimes(repository: DI()),
    instanceName: USECASE_SEARCH_CROSSWALK_FINITE,
  );
  DI.registerLazySingleton<SearchCrosswalk>(
    () => Search2InfiniteTimes(repository: DI()),
    instanceName: USECASE_SEARCH_CROSSWALK_INFINITE,
  );

  DI.registerLazySingleton<GetPosition>(
    () => GetCurrentPosition(repository: DI()),
  );

  DI.registerLazySingleton<SendCustomStartPointUseCase>(
    () => SendCustomStartPoint(repository: DI()),
  );

  DI.registerLazySingleton<GetBuildingEntrancesUseCase>(
    () => GetBuildingEntrancesUseCase(repository: DI()),
  );

  // repository injection area
  DI.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(authDataSource: DI()),
  );

  DI.registerLazySingleton(() => AuthService());

  DI.registerLazySingleton<FlashRepository>(
    () => FlashRepositoryImpl(
      flashDataSource: DI(),
      navDataSource: DI(),
      validator: DI(),
      weatherDataSource: DI(),
      allevelDataSource: DI(),
    ),
  );
  DI.registerLazySingleton<PermissionRepository>(
    () => PermissionRepositoryImpl(permissionDataSource: DI()),
  );

  DI.registerLazySingleton<CrosswalkRepository>(
    () => CrosswalkRepositoryImpl(
      blueDataSource: DI(),
      navDataSource: DI(),
      crosswalkDataSource: DI(),
    ),
  );
  DI.registerLazySingleton<NavigatorRepository>(
    () => NavigatorRepositoryImpl(navDataSource: DI()),
  );


  DI.registerLazySingleton<SensorStreams>(() => SensorStreamsImpl());
    
  DI.registerLazySingleton<SensorController>(
    () => SensorControllerImpl(DI<SensorStreams>()),
  );

  DI.registerLazySingleton<RouteController>(() => RouteController(
  mapController: null, // onMapReady에서 주입
  apiService: DI<NavigationApiService>(),
  pdrCalculator: DI<PdrCalculator>(),
  ));

  DI.registerLazySingleton<WeightedAverageFilter>(
  () => WeightedAverageFilter(5, [0.1, 0.2, 0.3, 0.4, 0.5]),
  instanceName: PDR_WEIGTHED_AVERAGE_FILTER_X,
  );
  DI.registerLazySingleton<WeightedAverageFilter>(
  () => WeightedAverageFilter(5, [0.1, 0.2, 0.3, 0.4, 0.5]),
  instanceName: PDR_WEIGTHED_AVERAGE_FILTER_Y,
  );

  DI.registerLazySingleton<PdrCalculator>(
  () => PdrCalculatorImpl(
      filteringX: DI<WeightedAverageFilter>(instanceName: PDR_WEIGTHED_AVERAGE_FILTER_X),
      filteringY: DI<WeightedAverageFilter>(instanceName: PDR_WEIGTHED_AVERAGE_FILTER_Y),
      yawRateAccFilteringValue: 0.3,
      accFilteringValue: 0.06,
      initialLatitude: 37.4865,
      initialLongitude: 126.8018,
    ),
  );

  DI.registerLazySingleton<MapOverlayController>(
      () => MapOverlayController(
        mapController: null, // 초기에는 null (onMapReady에서 주입)
        mapMode: ValueNotifier(MapControlMode.off),
        routeController: DI<RouteController>(),
      ),
    );
  DI.registerLazySingleton<IndexController>(() {
    final routeController  = DI<RouteController>();
    final pdrCalculator    = DI<PdrCalculator>();
    final sensorStreams = DI<SensorStreams>();

    return IndexController(
      routeController: routeController,
      pdrCalculator: pdrCalculator,
      sensorStreams: sensorStreams,
      getCurrentLatitude:  () => pdrCalculator.newlatitude,
      getCurrentLongitude: () => pdrCalculator.newlongitude,
      getCompassDeg:       () => sensorStreams.lastCompassDeg ?? 0.0,
      progressGuardFactor: 0.95,
      debug: true,
    );
  });
    
  DI.registerLazySingleton(() => GuidanceCalculator());

  // datasource injection area
  DI.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      auth: DI(),
      dio: DioClient().dio,
      googleSignIn: GoogleSignIn(
        scopes: scopes,
        clientId: Platform.isIOS
            ? DefaultFirebaseOptions.currentPlatform.iosClientId
            : DefaultFirebaseOptions.currentPlatform.androidClientId,
      ),
    ),
  );

  DI.registerLazySingleton<FlashNativeDataSource>(
    () => FlashNativeDataSourceImpl(),
  );
  DI.registerLazySingleton<BlueNativeDataSource>(
    () => BlueNativeDataSourceImpl(bluetooth: DI()),
  );
  DI.registerLazySingleton<PermissionNativeDataSource>(
    () => PermissionNativeDataSourceImpl(),
  );
  DI.registerLazySingleton<NavigateRemoteDataSource>(
    () => NavigateRemoteDataSourceImpl(geolocator: DI(), dio: DI()),
  );
  DI.registerLazySingleton<CrosswalkRemoteDataSource>(
    () => CrosswalkRemoteDataSourceImpl(distance: DI()),
  );
  DI.registerLazySingleton<WeatherRemoteDataSource>(
    () => WeatherRemoteDataSourceImpl(),
  );
  DI.registerLazySingleton<AmbientLightLevelDataSource>(
    () => AmbientLightLevelDataSourceImpl(),
  );

  // core injection area
  final GeolocatorPlatform geolocator = GeolocatorPlatform.instance;
  DI.registerLazySingleton(() => geolocator);

  const Distance distance = Distance();
  DI.registerLazySingleton(() => distance);

  // FirebaseFirestore 제거 - BLE 직접 연결로 변경

  final FirebaseAuth auth = FirebaseAuth.instance;
  DI.registerLazySingleton(() => auth);

  DI.registerLazySingleton<Dio>(() => Dio()); // 추가

  // TTS
  DI.registerLazySingleton(() => FlutterTts());

  DI.registerLazySingleton<TtsService>(() => TtsService());

  DI.registerLazySingleton<WeatherValidator>(() => WeatherValidator());

  DI.registerLazySingleton<TTS>(() => TTS(tts: DI()));

  DI.registerLazySingleton<Message>(() => Message());

  DI.registerLazySingleton<FlutterReactiveBle>(() => FlutterReactiveBle());

  DI.registerLazySingleton<NavigationApiService>(() => NavigationApiService());
}
