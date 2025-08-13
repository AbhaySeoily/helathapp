import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../main.dart';
import '../controller/habit_controller.dart';

/// ---------------- Habits ----------------
class HabitScreen extends StatelessWidget {
  final ctrl = Get.find<HabitController>();
  final newCtrl = TextEditingController();
  HabitScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Habits')), body: Padding(padding: EdgeInsets.all(kPad), child: Column(children: [
      Expanded(child: Obx(()=> ListView.separated(itemCount: ctrl.habits.length, separatorBuilder: (_,__)=> Divider(), itemBuilder: (_, idx){
        final h = ctrl.habits[idx];
        return CheckboxListTile(value: h.done, title: Text(h.name), subtitle: Text('Streak: ${h.streak} days'), onChanged: (_)=> ctrl.toggle(idx));
      }))),
      Row(children: [ Expanded(child: TextField(controller: newCtrl, decoration: InputDecoration(hintText:'Add habit'))), IconButton(icon: Icon(Iconsax.add), onPressed: (){
        final t = newCtrl.text.trim();
        if (t.isNotEmpty) { ctrl.add(t); newCtrl.clear(); }
      }) ])
    ])));
  }
}