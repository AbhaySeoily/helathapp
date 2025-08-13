import 'package:get/get.dart';

class MenstrualController extends GetxController {
  RxInt cycleDay = 10.obs;
  Rx<DateTime> nextPeriod = DateTime.now().add(Duration(days:20)).obs;
  RxList<DateTime> starts = RxList([DateTime.now().subtract(Duration(days:20)), DateTime.now().subtract(Duration(days:50))]);
  RxList<Map<String,dynamic>> symptoms = RxList([]);

  void logStart() {
    starts.insert(0, DateTime.now());
    cycleDay.value = 1;
    nextPeriod.value = DateTime.now().add(Duration(days:28));
    Get.snackbar('Logged', 'Period start recorded');
  }

  void logSymptoms(String text, String mood) {
    symptoms.insert(0, {'date': DateTime.now().toIso8601String(), 'text': text, 'mood': mood});
    Get.snackbar('Saved', 'Symptoms logged');
  }
}
