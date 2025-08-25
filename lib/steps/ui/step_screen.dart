import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import 'package:syncfusion_flutter_charts/charts.dart' as sfcharts;
import 'package:syncfusion_flutter_gauges/gauges.dart' as sfgauge;

import '../../notification/notification_service.dart';
import '../controller/step_controller.dart';
import 'monthly_steps_screen.dart';

import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sfcharts;
import 'package:syncfusion_flutter_gauges/gauges.dart' as sfgauge;
import 'monthly_steps_screen.dart';

import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sfcharts;
import 'package:syncfusion_flutter_gauges/gauges.dart' as sfgauge;
import 'monthly_steps_screen.dart';

class StepsScreen extends StatelessWidget {
  final ctrl = Get.put(StepsController());

  StepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
          //  onPressed: () => _showGoalDialog(context),
            onPressed: (){
              final box = GetStorage();
              int goal = box.read(ks_daily_goal) ?? 0;
              print(goal);
              _showGoalDialog(context);
            },
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        final m = ctrl.model.value;
        final last7 = (m.last7.length == 7) ? m.last7 : List.filled(7, 0);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 6,
                shadowColor: Colors.blue.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "Total Steps Today",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: sfgauge.SfRadialGauge(
                          axes: <sfgauge.RadialAxis>[
                            sfgauge.RadialAxis(
                              minimum: 0,
                              maximum:
                              (m.goal <= 0 ? 1 : m.goal).toDouble(),
                              startAngle: 180,
                              endAngle: 0,
                              showTicks: true,
                              showLabels: false,
                              axisLineStyle: sfgauge.AxisLineStyle(
                                thickness: 0.04,
                                thicknessUnit: sfgauge.GaugeSizeUnit.factor,
                                color: Colors.grey.shade300,
                              ),
                              pointers: <sfgauge.GaugePointer>[
                                sfgauge.RangePointer(
                                  value: m.today.toDouble(),
                                  width: 0.04,
                                  sizeUnit: sfgauge.GaugeSizeUnit.factor,
                                  color: Colors.orange,
                                  cornerStyle: sfgauge.CornerStyle.bothCurve,
                                ),
                              ],
                              annotations: <sfgauge.GaugeAnnotation>[
                                sfgauge.GaugeAnnotation(
                                  angle: 90,
                                  positionFactor: 0.1,
                                  widget: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("Steps",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey)),
                                      const SizedBox(height: 6),
                                      Text(
                                        "${m.today}",
                                        style: const TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12.0),
                        child: LinearProgressIndicator(
                          value: (m.goal == 0)
                              ? 0
                              : (m.today / m.goal).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.red.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.redAccent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${(m.goal == 0 ? 0 : (m.today / m.goal) * 100).toStringAsFixed(1)}% Completed",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Goal',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${NumberFormat().format(m.goal)} steps',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Last 7 Days',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: sfcharts.SfCartesianChart(
                  primaryXAxis: const sfcharts.CategoryAxis(),
                  series: <sfcharts.ColumnSeries<int, String>>[
                    sfcharts.ColumnSeries<int, String>(
                      dataSource: last7,
                      xValueMapper: (data, index) => DateFormat('E').format(
                          DateTime.now().subtract(Duration(days: 6 - index))),
                      yValueMapper: (data, _) => data,
                      color: Theme.of(context).primaryColor,
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.to(() => MonthlyStepsScreen()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Monthly Progress'),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showGoalDialog(BuildContext context) {
    final ctrl = Get.find<StepsController>();
    final textController =
    TextEditingController(text: ctrl.model.value.goal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Steps', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(textController.text) ?? 8000;
              ctrl.setDailyGoal(goal);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// class StepsScreen extends StatelessWidget {
//   final ctrl = Get.put(StepsController());
//
//   StepsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Step Tracker'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings, color: Colors.black),
//            onPressed: () => _showGoalDialog(context)
//            // onPressed: () =>     NotificationService.showTestNotification()
//             ,
//           ),
//         ],
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: Obx(() {
//         final m = ctrl.model.value;
//         final last7 = (m.last7.length == 7) ? m.last7 : List.filled(7, 0);
//
//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Card(
//                 elevation: 6,
//                 shadowColor: Colors.blue.withOpacity(0.3),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     children: [
//                       const Text(
//                         "Total Steps Today",
//                         style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue),
//                       ),
//                       const SizedBox(height: 20),
//
//                       // Gauge
//                       SizedBox(
//                         height: 320,
//                         child: Column(
//                           children: [
//                             SizedBox(
//                               height: 200,
//                               child: sfgauge.SfRadialGauge(
//                                 axes: <sfgauge.RadialAxis>[
//                                   sfgauge.RadialAxis(
//                                     minimum: 0,
//                                     maximum:
//                                         (m.goal <= 0 ? 1 : m.goal).toDouble(),
//                                     startAngle: 180,
//                                     endAngle: 0,
//                                     showTicks: true,
//                                     showLabels: false,
//                                     axisLineStyle: sfgauge.AxisLineStyle(
//                                       thickness: 0.04,
//                                       thicknessUnit:
//                                           sfgauge.GaugeSizeUnit.factor,
//                                       color: Colors.grey.shade300,
//                                     ),
//                                     pointers: <sfgauge.GaugePointer>[
//                                       sfgauge.RangePointer(
//                                         value: m.today.toDouble(),
//                                         width: 0.04,
//                                         sizeUnit: sfgauge.GaugeSizeUnit.factor,
//                                         color: Colors.orange,
//                                         cornerStyle:
//                                             sfgauge.CornerStyle.bothCurve,
//                                       ),
//                                     ],
//                                     annotations: <sfgauge.GaugeAnnotation>[
//                                       sfgauge.GaugeAnnotation(
//                                         angle: 90,
//                                         positionFactor: 0.1,
//                                         widget: Column(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             const Text("Steps",
//                                                 style: TextStyle(
//                                                     fontSize: 16,
//                                                     color: Colors.grey)),
//                                             const SizedBox(height: 6),
//                                             Text(
//                                               "${m.today}",
//                                               style: const TextStyle(
//                                                   fontSize: 38,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//
//                             const SizedBox(height: 12),
//
//                             // Progress bar
//                             Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(horizontal: 12.0),
//                               child: LinearProgressIndicator(
//                                 value: (m.goal == 0)
//                                     ? 0
//                                     : (m.today / m.goal).clamp(0.0, 1.0),
//                                 minHeight: 6,
//                                 backgroundColor: Colors.red.shade100,
//                                 valueColor: const AlwaysStoppedAnimation<Color>(
//                                     Colors.redAccent),
//                               ),
//                             ),
//
//                             const SizedBox(height: 16),
//
//                             // Slow vs Brisk
//                             Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(horizontal: 16.0),
//                               child: Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const Text("Slow walking",
//                                           style: TextStyle(
//                                               color: Colors.grey,
//                                               fontSize: 12)),
//                                       const SizedBox(height: 4),
//                                       Obx(() => Text(
//                                             "${ctrl.slowSteps.value} steps",
//                                             style: const TextStyle(
//                                                 fontSize: 14,
//                                                 fontWeight: FontWeight.w600,
//                                                 color: Colors.blue),
//                                           )),
//                                     ],
//                                   ),
//                                   Column(
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     children: [
//                                       const Text("Brisk walking",
//                                           style: TextStyle(
//                                               color: Colors.grey,
//                                               fontSize: 12)),
//                                       const SizedBox(height: 4),
//                                       Obx(() => Text(
//                                             "${ctrl.briskSteps.value} steps",
//                                             style: const TextStyle(
//                                                 fontSize: 14,
//                                                 fontWeight: FontWeight.w600,
//                                                 color: Colors.green),
//                                           )),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       const SizedBox(height: 10),
//
//                       // Overall %
//                       Text(
//                         "${(m.goal == 0 ? 0 : (m.today / m.goal) * 100).toStringAsFixed(1)}% Completed",
//                         style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Goal Info
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Daily Goal',
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   Text(
//                     '${NumberFormat().format(m.goal)} steps',
//                     style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Theme.of(context).primaryColor),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//
//               // Weekly Chart
//               const Text('Last 7 Days',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: 220,
//                 child: sfcharts.SfCartesianChart(
//                   primaryXAxis: const sfcharts.CategoryAxis(),
//                   series: <sfcharts.ColumnSeries<int, String>>[
//                     sfcharts.ColumnSeries<int, String>(
//                       dataSource: last7,
//                       xValueMapper: (data, index) => DateFormat('E').format(
//                           DateTime.now().subtract(Duration(days: 6 - index))),
//                       yValueMapper: (data, _) => data,
//                       color: Theme.of(context).primaryColor,
//                       borderRadius:
//                           const BorderRadius.vertical(top: Radius.circular(4)),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Monthly page
//               ElevatedButton(
//                 onPressed: () => Get.to(() => MonthlyStepsScreen()),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: const Text('View Monthly Progress'),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
//
//   void _showGoalDialog(BuildContext context) {
//     final ctrl = Get.find<StepsController>();
//     final textController =
//         TextEditingController(text: ctrl.model.value.goal.toString());
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Set Daily Goal'),
//         content: TextField(
//           controller: textController,
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(
//               labelText: 'Steps', border: OutlineInputBorder()),
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               final goal = int.tryParse(textController.text) ?? 8000;
//               ctrl.setGoal(goal);
//               Navigator.pop(context);
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
// }
