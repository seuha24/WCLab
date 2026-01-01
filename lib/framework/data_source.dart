library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpResponse, Platform;
import 'package:flutter/services.dart' show rootBundle;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safelight/data/models/auth_data_model.dart';
import 'package:safelight/data/network/api_endpoints.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/object.dart';
import 'package:torch_light/torch_light.dart';
import 'package:safelight/data/services/tts_service.dart';

import 'package:camera/camera.dart' as cam;

import '../injection.dart';

part '../data/sources/blue_native_data_source.dart';
part '../data/sources/auth_remote_data_source.dart';
part '../data/sources/crosswalk_remote_data_source.dart';
part '../data/sources/flash_native_data_source.dart';
part '../data/sources/navigate_remote_data_source.dart';
part '../data/sources/permission_native_data_source.dart';
part '../data/sources/weather_remote_data_source.dart';
part '../data/sources/setting_cache_data_source.dart';

part '../data/sources/ambientlightlevel.data_source.dart';

part '../data/sources/signal_device_local_data_source.dart';
