// v1.3.1(ios), v1.1.2(android) | 한영찬(hanmango-o) | hanmango.o@gmail.com
library safelight;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safelight/data/services/tts_service.dart';
import 'package:safelight/firebase_options.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/injection.dart' as injection;
import 'package:safelight/injection.dart';


import 'framework/controller.dart';
import 'framework/core.dart';
import 'framework/ui.dart';

part 'initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(
    clientId: 'pzijwnqrpi',
    onAuthFailed: (ex) {
      print("********* 네이버맵 인증오류 : $ex *********");
    },
  );

  await init();
  FlutterNativeSplash.remove();
  // LocationPlugin.register();

  final authService = AuthService();
  final loadedAuthData = await authService.loadAuthData();
  final userName = loadedAuthData['userName'];

  runApp(SafeLight(auth: DI.get<FirebaseAuth>(), userName: userName));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SafeLight extends StatelessWidget {
  final FirebaseAuth auth;
  final String? userName;

  const SafeLight({super.key, required this.auth, required this.userName});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(414, 896),
      builder: (context, child) => ValueListenableBuilder(
        valueListenable: Hive.box(SystemTheme.themeBox).listenable(),
        builder: (context, Box box, widget) {
          String? mode = box.get(
            SystemTheme.mode,
            defaultValue: ThemeMode.system.name,
          );
          TTS.enable = box.get('tts', defaultValue: false);
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => DI.get<CrosswalkBloc>(
                  instanceName: BLOC_BLUE_SEARCH_FINITE,
                ),
              ),
              BlocProvider(
                create: (_) => DI.get<AuthBloc>(),
              ),
              BlocProvider(
                create: (_) => DI.get<BluetoothPermissionCubit>(),
              ),
              BlocProvider(
                create: (_) => DI.get<LocationPermissionCubit>(),
              ),
              BlocProvider(
                create: (context) => SearchBloc(),
              ),
              // BlocProvider(
              //   create: (context) {
              //     final navigationService = NavigationService(DI.get<TtsService>());
              //     return NavigationBloc(DI.get<NavigationApiService>(), navigationService);
              //   },
              // ),
              // BlocProvider(create: (_) => DI.get<NavigationBloc>()),
            ],
            child: MaterialApp(
              navigatorKey: navigatorKey,
              // showSemanticsDebugger: true, // 접근성 테스트할 때 사용
              debugShowCheckedModeBanner: false,
              theme: SystemTheme.systemMode(ColorTheme.light),
              darkTheme: SystemTheme.systemMode(ColorTheme.dark),
              themeMode: ThemeMode.values.byName(mode ?? ThemeMode.system.name),
              home: StreamBuilder(
                stream: DI.get<FirebaseAuth>().authStateChanges(),
                builder: (context, snapshot) {
                  debugPrint('snapshot.data :${snapshot.data}');
                  if (snapshot.data == null) {
                    return const SignInView();
                  } else {
                    final emptyName = userName == '' || userName == null;
                    if (!snapshot.data!.isAnonymous && emptyName) {
                      return const SignInView();
                    } else {
                      return const MainView();
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
