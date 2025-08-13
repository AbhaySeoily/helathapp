// // StepsController
// lib/steps/controller/step_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pedometer/pedometer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wellness_getx_app/steps/controller/step_background_handler.dart';

import '../../main.dart';
import '../model/step_model.dart';

const String KS_STEPS = 'steps_model';
const String KS_DAILY = 'dailySteps';          // Map<String yyyy-MM-dd, int>
const String KS_BASELINE_PREFIX = 'baseline_'; // baseline_<date> : int

class StepsController extends GetxController {
  final box = GetStorage();

  /// UI model: today, goal, last7 (oldest → newest)
  Rx<StepsModel> model = StepsModel(today: 0, goal: 8000, last7: []).obs;

  late Stream<StepCount> _stepStream;
  StreamSubscription<StepCount>? _sub;
  int _startSteps = 0; // today's baseline (boot total @midnight or first event)
  String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    _initPermissions();
    _initNotifications();
    _loadData();
    _initPedometer();
    _startBackgroundIfNotRunning();
    _scheduleDailyNotification();
  }

  Future<void> _initPermissions() async {
    // Android 10+ activity recognition
    await Permission.activityRecognition.request();
    // Battery optimization ignore (for bg service stability)
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);
  }

  /// Load saved model else construct from stored history (no fake)
  void _loadData() {
    final stored = box.read(KS_STEPS);
    if (stored != null && stored is Map) {
      model.value = StepsModel.fromJson(Map.from(stored));
    }

    // Always refresh last7 from real stored daily map
    model.update((m) {
      if (m == null) return;
      m.last7 = _loadLast7FromHistory();
    });

    // Restore today's baseline if present
    final baseline = box.read<int>("$KS_BASELINE_PREFIX$_todayKey");
    if (baseline != null) _startSteps = baseline;
  }

  /// Build last7 from GetStorage 'dailySteps' (oldest → today)
  List<int> _loadLast7FromHistory() {
    final dailyMap = Map<String, int>.from(box.read(KS_DAILY) ?? {});
    final now = DateTime.now();
    final result = <int>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      result.add(dailyMap[key] ?? 0);
    }
    return result;
  }

  void _initPedometer() {
    _stepStream = Pedometer.stepCountStream;
    _sub = _stepStream.listen((event) {
      print("==================================================");
      print(event.steps);
      print("==================================================");
      _onStepEvent(event.steps);
    }, onError: (err) {
      debugPrint("Pedometer error: $err");
    });
  }

  void _onStepEvent(int totalStepsFromBoot) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // New day rollover handling
    if (today != _todayKey) {
      // Save yesterday's total
      _saveDailySteps(_todayKey, model.value.today);

      // switch to new day
      _todayKey = today;
      _startSteps = totalStepsFromBoot; // new baseline
      box.write("$KS_BASELINE_PREFIX$_todayKey", _startSteps);

      // refresh last7 from storage (yesterday persisted above)
      _refreshLast7();
    }

    // If baseline not set (first event of the day / first app open)
    if (_startSteps == 0) {
      final savedBaseline = box.read<int>("$KS_BASELINE_PREFIX$_todayKey");
      if (savedBaseline != null) {
        _startSteps = savedBaseline;
      } else {
        _startSteps = totalStepsFromBoot;
        box.write("$KS_BASELINE_PREFIX$_todayKey", _startSteps);

      }
    }

    final todayCount = (totalStepsFromBoot - _startSteps).clamp(0, 1 << 31);
    // Persist today's running value under today's key so monthly view gets live value
    _saveDailySteps(_todayKey, todayCount);

    model.update((m) {
      if (m == null) return;
      m.today = todayCount;

      // ensure last7 exists & last entry is today
      if (m.last7.isEmpty || m.last7.length != 7) {
        m.last7 = _loadLast7FromHistory();
      } else {
        m.last7[m.last7.length - 1] = todayCount; // oldest..today
      }
    });

    box.write(KS_STEPS, model.value.toJson());

    _checkGoalAchievement(); // triggers notifications when appropriate
  }

  void _refreshLast7() {
    model.update((m) {
      if (m == null) return;
      m.last7 = _loadLast7FromHistory();
    });
  }

  /// Save a single day's total in storage
  void _saveDailySteps(String dateKey, int steps) {
    final dailyMap = Map<String, int>.from(box.read(KS_DAILY) ?? {});
    dailyMap[dateKey] = steps;
    box.write(KS_DAILY, dailyMap);
  }

  void setGoal(int g) {
    model.update((m) {
      if (m == null) return;
      m.goal = g;
    });
    box.write(KS_STEPS, model.value.toJson());
    _checkGoalAchievement();
  }

  Future<void> _startBackgroundIfNotRunning() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      FlutterForegroundTask.startService(
        notificationTitle: 'Step Tracker Running',
        notificationText: 'Tracking your steps...',
        callback: startCallback, // defined in step_background_handler.dart
      );
    }
  }

  void _checkGoalAchievement() {
    final m = model.value;

    // Appreciation
    if (m.today >= m.goal) {
      _showGoalAchievedNotification();
      return;
    }

    // Motivation if close (>=80% and not done)
    if (m.today >= (m.goal * 0.8).floor() && m.today < m.goal) {
      _showMotivationalNotification();
    }
  }

  void _showGoalAchievedNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'goal_channel',
      'Goal Achievements',
      channelDescription: 'Notifications when you reach your step goal',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      100,
      'Goal Achieved! 🎉',
      'You reached your daily step goal of ${model.value.goal} steps!',
      platformChannelSpecifics,
    );
  }

  void _showMotivationalNotification() async {
    final remaining = (model.value.goal - model.value.today).clamp(0, 1 << 31);
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'motivation_channel',
      'Motivational',
      channelDescription: 'Notifications to motivate you to reach your step goal',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      101,
      'Keep Going! 💪',
      'Only $remaining steps left to reach your goal!',
      platformChannelSpecifics,
    );
  }

  /// Daily 8 PM summary notification (appreciate or motivate)
  void _scheduleDailyNotification() async {
    // Quick and simple: show once now based on current state when called
    // If you want exact 8 PM every day, keep your earlier zoned schedule code.
    final now = DateTime.now();
    if (now.hour >= 20) {
      // after 8 PM: send a state snapshot
      final msg = model.value.today < model.value.goal
          ? 'You walked ${model.value.today} steps today. Keep moving!'
          : 'Great job! You hit your goal!';
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'daily_reminder',
        'Daily Reminders',
        channelDescription: 'Daily step goal reminders',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notifications.show(102, 'Daily Step Update', msg, platformChannelSpecifics);
    }
  }

  /// Monthly date → steps map (no fake). Includes today’s live value.
  Future<Map<DateTime, int>> getMonthlySteps({DateTime? month}) async {
    final now = month ?? DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final last = DateTime(now.year, now.month, daysInMonth);

    final stored = Map<String, int>.from(box.read(KS_DAILY) ?? {});
    final result = <DateTime, int>{};

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(now.year, now.month, d);
      if (date.isAfter(DateTime.now())) break;

      final key = DateFormat('yyyy-MM-dd').format(date);
      result[date] = stored[key] ?? 0;
    }

    // Ensure today (if current month) reflects live value
    final today = DateTime.now();
    if (today.year == now.year && today.month == now.month) {
      final tKey = DateFormat('yyyy-MM-dd').format(today);
      result[today] = stored[tKey] ?? model.value.today;
    }

    return result;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:pedometer/pedometer.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:wellness_getx_app/steps/controller/step_background_handler.dart';
