library ui;

//import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelight/core/utils/status_enum.dart';
import 'package:safelight/infrastructure/services/auth_service.dart';
import 'package:safelight/presentation/views/signup_user_input.dart';
import 'package:safelight/presentation/widgets/custom_toast.dart';
import 'package:safelight/presentation/widgets/gap.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_plugin/location_plugin.dart';
import 'package:lottie/lottie.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vibration/vibration.dart';

import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/object.dart';
import 'package:safelight/framework/usecase.dart';
import 'package:safelight/framework/controller.dart';
import 'package:safelight/injection.dart';
import 'package:shimmer/shimmer.dart';

part '../presentation/views/blue_off_view.dart';
part '../presentation/views/dutorial_view.dart';
part '../presentation/views/flashlight_view.dart';
part '../presentation/views/home_view.dart';
part '../presentation/views/main_view.dart';
part '../presentation/views/setting_view.dart';
part '../presentation/views/sign_in_view.dart';
part '../presentation/views/map_view.dart';
part '../presentation/views/destination_search_view.dart';
part '../presentation/views/swift_location.dart';
part '../presentation/views/startspot_search_view.dart';

part '../presentation/widgets/board.dart';
part '../presentation/widgets/compass.dart';
part '../presentation/widgets/flat_card.dart';
part '../presentation/widgets/single_child_rounded_card.dart';
