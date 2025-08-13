// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import '../controller/meal_controller.dart';
//
// class MealScreen extends StatelessWidget {
//   final ctrl = Get.find<MealController>();
//   final picker = ImagePicker();
//
//   void _openAdd(BuildContext ctx, {bool isPlanned = false}) async {
//     final nameCtrl = TextEditingController();
//     final caloriesCtrl = TextEditingController();
//     String slot = 'Breakfast';
//     String? imagePath;
//     showDialog(
//         context: ctx,
//         builder: (_) => AlertDialog(
//           title: Text(isPlanned ? 'Plan Meal' : 'Add Meal'),
//           content: StatefulBuilder(builder: (c, s) {
//             return Column(mainAxisSize: MainAxisSize.min, children: [
//               DropdownButton<String>(
//                   value: slot,
//                   items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
//                       .map((e) =>
//                       DropdownMenuItem(child: Text(e), value: e))
//                       .toList(),
//                   onChanged: (v) => s(() => slot = v!)),
//               TextField(
//                   controller: nameCtrl,
//                   decoration: InputDecoration(labelText: 'Meal name')),
//               TextField(
//                   controller: caloriesCtrl,
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(labelText: 'Calories')),
//               SizedBox(height: 8),
//               Row(children: [
//                 ElevatedButton(
//                     onPressed: () async {
//                       final x = await picker.pickImage(
//                           source: ImageSource.gallery, maxWidth: 600);
//                       if (x != null) s(() => imagePath = x.path);
//                     },
//                     child: Text('Pick Photo')),
//                 SizedBox(width: 8),
//                 Text(imagePath == null ? 'No photo' : 'Photo selected')
//               ]),
//             ]);
//           }),
//           actions: [
//             TextButton(
//                 onPressed: () => Get.back(), child: Text('Cancel')),
//             TextButton(
//                 onPressed: () {
//                   final name = nameCtrl.text.trim();
//                   final cals =
//                       int.tryParse(caloriesCtrl.text.trim()) ?? 0;
//                   if (name.isNotEmpty) {
//                     ctrl.addMeal(slot, name, cals,
//                         image: imagePath, isPlanned: isPlanned);
//                   }
//                   Get.back();
//                 },
//                 child: Text('Save'))
//           ],
//         ));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text('Meals & Nutrition'), actions: [
//           IconButton(
//               icon: Icon(Icons.calendar_today),
//               onPressed: () async {
//                 final picked = await showDatePicker(
//                     context: context,
//                     initialDate: ctrl.selectedDate.value,
//                     firstDate: DateTime(2020),
//                     lastDate: DateTime(2100));
//                 if (picked != null) ctrl.selectedDate.value = picked;
//               })
//         ]),
//         body: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(children: [
//               Row(
//                 children: [
//                   ElevatedButton(
//                       onPressed: () => _openAdd(context),
//                       child: Text('Add Meal')),
//                   SizedBox(width: 10),
//                   ElevatedButton(
//                       onPressed: () => _openAdd(context, isPlanned: true),
//                       child: Text('Plan Meal')),
//                 ],
//               ),
//               SizedBox(height: 12),
//               Expanded(
//                   child: Obx(() {
//                     final items =
//                     ctrl.mealsForDate(ctrl.selectedDate.value);
//                     return ListView(
//                         children: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
//                             .map((slot) {
//                           final slotItems =
//                           items.where((m) => m.slot == slot).toList();
//                           return ExpansionTile(
//                               title: Text('$slot (${slotItems.length})'),
//                               children: slotItems
//                                   .map((it) => ListTile(
//                                 title: Text(it.name),
//                                 subtitle: Text(
//                                     '${it.calories} kcal - ${it.isPlanned ? (it.isCompleted ? "Completed" : "Planned") : "Actual"}'),
//                                 trailing: it.isPlanned && !it.isCompleted
//                                     ? IconButton(
//                                     icon: Icon(Icons.check_circle,
//                                         color: Colors.green),
//                                     onPressed: () =>
//                                         ctrl.markCompleted(it))
//                                     : null,
//                               ))
//                                   .toList());
//                         }).toList());
//                   }))
//             ])));
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/meal_controller.dart';
import '../model/meal.dart';

class MealScreen extends StatelessWidget {
  final MealController controller = Get.put(MealController());

  MealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meals & Nutrition'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddMealDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Calendar view
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Obx(() {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.dates.length,
                itemBuilder: (_, i) {
                  final date = controller.dates[i];
                  final isSelected =
                      controller.selectedDate.value.day == date.day &&
                          controller.selectedDate.value.month == date.month &&
                          controller.selectedDate.value.year == date.year;

                  final hasMeal = controller.mealDates.any((d) =>
                      d.day == date.day &&
                      d.month == date.month &&
                      d.year == date.year);

                  return GestureDetector(
                    onTap: () => controller.selectDate(date),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            _monthName(date.month),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                          if (hasMeal)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 10),

          // Tabs
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton("Planned", 0),
                  const SizedBox(width: 10),
                  _buildTabButton("Eaten", 1),
                ],
              )),

          const SizedBox(height: 10),

          // Meal List
          Expanded(
            child: Obx(() {
              final meals = controller.selectedTab.value == 0
                  ? controller.plainMeals
                      .where((m) =>
                          m.date.day == controller.selectedDate.value.day &&
                          m.date.month == controller.selectedDate.value.month &&
                          m.date.year == controller.selectedDate.value.year)
                      .toList()
                  : controller.eatenMeals
                      .where((m) =>
                          m.date.day == controller.selectedDate.value.day &&
                          m.date.month == controller.selectedDate.value.month &&
                          m.date.year == controller.selectedDate.value.year)
                      .toList();

              if (meals.isEmpty) {
                return const Center(
                  child: Text(
                    'No meals found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: meals.length,
                itemBuilder: (_, i) {
                  final meal = meals[i];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: meal.imagePath != null
                          ? Image.file(File(meal.imagePath!),
                              width: 50, fit: BoxFit.cover)
                          : const CircleAvatar(child: Icon(Icons.fastfood)),
                      title: Text(meal.name),
                      subtitle: Text(
                          "${meal.slot ?? 'Meal'} • ${meal.calories ?? 0} kcal"),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = controller.selectedTab.value == index;
    return GestureDetector(
      onTap: () => controller.selectedTab.value = index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _openAddMealDialog() {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    String slot = "Meal"; // optional
    String? imgPath;
    final picker = ImagePicker();

    Get.defaultDialog(
      title: controller.selectedTab.value == 0 ? "Plan Meal" : "Add Eaten Meal",
      content: Column(
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: "Meal Name"),
          ),
          TextField(
            controller: calCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Calories (optional)"),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final picked =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) imgPath = picked.path;
                },
                child: const Text("Pick Image"),
              ),
              if (imgPath != null) const Icon(Icons.check, color: Colors.green),
            ],
          ),
        ],
      ),
      textCancel: "Cancel",
      textConfirm: "Save",
      onConfirm: () {
        if (nameCtrl.text.isEmpty) return;

        final meal = Meal(
          name: nameCtrl.text,
          date: controller.selectedDate.value,
          imagePath: imgPath,
        );

        if (controller.selectedTab.value == 0) {
          controller.plainMeals.add(meal);
        } else {
          controller.eatenMeals.add(meal);
        }

        controller.mealDates.add(controller.selectedDate.value); // for dot
        Get.back();
      },
    );
  }
}
