import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:MediRate/models/models.dart';
import 'package:MediRate/functions/functions.dart';
import 'package:MediRate/widgets/data_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_better_camera/camera.dart';
import 'package:scidart/numdart.dart';
import 'package:wakelock/wakelock.dart';

const waveColor = Colors.blue;

class GameView extends StatefulWidget {
  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  CameraController _cameraController;
  int _fps = 30;
  CameraImage _lastCameraImage;
  List<SensorValue> _redValues = [];
  List<SensorValue> _redDiff = [];
  int frameTally = 0;
  List<SensorValue> cleanedData = [];

  List<Float64List> data = [];

  bool gameOn = false;
  Timer _timer;
  DateTime lastHRV;
  GameInfo gameInfo = GameInfo();

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
      body: Stack(children: [
        _ScaffoldBodyLandscape(_redDiff, gameInfo),
        cleanedData.length > 0
            ? Align(
                child: DataChart(cleanedData, 400),
                alignment: Alignment.center,
              )
            : Container(),
      ]),
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
    _timer =
        Timer.periodic(Duration(milliseconds: 1000 ~/ _fps), (timer) async {
      if (gameOn) {
        if (_lastCameraImage != null) {
          _scanImage(_lastCameraImage);
          frameTally++;
          if (frameTally >= _fps * 5) {
            frameTally = 0;
            // List<int> hrReturn = heartRate(_redDiff);
            cleanedData = await compute(doTheStuff, _redValues);
            List<int> hrReturn = heartRate(cleanedData);

            gameInfo.update(newHeartRate: hrReturn[0], newHRV: hrReturn[1]);
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

    int _redLength = _redValues.length;

    if (_redLength >= 2) {
      _redDiff.add(SensorValue(currentTime,
          _redValues[_redLength - 1].value - _redValues[_redLength - 2].value));
    }
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

class _ScaffoldBodyLandscape extends StatelessWidget {
  final List<SensorValue> data;
  final GameInfo gameInfo;

  _ScaffoldBodyLandscape(this.data, this.gameInfo);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Stack(
      overflow: Overflow.clip,
      children: [
        Sky(),
        data.isNotEmpty ? Waves(width, height, data) : Container(),
        Island(height, width),
        Tree(height, width),
        Water(height, width, gameInfo),
      ],
    );
  }
}

class Tree extends StatelessWidget {
  Tree(this.height, this.width);

  final double height;
  final double width;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: height / 3 + height * .22,
      right: 0,
      child: Stack(
        overflow: Overflow.visible,
        children: [
          Positioned(
            left: 20,
            child: Container(
              height: height * .3,
              width: height * .05,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.brown, Colors.brown[200]])),
            ),
          ),
          Positioned(
            child: Container(
              height: height * 0.15,
              width: height * 0.15,
              color: Colors.green,
            ),
          )
        ],
      ),
    );
  }
}

class Island extends StatelessWidget {
  Island(this.height, this.width);

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0.8 * width,
      bottom: height / 3 - height * .1,
      child: ClipOval(
        child: Container(
          height: height * .2,
          width: 0.25 * width,
          decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [Colors.orange, Colors.orange[200]])),
        ),
      ),
    );
  }
}

class Sky extends StatelessWidget {
  const Sky({
    Key key,
  }) : super(key: key);

  final double sunSize = 120;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
              Colors.orange[50],
              Colors.orange[400],
            ])),
        // decoration: BoxDecoration(color: Colors.orange[200]),
      ),
      Positioned(
          top: 30,
          left: 20,
          child: Container(
            height: sunSize,
            width: sunSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(sunSize / 2),
              // color: Colors.orange[200],
              gradient: RadialGradient(
                  colors: [Colors.red, Colors.orange.withAlpha(150)],
                  radius: 0.55),
            ),
          ))
    ]);
  }
}

class Waves extends StatelessWidget {
  final width;
  final height;
  final List<SensorValue> data;
  final double waveHeight = 20;

  swimmerYposition(List<SensorValue> data, _DrawParams params) {
    if (params.maxMinDiff == 0) return 0.0;
    double ret = (params.max - data[max(0, data.length - 101)].value) /
        params.maxMinDiff;
    return ret;
  }

