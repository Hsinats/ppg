import 'dart:math';

import 'package:PPG/models/models.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DataChart extends StatelessWidget {
  DataChart(this.redData);
  final List<SensorValue> redData;

  @override
  Widget build(BuildContext context) {
    List<FlSpot> red = [];

    redData.forEach((element) {});
    for (int i = max(0, redData.length - 100); i < redData.length; i++) {
      SensorValue element = redData[i];
      red.add(FlSpot(
          (element.time.millisecondsSinceEpoch -
                  redData.first.time.millisecondsSinceEpoch) /
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
