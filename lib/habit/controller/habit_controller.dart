import 'package:get/get.dart';

import '../model/habit.dart';

class HabitController extends GetxController {
  RxList<Habit> habits = RxList([
    Habit(name:'Morning Walk', done:false, streak:3),
    Habit(name:'Meditation', done:true, streak:10),
    Habit(name:'Read 20 min', done:false, streak:1),
  ]);

  void toggle(int idx) {
    final h = habits[idx];
    habits[idx] = Habit(name: h.name, done: !h.done, streak: !h.done ? h.streak+1 : 0);
  }

  void add(String name) {
    habits.add(Habit(name: name, done:false, streak:0));
  }
}
