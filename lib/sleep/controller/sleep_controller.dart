import 'package:get/get.dart';
import '../model/sleep_entry.dart';

import 'package:get/get.dart';
import '../model/sleep_entry.dart';

import 'package:get/get.dart';
import '../model/sleep_entry.dart';

class SleepController extends GetxController {
  RxList<SleepEntry> history = <SleepEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Dummy data
    history.addAll([
      SleepEntry(
        date: DateTime.now().subtract(Duration(days:1)),
        duration: Duration(hours:7, minutes:10),
        quality: 4,
      ),
      SleepEntry(
        date: DateTime.now().subtract(Duration(days:2)),
        duration: Duration(hours:6, minutes:30),
        quality: 3,
        isNap: true,
      ),
    ]);
  }

  void logSleep(DateTime start, DateTime end, int quality, {bool isNap = false}) {
    if (end.isBefore(start)) end = end.add(Duration(days:1));
    final duration = end.difference(start);

    history.insert(0, SleepEntry(
      date: start,
      duration: duration,
      quality: quality,
      isNap: isNap,
    ));
  }
}

