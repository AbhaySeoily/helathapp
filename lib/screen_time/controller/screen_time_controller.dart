// ScreenTimeController
import 'dart:math';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../main.dart';
import '../model/screen_app.dart';

class ScreenTimeController extends GetxController {
  final box = GetStorage();
  RxInt total = 320.obs;
  RxList<ScreenApp> apps = RxList([
    ScreenApp(name: 'YouTube', minutes: 120),
    ScreenApp(name: 'Instagram', minutes: 90),
    ScreenApp(name: 'WhatsApp', minutes: 50),
    ScreenApp(name: 'Browser', minutes: 30),
    ScreenApp(name: 'Other', minutes: 30),
  ]);
  RxMap<String, int> limits = <String,int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final stored = box.read(KS_SCREEN_LIMITS);
    if (stored != null && stored is Map) limits.value = Map<String,int>.from(stored);
    _refresh();
  }

  void _refresh() {
    total.value = apps.fold<int>(0, (p,a) => p + a.minutes);
  }

  void randomize() {
    final rnd = Random();
    apps.assignAll([
      ScreenApp(name: 'YouTube', minutes: 30 + rnd.nextInt(180)),
      ScreenApp(name: 'Instagram', minutes: 20 + rnd.nextInt(150)),
      ScreenApp(name: 'WhatsApp', minutes: 10 + rnd.nextInt(90)),
      ScreenApp(name: 'Browser', minutes: 5 + rnd.nextInt(60)),
      ScreenApp(name: 'Other', minutes: 2 + rnd.nextInt(40)),
    ]);
    _refresh();
  }

  void setLimit(String app, int mins, bool active) {
    if (active) limits[app] = mins; else limits.remove(app);
    box.write(KS_SCREEN_LIMITS, limits);
    Get.snackbar('Saved', active ? 'Limit set' : 'Limit removed');
  }
}