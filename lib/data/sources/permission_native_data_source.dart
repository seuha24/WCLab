part of data_source;

abstract class PermissionNativeDataSource {
  Future<bool> getBluetoothPermissionStatus();
  Future<bool> getLocationPermissionStatus();
  Future<bool> getCameraPermissionStatus();
  Future<void> setBluetoothPermission();
  Future<void> setLocationPermission();
  Future<void> setCameraPermission();
}

class PermissionNativeDataSourceImpl implements PermissionNativeDataSource {
  @override
  Future<bool> getBluetoothPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.bluetoothAdvertise.isGranted &&
            await Permission.bluetoothConnect.isGranted &&
            await Permission.bluetoothScan.isGranted) {
          return true;
        } else if (await Permission.bluetoothAdvertise.isPermanentlyDenied ||
            await Permission.bluetoothConnect.isPermanentlyDenied ||
            await Permission.bluetoothScan.isPermanentlyDenied) {
          return false;
        } else if (await Permission.bluetoothAdvertise.isDenied ||
            await Permission.bluetoothConnect.isDenied ||
            await Permission.bluetoothScan.isDenied) {
          return false;
        }
      } else {
        switch (await Permission.bluetooth.status) {
          case PermissionStatus.limited:
          case PermissionStatus.granted:
          case PermissionStatus.provisional:
            return true;
          case PermissionStatus.permanentlyDenied:
          case PermissionStatus.restricted:
          case PermissionStatus.denied:
            return false;
        }
      }
      return false;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<bool> getLocationPermissionStatus() async {
    try {
      switch (await Permission.location.status) {
        case PermissionStatus.granted:
        case PermissionStatus.limited:
        case PermissionStatus.provisional:
          return true;
        case PermissionStatus.denied:
        case PermissionStatus.restricted:
        case PermissionStatus.permanentlyDenied:
          return false;
      }
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<bool> getCameraPermissionStatus() async {
    try {
      switch (await Permission.location.status) {
        case PermissionStatus.granted:
        case PermissionStatus.limited:
        case PermissionStatus.provisional:
          return true;
        case PermissionStatus.denied:
        case PermissionStatus.restricted:
        case PermissionStatus.permanentlyDenied:
          return false;
      }
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> setBluetoothPermission() async {
    try {
      if (await getBluetoothPermissionStatus() ||
          await Permission.bluetooth.status ==
              PermissionStatus.permanentlyDenied) {
        openAppSettings();
      } else {
        await [
          Permission.bluetooth,
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.bluetoothScan
        ].request();
      }
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> setLocationPermission() async {
    try {
      if (await getLocationPermissionStatus() ||
          await Permission.location.status ==
              PermissionStatus.permanentlyDenied) {
        openAppSettings();
      } else {
        await Permission.location.request();
      }
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> setCameraPermission() async {
    try {
      if (await getCameraPermissionStatus() ||
          await Permission.camera.status ==
              PermissionStatus.permanentlyDenied) {
        openAppSettings();
      } else {
        await Permission.location.request();
      }
    } catch (e) {
      throw CacheException();
    }
  }
}