//
// import '../../main.dart';
// import '../model/step_model.dart';
//
// class StepsController extends GetxController {
//   final box = GetStorage();
//   Rx<StepsModel> model =
//       StepsModel(today: 0, goal: 8000, last7: []).obs; // start with empty list
//
//   late Stream<StepCount> _stepStream;
//   int _startSteps = 0;
//   String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//   final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();
//
//   @override
//   void onInit() {
//     super.onInit();
//     _initPermissions();
//     _initNotifications();
//     _loadData();
//     _initPedometer();
//     _startBackgroundIfNotRunning();
//     _scheduleDailyNotification();
//   }
//
//   Future<void> _initPermissions() async {
//     await Geolocator.requestPermission();
//     await FlutterForegroundTask.requestIgnoreBatteryOptimization();
//   }
//
//   void _initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('ic_launcher');
//
//     final InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
//
//     await _notifications.initialize(initializationSettings);
//   }
//
//   /// Load saved model, or start with actual history if present
//   void _loadData() {
//     final stored = box.read(KS_STEPS);
//     if (stored != null && stored is Map) {
//       model.value = StepsModel.fromJson(Map.from(stored));
//     } else {
//       model.value = StepsModel(
//         today: 0,
//         goal: 8000,
//         last7: _loadLast7FromHistory(),
//       );
//     }
//   }
//
//   /// Try to load last 7 days from stored daily totals
//   List<int> _loadLast7FromHistory() {
//     final dailyMap = Map<String, int>.from(
//         box.read('dailySteps') ?? {}); // "yyyy-MM-dd": steps
//     final now = DateTime.now();
//     List<int> result = [];
//     for (int i = 6; i >= 0; i--) {
//       final date = now.subtract(Duration(days: i));
//       final key =
//           "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
//       result.add(dailyMap[key] ?? 0);
//     }
//     return result;
//   }
//
//   void _initPedometer() {
//     _stepStream = Pedometer.stepCountStream;
//     _stepStream.listen((event) {
//       _updateSteps(event.steps);
//       _checkGoalAchievement();
//     }, onError: (err) {
//       print("Pedometer error: $err");
//     });
//   }
//
//   void _updateSteps(int totalSteps) {
//     final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//     // New day → shift history & save yesterday's total
//     if (today != _todayKey) {
//       _saveDailySteps(_todayKey, model.value.today);
//       _todayKey = today;
//       _startSteps = totalSteps;
//       _shiftHistory();
//     }
//
//     final todayCount = totalSteps - _startSteps;
//     model.update((m) {
//       if (m == null) return;
//       m.today = todayCount;
//       if (m.last7.isNotEmpty) {
//         m.last7[m.last7.length - 1] = todayCount;
//       }
//     });
//
//     box.write(KS_STEPS, model.value.toJson());
//   }
//
//   /// Save a single day's total in storage
//   void _saveDailySteps(String dateKey, int steps) {
//     final dailyMap = Map<String, int>.from(box.read('dailySteps') ?? {});
//     dailyMap[dateKey] = steps;
//     box.write('dailySteps', dailyMap);
//   }
//
//   void _shiftHistory() {
//     final history = _loadLast7FromHistory();
//     model.update((m) {
//       if (m == null) return;
//       m.last7 = history;
//     });
//   }
//
//   void setGoal(int g) {
//     model.update((m) {
//       if (m == null) return;
//       m.goal = g;
//     });
//     box.write(KS_STEPS, model.value.toJson());
//     _checkGoalAchievement();
//   }
//
//   Future<void> _startBackgroundIfNotRunning() async {
//     final isRunning = await FlutterForegroundTask.isRunningService;
//     if (!isRunning) {
//       FlutterForegroundTask.startService(
//         notificationTitle: 'Step Tracker Running',
//         notificationText: 'Tracking your steps...',
//         callback: startCallback,
//       );
//     }
//   }
//
//   void _checkGoalAchievement() {
//     final m = model.value;
//     if (m.today >= m.goal) {
//       _showGoalAchievedNotification();
//     } else if (m.today >= m.goal * 0.8) {
//       _showMotivationalNotification();
//     }
//   }
//
//   void _showGoalAchievedNotification() async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'goal_channel',
//       'Goal Achievements',
//       channelDescription: 'Notifications when you reach your step goal',
//       importance: Importance.high,
//       priority: Priority.high,
//       showWhen: false,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     await _notifications.show(
//       0,
//       'Goal Achieved! 🎉',
//       'You reached your daily step goal of ${model.value.goal} steps!',
//       platformChannelSpecifics,
//     );
//   }
//
//   void _showMotivationalNotification() async {
//     final remaining = model.value.goal - model.value.today;
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'motivation_channel',
//       'Motivational',
//       channelDescription:
//           'Notifications to motivate you to reach your step goal',
//       importance: Importance.defaultImportance,
//       priority: Priority.defaultPriority,
//       showWhen: false,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     await _notifications.show(
//       1,
//       'Keep Going! 💪',
//       'Only $remaining steps left to reach your goal!',
//       platformChannelSpecifics,
//     );
//   }
//
//   void _scheduleDailyNotification() async {
//     final time = Time(20, 0, 0); // 8 PM
//
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'daily_reminder',
//       'Daily Reminders',
//       channelDescription: 'Daily step goal reminders',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     await _notifications.showDailyAtTime(
//       2,
//       'Daily Step Update',
//       'You walked ${model.value.today} steps today. ${model.value.today < model.value.goal ? 'Keep moving!' : 'Great job!'}',
//       time,
//       platformChannelSpecifics,
//     );
//   }
//
//   Future<Map<DateTime, int>> getMonthlySteps() async {
//     final now = DateTime.now();
//     final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
//     final result = <DateTime, int>{};
//
//     final storedData = Map<String, int>.from(box.read('dailySteps') ?? {});
//
//     for (int day = 1; day <= daysInMonth; day++) {
//       final date = DateTime(now.year, now.month, day);
//       final key =
//           "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
//       result[date] = storedData[key] ?? 0;
//     }
//     return result;
//   }
// }

