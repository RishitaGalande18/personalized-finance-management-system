import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseChart extends StatelessWidget {

  final Map<String, double> data;

  const ExpenseChart({super.key, required this.data});

  static const List<Color> colors = [
    Colors.green,
    Colors.orange,
    Colors.blue,
    Colors.red,
    Colors.purple
  ];

  @override
  Widget build(BuildContext context) {

    final entries = data.entries.toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(entries.length, (index) {

          final entry = entries[index];

          return PieChartSectionData(
            value: entry.value,
            title: entry.key,
            radius: 50,
            color: colors[index % colors.length],
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );

        }),
      ),
    );
  }
}