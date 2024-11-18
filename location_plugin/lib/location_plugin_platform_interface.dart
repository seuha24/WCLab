import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'location_plugin_method_channel.dart';

abstract class LocationPluginPlatform extends PlatformInterface {
  /// Constructs a LocationPluginPlatform.
  LocationPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static LocationPluginPlatform _instance = MethodChannelLocationPlugin();

  /// The default instance of [LocationPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelLocationPlugin].
  static LocationPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LocationPluginPlatform] when
  /// they register themselves.
  static set instance(LocationPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
