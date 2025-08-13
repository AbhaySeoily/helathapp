import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class WaterModel {
  int intake;
  int goal;
  List<int> last7; // last 7 days intake
  List<TimeOfDay> reminders;
  Map<String, int> dailyIntake; // key = yyyy-MM-dd, value = intake

  WaterModel({
    this.intake = 0,
    this.goal = 2000,
    List<int>? last7,
    List<TimeOfDay>? reminders,
    Map<String, int>? dailyIntake,
  })  : last7 = last7 ?? List<int>.filled(7, 0),
        reminders = reminders ?? [],
        dailyIntake = dailyIntake ?? {};

  Map<String, dynamic> toJson() {
    return {
      'intake': intake,
      'goal': goal,
      'last7': last7,
      'reminders': reminders.map((t) => '${t.hour}:${t.minute}').toList(),
      'dailyIntake': dailyIntake,
    };
  }

  factory WaterModel.fromJson(Map j) {
    // parse reminders
    final remList = (j['reminders'] as List<dynamic>?)
        ?.map((s) {
      final parts = (s as String).split(':');
      return TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    })
        .toList() ??
        [];

    // parse daily intake
    final daily = <String, int>{};
    if (j['dailyIntake'] != null && j['dailyIntake'] is Map) {
      (j['dailyIntake'] as Map).forEach((key, value) {
        daily[key.toString()] =
        value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return WaterModel(
      intake: j['intake'] ?? 0,
      goal: j['goal'] ?? 2000,
      last7: List<int>.from(j['last7'] ?? List<int>.filled(7, 0)),
      reminders: remList,
      dailyIntake: daily,
    );
  }

  /// get intake for today
  int intakeToday() {
    final key = DateTime.now().toIso8601String().split('T')[0];
    return dailyIntake[key] ?? 0;
  }

  /// log water intake
  void addWater(int ml) {
    final key = DateTime.now().toIso8601String().split('T')[0];
    dailyIntake[key] = (dailyIntake[key] ?? 0) + ml;
    intake = dailyIntake[key]!;
  }
}
