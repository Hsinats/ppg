import 'package:camera/camera.dart';

class CameraData {
  CameraController controller;

  Future<void> initCamera() async {
    List _cameras = await availableCameras();
    controller = CameraController(_cameras.first, ResolutionPreset.low);
    await controller.initialize();
    Future.delayed(Duration(milliseconds: 100)).then((onValue) {
      controller.flash(true);
    });
    controller.startImageStream((CameraImage cameraImage) {});
  }
}
