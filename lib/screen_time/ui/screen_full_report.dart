import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../main.dart';
import '../controller/screen_time_controller.dart';

class ScreenFullReport extends StatefulWidget {
  @override
  _ScreenFullReportState createState() => _ScreenFullReportState();
}
class _ScreenFullReportState extends State<ScreenFullReport> {
  final ctrl = Get.find<ScreenTimeController>();
  bool weekly = false;
  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6-i)));
    return Scaffold(appBar: AppBar(title: Text('Screen Report')), body: Padding(padding: EdgeInsets.all(kPad), child: Column(children: [
      Row(children: [Text('View:'), SizedBox(width:8), ChoiceChip(label: Text('Daily'), selected: !weekly, onSelected: (_)=> setState(()=> weekly=false)), SizedBox(width:8), ChoiceChip(label: Text('Weekly'), selected: weekly, onSelected: (_)=> setState(()=> weekly=true))]),
      SizedBox(height:12),
      Expanded(child: ListView(children: days.map((d){
        final total = 40 + Random().nextInt(120);
        return ListTile(title: Text(fmtDate(d)), subtitle: Text('Total: ${total} min • Top: YouTube'));
      }).toList()))
    ])));
  }
}