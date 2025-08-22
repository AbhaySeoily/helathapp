

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

const String KS_STEPS = 'steps_model';            // StepsModel JSON
const String KS_DAILY = 'dailySteps';             // Map<String yyyy-MM-dd, int total>
const String KS_BASELINE_PREFIX = 'baseline_';    // baseline_<date> : int (boot total at 1st event)

const String KS_SLOW_PREFIX   = 'slow_';          // slow_<date>  : int
const String KS_BRISK_PREFIX  = 'brisk_';         // brisk_<date> : int
const String KS_RUNNING_PREFIX= 'running_';       // running_<date> : int

class StepsController extends GetxController {
  final box = GetStorage();

  // Foreground cadence calculation (per-event)
  DateTime? _lastStepEventTime;
  int? _lastStepCount;

  // UI model: today, goal, last7 (oldest → newest)
  Rx<StepsModel> model = StepsModel(today: 0, goal: 8000, last7: []).obs;

  late Stream<StepCount> _stepStream;
  StreamSubscription<StepCount>? _sub;
  int _startSteps = 0; // today's baseline (boot total @ 1st event)
  String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // segmented counters
  final slowSteps = 0.obs;
  final briskSteps = 0.obs;
  int runningSteps = 0;

  // notifications
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // date watcher (handles manual/auto date change even if no steps arrive)
  Timer? _dateTicker;

  @override
  void onInit() {
    super.onInit();
    _initPermissions();
    _initNotifications();
    _loadModelAndToday();   // loads model + today’s segmented counters
    _initPedometer();
    _startForegroundService();
    _scheduleDailyNotification();
    _startDateWatcher();
  }

