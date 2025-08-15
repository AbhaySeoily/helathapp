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
    // Request activity recognition (step counting)
    await Permission.activityRecognition.request();

    // Request location permissions (required for FGS with type 'location')
    await Permission.locationWhenInUse.request();

    // If background location is needed:
    if (await Permission.locationWhenInUse.isGranted) {
      await Permission.locationAlways.request();
    }

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

