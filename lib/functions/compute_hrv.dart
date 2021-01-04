import 'package:MediRate/models/models.dart';
import 'package:scidart/scidart.dart';
import 'package:scidart/numdart.dart';

List<SensorValue> doTheStuff(List<SensorValue> signal) {
  DateTime now = DateTime.now();
  Array signal1D = Array.fixed(signal.length);

  for (int i = 0; i < signal.length; i++) {
    signal1D[i] = signal[i].value;
  }

  ArrayComplex transformedSignal = arrayToComplexArray(signal1D);
  print('after made complex length: ${transformedSignal.length}');

  int timeDelta = signal.last.time.difference(signal.first.time).inSeconds;
  double secondWidth = signal.length / timeDelta;

  transformedSignal = fft(transformedSignal);
  print('after first transform length: ${transformedSignal.length}');

  transformedSignal = butterworthFilter(transformedSignal, secondWidth * 2);
  transformedSignal =
      butterworthFilter(transformedSignal, secondWidth * 0.5, isLowPass: true);

  print('after first filter length: ${transformedSignal.length}');

  transformedSignal = ifft(transformedSignal);
  Array outputSignal = Array.fixed(transformedSignal.length);
  List<SensorValue> sensorOutput = [];

  for (int i = 0; i < transformedSignal.length; i++) {
    outputSignal[i] = transformedSignal[i].real;
  }

  for (int i = 0; i < signal.length; i++) {
    SensorValue sensorValue = SensorValue(signal[i].time, outputSignal[i]);
    sensorOutput.add(sensorValue);
  }
  print('signal length${signal.length}');
  print('output signal length${outputSignal.length}');
  print('time: $timeDelta');
  Duration length = DateTime.now().difference(now);
  // print('length: $length ');
  return sensorOutput;
}

butterworthFilter(
  ArrayComplex freqDomainSignal,
  double frequencyCutoff, {
  bool isLowPass,
  int order = 2,
}) {
  // TODO: check fft form like half positive half negative
  int signalLength = freqDomainSignal.length;

  ArrayComplex smoothedSignal = ArrayComplex.fixed(signalLength);
  for (int i = 0; i < signalLength; i++) {
    double real =
        freqDomainSignal[i].real / sqrt(1 + pow(frequencyCutoff, order));
    double imag =
        freqDomainSignal[i].imaginary / sqrt(1 + pow(frequencyCutoff, order));
    smoothedSignal[i] = Complex(real: real, imaginary: imag);
  }

  return smoothedSignal;
}
