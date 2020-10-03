import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SmoothChart extends StatelessWidget {
  SmoothChart(this.interpolated);

  final List<Float64List> interpolated;

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    for (int i = 0; i < interpolated[0].length; i++) {
      spots.add(FlSpot(interpolated[0][i], interpolated[1][i]));
    }
    print(spots.length);
    return Container();

    // return LineChart(
    //     LineChartData(lineBarsData: [LineChartBarData(spots: spots)]));
  }
}
