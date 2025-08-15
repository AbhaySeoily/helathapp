import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../controller/habit_controller.dart';

class HabitScreen extends StatelessWidget {
  final ctrl = Get.find<HabitController>();
  final nameCtrl = TextEditingController();
  final targetCtrl = TextEditingController();

  HabitScreen({Key? key}) : super(key: key);

  void _showAddHabitDialog(BuildContext context) {
    nameCtrl.clear();
    targetCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add New Habit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Habit Name")),
            TextField(
              controller: targetCtrl,
              decoration: InputDecoration(labelText: "Daily Target (e.g. 4)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                ctrl.addHabit(
                  nameCtrl.text.trim(),
                  targetCount: int.tryParse(targetCtrl.text.trim()) ?? 1,
                );
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Habits with Sub-Tasks")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        child: Icon(Icons.add),
      ),
      body: Obx(() => ListView.separated(
        padding: EdgeInsets.all(12),
        itemCount: ctrl.habits.length,
        separatorBuilder: (_, __) => SizedBox(height: 10),
        itemBuilder: (context, index) {
          final h = ctrl.habits[index];
          double progress = h.targetCount > 0 ? h.completedCount / h.targetCount : 0;
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 8,
                    percent: progress > 1 ? 1 : progress,
                    backgroundColor: Colors.grey.shade300,
                    progressColor: progress >= 1 ? Colors.green : Colors.blue,
                    barRadius: Radius.circular(8),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${h.completedCount} / ${h.targetCount} completed"),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => ctrl.decrementProgress(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () => ctrl.incrementProgress(index),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      )),
    );
  }
}

