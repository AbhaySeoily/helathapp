import 'package:flutter/material.dart';

class WaterReminderModel {
  TimeOfDay time;
  int amount; // ml
  bool completed; // whether user logged water
  bool notified; // whether reminder notification has fired

  WaterReminderModel({
    required this.time,
    required this.amount,
    this.completed = false,
    this.notified = false,
  });

  Map<String, dynamic> toJson() => {
    'hour': time.hour,
    'minute': time.minute,
    'amount': amount,
    'completed': completed,
    'notified': notified,
  };

  factory WaterReminderModel.fromJson(Map<String, dynamic> json) {
    return WaterReminderModel(
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      amount: json['amount'],
      completed: json['completed'] ?? false,
      notified: json['notified'] ?? false,
    );
  }
}




class WaterReminder {
  TimeOfDay time;
  int amount;

  WaterReminder({required this.time, required this.amount});

  Map<String, dynamic> toJson() => {
    'hour': time.hour,
    'minute': time.minute,
    'amount': amount,
  };

  factory WaterReminder.fromJson(Map<String, dynamic> json) => WaterReminder(
    time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    amount: json['amount'],
  );
}





class WaterModel {
  int intake;
  int goal;
  List<int> last7;
  List<WaterReminder> reminderList; // updated for multi reminders
  Map<String, int> dailyIntake;

  WaterModel({
    this.intake = 0,
    this.goal = 2000,
    List<int>? last7,
    List<WaterReminder>? reminderList,
    Map<String, int>? dailyIntake,
  })  : last7 = last7 ?? List<int>.filled(7, 0),
        reminderList = reminderList ?? [],
        dailyIntake = dailyIntake ?? {};

  Map<String, dynamic> toJson() => {
    'intake': intake,
    'goal': goal,
    'last7': last7,
    'reminderList': reminderList.map((e) => e.toJson()).toList(),
    'dailyIntake': dailyIntake,
  };

  factory WaterModel.fromJson(Map<String, dynamic> j) => WaterModel(
    intake: j['intake'] ?? 0,
    goal: j['goal'] ?? 2000,
    last7: List<int>.from(j['last7'] ?? List<int>.filled(7, 0)),
    reminderList: (j['reminderList'] as List<dynamic>?)
        ?.map((e) => WaterReminder.fromJson(Map<String, dynamic>.from(e)))
        .toList() ??
        [],
    dailyIntake: Map<String, int>.from(j['dailyIntake'] ?? {}),
  );

  int intakeToday() {
    final key = DateTime.now().toIso8601String().split('T')[0];
    return dailyIntake[key] ?? 0;
  }

  /// Log water intake for today
  void addWater(int ml) {
    final key = DateTime.now().toIso8601String().split('T')[0];
    dailyIntake[key] = (dailyIntake[key] ?? 0) + ml;
  }
}

