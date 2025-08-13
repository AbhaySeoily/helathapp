import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wellness_getx_app/screen_time/ui/screen_full_report.dart';

import '../../main.dart';
import '../controller/screen_time_controller.dart';

/// ---------------- Screen Time screens ----------------
class ScreenTimeScreen extends StatelessWidget {
  final ctrl = Get.find<ScreenTimeController>();
  ScreenTimeScreen({Key? key}) : super(key: key);

  void _openLimitDialog(BuildContext ctx, String appName, int initial, bool active) {
    int val = initial;
    bool isActive = active;
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('Set limit for $appName'),
      content: StatefulBuilder(builder: (c,s) {
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Slider(value: val.toDouble(), min: 0, max: 180, divisions: 18, onChanged: (v)=> s(()=> val = v.round())),
          Row(children: [Text('Active'), Spacer(), Switch(value: isActive, onChanged: (v)=> s(()=> isActive = v))]),
          SizedBox(height:6), Text('$val minutes')
        ]);
      }),
      actions: [ TextButton(onPressed: ()=> Get.back(), child: Text('Cancel')), TextButton(onPressed: (){
        ctrl.setLimit(appName, val, isActive);
        Get.back();
      }, child: Text('Save')) ],
    ));
  }

  Widget _barChart() {
    return SizedBox();
    // final apps = ctrl.apps;
    // if (apps.isEmpty) return Center(child: Text('No data'));
    // final maxv = apps.map((a)=>a.minutes).reduce(max).toDouble();
    // return SizedBox(
    //   height: 180,
    //   child: BarChart(BarChartData(barGroups: apps.mapIndexed((i,a) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: a.minutes.toDouble(), color: Colors.indigo)])).toList(),
    //       titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val,meta){
    //         final idx = val.toInt();
    //         if (idx >=0 && idx < apps.length) return SideTitleWidget(child: Text(apps[idx].name, style: TextStyle(fontSize:10)), axisSide: meta.axisSide);
    //         return SideTitleWidget(child: Text(''), axisSide: meta.axisSide);
    //       })), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles:false))),
    //       gridData: FlGridData(show:false))),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Screen Time')), body: Padding(padding: EdgeInsets.all(kPad), child: Column(children: [
      Obx(()=> Column(children:[ CircleAvatar(radius:44, backgroundColor: Colors.indigo.shade50, child: Text('${ctrl.total.value}m', style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(height:8), Text('Today') ])),
      SizedBox(height:12),
      Card(child: Padding(padding: EdgeInsets.all(8), child: _barChart())),
      SizedBox(height:12),
      Expanded(child: Obx(()=> ListView.separated(itemCount: ctrl.apps.length, separatorBuilder: (_,__)=> Divider(), itemBuilder: (_, idx){
        final a = ctrl.apps[idx];
        final limit = ctrl.limits[a.name];
        return ListTile(leading: CircleAvatar(child: Text(a.name[0])), title: Text(a.name), subtitle: Text('${a.minutes} min${limit!=null? ' • Limit ${limit}m':''}'), trailing: IconButton(icon: Icon(Iconsax.timer), onPressed: ()=> _openLimitDialog(context, a.name, limit ?? 30, limit!=null)));
      }))),
      ElevatedButton(onPressed: ()=> Get.to(()=> ScreenFullReport()), child: Text('View Full Report'))
    ])));
  }
}