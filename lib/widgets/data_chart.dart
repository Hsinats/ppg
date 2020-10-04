import 'dart:math';

import 'package:PPG/models/models.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DataChart extends StatelessWidget {
  DataChart(this.greenData, this.redData);
  final List<SensorValue> greenData;
  final List<SensorValue> redData;

  @override
  Widget build(BuildContext context) {
    List<FlSpot> green = [];
    List<FlSpot> red = [];

    // for (int i = max(0, greenData.length - 200); i < greenData.length; i++) {
    //   SensorValue element = greenData[i];
    //   green.add(FlSpot(
    //       (element.time.millisecondsSinceEpoch -
    //               greenData.first.time.millisecondsSinceEpoch) /
    //           1000,
    //       element.value));
    // }
    redData.forEach((element) {});
    for (int i = max(0, redData.length - 100); i < redData.length; i++) {
      SensorValue element = redData[i];
      red.add(FlSpot(
          (element.time.millisecondsSinceEpoch -
                  greenData.first.time.millisecondsSinceEpoch) /
              1000,
          element.value));
    }

    return Container(
      height: 50,
      child: LineChart(LineChartData(
          titlesData: FlTitlesData(
              leftTitles: SideTitles(showTitles: false),
              bottomTitles: SideTitles(showTitles: false)),
          lineBarsData: [
            LineChartBarData(spots: red, dotData: FlDotData(show: false))
          ])),
    );
  }
}
