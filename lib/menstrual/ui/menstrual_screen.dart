import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../main.dart';
import '../controller/menstrual_controller.dart';

class MenstrualScreen extends StatelessWidget {
  final ctrl = Get.find<MenstrualController>();
  final _symCtrl = TextEditingController();
  MenstrualScreen({Key? key}) : super(key: key);

  void _logSymptom(BuildContext ctx) {
    _symCtrl.clear();
    String mood = 'Neutral';
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('Log Symptoms'),
      content: StatefulBuilder(builder: (c,s){
        return Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _symCtrl, decoration: InputDecoration(labelText:'Symptoms')),
          SizedBox(height:8),
          DropdownButton<String>(value: mood, items: ['Sad','Neutral','Happy'].map((e)=> DropdownMenuItem(child: Text(e), value: e)).toList(), onChanged: (v)=> s(()=> mood=v!))
        ]);
      }),
      actions: [ TextButton(onPressed: ()=> Get.back(), child: Text('Cancel')), TextButton(onPressed: (){
        ctrl.logSymptoms(_symCtrl.text.trim(), 'Neutral');
        Get.back();
      }, child: Text('Save')) ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Menstrual Cycle')), body: Padding(padding: EdgeInsets.all(kPad), child: Column(children: [
      Obx(()=> ListTile(leading: Icon(Iconsax.calendar_1), title: Text('Day ${ctrl.cycleDay.value}'), subtitle: Text('Next: ${fmtDate(ctrl.nextPeriod.value)}'))),
      SizedBox(height:8),
      ElevatedButton(onPressed: ()=> ctrl.logStart(), child: Text('Log Period Start')),
      SizedBox(height:8),
      ElevatedButton(onPressed: ()=> _logSymptom(context), child: Text('Log Symptoms')),
      SizedBox(height:12),
      Expanded(child: Obx(()=> ListView(children: [
        ListTile(title: Text('Starts'), subtitle: Text(ctrl.starts.map((d)=>fmtDate(d)).join('\n')), isThreeLine:true),
        Divider(),
        ListTile(title: Text('Symptoms log')),
        ...ctrl.symptoms.map((s) => ListTile(title: Text(fmtDate(DateTime.parse(s['date']))), subtitle: Text('${s['text']} • Mood: ${s['mood']}'))).toList()
      ])))
    ])));
  }
}