// class StepsController extends GetxController {
//   final box = GetStorage();
//   Rx<StepsModel> model = StepsModel(today: 0, goal: 8000, last7: List.filled(7, 0)).obs;
//
//   late Stream<StepCount> _stepStream;
//   int _startSteps = 0;
//   String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//   final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
//
//   @override
//   void onInit() {
//     super.onInit();
//     _initNotifications();
//     _loadData();
//     _initPedometer();
//     _startBackgroundIfNotRunning();
//     _scheduleDailyNotification();
//   }
//
//   void _initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('ic_launcher');
//
//     final InitializationSettings initializationSettings =
//     InitializationSettings(android: initializationSettingsAndroid);
//
//     await _notifications.initialize(initializationSettings);
//   }
//
//   void _loadData() {
//     final stored = box.read(KS_STEPS);
//     if (stored != null && stored is Map) {
//       model.value = StepsModel.fromJson(Map.from(stored));
//     }
//   }
//
//   void _initPedometer() {
//     _stepStream = Pedometer.stepCountStream;
//     _stepStream.listen((event) {
//       _updateSteps(event.steps);
//       _checkGoalAchievement();
//     }, onError: (err) {
//       print("Pedometer error: $err");
//     });
//   }
//
//   void _updateSteps(int totalSteps) {
//     final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//     // Reset on new day
//     if (today != _todayKey) {
//       _todayKey = today;
//       _startSteps = totalSteps;
//       _shiftHistory();
//     }
//
//     final todayCount = totalSteps - _startSteps;
//     model.update((m) {
//       if (m == null) return;
//       m.today = todayCount;
//       m.last7[0] = m.today;
//     });
//
//     box.write(KS_STEPS, model.value.toJson());
//   }
//
//   void _shiftHistory() {
//     model.update((m) {
//       if (m == null) return;
//       m.last7.insert(0, 0);
//       if (m.last7.length > 7) m.last7 = m.last7.sublist(0, 7);
//     });
//   }
//
//   void setGoal(int g) {
//     model.update((m) {
//       if (m == null) return;
//       m.goal = g;
//     });
//     box.write(KS_STEPS, model.value.toJson());
//     _checkGoalAchievement();
//   }
//
//   Future<void> _startBackgroundIfNotRunning() async {
//     final isRunning = await FlutterForegroundTask.isRunningService;
//     if (!isRunning) {
//       FlutterForegroundTask.startService(
//         notificationTitle: 'Step Tracker Running',
//         notificationText: 'Tracking your steps...',
//         callback: startCallback,
//       );
//     }
//   }
//
//   void _checkGoalAchievement() {
//     final m = model.value;
//     if (m.today >= m.goal) {
//       _showGoalAchievedNotification();
//     } else if (m.today >= m.goal * 0.8) {
//       _showMotivationalNotification();
//     }
//   }
//
//   void _showGoalAchievedNotification() async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//     AndroidNotificationDetails(
//       'goal_channel', 'Goal Achievements',
//       channelDescription: 'Notifications when you reach your step goal',
//       importance: Importance.high,
//       priority: Priority.high,
//       showWhen: false,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//     NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     await _notifications.show(
//       0,
//       'Goal Achieved! 🎉',
//       'You reached your daily step goal of ${model.value.goal} steps!',
//       platformChannelSpecifics,
//     );
//   }
//
//   void _showMotivationalNotification() async {
//     final remaining = model.value.goal - model.value.today;
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//     AndroidNotificationDetails(
//       'motivation_channel', 'Motivational',
//       channelDescription: 'Notifications to motivate you to reach your step goal',
//       importance: Importance.defaultImportance,
//       priority: Priority.defaultPriority,
//       showWhen: false,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//     NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     await _notifications.show(
//       1,
//       'Keep Going! 💪',
//       'Only $remaining steps left to reach your goal!',
//       platformChannelSpecifics,
//     );
//   }
//
//   void _scheduleDailyNotification() async {
//     // Schedule evening notification if goal not met
//     final time = Time(20, 0, 0); // 8 PM
//
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//     AndroidNotificationDetails(
//       'daily_reminder', 'Daily Reminders',
//       channelDescription: 'Daily step goal reminders',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//     NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     await _notifications.showDailyAtTime(
//       2,
//       'Daily Step Update',
//       'You walked ${model.value.today} steps today. ${model.value.today < model.value.goal ? 'Keep moving!' : 'Great job!'}',
//       time,
//       platformChannelSpecifics,
//     );
//   }
//
//   Future<Map<DateTime, int>> getMonthlySteps() async {
//     final now = DateTime.now();
//     final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
//     final result = <DateTime, int>{};
//
//     // Yahan tum apne stored monthly data load karoge (DB ya storage se)
//     // Example: Map<String, int> storedData = { "2025-08-01": 5432, ... };
//     final storedData = await _loadMonthlyDataFromStorage();
//
//     for (int day = 1; day <= daysInMonth; day++) {
//       final date = DateTime(now.year, now.month, day);
//
//       // Format key "yyyy-MM-dd" banate hain
//       final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
//
//       if (storedData.containsKey(key)) {
//         result[date] = storedData[key]!;
//       } else {
//         result[date] = 0; // Agar data nahi hai to 0 steps
//       }
//     }
//     return result;
//   }
//
//   Future<Map<String, int>> _loadMonthlyDataFromStorage() async {
//     // Example GetStorage se load karne ka
//     final box = GetStorage();
//     return Map<String, int>.from(box.read('monthlySteps') ?? {});
//   }
//
// // Future<Map<DateTime, int>> getMonthlySteps() async {
//   //   // In a real app, you would fetch this from your database/storage
//   //   // For demo purposes, we'll generate some random data
//   //   final now = DateTime.now();
//   //   final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
//   //   final result = <DateTime, int>{};
//   //
//   //   for (int day = 1; day <= daysInMonth; day++) {
//   //     final date = DateTime(now.year, now.month, day);
//   //     if (date.isAfter(now)) break;
//   //
//   //     // For the current day, use actual steps
//   //     if (day == now.day) {
//   //       result[date] = model.value.today;
//   //     } else {
//   //       // For other days, generate random data (replace with your actual storage)
//   //       result[date] = Random().nextInt(model.value.goal + 2000);
//   //     }
//   //   }
//   //
//   //   return result;
//   // }
// }

