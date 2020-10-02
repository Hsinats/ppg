import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

import 'package:PPG/models/models.dart';
import 'package:PPG/functions/functions.dart';

class GameView extends StatefulWidget {
  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  CameraController _cameraController;
  int _fps = 30;
  CameraImage _lastCameraImage;
  List<SensorValue> _greenValues = [];
  List<SensorValue> _redValues = [];

  bool gameOn = false;
  // DateTime _gameStartTime;
  Timer _timer;

  @override
  void dispose() {
    // _timer?.cancel();
    // _toggled = false;
    // _disposeController();
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          FloatingActionButton(onPressed: gameOn ? _play : print),
    );
  }

  Future<void> initCameraControler() async {
    try {
      List _cameras = await availableCameras();
      _cameraController =
          CameraController(_cameras.first, ResolutionPreset.low);
      _cameraController.initialize();
      Future.delayed(Duration(milliseconds: 100)).then((value) {
        _cameraController.flash(true);
      });
      _cameraController.startImageStream((CameraImage image) {
        _lastCameraImage = image;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  _initTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _fps), (timer) {
      if (gameOn) {
        if (_lastCameraImage != null) _scanImage();
      }
    });
  }

  _play() {
    _clearCameraFrames();
    initCameraControler();
    // _gameStartTime = DateTime.now();
    _initTimer();
  }

  _scanImage() {
    DateTime currentTime = DateTime.now();
    double greenAvg = _planeAverage('green');
    double redAvg = _planeAverage('red');

    _greenValues.add(SensorValue(currentTime, greenAvg));
    _redValues.add(SensorValue(currentTime, redAvg));
    setState(() {});
  }

  double _planeAverage(String color) {
    double ret;
    int colorInt = color == 'red' ? 0 : 1;
    int tally = 0;
    int imageTally = _lastCameraImage.planes[colorInt].bytes
        .reduce((value, element) => _incrementWithPixel(value, element, tally));
    ret = imageTally / tally;
    return ret;
  }

  int _incrementWithPixel(int value, int element, int tally) {
    int ret;
    if (element != 255) {
      tally++;
      ret = value + element;
    } else {
      ret = value;
    }
    return ret;
  }

  _clearCameraFrames() {
    _greenValues.clear();
    _redValues.clear();
  }
}
