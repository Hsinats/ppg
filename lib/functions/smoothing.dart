import 'dart:typed_data';

import 'package:PPG/models/models.dart';
import 'package:smart_signal_processing/smart_signal_processing.dart';

smoothing(List<SensorValue> array) {
  // final Duration timeDelta = array.last.time.difference(array.first.time);
  final arrayLength = getArrayRoot2Length(array);
  final firstPoint = array.length - arrayLength;
  Duration timeDelta = array.last.time.difference(array[firstPoint].time);
  final timeWidth =
      Duration(microseconds: timeDelta.inMicroseconds ~/ arrayLength);

  // Float64List time = Float64List(arrayLength);
  Float64List real = Float64List(arrayLength);
  Float64List imaginary = Float64List(arrayLength);

  for (int i = 1; i <= arrayLength; i++) {
    // time[i - 1] = i * timeWidth.inSeconds.toDouble();
    if (i == 1) {
      real[arrayLength - i] = array.last.value;
    } else {
      int currentPoint = array.length - i;
      if (array[currentPoint]
          .time
          .isAfter(array.last.time.subtract(timeWidth * (i - 1)))) {
        double rise =
            (array[currentPoint].value - array[currentPoint - 1].value) / 2;
        int tToPt1 = array[currentPoint]
            .time
            .difference(array.last.time.subtract(timeWidth * (i - 1)))
            .inMicroseconds;
        int ptDelta = array[currentPoint]
            .time
            .difference(array[currentPoint - 1].time)
            .inMicroseconds;
        real[real.length - i - 1] =
            array[currentPoint].value - rise * (tToPt1 / ptDelta);
      } else if (array[currentPoint]
          .time
          .isBefore(array.last.time.subtract(timeWidth * (i - 1)))) {
        double rise =
            (array[currentPoint].value - array[currentPoint + 1].value) / 2;
        int tToPt1 = array[currentPoint]
            .time
            .difference(array.last.time.subtract(timeWidth * (i)))
            .inMicroseconds;
        int ptDelta = array[currentPoint]
            .time
            .difference(array[currentPoint].time)
            .inMicroseconds;
        real[real.length - i] =
            array[currentPoint].value - rise * (tToPt1 / ptDelta);
      } else {
        real[real.length - i] = array[currentPoint].value;
      }
    }
  }
  // return [time, real, imaginary];

  FFT.transform(real, imaginary);

  print(real);

  print(imaginary);
}

int getArrayRoot2Length(List array) {
  int i = 1;
  if (array.length == 1) return 1;
  while (array.length / i >= 1) {
    i *= 2;
  }
  return i ~/ 2;
}
