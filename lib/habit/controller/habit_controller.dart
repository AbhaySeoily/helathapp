import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../model/habit.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../model/habit.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../model/habit.dart';

class HabitController extends GetxController {
  final storage = GetStorage();
  final habits = <Habit>[].obs;

  /// Today's date key e.g. 2025-08-14
  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _handleDateChangeAndReset();
    _loadHabits();
  }

  /// If date changed:
  /// 1) Save previous day's snapshot to history_{lastDate}
  /// 2) Reset today's 'done' & 'completedCount'
  void _handleDateChangeAndReset() {
    final String today = todayDate;
    final String? lastDate = storage.read('lastDate');

    // First time app open OR device date changed
    if (lastDate != today) {
      final List? stored = storage.read<List>('habits');

      // Save yesterday snapshot to history
      if (lastDate != null && stored != null) {
        storage.write('history_$lastDate', stored);
      }

      // Reset today's state (keep same habits but clear today's progress)
      final reset = (stored ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        m['done'] = false;
        m['completedCount'] = 0;
        return m;
      }).toList();

      storage.write('habits', reset);
      storage.write('lastDate', today);
    }
  }

  void _loadHabits() {
    final List raw = storage.read<List>('habits') ?? [];
    habits.value =
        raw.map((e) => Habit.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  void _saveHabitsAndTodayHistory() {
    final data = habits.map((h) => h.toMap()).toList();
    storage.write('habits', data);
    storage.write('history_$todayDate', data); // keep today's snapshot updated
    storage.write('lastDate', todayDate);
  }

  // ---------- Public API ----------

  void addHabit(String name, {int targetCount = 1, String? notes}) {
    habits.add(Habit(
      name: name,
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      targetCount: targetCount,
      done: false,
      completedCount: 0,
    ));
    habits.refresh();
    _saveHabitsAndTodayHistory();
  }

  void incrementProgress(int index) {
    final h = habits[index];
    if (h.completedCount < h.targetCount) {
      h.completedCount += 1;
      if (h.completedCount >= h.targetCount) h.done = true;
      habits[index] = h;
      habits.refresh();
      _saveHabitsAndTodayHistory();
    }
  }

  void decrementProgress(int index) {
    final h = habits[index];
    if (h.completedCount > 0) {
      h.completedCount -= 1;
      if (h.completedCount < h.targetCount) h.done = false;
      habits[index] = h;
      habits.refresh();
      _saveHabitsAndTodayHistory();
    }
  }

  void deleteHabit(int index) {
    habits.removeAt(index);
    habits.refresh();
    _saveHabitsAndTodayHistory();
  }

  /// Read single date snapshot (used by per-day history)
  List<Habit> getHistory(String date) {
    final raw = storage.read<List>('history_$date') ?? [];
    return raw.map((e) => Habit.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Read **all dates** snapshots (for multi-day graph)
  Map<String, List<Habit>> getAllHistory() {
    final Map<String, List<Habit>> out = {};
    for (final key in storage.getKeys()) {
      final k = key.toString();
      if (k.startsWith('history_')) {
        final date = k.replaceFirst('history_', '');
        final raw = storage.read<List>(k) ?? [];
        final items =
        raw.map((e) => Habit.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        out[date] = items;
      }
    }
    return out;
  }
}


// class HabitController extends GetxController {
//   final storage = GetStorage();
//   final habits = <Habit>[].obs;
//   String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//   @override
//   void onInit() {
//     super.onInit();
//     _handleDateChange();
//     loadHabits();
//   }
//
//   void _handleDateChange() {
//     String? lastDate = storage.read('lastDate');
//
//     if (lastDate != today) {
//       // Save yesterday's habits to history
//       if (lastDate != null && storage.read<List>('habits') != null) {
//         storage.write('history_$lastDate', storage.read<List>('habits'));
//       }
//
//       // Reset today's habits (done = false, completedCount = 0)
//       final resetHabits = (storage.read<List>('habits') ?? []).map((e) {
//         final map = Map<String, dynamic>.from(e);
//         map['done'] = false;
//         map['completedCount'] = 0;
//         return map;
//       }).toList();
//
//       storage.write('habits', resetHabits);
//       storage.write('lastDate', today);
//     }
//   }
//
//   void loadHabits() {
//     final stored = storage.read<List>('habits') ?? [];
//     habits.value = stored.map((e) => Habit.fromMap(Map<String, dynamic>.from(e))).toList();
//   }
//
//   void saveHabits() {
//     storage.write('habits', habits.map((h) => h.toMap()).toList());
//   }
//
//   void incrementProgress(int index) {
//     if (habits[index].completedCount < habits[index].targetCount) {
//       habits[index].completedCount++;
//       if (habits[index].completedCount == habits[index].targetCount) {
//         habits[index].done = true;
//       }
//       habits.refresh();
//       saveHabits();
//       storage.write('history_$today', habits.map((h) => h.toMap()).toList());
//     }
//   }
//
//   void decrementProgress(int index) {
//     if (habits[index].completedCount > 0) {
//       habits[index].completedCount--;
//       habits[index].done = false;
//       habits.refresh();
//       saveHabits();
//       storage.write('history_$today', habits.map((h) => h.toMap()).toList());
//     }
//   }
//
//
//
//   void addHabit(String name, int targetCount, String notes) {
//     habits.add(Habit(
//       name: name,
//       done: false,
//       streak: 0,
//       targetCount: targetCount,
//       completedCount: 0,
//       notes: notes,
//     ));
//     saveToday();
//   }
//
//
//   List<Habit> getHistory(String date) {
//     final stored = storage.read<List>('history_$date') ?? [];
//     return stored.map((e) => Habit.fromMap(Map<String, dynamic>.from(e))).toList();
//   }
// }

