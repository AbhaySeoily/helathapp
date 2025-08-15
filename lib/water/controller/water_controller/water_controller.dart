// // WaterController
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import '../../../main.dart';
// import '../../model/water_model.dart';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
//
// import '../../model/water_model.dart';
// import '../../../main.dart';
//
// class WaterController extends GetxController {
//   final box = GetStorage();
//   Rx<WaterModel> model = WaterModel(goal: 2000).obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     final stored = box.read(KS_WATER);
//     if (stored != null && stored is Map) {
//       model.value = WaterModel.fromJson(Map<String, dynamic>.from(stored));
//     }
//   }
//
//   void addWater(int ml) {
//     model.update((m) {
//       if (m == null) return;
//       m.intake += ml;
//       m.last7[0] = m.intake; // today’s value
//     });
//     box.write(KS_WATER, model.value.toJson());
//   }
//
//   void setGoal(int ml, {List<TimeOfDay>? reminders}) {
//     model.update((m) {
//       if (m == null) return;
//       m.goal = ml;
//       if (reminders != null) m.reminders = reminders;
//     });
//     box.write(KS_WATER, model.value.toJson());
//   }
// }
//
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../main.dart';
import '../../model/water_model.dart';

class WaterController extends GetxController {
  final box = GetStorage();
  Rx<WaterModel> model = WaterModel(goal: 2000).obs;

  @override
  void onInit() {
    super.onInit();
    final stored = box.read(KS_WATER);
    if (stored != null && stored is Map) {
      model.value = WaterModel.fromJson(Map<String, dynamic>.from(stored));
    }
  }

  void addWater(int ml) {
    model.update((m) {
      if (m == null) return;

      // Today key
      final key = DateTime.now().toIso8601String().split('T')[0];

      // Update dailyIntake with a new map
      final updatedDaily = {...m.dailyIntake};
      updatedDaily[key] = (updatedDaily[key] ?? 0) + ml;
      m.dailyIntake = updatedDaily;

      // Update today's intake
      m.intake = updatedDaily[key]!;

      // Update last7 with a new list
      m.last7 = [m.intake, ...m.last7.sublist(1)];
    });

    // Save to storage
    box.write(KS_WATER, model.value.toJson());
  }

  void setGoal(int ml, {List<TimeOfDay>? reminders}) {
    model.update((m) {
      if (m == null) return;

      m.goal = ml;
      if (reminders != null) m.reminders = reminders;
    });
    box.write(KS_WATER, model.value.toJson());
  }
}
