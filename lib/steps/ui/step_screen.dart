import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../controller/step_controller.dart';
import 'monthly_steps_screen.dart';



class StepsScreen extends StatelessWidget {
  final ctrl = Get.put(StepsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showGoalDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        final m = ctrl.model.value;
        final pct = (m.today / (m.goal == 0 ? 1 : m.goal)).clamp(0.0, 1.0);
        final remainingSteps = (m.goal - m.today).clamp(0, m.goal);
        final last7 = (m.last7.length == 7) ? m.last7 : List.filled(7, 0);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Today's Progress Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        NumberFormat().format(m.today),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: pct,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pct >= 1 ? Colors.green : Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: pct >= 1 ? Colors.green : Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            '${NumberFormat().format(remainingSteps)} steps left',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Goal Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${NumberFormat().format(m.goal)} steps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Weekly Chart
              Text(
                'Last 7 Days',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: <ColumnSeries<int, String>>[
                    ColumnSeries<int, String>(
                      dataSource: last7,
                      xValueMapper: (data, index) =>
                          DateFormat('E').format(DateTime.now().subtract(Duration(days: 6 - index))),
                      yValueMapper: (data, _) => data,
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Monthly Chart Button
              ElevatedButton(
                onPressed: () => Get.to(() => MonthlyStepsScreen()),
                child: Text('View Monthly Progress'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showGoalDialog(BuildContext context) {
    final ctrl = Get.find<StepsController>();
    final textController = TextEditingController(text: ctrl.model.value.goal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Daily Goal'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Steps',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(textController.text) ?? 8000;
              ctrl.setGoal(goal);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}


// class StepsScreen extends StatelessWidget {
//   final ctrl = Get.put(StepsController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Step Tracker'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.settings),
//             onPressed: () => _showGoalDialog(context),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         final m = ctrl.model.value;
//         final pct = (m.today / (m.goal == 0 ? 1 : m.goal)).clamp(0.0, 1.0);
//         final remainingSteps = (m.goal - m.today).clamp(0, m.goal);
//
//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Today's Progress Card
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Today',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Text(
//                         '${NumberFormat().format(m.today)}',
//                         style: TextStyle(
//                           fontSize: 42,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       Text(
//                         'Steps',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       LinearProgressIndicator(
//                         value: pct,
//                         minHeight: 12,
//                         borderRadius: BorderRadius.circular(6),
//                         backgroundColor: Colors.grey[200],
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           pct >= 1 ? Colors.green : Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             '${(pct * 100).toStringAsFixed(0)}%',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: pct >= 1 ? Colors.green : Theme.of(context).primaryColor,
//                             ),
//                           ),
//                           Text(
//                             '${NumberFormat().format(remainingSteps)} steps left',
//                             style: TextStyle(
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Goal Info
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Daily Goal',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     '${NumberFormat().format(m.goal)} steps',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 20),
//
//               // Weekly Chart
//               Text(
//                 'Last 7 Days',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 10),
//               Container(
//                 height: 200,
//                 child: SfCartesianChart(
//                   primaryXAxis: CategoryAxis(),
//                   series: <ColumnSeries<int, String>>[
//                     ColumnSeries<int, String>(
//                       dataSource: m.last7,
//                       xValueMapper: (data, index) =>
//                           DateFormat('E').format(DateTime.now().subtract(Duration(days: 6 - index))),
//                       yValueMapper: (data, _) => data,
//                       color: Theme.of(context).primaryColor,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
//                     )
//                   ],
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Monthly Chart Button
//               ElevatedButton(
//                 onPressed: () => Get.to(() => MonthlyStepsScreen()),
//                 child: Text('View Monthly Progress'),
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
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
//     final textController = TextEditingController(text: ctrl.model.value.goal.toString());
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Set Daily Goal'),
//         content: TextField(
//           controller: textController,
//           keyboardType: TextInputType.number,
//           decoration: InputDecoration(
//             labelText: 'Steps',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final goal = int.tryParse(textController.text) ?? 8000;
//               ctrl.setGoal(goal);
//               Navigator.pop(context);
//             },
//             child: Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../main.dart';
// import '../controller/step_background_handler.dart';
// import '../controller/step_controller.dart';
//
// /// ---------------- Steps Screen & history ----------------
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:intl/intl.dart';
//
// class StepsScreen extends StatelessWidget {
//   final ctrl = Get.put(StepsController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Step Tracker'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.settings),
//             onPressed: () => _showGoalDialog(context),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         final m = ctrl.model.value;
//         final pct = (m.today / (m.goal == 0 ? 1 : m.goal)).clamp(0.0, 1.0);
//         final remainingSteps = (m.goal - m.today).clamp(0, m.goal);
//
//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Today's Progress Card
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Today',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Text(
//                         '${NumberFormat().format(m.today)}',
//                         style: TextStyle(
//                           fontSize: 42,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       Text(
//                         'Steps',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       LinearProgressIndicator(
//                         value: pct,
//                         minHeight: 12,
//                         borderRadius: BorderRadius.circular(6),
//                         backgroundColor: Colors.grey[200],
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           pct >= 1 ? Colors.green : Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             '${(pct * 100).toStringAsFixed(0)}%',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: pct >= 1 ? Colors.green : Theme.of(context).primaryColor,
//                             ),
//                           ),
//                           Text(
//                             '${NumberFormat().format(remainingSteps)} steps left',
//                             style: TextStyle(
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Goal Info
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Daily Goal',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     '${NumberFormat().format(m.goal)} steps',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 20),
//
//               // Weekly Chart
//               Text(
//                 'Last 7 Days',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 10),
//               Container(
//                 height: 200,
//                 child: SfCartesianChart(
//                   primaryXAxis: CategoryAxis(),
//                   series: <ColumnSeries<int, String>>[
//                   ColumnSeries<int, String>(
//                 dataSource: m.last7,
//                 xValueMapper: (data, index) =>
//                     DateFormat('E').format(DateTime.now().subtract(Duration(days: 6 - index))),
//                 yValueMapper: (data, _) => data,
//                 color: Theme.of(context).primaryColor,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
//                   )],
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Monthly Chart Button
//               ElevatedButton(
//                 onPressed: () => Get.to(() => MonthlyStepsScreen()),
//                 child: Text('View Monthly Progress'),
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
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
//     final textController = TextEditingController(text: ctrl.model.value.goal.toString());
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Set Daily Goal'),
//         content: TextField(
//           controller: textController,
//           keyboardType: TextInputType.number,
//           decoration: InputDecoration(
//             labelText: 'Steps',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final goal = int.tryParse(textController.text) ?? 8000;
//               ctrl.setGoal(goal);
//               Navigator.pop(context);
//             },
//             child: Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
// }
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
//
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No data available'));
//           }
//
//           final data = snapshot.data!;
//           final dates = data.keys.toList()..sort();
//           final values = dates.map((date) => data[date] ?? 0).toList();
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
//                         markerSettings: MarkerSettings(isVisible: true),
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

//
// class StepsScreen extends StatelessWidget {
//   final ctrl = Get.put(StepsController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Step Tracker')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Obx(() {
//           final m = ctrl.model.value;
//           final pct = (m.today / (m.goal == 0 ? 1 : m.goal)).clamp(0.0, 1.0);
//           return Column(
//             children: [
//               Text('${m.today} Steps', style: TextStyle(fontSize: 36)),
//               LinearProgressIndicator(value: pct),
//               Text('Goal: ${m.goal}'),
//             ],
//           );
//         }),
//       ),
//     );
//   }
// }



// class StepsScreen extends StatelessWidget {
//   final ctrl = Get.find<StepsController>();
//   StepsScreen({Key? key}) : super(key: key);
//
//   List<FlSpot> _toSpots(List<int> data) {
//     final len = data.length;
//     return List.generate(len, (i) => FlSpot(i.toDouble(), data[i].toDouble()));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Steps')),
//       body: Padding(padding: EdgeInsets.all(kPad), child: Column(children: [
//         Obx(() {
//           final m = ctrl.model.value;
//           final pct = (m.today / (m.goal==0?1:m.goal)).clamp(0.0,1.0);
//           final calories = (m.today * 0.04).toStringAsFixed(1);
//           final dist = (m.today * 0.0008).toStringAsFixed(2);
//           return Column(children: [
//             Text('${m.today}', style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
//             SizedBox(height:8),
//             LinearProgressIndicator(value: pct, minHeight: 10),
//             SizedBox(height:8),
//             Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
//               Column(children: [Text('Calories'), SizedBox(height:4), Text('$calories kcal')]),
//               Column(children: [Text('Distance'), SizedBox(height:4), Text('$dist km')]),
//             ]),
//             SizedBox(height: 12),
//             Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//               ElevatedButton(onPressed: ()=> ctrl.addSteps(500), child: Text('+500 (mock)')),
//               SizedBox(width:12),
//               OutlinedButton(onPressed: ()=> _openSetGoal(context), child: Text('Set Goal')),
//             ])
//           ]);
//         }),
//
//         SizedBox(height: 12),
//
//         // Expanded(child: Card(child: Padding(padding: EdgeInsets.all(8), child: Obx(() {
//         //   final data = ctrl.model.value.last7;
//         //   final spots = _toSpots(data.reversed.toList()); // show last7 with oldest first
//         //   return LineChart(LineChartData(
//         //     lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: kPrimary, dotData: FlDotData(show:false))],
//         //     minY: 0,
//         //     gridData: FlGridData(show:false),
//         //     titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles:true,getTitlesWidget: (v,meta){
//         //       final idx = v.toInt();
//         //       final label = ['6d','5d','4d','3d','2d','1d','Today'];
//         //       if (idx >=0 && idx < label.length) return SideTitleWidget(child: Text(label[idx], style: TextStyle(fontSize:10)), side: meta.axisSide);
//         //       return SideTitleWidget(child: Text(''), axisSide: meta.axisSide);
//         //     }),), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles:false))),
//         //   ));
//         // })))),
//
//       ])),
//     );
//   }
//
//   void _openSetGoal(BuildContext ctx) {
//     final tc = TextEditingController(text: ctrl.model.value.goal.toString());
//     showDialog(context: ctx, builder: (_) => AlertDialog(
//       title: Text('Set step goal'),
//       content: TextField(controller: tc, keyboardType: TextInputType.number),
//       actions: [ TextButton(onPressed: ()=> Get.back(), child: Text('Cancel')), TextButton(onPressed: (){
//         final v = int.tryParse(tc.text.trim());
//         if (v!=null) ctrl.setGoal(v);
//         Get.back();
//       }, child: Text('Save')) ],
//     ));
//   }
// }