  /// ==============
  /// INIT HELPERS
  /// ==============
  Future<void> _initPermissions() async {
    await Permission.activityRecognition.request();

    // For foreground task stability on some devices:
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();

    // Only if your service uses location-type foreground service, else you may skip.
    await Permission.locationWhenInUse.request();
    if (await Permission.locationWhenInUse.isGranted) {
      await Permission.locationAlways.request();
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('ic_launcher');
    const InitializationSettings init = InitializationSettings(android: initAndroid);
    await _notifications.initialize(init);
  }

  void _initPedometer() {
    _stepStream = Pedometer.stepCountStream;
    _sub = _stepStream.listen((event) {
      print("CHECKING IN S S S SS ");
      print(event.steps);
      _onStepEvent(event.steps);
    }, onError: (err) {
      debugPrint("Pedometer error: $err");
    });
  }


  Future<void> _startForegroundService() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      FlutterForegroundTask.startService(
        notificationTitle: 'Step Tracker Running',
        notificationText: 'Tracking your steps...',
        callback: startCallback, // step_background_handler.dart
      );
    }
  }




  void _startDateWatcher() {
    _dateTicker?.cancel();
    _dateTicker = Timer.periodic(const Duration(seconds: 30), (_) => _ensureDateSync());
  }

  /// ============================
  /// LOAD / SAVE & DATE SWITCHES
  /// ============================
  void _loadModelAndToday() {
    // Load model (goal, last7, today)
    final stored = box.read(KS_STEPS);
    if (stored != null && stored is Map) {
      model.value = StepsModel.fromJson(Map.from(stored));
    }

    // last 7 strictly from KS_DAILY map
    model.update((m) {
      if (m == null) return;
      m.last7 = _loadLast7FromHistory();
    });

    // baseline for today (if present)
    final baseline = box.read<int>("$KS_BASELINE_PREFIX$_todayKey");
    if (baseline != null) _startSteps = baseline;

    // Load segmented counters for today's key
    _loadSegmentsForDate(_todayKey);

    // Keep model.today as "total segmented" if stored daily != current
    _syncTodayFromSegments();
    _persistModel();
  }

  void _loadSegmentsForDate(String dateKey) {
    slowSteps.value = box.read<int>("$KS_SLOW_PREFIX$dateKey") ?? 0;
    briskSteps.value = box.read<int>("$KS_BRISK_PREFIX$dateKey") ?? 0;
    runningSteps   = box.read<int>("$KS_RUNNING_PREFIX$dateKey") ?? 0;
  }

  void _saveSegmentsForDate(String dateKey) {
    box.write("$KS_SLOW_PREFIX$dateKey", slowSteps.value);
    box.write("$KS_BRISK_PREFIX$dateKey", briskSteps.value);
    box.write("$KS_RUNNING_PREFIX$dateKey", runningSteps);
  }

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

  void _saveDailySteps(String dateKey, int steps) {
    final dailyMap = Map<String, int>.from(box.read(KS_DAILY) ?? {});
    dailyMap[dateKey] = steps;
    box.write(KS_DAILY, dailyMap);
  }

  void _refreshLast7() {
    model.update((m) {
      if (m == null) return;
      m.last7 = _loadLast7FromHistory();
    });
  }

  void _persistModel() {
    box.write(KS_STEPS, model.value.toJson());
  }

  /// Called periodically to handle auto/manual date changes even when no steps arrive.
  void _ensureDateSync() {
    final currentKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (currentKey == _todayKey) return;

    // Day switched (past or future):
    // 1) load segments of the new day (could be zeros if future/no data)
    _todayKey = currentKey;
    _loadSegmentsForDate(_todayKey);

    // 2) Update model.today to reflect the new day's total (segments sum)
    _syncTodayFromSegments();

    // 3) Reset baseline; will be set on the first step event
    _startSteps = 0;
    box.remove("$KS_BASELINE_PREFIX$_todayKey");

    // 4) Update last7 to reflect daily map (no fake data)
    _refreshLast7();
    _persistModel();
    update();
  }


  void _syncTodayFromSegments() {
    final total = slowSteps.value + briskSteps.value + runningSteps;
    model.update((m) {
      if (m == null) return;
      m.today = total;
    });
    _saveDailySteps(_todayKey, total);
  }

  /// ==================
  /// STEP EVENT HANDLER
  /// ==================
  void _onStepEvent(int totalStepsFromBoot) {
    final now = DateTime.now();
    final currentKey = DateFormat('yyyy-MM-dd').format(now);

    // Day switch
    if (currentKey != _todayKey) {
      _syncTodayFromSegments(); // persist previous day
      _todayKey = currentKey;
      _startSteps = 0;
      _lastStepEventTime = null;
      _lastStepCount = null;
      _loadSegmentsForDate(_todayKey); // load new day (likely 0)
    }

    // Baseline (first event of the day)
    if (_startSteps == 0) {
      final savedBaseline = box.read<int>("$KS_BASELINE_PREFIX$_todayKey");
      _startSteps = savedBaseline ?? totalStepsFromBoot;
      box.write("$KS_BASELINE_PREFIX$_todayKey", _startSteps);
    }

    // Cadence segmentation
    if (_lastStepEventTime != null && _lastStepCount != null) {
      final stepDiff = totalStepsFromBoot - _lastStepCount!;
      final secDiff = now.difference(_lastStepEventTime!).inSeconds;

      if (stepDiff > 0 && secDiff > 0) {
        final spm = (stepDiff / secDiff) * 60; // steps per minute

        if (spm < 100) {
          slowSteps.value += stepDiff;
        } else if (spm < 130) {
          briskSteps.value += stepDiff;
        } else {
          runningSteps += stepDiff;
        }

        _saveSegmentsForDate(_todayKey);
      }
    }

    _lastStepEventTime = now;
    _lastStepCount = totalStepsFromBoot;

    // ✅ UI + storage: always from segments
    _syncTodayFromSegments();

    // ✅ Notification check exactly with the same value UI shows
    final todaySteps = model.value.today;
    _checkGoalAchievement(todaySteps, model.value.goal);

    _refreshLast7();
    _persistModel();
    update();
  }



  /// ===============
  /// GOAL + NOTIFS
  /// ===============
  void setGoal(int g) {
    model.update((m) {
      if (m == null) return;
      m.goal = g;
    });
    _persistModel();

    // get today's steps
    // Calculate today's steps from segments
    final todaySteps = (slowSteps.value + briskSteps.value + runningSteps);
    final goal = model.value.goal ?? 0;
    _checkGoalAchievement(todaySteps,goal);
  }


  void _updateSteps(int todaySteps) {
    final goal = model.value.goal ?? 0;
    _checkGoalAchievement(todaySteps, goal);
  }





  void _checkGoalAchievement(int todaySteps, int goal) {
    if (goal <= 0) return; // Agar goal set hi nahi hai

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final notifyKey = "goalNotified:$todayKey";

    // Debug logs
    debugPrint("🔍 [Goal Check] Date: $todayKey");
    debugPrint("🔍 Goal set: $goal");
    debugPrint("🔍 Today steps: $todaySteps");

    // bool alreadyNotified = box.read(notifyKey) ?? false;
    bool alreadyNotified = false;

    debugPrint("🔍 Already Notified: $alreadyNotified");

    // ✅ sirf tab trigger ho jab goal complete ya exceed ho
    if (todaySteps >= goal && !alreadyNotified) {
      debugPrint("🎉 Condition matched → Sending Notification!");

      NotificationService.showNotification(
        title: "Goal Achieved 🎉",
        channelId: "step_channel",
        channelName: "stepnoti",
        body:  "Congrats! You've completed your step goal of $goal steps today.",


      );

      box.write(notifyKey, true);
    } else {
      debugPrint("⚠️ Condition NOT matched → No Notification");
    }
  }





  Future<void> _showMotivationalNotification() async {
    final remaining = (model.value.goal - model.value.today).clamp(0, 1 << 31);
    const android = AndroidNotificationDetails(
      'motivation_channel',
      'Motivational',
      channelDescription: 'Notifications to motivate you to reach your step goal',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: false,
    );
    const details = NotificationDetails(android: android);
    await _notifications.show(
      101,
      'Keep Going! 💪',
      'Only $remaining steps left to reach your goal!',
      details,
    );
  }

  void _scheduleDailyNotification() async {
    // Snapshot after 8 PM (simple version)
    final now = DateTime.now();
    if (now.hour >= 20) {
      final msg = model.value.today < model.value.goal
          ? 'You walked ${model.value.today} steps today. Keep moving!'
          : 'Great job! You hit your goal!';
      const android = AndroidNotificationDetails(
        'daily_reminder',
        'Daily Reminders',
        channelDescription: 'Daily step goal reminders',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: android);
      await _notifications.show(102, 'Daily Step Update', msg, details);
    }
  }

  /// ===========
  /// MONTHLY API
  /// ===========
  Future<Map<DateTime, int>> getMonthlySteps({DateTime? month}) async {
    final now = month ?? DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final stored = Map<String, int>.from(box.read(KS_DAILY) ?? {});
    final result = <DateTime, int>{};

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(now.year, now.month, d);
      final key = DateFormat('yyyy-MM-dd').format(date);
      // Allow past/future: if future, probably 0 or existing data if user changed date before
      result[date] = stored[key] ?? 0;
    }

    // ensure "today" index reflects live sum (if in this month)
    final today = DateTime.now();
    if (today.year == now.year && today.month == now.month) {
      final tKey = DateFormat('yyyy-MM-dd').format(today);
      result[today] = stored[tKey] ?? (slowSteps.value + briskSteps.value + runningSteps);
    }
    return result;
  }


  void _checkGoal(int todaySteps) {
    final goal = box.read<int>("step_goal") ?? 0;

    if (goal > 0 && todaySteps >= goal) {
      final isGoalAlreadyNotified = box.read<bool>("goal_notified_${DateTime.now().toString().substring(0,10)}") ?? false;

      if (!isGoalAlreadyNotified) {
        NotificationService.showNotification(
          title: "Goal Achieved 🎉",
          channelId: "step_channel",
          channelName: "stepnoti",
          body:  "Congrats! You've completed your step goal of $goal steps today.",

        );

        // save flag so multiple notifications na aaye
        box.write("goal_notified_${DateTime.now().toString().substring(0,10)}", true);
      }
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _dateTicker?.cancel();
    super.onClose();
  }
}
