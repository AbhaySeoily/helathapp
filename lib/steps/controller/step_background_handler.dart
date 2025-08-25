

import 'dart:async';
import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:wellness_getx_app/steps/controller/step_controller.dart' hide KS_STEPS;

import '../../main.dart';
import '../../notification/notification_service.dart';
import '../model/step_model.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';



@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StepTaskHandler());
}

class StepTaskHandler extends TaskHandler {
  final _box = GetStorage();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("🟢 Background task started at $timestamp");
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    int steps = _box.read("$KS_STEPS_PREFIX$todayKey") ?? 0;
    int goal = _box.read(KS_DAILY_GOAL) ?? 0;

    FlutterForegroundTask.updateService(
      notificationTitle: "Step Counter",
      notificationText: "$steps / $goal steps",
    );

    // Goal notification safety (background check)
    final notifyKey = "$KS_GOAL_NOTIFIED_PREFIX$todayKey";
    bool alreadyNotified = _box.read(notifyKey) ?? false;

    if (goal > 0 && steps >= goal && !alreadyNotified) {
      NotificationService.showNotification(
        channelId: "stepcounts",
        channelName: "step_counter",
        title: "Goal Achieved 🎉",
        body: "Great job! You reached $goal steps today.",
      );
      _box.write(notifyKey, true);
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("🛑 Background task destroyed");
  }

  @override
  void onButtonPressed(String id) {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // 👇 Agar aap repeat ke time par bhi same kaam chahte ho to yahan call kar do
    await onEvent(timestamp, sendPort);
  }
}

// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(StepBackgroundHandler());
// }
//
// class StepBackgroundHandler extends TaskHandler {
//   final _notifications = FlutterLocalNotificationsPlugin();
//   final _box = GetStorage();
//   final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//   StreamSubscription<StepCount>? _stepSub;
//   DateTime? _lastStepTime;
//   int? _lastStepCount;
//   String _bgTodayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//   int _bgBaseline = 0;
//
//   @override
//   Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
//
//     // Init notifications
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const initSettings = InitializationSettings(android: androidInit);
//     await _notifications.initialize(initSettings);
//
//     // Listen to steps
//     _stepSub = Pedometer.stepCountStream.listen(_onStepEvent);
//   }
//
//   void _onStepEvent(StepCount event) {
//     final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//     // ✅ Naya din aaya to hi baseline reset karo
//     if (today != _bgTodayKey) {
//       _bgTodayKey = today;
//
//       // Pehle se baseline hai to use karo, nahi to naya set karo
//       _bgBaseline = _box.read<int>("$KS_BASELINE_PREFIX$_bgTodayKey") ?? event.steps;
//
//       _box.write("$KS_BASELINE_PREFIX$_bgTodayKey", _bgBaseline);
//     }
//
//     // ✅ Yahan se todaySteps nikalna
//     final baseline = _box.read<int>("$KS_BASELINE_PREFIX$_bgTodayKey") ?? event.steps;
//     final todaySteps = event.steps - baseline;
//
//     // ✅ Goal same key se
//     final goal = _box.read(ks_daily_goal) ?? 8000;
//
//     // ✅ Save steps in GetStorage
//     _box.write("steps_$_bgTodayKey", todaySteps);
//
//     int goala = _box.read<int>("dailyStepGoal") ?? 1000;
//     print("🎯 Goal loaded in isolate: $goala");
//
//
//     // Save model (UI use karega)
//     final model = StepsModel(today: todaySteps, goal: goal, last7: []);
//     _box.write(KS_STEPS, model.toJson());
//     Rx<StepsModel> modell = StepsModel(today: 0, goal: 8000, last7: []).obs;
//
//     _lastStepTime = event.timeStamp;
//     _lastStepCount = event.steps;
//     int steps = _box.read("steps_$_bgTodayKey") ?? 0;
//     print("CHECKING HERE STEPTSSSS_  ${_box.read("steps_$_bgTodayKey")}");
//     print("🔔 Notificationdddd Update: $steps / $goal");
//     // ⚡ Foreground notification ko bhi yahi se update kar do
//     FlutterForegroundTask.updateService(
//       notificationTitle: 'Step Counter',
//       notificationText: '$steps / $goal steps',
//     );
//   }
//
//   // void _onStepEvent(StepCount event) {
//   //   final today = DateFormat('yyyy-MM-dd').format(DateTime.now()); // ✅ yahan hi fresh date lo
//   //
//   //   // Switch to new day
//   //   if (today != _bgTodayKey) {
//   //     _bgTodayKey = today;
//   //     _bgBaseline = event.steps;
//   //     _box.write("$KS_BASELINE_PREFIX$_bgTodayKey", _bgBaseline);
//   //   }
//   //
//   //   final baseline = _box.read<int>("$KS_BASELINE_PREFIX$_bgTodayKey") ?? event.steps;
//   //   final todaySteps = event.steps - baseline;
//   //
//   //
//   //   // ✅ Goal GetStorage se uthao (correct key use karo)
//   //   final goal = _box.read(ks_daily_goal) ?? 8000;
//   //
//   //   // ✅ Save steps in GetStorage
//   //   _box.write("steps_$_bgTodayKey", todaySteps);
//   //
//   //
//   //   // Save in storage
//   //   final model = StepsModel(today: todaySteps, goal: goal, last7: []);
//   //   _box.write(KS_STEPS, model.toJson());
//   //
//   //   // Save detailed record (slow/brisk detection yahan handle karna hai)
//   //   // Example placeholder
//   //   if (todaySteps % 2 == 0) {
//   //     _box.write("$KS_SLOW_PREFIX$_bgTodayKey", todaySteps);
//   //   } else {
//   //     _box.write("$KS_BRISK_PREFIX$_bgTodayKey", todaySteps);
//   //   }
//   //
//   //   _lastStepTime = event.timeStamp;
//   //   _lastStepCount = event.steps;
//   // }
//
//   // @override
//   // Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
//   //   try {
//   //     final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//   //
//   //     // ✅ Always read from steps_<today>
//   //     final todaySteps = _box.read<int>("steps_$todayKey") ?? 0;
//   //
//   //     // ✅ Goal bhi same key se uthao
//   //     final goal = _box.read(ks_daily_goal) ?? 8000;
//   //     final stored = _box.read(KS_STEPS);
//   //     // int todaySteps = 0;
//   //     // int goal = _box.read("step_goal") ?? 1200; // ✅ Goal yahan bhi storage se
//   //
//   //     if (stored != null && stored is Map) {
//   //       final model = StepsModel.fromJson(Map.from(stored));
//   //       //todaySteps = model.today;
//   //       //goal = model.goal;
//   //     }
//   //     String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//   //
//   //     int todayStepsz = _box.read<int>("steps_$_bgTodayKey") ?? 0;
//   //     FlutterForegroundTask.updateService(
//   //       notificationTitle: 'Step Tracker Running',
//   //       notificationText: 'Today Steps: $todaySteps / $goal',
//   //
//   //     );
//   //
//   //     if (todaySteps < goal && todaySteps > goal * 0.8) {
//   //       final remaining = goal - todaySteps;
//   //
//   //       const androidDetails = AndroidNotificationDetails(
//   //         'background_motivation',
//   //         'Background Motivation',
//   //         channelDescription: 'Motivational notifications',
//   //         importance: Importance.defaultImportance,
//   //         priority: Priority.defaultPriority,
//   //       );
//   //       const platformDetails = NotificationDetails(android: androidDetails);
//   //
//   //       await _notifications.show(
//   //         103,
//   //         'You Can Do It!',
//   //         'Only ${NumberFormat().format(remaining)} steps left!',
//   //         platformDetails,
//   //       );
//   //     }
//   //   } catch (_) {}
//   // }
//
//   @override
//   Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
//     try {
//       print("CODE IS RUNNING onRepeatEvent onRepeatEvent onRepeatEvent onRepeatEvent onRepeatEvent");
//       String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//       int todaySteps = _box.read<int>("steps_$today") ?? 0;
//       int goal = _box.read(ks_daily_goal) ?? 1200;
//
//       // ✅ Live update notification
//       // await FlutterForegroundTask.updateService(
//       //   notificationTitle: 'Step Tracker Running',
//       //   notificationText: '$todaySteps / $goal steps',
//       // );
//       print("🔔 Notification Update: $todaySteps / $goal");
//
//       // await FlutterForegroundTask.updateService(
//       //   notificationTitle: 'Step Tracker Running',
//       //   notificationText: '$todaySteps / $goal steps',
//       // );
//       // Motivation push
//       if (todaySteps < goal && todaySteps > goal * 0.8) {
//         final remaining = goal - todaySteps;
//
//         const androidDetails = AndroidNotificationDetails(
//           'background_motivation',
//           'Background Motivation',
//           channelDescription: 'Motivational notifications',
//           importance: Importance.defaultImportance,
//           priority: Priority.defaultPriority,
//         );
//         const platformDetails = NotificationDetails(android: androidDetails);
//
//         await _notifications.show(
//           103,
//           'You Can Do It!',
//           'Only $remaining steps left!',
//           platformDetails,
//         );
//       }
//     } catch (e) {
//       print("Error in repeat: $e");
//     }
//   }
//
//
//   @override
//   Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
//     await _stepSub?.cancel();
//   }
//
//   @override
//   void onNotificationPressed() {
//     FlutterForegroundTask.launchApp();
//   }
//
//   @override
//   void onButtonPressed(String id) {}
// }
