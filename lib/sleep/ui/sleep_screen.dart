import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/sleep_controller.dart';
import '../model/sleep_entry.dart';
import 'package:intl/intl.dart';

class SleepScreen extends StatelessWidget {
  final ctrl = Get.find<SleepController>();

  SleepScreen({Key? key}) : super(key: key);

  void _openLog(BuildContext context, {bool isNap = false}) async {
    TimeOfDay start = TimeOfDay(hour:23, minute:0);
    TimeOfDay end = TimeOfDay(hour:7, minute:0);
    int quality = 3;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isNap ? "Log Nap" : "Log Sleep"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Start: ${start.format(context)}'),
                trailing: Icon(Icons.edit),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: start);
                  if(t != null) setState(() => start = t);
                },
              ),
              ListTile(
                title: Text('End: ${end.format(context)}'),
                trailing: Icon(Icons.edit),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: end);
                  if(t != null) setState(() => end = t);
                },
              ),
              SizedBox(height: 8),
              Text("Sleep Quality", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final index = i + 1;
                  final selected = quality == index;
                  return GestureDetector(
                    onTap: () => setState(() => quality = index),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? Colors.blue.shade200 : Colors.transparent,
                      ),
                      child: Text(
                        _getEmoji(index),
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                }),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: ()=> Get.back(), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final sdt = DateTime(now.year, now.month, now.day, start.hour, start.minute);
                var edt = DateTime(now.year, now.month, now.day, end.hour, end.minute);
                if(edt.isBefore(sdt)) edt = edt.add(Duration(days:1));

                ctrl.logSleep(sdt, edt, quality, isNap: isNap);
                Get.back(); // dialog auto close
              },
              child: Text('Save'),
            )
          ],
        ),
      ),
    );
  }

  String _getEmoji(int quality) {
    switch(quality){
      case 5: return '😁';
      case 4: return '🙂';
      case 3: return '😐';
      case 2: return '😕';
      default: return '😴';
    }
  }

  String _formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sleep Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.nightlight_round),
                  label: Text("Log Sleep"),
                  onPressed: ()=> _openLog(context),
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.bedtime),
                  label: Text("Log Nap"),
                  onPressed: ()=> _openLog(context, isNap:true),
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Obx(()=> ListView.separated(
                itemCount: ctrl.history.length,
                separatorBuilder: (_,__)=> Divider(),
                itemBuilder: (_,idx){
                  final e = ctrl.history[idx];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: e.isNap ? Colors.blue.shade50 : Colors.indigo.shade50,
                    child: ListTile(
                      leading: Text(e.isNap ? '🛌' : '🌙', style: TextStyle(fontSize: 28)),
                      title: Text(e.isNap ? 'Nap' : 'Night Sleep'),
                      subtitle: Text('${_formatDate(e.date)} • ${e.durationString}'),
                      trailing: Text(_getEmoji(e.quality), style: TextStyle(fontSize:28)),
                    ),
                  );
                },
              )),
            )
          ],
        ),
      ),
    );
  }
}
