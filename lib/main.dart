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
import 'package:safelight/firebase_options.dart';
import 'package:safelight/injection.dart' as injection;
import 'package:safelight/injection.dart';
import 'package:safelight/presentation/views/signup_user_input.dart';

// import 'package:location_plugin/location_plugin.dart';

import 'framework/controller.dart';
import 'framework/core.dart';
import 'framework/ui.dart';

part 'initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(
    clientId: '5eprka27uz',
    onAuthFailed: (ex) {
      print("********* 네이버맵 인증오류 : $ex *********");
    },
  );

  await init();
  FlutterNativeSplash.remove();
  // LocationPlugin.register();
  runApp(SafeLight(auth: DI.get<FirebaseAuth>()));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SafeLight extends StatelessWidget {
  final FirebaseAuth auth;

  const SafeLight({super.key, required this.auth});

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
                  if (snapshot.data == null) {
                    return const SignInView();
                  } else {
                    return const MainView();
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
