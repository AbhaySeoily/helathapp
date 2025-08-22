

import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:wellness_getx_app/steps/controller/step_controller.dart' hide KS_STEPS;

import '../../main.dart';
import '../model/step_model.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StepBackgroundHandler());
}

class StepBackgroundHandler extends TaskHandler {
  final _notifications = FlutterLocalNotificationsPlugin();
  final _box = GetStorage();

  StreamSubscription<StepCount>? _stepSub;
  DateTime? _lastStepTime;
  int? _lastStepCount;
  String _bgTodayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  int _bgBaseline = 0;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Init notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);

    // Listen to steps
    _stepSub = Pedometer.stepCountStream.listen(_onStepEvent);
  }

  void _onStepEvent(StepCount event) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Switch to new day
    if (today != _bgTodayKey) {
      _bgTodayKey = today;
      _bgBaseline = event.steps;
      _box.write("$KS_BASELINE_PREFIX$_bgTodayKey", _bgBaseline);
    }

    final baseline = _box.read<int>("$KS_BASELINE_PREFIX$_bgTodayKey") ?? event.steps;
    final todaySteps = event.steps - baseline;

    // Save in storage
    final model = StepsModel(today: todaySteps, goal: 8000, last7: []);
    _box.write(KS_STEPS, model.toJson());

    // Save detailed record (slow/brisk detection yahan handle karna hai)
    // Example placeholder
    if (todaySteps % 2 == 0) {
      _box.write("$KS_SLOW_PREFIX$_bgTodayKey", todaySteps);
    } else {
      _box.write("$KS_BRISK_PREFIX$_bgTodayKey", todaySteps);
    }

    _lastStepTime = event.timeStamp;
    _lastStepCount = event.steps;
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    try {
      final stored = _box.read(KS_STEPS);
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
        'Goal: ${NumberFormat().format(goal)} (${goal == 0 ? 0 : (todaySteps / goal * 100).toStringAsFixed(0)}%)',
      );

      if (todaySteps < goal && todaySteps > goal * 0.8) {
        final remaining = goal - todaySteps;

        const androidDetails = AndroidNotificationDetails(
          'background_motivation',
          'Background Motivation',
          channelDescription: 'Motivational notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
        const platformDetails = NotificationDetails(android: androidDetails);

        await _notifications.show(
          103,
          'You Can Do It!',
          'Only ${NumberFormat().format(remaining)} steps left!',
          platformDetails,
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await _stepSub?.cancel();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onButtonPressed(String id) {}
}
