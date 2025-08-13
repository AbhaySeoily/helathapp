// lib/steps/ui/monthly_steps_screen.dart
import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../controller/step_controller.dart';

class MonthlyStepsScreen extends StatelessWidget {
  final StepsController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monthly Progress')),
      body: FutureBuilder<Map<DateTime, int>>(
        future: ctrl.getMonthlySteps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          final data = snapshot.data!;
          final dates = data.keys.toList()..sort();
          final values = dates.map((d) => data[d] ?? 0).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 300,
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat('d MMM'),
                      intervalType: DateTimeIntervalType.days,
                      interval: 3,
                    ),
                    series: <LineSeries<int, DateTime>>[
                      LineSeries<int, DateTime>(
                        dataSource: values,
                        xValueMapper: (_, index) => dates[index],
                        yValueMapper: (data, _) => data,
                        color: Theme.of(context).primaryColor,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final steps = values[index];
                      return ListTile(
                        title: Text(DateFormat('MMMM d, y').format(date)),
                        trailing: Text('$steps steps'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
