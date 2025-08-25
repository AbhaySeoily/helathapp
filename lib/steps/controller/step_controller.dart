import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pedometer/pedometer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../main.dart';
import '../../notification/notification_service.dart';
import '../model/step_model.dart';
import 'step_background_handler.dart';

const String KS_STEPS = 'steps_model'; // StepsModel JSON
const String ks_daily_goal = 'steps_goal';
const String KS_DAILY = 'dailySteps'; // Map<String yyyy-MM-dd, int total>
const String KS_BASELINE_PREFIX = 'baseline_';
const String KS_SLOW_PREFIX = 'slow_';
const String KS_BRISK_PREFIX = 'brisk_';
const String KS_RUNNING_PREFIX = 'running_';
// 🔑 Keys for storage consistency



// User daily goal value
const String KS_DAILY_GOAL = 'steps_goal';



// Prefix for per-day step counters
const String KS_STEPS_PREFIX = "steps_"; // steps_<yyyy-MM-dd>



// Prefix for notifications
const String KS_GOAL_NOTIFIED_PREFIX = "goalNotified_"; // goalNotified_<yyyy-MM-dd>
const String KS_MOTIVATED_PREFIX = "motivated_";       // motivated_<yyyy-MM-dd>




class StepsController extends GetxController {
  final box = GetStorage();

  final model = StepsModel.empty().obs;
  int _startSteps = 0;
  late StreamSubscription<StepCount> _stepSub;

  @override
  void onInit() {
    super.onInit();
    _initPedometer();
    final savedGoal = box.read(KS_DAILY_GOAL) ?? 8000;
    model.update((m) {
      if (m == null) return;
      m.goal = savedGoal;
    });
    _initNotifications();
    _startForegroundService();
    _scheduleDailyResetNotification();
  }

  @override
  void onClose() {
    _stepSub.cancel();
    super.onClose();
  }

  // ✅ Initialize pedometer
  void _initPedometer() {
    _stepSub = Pedometer.stepCountStream.listen(
          (event) => _onStepEvent(event.steps),
      onError: (err) => debugPrint("⚠️ Pedometer error: $err"),
    );
  }
// ✅ Set daily goal
  void setDailyGoal(int goal) {

    // Update foreground notification immediately
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaySteps = box.read("$KS_STEPS_PREFIX$todayKey") ?? 0;


    box.write(KS_DAILY_GOAL, goal);

    // ✅ Update model also
    model.update((m) {
      if (m == null) return;
      m.goal = goal;
    });
    _updateForegroundNotification(model.value.today);
  }

//   /// Monthly steps fetch
  Future<Map<DateTime, int>> getMonthlySteps() async {
    Map<DateTime, int> monthly = {};
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(now.year, now.month, day);
      String key = DateFormat('yyyy-MM-dd').format(date);
      monthly[date] = box.read<int>("steps_$key") ?? 0;
    }
    return monthly;
  }

  // ✅ Handle step event
  void _onStepEvent(int steps) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (_startSteps == 0) {
      _startSteps = steps;
    }

    int todaySteps = steps - _startSteps;

    // save in storage
    box.write("$KS_STEPS_PREFIX$todayKey", todaySteps);

    // update model
    model.update((m) {
      if (m == null) return;
      m.today = todaySteps;
      m.last7 = _getLast7DaysSteps();
    });

    // check notifications
    _checkGoalAchievement(todaySteps);
    _updateForegroundNotification(todaySteps);
  }

  // ✅ Get last 7 days steps for chart/history
  List<int> _getLast7DaysSteps() {
    final now = DateTime.now();
    List<int> steps = [];
    for (int i = 0; i < 7; i++) {
      final day = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      steps.add(box.read("$KS_STEPS_PREFIX$day") ?? 0);
    }
    return steps.reversed.toList();
  }

  // ✅ Goal achievement notification (once per day)
  void _checkGoalAchievement(int todaySteps) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final notifyKey = "$KS_GOAL_NOTIFIED_PREFIX$todayKey";

    int goal = box.read(KS_DAILY_GOAL) ?? 0;
    bool alreadyNotified = box.read(notifyKey) ?? false;

    if (goal > 0 && todaySteps >= goal && !alreadyNotified) {
      NotificationService.showNotification(
        channelId: "stepcounts",
        channelName: "step_counter",
        title: "Goal Achieved 🎉",
        body: "Congrats! You've completed your step goal of $goal steps today.",
      );
      box.write(notifyKey, true);
    }
  }

  // ✅ Foreground persistent notification
  void _updateForegroundNotification(int todaySteps) {
    final goal = box.read(KS_DAILY_GOAL) ?? 0;
    FlutterForegroundTask.updateService(
      notificationTitle: "Step Counter",
      notificationText: "$todaySteps / $goal steps",
    );
  }

  // ✅ Init notifications channel
  void _initNotifications() {
    NotificationService.init();
  }

  // ✅ Start foreground service
  void _startForegroundService() {
    FlutterForegroundTask.startService(
      notificationTitle: "Step Counter Active",
      notificationText: "Tracking your steps...",
      callback: startCallback,
    );
  }

  // ✅ Schedule daily reset notification (midnight etc.)
  void _scheduleDailyResetNotification() {
    // Example: schedule reset or motivational nudge
    // TODO: integrate flutter_local_notifications periodic notifications if required
  }
}


