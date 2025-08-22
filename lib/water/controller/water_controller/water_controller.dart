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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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

  void addWater(int ml, {bool beforeReminder = true}) {
    model.update((m) {
      if (m == null) return;

      final key = DateTime.now().toIso8601String().split('T')[0];
      m.dailyIntake[key] = (m.dailyIntake[key] ?? 0) + ml;
      m.intake = m.dailyIntake[key]!;
      m.last7 = [m.intake, ...m.last7.sublist(1)];
    });

    // Award points
    final prevPoints = box.read(KS_WATER_REWARD) ?? 0;
    box.write(KS_WATER_REWARD, prevPoints + (beforeReminder ? 15 : 10));

    box.write(KS_WATER, model.value.toJson());
  }

  /// ---------------- Set goal + reminders ----------------
  void setGoal(int goal, {List<WaterReminder>? reminders}) {
    model.update((m) {
      if (m == null) return;
      m.goal = goal;
      if (reminders != null) m.reminderList = reminders;
    });
    box.write(KS_WATER, model.value.toJson());
  }

  /// ---------------- Check if current time is before next reminder ----------------
  bool isBeforeNextReminder() {
    final now = DateTime.now();
    final reminders = model.value.reminderList;
    if (reminders.isEmpty) return true;

    reminders.sort((a, b) =>
    a.time.hour * 60 + a.time.minute - (b.time.hour * 60 + b.time.minute));

    for (var r in reminders) {
      final reminderTime =
      DateTime(now.year, now.month, now.day, r.time.hour, r.time.minute);
      if (now.isBefore(reminderTime)) return true;
    }
    return false;
  }
}
