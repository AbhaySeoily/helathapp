import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../controller/screen_time_controller.dart';

class ScreenFullReport extends StatefulWidget {
  @override
  State<ScreenFullReport> createState() => _ScreenFullReportState();
}

class _ScreenFullReportState extends State<ScreenFullReport> {
  final ctrl = Get.find<ScreenTimeController>();
  bool weekly = true;

  @override
  void initState() {
    super.initState();
    ctrl.loadDailyTotals(days: weekly ? 7 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Report')),
      body: Padding(
        padding: EdgeInsets.all(kPad),
        child: Column(
          children: [
            Row(
              children: [
                const Text('View:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Daily'),
                  selected: !weekly,
                  onSelected: (_) async {
                    setState(() => weekly = false);
                    await ctrl.loadDailyTotals(days: 1);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Weekly'),
                  selected: weekly,
                  onSelected: (_) async {
                    setState(() => weekly = true);
                    await ctrl.loadDailyTotals(days: 7);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final items = ctrl.dailyTotals
                    .where((d) => d.totalMinutes > 0) // remove 0-second days
                    .toList();

                if (items.isEmpty) {
                  return const Center(child: Text('No historical usage data'));
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final d = items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        title: Text(fmtDate(d.date)),
                        subtitle: Text('Total: ${d.totalMinutes} min'),
                        children: [
                          // get all apps for this date from ctrl.apps if needed
                          ...ctrl.apps
                              .where((app) => app.minutes > 0)
                              .map((app) {
                            final isTop = app.name == d.topApp;
                            return ListTile(
                              dense: true,
                              title: Text(
                                app.name + (isTop ? '  (Top)' : ''),
                                style: TextStyle(
                                  fontWeight: isTop
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: Text('${app.minutes} min'),
                            );
                          }).toList()
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
