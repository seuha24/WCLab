library ;

import 'dart:math' as math;
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:latlong2/latlong.dart';
import 'package:safelight/data/models/auth_data_model.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/data_source.dart';
import 'package:safelight/framework/object.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:safelight/core/utils/weighted_average_filter.dart';

part '../domain/repositories/auth_repository.dart';
part '../domain/repositories/crosswalk_repository.dart';
part '../domain/repositories/flash_repository.dart';
part '../domain/repositories/navigator_repository.dart';
part '../domain/repositories/permission_repository.dart';
part '../domain/repositories/accelerometer_repository.dart';
part '../domain/repositories/sensor_controller_repository.dart';

part '../domain/repositories/sensor_streams_repository.dart';
part '../domain/repositories/pdr_calculator_repository.dart';

part '../data/repositories/auth_repository_impl.dart';
part '../data/repositories/crosswalk_repository_impl.dart';
part '../data/repositories/flash_repository_impl.dart';
part '../data/repositories/navigator_repository_impl.dart';
part '../data/repositories/permission_repository_impl.dart';
part '../data/repositories/accelerometer_repository_impl.dart';
part '../data/repositories/sensor_controller_repository_impl.dart';
part '../data/repositories/sensor_streams_repository_impl.dart';
part '../data/repositories/pdr_calculator_repository_impl.dart';