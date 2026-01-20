library;

// =====================================================================
// Dart Standard Library
// =====================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

// =====================================================================
// Flutter Core
// =====================================================================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// =====================================================================
// External Packages (Alphabetical)
// =====================================================================
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';

// =====================================================================
// Project - Framework
// =====================================================================
import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/object.dart';
import 'package:safelight/framework/usecase.dart';
import 'package:safelight/framework/controller.dart';

// =====================================================================
// Project - Core & Data
// =====================================================================
import 'package:safelight/core/utils/app_sizes.dart';
import 'package:safelight/core/utils/status_enum.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/data/services/tts_service.dart';
import 'package:safelight/core/utils/tts_messages.dart';
import 'package:safelight/domain/entities/place_result.dart';
import 'package:safelight/domain/repositories/kakao_repository.dart';
import 'package:safelight/injection.dart';

// =====================================================================
// Project - Presentation
// =====================================================================
import 'package:safelight/presentation/views/signup_user_input.dart';
import 'package:safelight/presentation/widgets/custom_toast.dart';
import 'package:safelight/presentation/widgets/gap.dart';

// Independent Panel Views (Imports)
import 'package:safelight/presentation/views/favorite_views/favorite_main_panel_view.dart';

// =====================================================================
// Part Files - Main Views
// =====================================================================
part '../presentation/views/main_view.dart';
part '../presentation/views/map_view.dart';
part '../presentation/views/sign_in_view.dart';
part '../presentation/views/tutorial_view.dart';
part '../presentation/views/blue_off_view.dart';

// =====================================================================
// Part Files - Search Views
// =====================================================================
part '../presentation/views/destination_search_view.dart';
part '../presentation/views/startspot_search_view.dart';
part '../presentation/views/destination_picker_view.dart';

// =====================================================================
// Part Files - Panel Views
// =====================================================================
part '../presentation/views/map_panel_view.dart';
part '../presentation/views/crosswalk_panel_view.dart';
part '../presentation/views/setting_panel_view.dart';
part '../presentation/views/entrance_views/entrance_selection_panel.dart';
part '../presentation/views/entrance_views/entrance_registration_panel_view.dart';

// =====================================================================
// Part Files - Widgets
// =====================================================================
part '../presentation/widgets/board.dart';
part '../presentation/widgets/flat_card.dart';
part '../presentation/widgets/single_child_rounded_card.dart';
