import 'package:flutter_test/flutter_test.dart';
import 'package:location_plugin/location_plugin.dart';
import 'package:location_plugin/location_plugin_platform_interface.dart';
import 'package:location_plugin/location_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLocationPluginPlatform
    with MockPlatformInterfaceMixin
    implements LocationPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LocationPluginPlatform initialPlatform =
      LocationPluginPlatform.instance;

  test('$MethodChannelLocationPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLocationPlugin>());
  });

  test('getPlatformVersion', () async {
    LocationPlugin locationPlugin = LocationPlugin();
    MockLocationPluginPlatform fakePlatform = MockLocationPluginPlatform();
    LocationPluginPlatform.instance = fakePlatform;

    expect(await locationPlugin.getPlatformVersion(), '42');
  });
}
