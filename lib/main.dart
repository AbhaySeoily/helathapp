
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'auth/controller/AuthController.dart';
import 'auth/ui/login_screen.dart';
import 'dashboard/ui/dashboard_screen.dart';
import 'notification/notification_service.dart';

/// ---------------- Theme & helpers ----------------
const Color kPrimary = Color(0xFF1976D2);
const double kPad = 12.0;

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kPrimary,
  colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Color(0xFF7C4DFF)),
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
  scaffoldBackgroundColor: Colors.grey[50],
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 1,
  ),
);

String fmtDate(DateTime d) => DateFormat.yMMMd().format(d);
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// ---------------- Storage keys ----------------
const String KS_STEPS = 'ks_steps';
const String KS_WATER = 'ks_water';
const String KS_SCREEN_LIMITS = 'ks_screen_limits';
const String KS_WATER_REWARD = 'ks_waterreward';
const String KS_LOGGED = 'ks_logged';
const String KS_WALKING_TYPE = "walking_type";
const String KS_SLOW_STEPS = "slow";
const String KS_BRISK_STEPS = "brisk";
const String KS_RUNNING_STEPS = "running";


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await GetStorage.init();
  _initForegroundTask();

  runApp(WellnessApp());
}

void _initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'step_tracker_channel',
      channelName: 'Step Tracker Service',
      channelDescription: 'Tracks steps & location in background.',
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
      interval: 2000,
    ),
  );
}

class WellnessApp extends StatelessWidget {
  WellnessApp({Key? key}) : super(key: key);

  final auth = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Wellness App',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: Obx(() => auth.logged.value ? DashboardScreen() : LoginScreen()),
    );
  }
}

