// ScreenTimeController
// ScreenTimeController
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:usage_stats/usage_stats.dart';
import '../../main.dart';
import '../model/screen_app.dart';
import '../service/usage_stats_service.dart';

class ScreenTimeController extends GetxController {
  final box = GetStorage();

  // state
  RxBool isLoading = true.obs;
  RxBool hasPermission = false.obs;
  RxString error = ''.obs;

  RxInt total = 0.obs;
  RxList<ScreenApp> apps = <ScreenApp>[].obs;

  // limits persistence (kept as-is)
  RxMap<String, int> limits = <String, int>{}.obs;

  // full report data
  RxList<DailyUsage> dailyTotals = <DailyUsage>[].obs;

  Future<void> ensureUsagePermission() async {
    bool granted = await UsageStats.checkUsagePermission() ?? false;
    if (!granted) {
      final intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      await intent.launch();
    }
  }



  @override
  void onInit() {
    super.onInit();
    ensureUsagePermission();
    final stored = box.read(KS_SCREEN_LIMITS);
    if (stored != null && stored is Map) {
      limits.value = Map<String, int>.from(stored);
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    error.value = '';
    try {
      hasPermission.value = await UsageStatsService.hasUsagePermission();
      if (!hasPermission.value) {
        apps.clear();
        total.value = 0;
        isLoading.value = false;
        return;
      }
      await loadToday();
      // preload 7-day totals for report
      await loadDailyTotals(days: 7);
    } catch (e) {
      error.value = 'Failed to load: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestPermission() async {
    await UsageStatsService.openUsageSettings();
    // give user a moment and then re-check
    await Future.delayed(const Duration(seconds: 1));
    await _bootstrap();
  }

  Future<void> refresh() async => _bootstrap();

  Future<void> loadToday() async {
    isLoading.value = true;
    try {
      final data = await UsageStatsService.getUsageStats();
      final real = data
          .where((a) => a.minutes > 0)
          .map((a) => ScreenApp(
        name: a.appName,
        minutes: a.minutes,
        packageName: a.packageName,
      ))
          .toList();

      // sort descending by minutes
      real.sort((a, b) => b.minutes.compareTo(a.minutes));

      apps.assignAll(real);
      _recalcTotal();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDailyTotals({int days = 7}) async {
    final list = await UsageStatsService.getDailyTotals(days: days);
    dailyTotals.assignAll(list
        .map((d) => DailyUsage(
      date: d.dayStart,
      totalMinutes: d.minutes,
      topApp: d.topAppName,
    ))
        .toList());
  }

  void _recalcTotal() {
    total.value = apps.fold<int>(0, (p, a) => p + a.minutes);
  }

  // limits logic (unchanged)
  void setLimit(String app, int mins, bool active) {
    if (active) {
      limits[app] = mins;
    } else {
      limits.remove(app);
    }
    box.write(KS_SCREEN_LIMITS, limits);
    Get.snackbar('Saved', active ? 'Limit set' : 'Limit removed');
  }
}

// simple report model used by the full report screen
class DailyUsage {
  final DateTime date;
  final int totalMinutes;
  final String topApp;
  DailyUsage({
    required this.date,
    required this.totalMinutes,
    required this.topApp,
  });
}
