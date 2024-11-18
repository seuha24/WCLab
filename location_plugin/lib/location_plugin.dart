import 'dart:async';
import 'package:flutter/services.dart';
import 'package:location_plugin/location_plugin_platform_interface.dart';

class LocationPlugin {
  static const EventChannel _channel = EventChannel('location_stream');

  static Stream<Map<String, dynamic>> _locationStream =
      _channel.receiveBroadcastStream().map((dynamic event) {
    return Map<String, dynamic>.from(event);
  });

  static Stream<Map<String, dynamic>> get locationStream => _locationStream;

  Future<String?> getPlatformVersion() {
    return LocationPluginPlatform.instance.getPlatformVersion();
  }

  static void register() {
    // Event channel 등록
    _channel.receiveBroadcastStream().listen((dynamic event) {
      // 위치 정보 수신
    });
  }
}
