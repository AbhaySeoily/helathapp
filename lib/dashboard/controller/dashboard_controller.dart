import 'package:get/get.dart';

import '../../habit/controller/habit_controller.dart';
import '../../meal/controller/meal_controller.dart';
import '../../menstrual/controller/menstrual_controller.dart';
import '../../screen_time/controller/screen_time_controller.dart';
import '../../sleep/controller/sleep_controller.dart';
import '../../steps/controller/step_controller.dart';
import '../../water/controller/water_controller/water_controller.dart';
/// DashboardController to instantiate & share controllers
class DashboardController extends GetxController {
  final steps = Get.put(StepsController());
  final water = Get.put(WaterController());
  final screen = Get.put(ScreenTimeController());
  final sleep = Get.put(SleepController());
  final menstrual = Get.put(MenstrualController());
  final meal = Get.put(MealController());
  final habit = Get.put(HabitController());
}