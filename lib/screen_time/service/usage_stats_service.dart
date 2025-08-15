import 'package:flutter/services.dart';

class UsageStatsService {
  static const _channel = MethodChannel('app.usage.stats/channel');

  static Future<bool> hasUsagePermission() async {
    try {
      final ok = await _channel.invokeMethod<bool>('hasUsagePermission');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
  }

  static Future<List<AppUsageInfo>> getUsageStats() async {
    try {
      final List<dynamic> raw =
      await _channel.invokeMethod('getUsageStats');
      return raw
          .map((e) => AppUsageInfo.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<DailyTotal>> getDailyTotals({int days = 7}) async {
    try {
      final List<dynamic> raw = await _channel.invokeMethod(
        'getDailyTotals',
        {'days': days},
      );
      return raw
          .map((e) => DailyTotal.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class AppUsageInfo {
  final String packageName;
  final String appName;
  final int totalTimeMs;
  final int lastTimeUsedMs;

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.totalTimeMs,
    required this.lastTimeUsedMs,
  });

  int get minutes => (totalTimeMs / 60000).round();

  factory AppUsageInfo.fromMap(Map<dynamic, dynamic> m) => AppUsageInfo(
    packageName: m['packageName']?.toString() ?? '',
    appName: m['appName']?.toString() ?? '',
    totalTimeMs: (m['totalTimeMs'] ?? 0 as int) is int
        ? m['totalTimeMs'] as int
        : (m['totalTimeMs'] as num).toInt(),
    lastTimeUsedMs: (m['lastTimeUsed'] ?? 0 as int) is int
        ? m['lastTimeUsed'] as int
        : (m['lastTimeUsed'] as num).toInt(),
  );
}

class DailyTotal {
  final DateTime dayStart; // local midnight
  final int totalTimeMs;
  final String topAppName;

  DailyTotal({
    required this.dayStart,
    required this.totalTimeMs,
    required this.topAppName,
  });

  int get minutes => (totalTimeMs / 60000).round();

  factory DailyTotal.fromMap(Map<dynamic, dynamic> m) => DailyTotal(
    dayStart: DateTime.fromMillisecondsSinceEpoch(
        (m['dayStartMs'] as num).toInt()),
    totalTimeMs: (m['totalTimeMs'] as num).toInt(),
    topAppName: m['topAppName']?.toString() ?? '',
  );
}
