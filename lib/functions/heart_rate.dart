import 'package:PPG/models/models.dart';
import 'dart:math' as math;

heartRate(List<SensorValue> data) {
  int ret;
  double max;
  double min;
  // ignore: unused_local_variable
  double average = 0;
  double threshold;
  double alpha = 0.3;

  int trailing = 151;
  int dataStart = math.max(data.length - trailing, 0);
  int dataLength = data.length - dataStart;

  for (int i = dataStart; i < data.length; i++) {
    average += data[i].value / dataLength;
    if ((data[i].value ?? 0) > max) max = data[i].value;
    if ((data[i].value ?? 255) < max) min = data[i].value;
  }

  threshold = 0.7 * (max - min) + min;

  double bpm = 0;
  int counter = 0;
  int previous;
  List<int> beatTimes = [];
  for (int i = dataStart; i < data.length; i++) {
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
    ret = ((1 - alpha) * bpm + alpha * bpm) ~/ 1;
  }
  return ret;
}
