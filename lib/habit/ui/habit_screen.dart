import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../controller/habit_controller.dart';
import 'history_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../controller/habit_controller.dart';
import 'history_screen.dart';

class HabitScreen extends StatelessWidget {
  HabitScreen({super.key});

  final ctrl = Get.find<HabitController>();

  void _showAddHabitDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add New Habit",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Habit Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.task_alt_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Target Count (per day)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.flag_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Notes (optional)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text("Add", style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final notes = notesCtrl.text.trim();
                        final target = int.tryParse(targetCtrl.text.trim()) ?? 1;
                        if (name.isNotEmpty) {
                          ctrl.addHabit(name, targetCount: target, notes: notes);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Today\'s Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: "View History",
            onPressed: () => Get.to(() => const HistoryScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Habit"),
      ),
      body: Obx(() {
        if (ctrl.habits.isEmpty) {
          return const Center(
            child: Text("No habits yet. Tap 'Add Habit' to create one."),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.habits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final h = ctrl.habits[index];
            final progress = (h.targetCount == 0)
                ? 0.0
                : (h.completedCount / h.targetCount).clamp(0, 1).toDouble();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + delete
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            h.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: h.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => ctrl.deleteHabit(index),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    if (h.notes != null && h.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(h.notes!, style: TextStyle(color: Colors.grey[700])),
                    ],
                    const SizedBox(height: 10),
                    LinearPercentIndicator(
                      lineHeight: 10,
                      percent: progress,
                      backgroundColor: Colors.grey.shade300,
                      progressColor: progress >= 1 ? Colors.green : Colors.blue,
                      barRadius: const Radius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${h.completedCount} / ${h.targetCount} completed",
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => ctrl.decrementProgress(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => ctrl.incrementProgress(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// class HabitScreen extends StatelessWidget {
//   final ctrl = Get.find<HabitController>();
//   final nameCtrl = TextEditingController();
//   final targetCtrl = TextEditingController();
//
//   HabitScreen({Key? key}) : super(key: key);
//
//   // void _showAddHabitDialog(BuildContext context) {
//   //   nameCtrl.clear();
//   //   targetCtrl.clear();
//   //   showDialog(
//   //     context: context,
//   //     builder: (_) => AlertDialog(
//   //       title: Text("Add New Habit"),
//   //       content: Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [
//   //           TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Habit Name")),
//   //           TextField(
//   //             controller: targetCtrl,
//   //             decoration: InputDecoration(labelText: "Daily Target (e.g. 4)"),
//   //             keyboardType: TextInputType.number,
//   //           ),
//   //         ],
//   //       ),
//   //       actions: [
//   //         TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
//   //         ElevatedButton(
//   //           onPressed: () {
//   //             if (nameCtrl.text.trim().isNotEmpty) {
//   //               ctrl.addHabit(
//   //                 nameCtrl.text.trim(),
//   //                 targetCount: int.tryParse(targetCtrl.text.trim()) ?? 1,
//   //               );
//   //               Navigator.pop(context);
//   //             }
//   //           },
//   //           child: Text("Add"),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//
//
//   void _showAddHabitDialog(BuildContext context) {
//     final ctrl = Get.find<HabitController>();
//     final nameCtrl = TextEditingController();
//     final notesCtrl = TextEditingController();
//     final targetCtrl = TextEditingController(text: "1");
//
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text("Add New Habit",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: nameCtrl,
//                   decoration: InputDecoration(
//                     labelText: "Habit Name",
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                     prefixIcon: const Icon(Icons.task_alt_rounded),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: targetCtrl,
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(
//                     labelText: "Target Count (per day)",
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                     prefixIcon: const Icon(Icons.flag_rounded),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: notesCtrl,
//                   maxLines: 2,
//                   decoration: InputDecoration(
//                     labelText: "Notes (optional)",
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                     prefixIcon: const Icon(Icons.notes_rounded),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
//                     const SizedBox(width: 8),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.add_rounded, color: Colors.white),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       label: const Text("Add", style: TextStyle(color: Colors.white)),
//                       onPressed: () {
//                         final name = nameCtrl.text.trim();
//                         final target = int.tryParse(targetCtrl.text.trim()) ?? 1;
//                         final notes = notesCtrl.text.trim();
//                         if (name.isNotEmpty) {
//                           ctrl.addHabit(name, targetCount: target, notes: notes);
//                           Navigator.pop(context);
//                         }
//                       },
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Habits'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history_rounded),
//             tooltip: "View History",
//             onPressed: () {
//               Get.to(() => const HistoryScreen());
//             },
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddHabitDialog(context),
//         child: Icon(Icons.add),
//       ),
//       body: Obx(() => ListView.separated(
//         padding: EdgeInsets.all(12),
//         itemCount: ctrl.habits.length,
//         separatorBuilder: (_, __) => SizedBox(height: 10),
//         itemBuilder: (context, index) {
//           final h = ctrl.habits[index];
//           double progress = h.targetCount > 0 ? h.completedCount / h.targetCount : 0;
//           return Card(
//             elevation: 3,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(h.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   SizedBox(height: 8),
//                   LinearPercentIndicator(
//                     lineHeight: 8,
//                     percent: progress > 1 ? 1 : progress,
//                     backgroundColor: Colors.grey.shade300,
//                     progressColor: progress >= 1 ? Colors.green : Colors.blue,
//                     barRadius: Radius.circular(8),
//                   ),
//                   SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text("${h.completedCount} / ${h.targetCount} completed"),
//                       Row(
//                         children: [
//                           IconButton(
//                             icon: Icon(Icons.remove_circle, color: Colors.red),
//                             onPressed: () => ctrl.decrementProgress(index),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.add_circle, color: Colors.green),
//                             onPressed: () => ctrl.incrementProgress(index),
//                           ),
//                         ],
//                       )
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           );
//         },
//       )),
//     );
//   }
// }

