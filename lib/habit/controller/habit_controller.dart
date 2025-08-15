import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../model/habit.dart';

class HabitController extends GetxController {
  final storage = GetStorage();
  final habits = <Habit>[].obs;
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _handleDateChange();
    loadHabits();
  }

  void _handleDateChange() {
    String? lastDate = storage.read('lastDate');

    if (lastDate != today) {
      // Save yesterday's habits to history
      if (lastDate != null && storage.read<List>('habits') != null) {
        storage.write('history_$lastDate', storage.read<List>('habits'));
      }

      // Reset today's habits (done = false, completedCount = 0)
      final resetHabits = (storage.read<List>('habits') ?? []).map((e) {
        final map = Map<String, dynamic>.from(e);
        map['done'] = false;
        map['completedCount'] = 0;
        return map;
      }).toList();

      storage.write('habits', resetHabits);
      storage.write('lastDate', today);
    }
  }

  void loadHabits() {
    final stored = storage.read<List>('habits') ?? [];
    habits.value = stored.map((e) => Habit.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  void saveHabits() {
    storage.write('habits', habits.map((h) => h.toMap()).toList());
  }

  void incrementProgress(int index) {
    if (habits[index].completedCount < habits[index].targetCount) {
      habits[index].completedCount++;
      if (habits[index].completedCount == habits[index].targetCount) {
        habits[index].done = true;
      }
      habits.refresh();
      saveHabits();
      storage.write('history_$today', habits.map((h) => h.toMap()).toList());
    }
  }

  void decrementProgress(int index) {
    if (habits[index].completedCount > 0) {
      habits[index].completedCount--;
      habits[index].done = false;
      habits.refresh();
      saveHabits();
      storage.write('history_$today', habits.map((h) => h.toMap()).toList());
    }
  }

  void addHabit(String name, {String? notes, int targetCount = 1}) {
    habits.add(Habit(name: name, notes: notes, done: false, targetCount: targetCount));
    habits.refresh();
    saveHabits();
    storage.write('history_$today', habits.map((h) => h.toMap()).toList());
  }

  List<Habit> getHistory(String date) {
    final stored = storage.read<List>('history_$date') ?? [];
    return stored.map((e) => Habit.fromMap(Map<String, dynamic>.from(e))).toList();
  }
}

