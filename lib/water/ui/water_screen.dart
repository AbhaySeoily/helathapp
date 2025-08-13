import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../main.dart';
import '../controller/water_controller/water_controller.dart';

/// ---------------- Water Screens ----------------
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../controller/water_controller/water_controller.dart';
import '../../main.dart';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../main.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../main.dart';

class WaterScreen extends StatelessWidget {
  final ctrl = Get.find<WaterController>();
  WaterScreen({Key? key}) : super(key: key);

  Widget _barRows(List<int> data) {
    final maxv = data.reduce(max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((v) {
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: maxv == 0 ? 0 : 100 * (v / maxv),
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(height: 6),
              Text('$v', style: TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _openSetGoal(BuildContext ctx) {
    final reminders = <TimeOfDay>[];
    int goal = ctrl.model.value.goal.clamp(1000, 5000); // initial value

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Set Daily Goal & Reminders'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Goal: $goal ml'),
              Slider(
                value: goal.toDouble(),
                min: 1000,
                max: 5000,
                divisions: 8,
                label: '$goal ml',
                onChanged: (v) => setState(() => goal = v.round()),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final t = await showTimePicker(
                      context: ctx, initialTime: TimeOfDay.now());
                  if (t != null) setState(() => reminders.add(t));
                },
                child: Text('Add Reminder'),
              ),
              SizedBox(height: 8),
              Text('Reminders: ${reminders.map((e) => '${e.hour}:${e.minute}').join(', ')}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
            TextButton(
                onPressed: () {
                  ctrl.setGoal(goal, reminders: reminders);
                  Get.back();
                },
                child: Text('Save')),
          ],
        ),
      ),
    );
  }

  void _openHistory(BuildContext ctx) {
    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: Text('Water History (Last 7 Days)'),
          content: Obx(() {
            final m = ctrl.model.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (i) {
                final date =
                DateTime.now().subtract(Duration(days: i));
                return ListTile(
                  title: Text(
                      '${date.day}/${date.month} : ${m.last7[i]} ml'),
                );
              }),
            );
          }),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: Text('Close'))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Water Tracker')),
      body: Padding(
        padding: EdgeInsets.all(kPad),
        child: Column(
          children: [
            Obx(() {
              final m = ctrl.model.value;
              final pct =
              (m.intake / (m.goal == 0 ? 1 : m.goal)).clamp(0.0, 1.0);
              return Column(
                children: [
                  Text('${m.intake} / ${m.goal} ml',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  CircularPercentIndicator(
                    radius: 70,
                    lineWidth: 10,
                    percent: pct,
                    center: Text('${(pct * 100).toStringAsFixed(0)}%'),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                          onPressed: () => ctrl.addWater(100),
                          child: Text('+100ml')),
                      ElevatedButton(
                          onPressed: () => ctrl.addWater(250),
                          child: Text('+250ml')),
                      ElevatedButton(
                          onPressed: () => ctrl.addWater(500),
                          child: Text('+500ml')),
                    ],
                  ),
                  SizedBox(height: 8),
                  OutlinedButton(
                      onPressed: () => _openSetGoal(context),
                      child: Text('Set Daily Goal & Reminders')),
                  SizedBox(height: 4),
                  OutlinedButton(
                      onPressed: () => _openHistory(context),
                      child: Text('View History')),
                ],
              );
            }),
            SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Obx(() => _barRows(ctrl.model.value.last7)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