//==============================

// import 'dart:async';
// import 'dart:math';
//
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:wellness_getx_app/steps/controller/step_background_handler.dart';
//
// import '../../main.dart';
// import '../model/step_model.dart';
// import 'dart:async';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:pedometer/pedometer.dart';
// import 'package:intl/intl.dart';
// import '../model/step_model.dart';
//
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
//
// class StepsController extends GetxController {
//   final box = GetStorage();
//   Rx<StepsModel> model = StepsModel(today: 0, goal: 8000, last7: List.filled(7, 0)).obs;
//
//   late Stream<StepCount> _stepStream;
//   int _startSteps = 0;
//   String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//   @override
//   void onInit() {
//     super.onInit();
//     _loadData();
//     _initPedometer();
//     _startBackgroundIfNotRunning();
//   }
//
//   void _loadData() {
//     final stored = box.read(KS_STEPS);
//     if (stored != null && stored is Map) {
//       model.value = StepsModel.fromJson(Map.from(stored));
//     }
//   }
//
//   void _initPedometer() {
//     _stepStream = Pedometer.stepCountStream;
//     _stepStream.listen((event) {
//       _updateSteps(event.steps);
//     }, onError: (err) {
//       print("Pedometer error: $err");
//     });
//   }
//
//   void _updateSteps(int totalSteps) {
//     final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//     // Reset on new day
//     if (today != _todayKey) {
//       _todayKey = today;
//       _startSteps = totalSteps;
//       _shiftHistory();
//     }
//
//     final todayCount = totalSteps - _startSteps;
//     model.update((m) {
//       if (m == null) return;
//       m.today = todayCount;
//       m.last7[0] = m.today;
//     });
//
//     box.write(KS_STEPS, model.value.toJson());
//   }
//
//   void _shiftHistory() {
//     model.update((m) {
//       if (m == null) return;
//       m.last7.insert(0, 0);
//       if (m.last7.length > 7) m.last7 = m.last7.sublist(0, 7);
//     });
//   }
//
//   void setGoal(int g) {
//     model.update((m) {
//       if (m == null) return;
//       m.goal = g;
//     });
//     box.write(KS_STEPS, model.value.toJson());
//   }
//
//   Future<void> _startBackgroundIfNotRunning() async {
//     final isRunning = await FlutterForegroundTask.isRunningService;
//     if (!isRunning) {
//       FlutterForegroundTask.startService(
//         notificationTitle: 'Step Tracker Running',
//         notificationText: 'Tracking your steps...',
//         callback: startCallback, // from your background handler
//       );
//     }
//   }
// }

