import 'package:MediRate/models/models.dart';
import 'package:scidart/scidart.dart';
import 'package:scidart/numdart.dart';

void doTheStuff(List<SensorValue> signal) {
  Array signal1D = Array.fixed(signal.length);

  for (int i = 0; i < signal.length; i++) {
    signal1D[i] = signal[i].value;
  }
  // signal.forEach((point) {
  //   signal1D.add(point.value);
  // });

  int timeDelta = signal.last.time.difference(signal.first.time).inMilliseconds;

  rfft(signal1D);

  print(signal.length);
  print('time: $timeDelta');
}
