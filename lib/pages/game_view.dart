import 'dart:async';
import 'dart:typed_data';

import 'package:PPG/functions/smoothing.dart';
import 'package:PPG/widgets/data_chart.dart';
import 'package:PPG/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_camera/camera.dart';
import 'package:wakelock/wakelock.dart';

import 'package:PPG/models/models.dart';

class GameView extends StatefulWidget {
  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  CameraController _cameraController;
  int _fps = 30;
  CameraImage _lastCameraImage;
  List<SensorValue> _redValues = [];
  List<Float64List> smoothedData = [];

  bool gameOn = false;
  Timer _timer;

  @override
  void dispose() {
    _timer?.cancel();
    gameOn = false;
    _disposeController();
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 50),
          Container(
            child: _redValues.length < 2 ? Container() : DataChart(_redValues),
          ),
          Container(
            child: smoothedData.isNotEmpty
                ? SmoothChart(smoothedData)
                : Container(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(gameOn ? Icons.pause : Icons.play_arrow),
          onPressed: gameOn ? _stopGame : _play),
    );
  }

  testing() {
    print('calling to close');
  }

  Future<void> initCameraControler() async {
    try {
      List _cameras = await availableCameras();
      _cameraController =
          CameraController(_cameras.first, ResolutionPreset.low);
      await _cameraController.initialize();
      Future.delayed(Duration(seconds: 1)).then((value) {
        _cameraController.setFlashMode(FlashMode.torch);
      });
      _cameraController.startImageStream((image) {
        // _lastCameraImage = null;
        _lastCameraImage = image;
        // print(ismage);
      });
    } catch (e) {
      print(e.toString());
    }
  }

  _initTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _fps), (timer) {
      if (gameOn) {
        if (_lastCameraImage != null) {
          _scanImage(_lastCameraImage);
          // print(smoothing(_redValues));
          // print(smoothedData.isNotEmpty ? smoothedData[1].length : '');
        }
      } else {
        _timer.cancel();
      }
    });
  }

  _play() {
    _clearCameraFrames();
    initCameraControler().then((value) {
      setState(() {
        gameOn = true;
      });
      Wakelock.enable();
      _initTimer();
    });
  }

  _stopGame() {
    _disposeController();
    Wakelock.disable();
    print('stopping');
    setState(() {
      gameOn = false;
    });
  }

  _scanImage(CameraImage image) {
    DateTime currentTime = DateTime.now();
    double redAvg = _planeAverage(image, 'red');

    _redValues.add(SensorValue(currentTime, redAvg));
    smoothing(_redValues);
    setState(() {});
  }

  _clearCameraFrames() {
    _redValues.clear();
  }

  _disposeController() {
    _cameraController?.dispose();
    _cameraController = null;
  }
}

double _planeAverage(CameraImage image, String color) {
  double ret;
  int colorInt = color == 'red' ? 0 : 1;
  var data = image.planes[colorInt].bytes;
  int imageTally = data.reduce((value, element) => value + element);
  ret = imageTally / data.length;
  return ret;
}
