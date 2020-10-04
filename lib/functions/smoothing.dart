import 'dart:typed_data';

import 'package:PPG/models/models.dart';
import 'package:smart_signal_processing/smart_signal_processing.dart';

smoothing(List<SensorValue> array) {
  List<Float64List> data = [];

  data = arrayCreation(array);

  return 'smoothed';
}

arrayCreation(List<SensorValue> array) {
  final arrayLength = getArrayRoot2Length(array);
  final double lastTime = array.last.time.millisecondsSinceEpoch.toDouble();
  Duration timeDelta =
      array.last.time.difference(array[array.length - arrayLength].time);

  Float64List time = Float64List(arrayLength);
  Float64List real = Float64List(arrayLength);
  Float64List imaginary = Float64List(arrayLength);

  for (int i = 1; i <= arrayLength;) {
    time[arrayLength - i] = lastTime - timeDelta.inMilliseconds * (i - 1);
    real[arrayLength - 1] = array[arrayLength - i].value;
  }

  return [time, real, imaginary];
}

int getArrayRoot2Length(List array) {
  int i = 1;
  if (array.length == 1) return 1;
  while (array.length / i >= 1 && i != 512) {
    i *= 2;
  }
  return i ~/ 2;
}

double interpolatePoint(DateTime realTime,
    {DateTime t1, DateTime t2, double v1, double v2}) {
  Duration elapsedInSegment = realTime.difference(t1);
  Duration tDelta = t1.difference(t2);
  double valueDelta = v2 - v1;

  double elapsedPercentage =
      elapsedInSegment.inMilliseconds / tDelta.inMilliseconds;

  double ret = valueDelta * elapsedPercentage + v1;
  return ret;
}
