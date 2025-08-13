// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import '../model/meal.dart';
//
// class MealController extends GetxController {
//   final box = GetStorage();
//   RxList<Meal> meals = <Meal>[].obs;
//   Rx<DateTime> selectedDate = DateTime.now().obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadMeals();
//   }
//
//   void loadMeals() {
//     final data = box.read<List>('meals') ?? [];
//     meals.value = data.map((e) => Meal.fromJson(Map<String, dynamic>.from(e))).toList();
//   }
//
//   void saveMeals() {
//     box.write('meals', meals.map((m) => m.toJson()).toList());
//   }
//
//   void addMeal(String slot, String name, int cals,
//       {String? image, bool isPlanned = false}) {
//     meals.add(Meal(
//       slot: slot,
//       name: name,
//       calories: cals,
//       date: selectedDate.value,
//       imagePath: image,
//       isPlanned: isPlanned,
//     ));
//     saveMeals();
//     Get.snackbar('Saved', isPlanned ? 'Meal planned' : 'Meal added');
//   }
//
//   void markCompleted(Meal meal) {
//     final index = meals.indexOf(meal);
//     if (index != -1) {
//       meals[index].isCompleted = true;
//       saveMeals();
//     }
//   }
//
//   List<Meal> mealsForDate(DateTime date) {
//     return meals.where((m) => sameDay(m.date, date)).toList();
//   }
//
//   bool sameDay(DateTime a, DateTime b) =>
//       a.year == b.year && a.month == b.month && a.day == b.day;
// }
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../main.dart';
import '../model/meal.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../model/meal.dart';

class MealController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var selectedTab = 0.obs;

  var dates = <DateTime>[].obs;
  var mealDates = <DateTime>{}.obs;

  var plainMeals = <Meal>[].obs;
  var eatenMeals = <Meal>[].obs;

  @override
  void onInit() {
    super.onInit();
    _generateDates();
    _loadMeals();
  }

  void _generateDates() {
    final today = DateTime.now();
    dates.value = List.generate(
      14,
          (i) => today.subtract(Duration(days: 7 - i)),
    );
  }

  void _loadMeals() {
    // Dummy data
    plainMeals.value = [
      Meal(name: "Breakfast", date: DateTime.now()),
      Meal(name: "Lunch", date: DateTime.now()),
    ];
    eatenMeals.value = [
      Meal(name: "Dinner", date: DateTime.now()),
    ];
    mealDates.add(DateTime.now());
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    // filter meals based on date if needed
  }
}