//
// class StepsController extends GetxController {
//   final box = GetStorage();
//   Rx<StepsModel> model = StepsModel(today: 4200, goal: 8000, last7: [4000,4500,6000,3000,7200,4300,4200]).obs;
//
//   Timer? _ticker;
//   @override
//   void onInit() {
//     super.onInit();
//     final stored = box.read(KS_STEPS);
//     if (stored != null && stored is Map) model.value = StepsModel.fromJson(Map.from(stored));
//     // mock real-time increment
//     _ticker = Timer.periodic(Duration(seconds: 2), (_) {
//       addSteps(10);
//     });
//   }
//
//   @override
//   void onClose() {
//     _ticker?.cancel();
//     super.onClose();
//   }
//
//   void addSteps(int s) {
//     model.update((m) {
//       if (m == null) return;
//       m.today += s;
//       // update last7's today index (assume index 0 is today)
//       if (m.last7.isEmpty) m.last7 = List.filled(7, 0);
//       m.last7[0] = m.today;
//     });
//     box.write(KS_STEPS, model.value.toJson());
//   }
//
//   void setGoal(int g) {
//     model.update((m) { if (m==null) return; m.goal = g;});
//     box.write(KS_STEPS, model.value.toJson());
//   }
//
//   void randomizeHistory() {
//     final rnd = Random();
//     model.update((m) {
//       if (m == null) return;
//       m.last7 = List.generate(7, (_) => 2000 + rnd.nextInt(9000));
//       m.today = m.last7[0];
//     });
//     box.write(KS_STEPS, model.value.toJson());
//   }
// }
