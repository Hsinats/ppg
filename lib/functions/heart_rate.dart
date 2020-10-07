import 'dart:math';

import 'package:PPG/models/models.dart';
import 'dart:math' as math;

List<int> heartRate(List<SensorValue> data) {
  List<int> ret = [];
  double max = 0;
  double min = 255;
  // ignore: unused_local_variable
  double average = 0;
  double threshold;
  double alpha = 0.3;

  int trailing = 301;
  int dataStart = math.max(data.length - trailing, 0);
  int dataLength = data.length - dataStart;

  for (int i = dataStart; i < data.length; i++) {
    average += data[i].value / dataLength;
    if ((data[i].value ?? 0) > max) max = data[i].value;
    if ((data[i].value ?? 255) < max) min = data[i].value;
  }

  threshold = 0.6 * (max - min) + min;

  double bpm = 0;
  int counter = 0;
  int previous;
  List<int> beatTimes = [];
  for (int i = dataStart + 1; i < data.length; i++) {
    if (data[i - 1].value < threshold && data[i].value > threshold) {
      if (previous != null) {
        counter++;
        bpm += 60 * 1000 / (data[i].time.millisecondsSinceEpoch - previous);
      }
      previous = data[i].time.millisecondsSinceEpoch;
      beatTimes.add(previous);
    }
  }

  if (counter != 0) {
    bpm /= counter;
    ret.add(((1 - alpha) * bpm + alpha * bpm) ~/ 1);
  } else {
    ret.add(0);
  }

  if (beatTimes.length > 1) {
    int variabilityTally = 0;
    for (int i = 1; i < beatTimes.length; i++) {
      variabilityTally += pow(beatTimes[i] - beatTimes[i - 1], 2);
    }
    ret.add((variabilityTally) ~/ 1);
  } else {
    ret.add(0);
  }
  return ret;
}