//
// class StepsController extends GetxController {
//   final box = GetStorage();
//   Rx<StepsModel> model = StepsModel(today: 0, goal: 8000, last7: []).obs;
//
// // notifications
//   final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();
//
//   late Stream<StepCount> _stepStream;
//   StreamSubscription<StepCount>? _sub;
//   int _startSteps = 0;
//   String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//   @override
//   void onInit() {
//     super.onInit();
//     _loadTodaySteps();
//     // ✅ Saved goal load karo
//     final savedGoal = box.read<int>(ks_daily_goal) ?? 8000;
//     model.update((m) {
//       if (m == null) return;
//       m.goal = savedGoal;
//     });
//     _initPedometer();
//     _initPermissions();
//     _initNotifications();
//     _startForegroundService();
//     _scheduleDailyNotification();
//   }
//
//   void _scheduleDailyNotification() async {
//     // Snapshot after 8 PM (simple version)
//     final now = DateTime.now();
//     if (now.hour >= 20) {
//       final msg = model.value.today < model.value.goal
//           ? 'You walked ${model.value.today} steps today. Keep moving!'
//           : 'Great job! You hit your goal!';
//       const android = AndroidNotificationDetails(
//         'daily_reminder',
//         'Daily Reminders',
//         channelDescription: 'Daily step goal reminders',
//         importance: Importance.high,
//         priority: Priority.high,
//       );
//       const details = NotificationDetails(android: android);
//       await _notifications.show(102, 'Daily Step Update', msg, details);
//     }
//   }
//
//   Future<void> _initPermissions() async {
//     await Permission.activityRecognition.request();
//
//     // For foreground task stability on some devices:
//     await FlutterForegroundTask.requestIgnoreBatteryOptimization();
//
//     // Only if your service uses location-type foreground service, else you may skip.
//     await Permission.locationWhenInUse.request();
//     if (await Permission.locationWhenInUse.isGranted) {
//       await Permission.locationAlways.request();
//     }
//   }
//
//   Future<void> _initNotifications() async {
//     const AndroidInitializationSettings initAndroid =
//         AndroidInitializationSettings('ic_launcher');
//     const InitializationSettings init =
//         InitializationSettings(android: initAndroid);
//     await _notifications.initialize(init);
//   }
//
//   Future<void> _startForegroundService() async {
//     final isRunning = await FlutterForegroundTask.isRunningService;
//     if (!isRunning) {
//       FlutterForegroundTask.startService(
//         notificationTitle: 'Step Tracker Running',
//         notificationText: 'Tracking your steps...',
//         callback: startCallback, // step_background_handler.dart
//       );
//     }
//   }
//
//   void _loadTodaySteps() {
//     _startSteps = box.read<int>("baseline_$_todayKey") ?? 0;
//     int todaySteps = box.read<int>("steps_$_todayKey") ?? 0;
//     model.update((m) {
//       if (m == null) return;
//       m.today = todaySteps;
//       m.last7 = _getLast7DaysSteps();
//     });
//   }
//
//   void _initPedometer() {
//     _stepStream = Pedometer.stepCountStream;
//     _sub = _stepStream.listen((event) {
//       _onStepEvent(event.steps);
//     });
//   }
//
//   void _onStepEvent(int steps) {
//     int totalSteps = steps - _startSteps;
//     box.write("steps_$_todayKey", totalSteps);
//
//     model.update((m) {
//       if (m == null) return;
//       m.today = totalSteps;
//       m.last7 = _getLast7DaysSteps();
//     });
//     _checkGoalAchievement(totalSteps);
//   }
//
//
//   void _checkGoalAchievement(int todaySteps) {
//     final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final notifyKey = "goalNotified:$todayKey";
//
//     // Storage se goal uthao (default 0 agar na mile)
//     int goal = box.read(ks_daily_goal) ?? 0;
//     bool alreadyNotified = box.read(notifyKey) ?? false;
//
//     debugPrint("🔍 [Goal Check] Date: $todayKey");
//     debugPrint("🔍 Goal set: $goal");
//     debugPrint("🔍 Today steps: $todaySteps");
//     debugPrint("🔍 Already Notified: $alreadyNotified");
//
//     if (goal > 0 && todaySteps >= goal && !alreadyNotified) {
//       NotificationService.showNotification(
//         channelName: "step_counter",
//         channelId: "stepcounts",
//         title: "Goal Achieved 🎉",
//         body: "Congrats! You've completed your step goal of $goal steps today.",
//       );
//
//       box.write(notifyKey, true);
//       debugPrint("🎉 Condition matched → Sending Notification!");
//     }
//   }
//
//
//   void setGoal(int goal) {
//     model.update((m) {
//       if (m == null) return;
//       m.goal = goal;
//     });
//     box.write(ks_daily_goal, goal);
//   }
//
//   List<int> _getLast7DaysSteps() {
//     List<int> last7 = [];
//     for (int i = 6; i >= 0; i--) {
//       DateTime date = DateTime.now().subtract(Duration(days: i));
//       String key = DateFormat('yyyy-MM-dd').format(date);
//       last7.add(box.read<int>("steps_$key") ?? 0);
//     }
//     return last7;
//   }
//
//   /// Monthly steps fetch
//   Future<Map<DateTime, int>> getMonthlySteps() async {
//     Map<DateTime, int> monthly = {};
//     DateTime now = DateTime.now();
//     int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
//
//     for (int day = 1; day <= daysInMonth; day++) {
//       DateTime date = DateTime(now.year, now.month, day);
//       String key = DateFormat('yyyy-MM-dd').format(date);
//       monthly[date] = box.read<int>("steps_$key") ?? 0;
//     }
//     return monthly;
//   }
//
//   @override
//   void onClose() {
//     _sub?.cancel();
//     super.onClose();
//   }
// }

