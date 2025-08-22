import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../main.dart';
import '../../notification/notification_service.dart';
import '../controller/water_controller/water_controller.dart';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../main.dart';
import '../controller/water_controller/water_controller.dart';
import '../model/water_model.dart';

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

  /// ---------------- Add water and award points ----------------
  void _addWater(int ml) {
    bool beforeReminder = ctrl.isBeforeNextReminder();
    ctrl.addWater(ml, beforeReminder: beforeReminder);

    // Show snackbar
    Get.snackbar(
      "Water Logged",
      beforeReminder
          ? "+15 points (before reminder)"
          : "+10 points (after reminder)",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// ---------------- Set goal and multiple reminders ----------------
  void openSetGoalDialog(BuildContext context) {
    final ctrl = Get.find<WaterController>();
    int goal = ctrl.model.value.goal;
    List<WaterReminder> reminders = List.from(ctrl.model.value.reminderList);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Set Daily Goal & Reminders'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Goal: $goal ml'),
                Slider(
                  value: goal.toDouble(),
                  min: 500,
                  max: 5000,
                  divisions: 9,
                  label: '$goal ml',
                  onChanged: (v) => setState(() => goal = v.round()),
                ),
                SizedBox(height: 12),

                // Add new reminder
                ElevatedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) {
                      final qtyController = TextEditingController(text: "250");
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Set Quantity for ${t.format(context)}'),
                          content: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Quantity (ml)'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                final qty = int.tryParse(qtyController.text) ?? 250;
                                setState(() {
                                  reminders.add(WaterReminder(
                                    time: t,
                                    amount: qty,
                                  ));
                                });
                                Get.back();
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text('Add Reminder'),
                ),
                SizedBox(height: 12),

                // Display reminders
                if (reminders.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reminders:'),
                      ...reminders.map((r) => ListTile(
                        title: Text(
                            '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')} - ${r.amount} ml'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                final newTime = await showTimePicker(
                                  context: context,
                                  initialTime: r.time,
                                );
                                if (newTime != null) {
                                  final qtyController =
                                  TextEditingController(text: r.amount.toString());
                                  await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('Update Quantity'),
                                      content: TextField(
                                        controller: qtyController,
                                        keyboardType: TextInputType.number,
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Get.back(),
                                            child: Text('Cancel')),
                                        TextButton(
                                            onPressed: () {
                                              final qty = int.tryParse(qtyController.text) ?? r.amount;
                                              setState(() {
                                                r.time = newTime;
                                                r.amount = qty;
                                              });
                                              Get.back();
                                            },
                                            child: Text('Update')),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => setState(() => reminders.remove(r)),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                ctrl.setGoal(
                  goal,
                  reminders: reminders,
                );
                Get.back();
              },
              child: Text('Save'),
            ),
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
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),

            child: Obx(() {
              final m = ctrl.model.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (i) {
                  final date = DateTime.now().subtract(Duration(days: i));
                  return ListTile(
                    title: Text('${date.day}/${date.month} : ${m.last7[i]} ml'),
                  );
                }),
              );
            }),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Close'))
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
              final pct = (m.intake / (m.goal == 0 ? 1 : m.goal)).clamp(0.0, 1.0);
              final points = ctrl.box.read(KS_WATER_REWARD) ?? 0;
              return Column(
                children: [
                  Text('${m.intake} / ${m.goal} ml',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Reward Points: $points', style: TextStyle(fontSize: 16)),
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
                          onPressed: () => _addWater(100), child: Text('+100ml')),
                      ElevatedButton(
                          onPressed: () => _addWater(250), child: Text('+250ml')),
                      ElevatedButton(
                          onPressed: () => _addWater(500), child: Text('+500ml')),
                    ],
                  ),
                  SizedBox(height: 8),
                  OutlinedButton(
                      onPressed: () => openSetGoalDialog(context),
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
