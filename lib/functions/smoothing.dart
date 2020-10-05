import 'dart:math';
import 'dart:typed_data';

import 'package:PPG/models/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_signal_processing/smart_signal_processing.dart';

List<Float64List> smoothing(List<SensorValue> array) {
  List<Float64List> data = arrayCreation(array);
  Float64List time = data[0];
  Float64List real = data[1];
  Float64List imag = Float64List(real.length);
  int fps = 30;

  FFT.transform(real, imag);
  List<Float64List> filtered = butterworthFilter(real, imag,
      order: 2, cutoff: fps / 2, isHighPass: true);
  real = filtered[0];
  imag = filtered[1];
  filtered = butterworthFilter(real, imag,
      order: 2, cutoff: (fps * 2).toDouble(), isHighPass: false);
  real = filtered[0];
  imag = filtered[1];
  FFT.transform(real, imag);

  List<Float64List> ret = [time, real, imag];

  return ret;
}

butterworthFilter(
  Float64List real,
  Float64List imag, {
  @required int order,
  @required double cutoff,
  @required bool isHighPass,
}) {
  int arrayLength = real.length;
  Float64List retReal = Float64List(arrayLength);
  Float64List retImag = Float64List(arrayLength);

  for (int i = 0; i < arrayLength ~/ 2; i++) {
    double wl = i / cutoff;
    double gain = 1 / (sqrt(1 + pow(wl, 2 * order)));
    if (isHighPass) gain = 1 - gain;
    retReal[i] = real[i] * gain;
    retReal[i + arrayLength ~/ 2] = real[i + arrayLength ~/ 2];
    retImag[i] = imag[i] * gain;
    retImag[i + arrayLength ~/ 2] = imag[i + arrayLength ~/ 2];
  }

  return [retReal, retImag];
}

arrayCreation(List<SensorValue> array) {
  final arrayLength = getArrayRoot2Length(array);
  Float64List real = Float64List(arrayLength);
  Float64List time = Float64List(arrayLength);

  double startTIme = dateToDouble(array[array.length - arrayLength].time);
  double endTime = dateToDouble(array.last.time);
  double tDelta = (endTime - startTIme) / arrayLength;

  for (int i = 1; i <= arrayLength; i++) {
    double currentTime = dateToDouble(array[array.length - i].time);
    time[arrayLength - i] = endTime - tDelta * (i - 1);
    if (currentTime == (endTime - tDelta * (i - 1))) {
      real[arrayLength - i] = array[array.length - i].value;
    } else if (currentTime > (endTime - tDelta * (i - 1))) {
      real[arrayLength - i] = interpolatePoint(
        time[arrayLength - i],
        t1: dateToDouble(array[array.length - i].time),
        t2: dateToDouble(array[array.length - i + 1].time),
        v1: array[array.length - i].value,
        v2: array[array.length - i + 1].value,
      );
    } else {
      real[arrayLength - i] = interpolatePoint(
        time[arrayLength - i],
        t1: dateToDouble(array[array.length - i - 1].time),
        t2: dateToDouble(array[array.length - i].time),
        v1: array[array.length - i - 1].value,
        v2: array[array.length - i].value,
      );
    }
    real[arrayLength - i] = array[arrayLength - i].value;
  }

  return [time, real];
}

int getArrayRoot2Length(List array) {
  int i = 1;
  if (array.length == 1) return 1;
  while (array.length / i >= 1 && i != 512) {
    i *= 2;
  }
  return i ~/ 2;
}

double interpolatePoint(double realTime,
    {double t1, double t2, double v1, double v2}) {
  double elapsedInSegment = realTime - t1;
  double tDelta = t2 - t1;
  double valueDelta = v2 - v1;

  double elapsedPercentage = elapsedInSegment / tDelta;

  double ret = valueDelta * elapsedPercentage + v1;
  return ret;
}

double dateToDouble(DateTime dateObj) {
  double ret = dateObj.millisecondsSinceEpoch.toDouble();
  return ret;
}
