import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SmoothChart extends StatelessWidget {
  SmoothChart(this.interpolated, this.width);

  final List<Float64List> interpolated;
  final double width;

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    List<FlSpot> persist = [];
    for (int i = 1; i < interpolated[0].length ~/ 2; i++) {
      double _time = (interpolated[0][i] - interpolated[0].first) / 1000;
      spots.add(FlSpot(_time, interpolated[1][i]));
      persist.add(FlSpot(_time, interpolated[2][i]));
    }

    return spots.isNotEmpty
        ? Container(
            width: width,
            height: 20,
            child: LineChart(LineChartData(
                titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: false),
                    bottomTitles: SideTitles(showTitles: false)),
                lineBarsData: [
                  LineChartBarData(
                      spots: spots, dotData: FlDotData(show: false)),
                  // LineChartBarData(
                  //     spots: persist,
                  //     colors: [Colors.green],
                  //     dotData: FlDotData(show: false)),
                ])),
          )
        : Container();
  }
}
