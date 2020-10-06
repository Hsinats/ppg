import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:PPG/functions/smoothing.dart';
import 'package:PPG/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  int frameTally = 0;

  List<Float64List> data = [];

  bool gameOn = false;
  Timer _timer;
  DateTime lastHRV;
  int hrv;

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
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: OrientationBuilder(builder: (context, orientation) {
        return orientation == Orientation.portrait
            ? _ScaffoldBodyPortrait()
            : _ScaffoldBodyLandscape();
      }),
      // body: Column(
      //   children: [
      //     SizedBox(height: 50),
      //     Container(
      //       child: _redValues.length < 2
      //           ? Container()
      //           : DataChart(_redValues, width),
      //     ),
      //     Container(
      //       child: data.isNotEmpty ? SmoothChart(data, width) : Container(),
      //     )
      //   ],
      // ),
      floatingActionButton: FloatingActionButton(
          child: Icon(gameOn ? Icons.pause : Icons.play_arrow),
          onPressed: gameOn ? _stopGame : _play),
    );
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
        _lastCameraImage = image;
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
          frameTally++;
          if (frameTally >= 200) {
            data = smoothing(_redValues);
            print(data[0].length);
            frameTally = 0;
            setState(() {});
          }
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
      lastHRV = DateTime.now();
      _initTimer();
    });
  }

  _stopGame() {
    _disposeController();
    lastHRV = null;
    Wakelock.disable();
    setState(() {
      gameOn = false;
    });
  }

  _scanImage(CameraImage image) {
    DateTime currentTime = DateTime.now();
    double redAvg = _planeAverage(image, 'red');

    _redValues.add(SensorValue(currentTime, redAvg));

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

class _ScaffoldBodyPortrait extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.blue),
        )
      ],
    );
  }
}

class _ScaffoldBodyLandscape extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.pink[200]),
        ),
        Swimmer(),
        Water(height, width),
        Waves(width),
      ],
    );
  }
}

class Waves extends StatelessWidget {
  final width;

  Waves(this.width);
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: WavesPainter(width),
    );
  }
}

class WavesPainter extends CustomPainter {
  double width;
  List<SensorValue> data;

  WavesPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 101) {
      return;
    }

    //generate trapezoids
    List<Trapezoid> trapezoids = _generateTrapezoid(width, data);

    // paint waves
    for (Trapezoid trapezoid in trapezoids) {
      canvas.drawLine(Offset(0, trapezoid.y1), Offset(1, trapezoid.y1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

List<Trapezoid> _generateTrapezoid(double width, List<SensorValue> data) {
  double min;
  double max;
  List<Trapezoid> ret = [];

  data.forEach((element) {
    if (min == null) {
      min = element.value;
      max = element.value;
    } else if (element.value > max) {
      max = element.value;
    } else if (element.value < min) {
      min = element.value;
    }
  });

  double maxMinDiff = max - min;

  for (int i = 0; i < data.length - 1; i++) {
    double y1 = (max - data[i].value) / maxMinDiff;
    double y2 = (max - data[i + 1].value) / maxMinDiff;
    ret.add(Trapezoid(y1: y1, y2: y2));
  }
  return ret;
}

class Trapezoid {
  Trapezoid({
    @required this.y1,
    @required this.y2,
  });

  double y1;
  double y2;
}

class Water extends StatelessWidget {
  final double height;
  final double width;

  Water(this.height, this.width);

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 0,
        height: height / 2,
        width: width,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.5),
          ),
        ));
  }
}

class Swimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: 0.5,
        top: 0.5,
        child: Image(image: AssetImage('assets/sprites.png')));
  }
}
