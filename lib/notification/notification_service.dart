// lib/steps/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// ---------------- Initialize notification service ----------------
  static Future<void> init() async {
    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings();

    const InitializationSettings settings =
    InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(settings);

    // Initialize timezone database
    tzdata.initializeTimeZones();
  }

  /// ---------------- Generic immediate notification ----------------
  static Future<void> showNotification({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    int id = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: '$channelName notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(id, title, body, details);
  }

  /// ---------------- Step Notification ----------------
  static Future<void> showStepNotification(String title, String body,
      {int id = 0}) async {
    await showNotification(
      title: title,
      body: body,
      channelId: 'step_channel',
      channelName: 'Step Notifications',
      id: id,
    );
  }

  /// ---------------- Water Notification ----------------
  static Future<void> showWaterNotification(String title, String body,
      {int id = 100}) async {
    await showNotification(
      title: title,
      body: body,
      channelId: 'water_channel',
      channelName: 'Water Reminders',
      id: id,
    );
  }

  /// ---------------- Schedule Water Reminder ----------------
  /// This schedules the notification at the exact time daily
  static Future<void> scheduleWaterReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);

    // If time already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) scheduled = scheduled.add(Duration(days: 1));

    final androidDetails = AndroidNotificationDetails(
      'water_channel',
      'Water Reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }
}