  Waves(this.width, this.height, this.data);
  @override
  Widget build(BuildContext context) {
    _DrawParams _drawParams = _DrawParams.findMaxMinDiff(data);
    double swimmerY = swimmerYposition(data, _drawParams) * waveHeight;
    return Stack(children: [
      Positioned(
          bottom: height / 3 + waveHeight - swimmerY - 5, child: Swimmer()),
      Positioned(
        bottom: height / 3,
        height: waveHeight,
        width: width,
        child: CustomPaint(
          size: Size.infinite,
          painter: WavesPainter(data, width, _drawParams),
        ),
      ),
    ]);
  }
}

class WavesPainter extends CustomPainter {
  double width;
  List<SensorValue> data;
  _DrawParams _drawParams;

  WavesPainter(this.data, this.width, this._drawParams);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      print('not enough data');
      return;
    }

    //generate trapezoids
    List<Trapezoid> trapezoids = _generateTrapezoid(width, data, _drawParams);

    // paint waves

    var wavePaint = Paint()
      ..color = waveColor[200]
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    var path = Path();

    bool first = true;
    for (int i = max(trapezoids.length - 101, 0); i < trapezoids.length; i++) {
      if (first) {
        path.moveTo(0, 0);
        path.lineTo(0, trapezoids[i].y1 * size.height);
        first = false;
      }
      path.lineTo(
          width / (trapezoids.length - 1) * i, trapezoids[i].y2 * size.height);
      if (i == trapezoids.length - 1) {
        path.lineTo(width / (trapezoids.length - 1) * i, size.height);
        path.lineTo(0, size.height);
      }
    }

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

List<Trapezoid> _generateTrapezoid(
    double width, List<SensorValue> data, _DrawParams _drawParams) {
  List<Trapezoid> ret = [];

  for (int i = 0; i < data.length - 1; i++) {
    if (data.length - i > 101) continue;
    double y1 = (_drawParams.max - data[i].value) / _drawParams.maxMinDiff;
    double y2 = (_drawParams.max - data[i + 1].value) / _drawParams.maxMinDiff;
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
  final GameInfo gameInfo;

  Water(this.height, this.width, this.gameInfo);

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 0,
        height: height / 3,
        width: width,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [waveColor[900], waveColor[200]]),
          ),
          child: InfoBuoys(
            heartRate: gameInfo.heartRate,
            hRV: gameInfo.hRV,
          ),
        ));
  }
}

class Swimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/sprite_in_motion.png',
      scale: .5,
    );
  }
}

class _DrawParams {
  List<SensorValue> data;
  double max;
  double min;
  double maxMinDiff;

  _DrawParams.findMaxMinDiff(this.data) {
    for (int i = 0; i < data.length; i++) {
      if (data.length - i > 101) continue;
      if (min == null) {
        min = data[i].value;
        max = data[i].value;
      } else if (data[i].value > max) {
        max = data[i].value;
      } else if (data[i].value < min) {
        min = data[i].value;
      }
    }

    maxMinDiff = max - min;
  }
}

class Buoy extends StatelessWidget {
  Buoy(this.metric, this.value);

  final String metric;
  final num value;

  @override
  Widget build(BuildContext context) {
    bool isTime = false;
    Text timeText;
    if (metric == 'Time') {
      isTime = true;
      timeText = Text('${(value ?? 0) ~/ 60}:${(value ?? 0) % 60}');
    }

    return Stack(children: [
      Container(
        height: 50,
        width: 150,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            isTime ? timeText : Text((value ?? 0).toStringAsFixed(0)),
          ],
        ),
      ),
      Positioned(
        left: 25,
        child: Container(
          height: 70,
          width: 20,
          decoration: BoxDecoration(color: Colors.red),
        ),
      ),
      Positioned(
        right: 25,
        child: Container(
          height: 70,
          width: 20,
          decoration: BoxDecoration(color: Colors.red),
        ),
      ),
    ]);
  }
}

class InfoBuoys extends StatelessWidget {
  InfoBuoys({this.heartRate, this.hRV, this.time, this.score});

  final int heartRate;
  final int hRV;
  final int time;
  final int score;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        if (constraints.maxWidth <= 320) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Buoy('HR', heartRate),
              Buoy('HRV', hRV),
              Buoy('Time', time),
              Buoy('Score', score)
            ],
          );
        } else if (constraints.maxWidth <= 640) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Buoy('HR', heartRate),
                  Buoy('HRV', hRV),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Buoy('Time', time),
                  Buoy('Score', score),
                ],
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Buoy('HR', heartRate),
              Buoy('HRV', hRV),
              Buoy('Time', time),
              Buoy('Score', score)
            ],
          );
        }
      },
    );
  }
}