// class StepsController extends GetxController {
//   final box = GetStorage();
//
//   Rx<StepsModel> model = StepsModel(today: 0, goal: 8000, last7: []).obs;
//
//   late Stream<StepCount> _stepStream;
//   StreamSubscription<StepCount>? _sub;
//   int _startSteps = 0;
//   String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//   @override
//   void onInit() {
//     super.onInit();
//     _loadModel();
//     _initPedometer();
//     _startForegroundService();
//   }
//
//   void _loadModel() {
//     final stored = box.read(KS_STEPS);
//     if (stored != null && stored is Map) {
//       model.value = StepsModel.fromJson(Map.from(stored));
//     }
//     _startSteps = box.read<int>("$KS_BASELINE$_todayKey") ?? 0;
//     _updateTodaySteps();
//   }
//
//   void _updateTodaySteps() {
//     int total = box.read<int>("$KS_STEPS$_todayKey") ?? 0;
//     model.update((m) {
//       if (m == null) return;
//       m.today = total;
//     });
//     _persistModel();
//   }
//
//   void _persistModel() {
//     box.write(KS_STEPS, model.value.toJson());
//   }
//
//   void _initPedometer() {
//     _stepStream = Pedometer.stepCountStream;
//     _sub = _stepStream.listen((event) {
//       _onStepEvent(event.steps);
//     });
//   }
//
//   void _onStepEvent(int steps) {
//     int totalSteps = steps - _startSteps;
//     box.write("$KS_STEPS$_todayKey", totalSteps);
//     _updateTodaySteps();
//
//     // Update foreground notification
//     NotificationService.showStepNotification(model.value.today.toString(),"dsfddfdf");
//   }
//   /// ✅ Monthly steps method
//   Future<Map<DateTime, int>> getMonthlySteps() async {
//     Map<DateTime, int> monthly = {};
//     DateTime now = DateTime.now();
//     int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
//
//     for (int day = 1; day <= daysInMonth; day++) {
//       DateTime date = DateTime(now.year, now.month, day);
//       String key = DateFormat('yyyy-MM-dd').format(date);
//       int steps = box.read<int>("steps_model$key") ?? 0;
//       monthly[date] = steps;
//     }
//
//     return monthly;
//   }
//
//   void setGoal(int goal) {
//     model.update((m) {
//       if (m == null) return;
//       m.goal = goal;
//     });
//     _persistModel();
//   }
//
//   void _startForegroundService() {
//     FlutterForegroundTask.startService(
//       notificationTitle: 'Step Tracker Running',
//       notificationText: 'Tracking your steps...',
//       callback: startCallback,
//     );
//   }
//
//   List<int> _loadLast7FromHistory() {
//     List<int> last7 = [];
//     for (int i = 6; i >= 0; i--) {
//       String key = DateFormat('yyyy-MM-dd')
//           .format(DateTime.now().subtract(Duration(days: i)));
//       int val = box.read<int>("$KS_STEPS$key") ?? 0;
//       last7.add(val);
//     }
//     return last7;
//   }
//
//   @override
//   void onClose() {
//     _sub?.cancel();
//     super.onClose();
//   }
// }
