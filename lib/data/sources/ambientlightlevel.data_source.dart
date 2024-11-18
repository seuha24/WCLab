part of data_source;

abstract class AmbientLightLevelDataSource {
  Future<AmbientLightLevelModel> getCurrentAmbientLightLevel();
}

class AmbientLightLevelDataSourceImpl implements AmbientLightLevelDataSource {
  @override
  Future<AmbientLightLevelModel> getCurrentAmbientLightLevel() async {
    final controller = await initFrontCamera();
    Completer<double> completer = Completer<double>();

    controller.startImageStream((image) async {
      double ambientLightLevel = await AmbientLightLevelDataSourceImpl
          .estimateOpacityByAmbientLightLevel(
        sensorExposureTime: image.sensorExposureTime!,
        sensorSensitivity: image.sensorSensitivity!,
        lensAperture: image.lensAperture!,
      );
      completer.complete(ambientLightLevel);
    });

    try {
      double ambientLightLevel = await completer.future;
      return AmbientLightLevelModel(ambientLightLevel: ambientLightLevel);
    } catch (e) {
      return AmbientLightLevelModel(
          ambientLightLevel: 0.0); // or any default value
    } finally {
      await controller.dispose(); // Dispose the camera controller
    }
  }

  static Future<cam.CameraController> initFrontCamera() async {
    final cameras = await cam.availableCameras();
    final firstCamera = cameras[1];
    final controller = cam.CameraController(
      firstCamera,
      cam.ResolutionPreset.ultraHigh,
      imageFormatGroup: cam.ImageFormatGroup.yuv420,
    );
    await controller.initialize();
    return controller;
  }

  static Future<double> estimateOpacityByAmbientLightLevel({
    required int sensorExposureTime,
    required double sensorSensitivity,
    required double lensAperture,
  }) async {
    double ambientLightLevel = ((50 * lensAperture * lensAperture) /
            (sensorExposureTime * sensorSensitivity)) *
        100000000;
    return ambientLightLevel;
  }
}
