// import 'dart:isolate';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:get_storage/get_storage.dart';
//
// import '../../main.dart';
// import '../model/step_model.dart';
//
//
// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(StepBackgroundHandler());
// }
//
// class StepBackgroundHandler extends TaskHandler {
//   @override
//   Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {}
//
//   @override
//   Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
//     try {
//       final box = GetStorage();
//       final stored = box.read(KS_STEPS);
//       int todaySteps = 0;
//       if (stored != null && stored is Map) {
//         todaySteps = StepsModel.fromJson(Map.from(stored)).today;
//       }
//       FlutterForegroundTask.updateService(
//         notificationTitle: 'Steps: $todaySteps',
//         notificationText: 'Tracking your activity...',
//       );
//     } catch (e) {
//       print("❌ Background error: $e");
//     }
//   }
//
//   @override
//   Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}
//
//   @override
//   void onNotificationPressed() {
//     FlutterForegroundTask.launchApp();
//   }
//
//   @override
//   void onButtonPressed(String id) {}
// }
// lib/steps/step_background_handler.dart
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../model/step_model.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StepBackgroundHandler());
}

class StepBackgroundHandler extends TaskHandler {
  final _notifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    try {
      final box = GetStorage();
      final stored = box.read('steps_model');
      int todaySteps = 0;
      int goal = 8000;

      if (stored != null && stored is Map) {
        final model = StepsModel.fromJson(Map.from(stored));
        todaySteps = model.today;
        goal = model.goal;
      }

      FlutterForegroundTask.updateService(
        notificationTitle: 'Steps: ${NumberFormat().format(todaySteps)}',
        notificationText:
        'Goal: ${NumberFormat().format(goal)} (${(goal == 0 ? 0 : (todaySteps / goal) * 100).toStringAsFixed(0)}%)',
      );

      if (todaySteps < goal && todaySteps > goal * 0.8) {
        final remaining = goal - todaySteps;
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'background_motivation',
          'Background Motivation',
          channelDescription: 'Motivational notifications from background service',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

        const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

        await _notifications.show(
          103,
          'You Can Do It!',
          'Only ${NumberFormat().format(remaining)} steps left to reach your goal!',
          platformChannelSpecifics,
        );
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onButtonPressed(String id) {}
}
