// lib/steps/ui/monthly_steps_screen.dart
// import 'package:flutter/material.dart' hide SelectionDetails;
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
//
// import '../controller/step_controller.dart';
//
// class MonthlyStepsScreen extends StatelessWidget {
//   final StepsController ctrl = Get.find();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Monthly Progress')),
//       body: FutureBuilder<Map<DateTime, int>>(
//         future: ctrl.getMonthlySteps(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No data available'));
//           }
//
//           final data = snapshot.data!;
//           final dates = data.keys.toList()..sort();
//           final values = dates.map((d) => data[d] ?? 0).toList();
//
//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Container(
//                   height: 300,
//                   child: SfCartesianChart(
//                     primaryXAxis: DateTimeAxis(
//                       dateFormat: DateFormat('d MMM'),
//                       intervalType: DateTimeIntervalType.days,
//                       interval: 3,
//                     ),
//                     series: <LineSeries<int, DateTime>>[
//                       LineSeries<int, DateTime>(
//                         dataSource: values,
//                         xValueMapper: (_, index) => dates[index],
//                         yValueMapper: (data, _) => data,
//                         color: Theme.of(context).primaryColor,
//                         markerSettings: const MarkerSettings(isVisible: true),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: dates.length,
//                     itemBuilder: (context, index) {
//                       final date = dates[index];
//                       final steps = values[index];
//                       return ListTile(
//                         title: Text(DateFormat('MMMM d, y').format(date)),
//                         trailing: Text('$steps steps'),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
// lib/steps/ui/monthly_steps_screen.dart
// lib/steps/ui/monthly_steps_screen.dart
import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../controller/step_controller.dart';

class StepData {
  final DateTime date;
  final int steps;

  StepData(this.date, this.steps);
}

class MonthlyStepsScreen extends StatelessWidget {
  final StepsController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Progress')),
      body: FutureBuilder<Map<DateTime, int>>(
        future: ctrl.getMonthlySteps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final rawData = snapshot.data!;

          /// 🔑 Normalize dates (remove time) & aggregate steps
          final Map<DateTime, int> dailyAggregated = {};
          rawData.forEach((dateTime, steps) {
            final normalizedDate =
                DateTime(dateTime.year, dateTime.month, dateTime.day);
            dailyAggregated[normalizedDate] =
                (dailyAggregated[normalizedDate] ?? 0) + steps;
          });

          final dates = dailyAggregated.keys.toList()..sort();
          final stepData =
              dates.map((d) => StepData(d, dailyAggregated[d] ?? 0)).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat('d MMM'),
                      intervalType: DateTimeIntervalType.days,
                      interval: 2,
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                    ),
                    primaryYAxis: NumericAxis(
                      labelFormat: '{value} steps',
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <LineSeries<StepData, DateTime>>[
                      LineSeries<StepData, DateTime>(
                        dataSource: stepData,
                        xValueMapper: (StepData sd, _) => sd.date,
                        yValueMapper: (StepData sd, _) => sd.steps,
                        color: Theme.of(context).primaryColor,
                        markerSettings: const MarkerSettings(isVisible: true),
                        name: 'Steps',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: stepData.length,
                    itemBuilder: (context, index) {
                      final entry = stepData[index];
                      return ListTile(
                        title: Text(DateFormat('MMMM d, y').format(entry.date)),
                        trailing: Text('${entry.steps} steps'),
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
