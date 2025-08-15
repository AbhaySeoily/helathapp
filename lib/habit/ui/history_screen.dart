import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../controller/habit_controller.dart';
import '../model/habit.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../controller/habit_controller.dart';
import '../model/habit.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ctrl = Get.find<HabitController>();
  late Map<String, List<Habit>> allHistory;
  String? selectedDate; // which date's list is visible

  @override
  void initState() {
    super.initState();
    allHistory = ctrl.getAllHistory();
    if (allHistory.isNotEmpty) {
      // default selection: latest date
      final keys = allHistory.keys.toList()..sort();
      selectedDate = keys.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (allHistory.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("History")),
        body: const Center(child: Text("No history found yet.")),
      );
    }

    final dates = allHistory.keys.toList()..sort(); // ascending
    // Prepare numbers
    final assignedList = <double>[];
    final completedList = <double>[];
    for (final d in dates) {
      final items = allHistory[d]!;
      // NOTE: Assigned = number of habits that day (not sum of targets)
      final assigned = items.length.toDouble();
      final completed = items.where((h) => h.done).length.toDouble();
      assignedList.add(assigned);
      completedList.add(completed);
    }

    final maxY = [
      ...assignedList,
      ...completedList,
    ].fold<double>(0, (p, n) => n > p ? n : p).clamp(1, 999);

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------- Scrollable Bar Chart (All Dates) ----------
            SizedBox(
              height: 240,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: dates.length * 70, // width per day group
                  child: BarChart(
                    BarChartData(
                      maxY: maxY + 1,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchCallback: (ev, resp) {
                          final idx = resp?.spot?.touchedBarGroupIndex;
                          if (idx != null && idx >= 0 && idx < dates.length) {
                            setState(() {
                              selectedDate = dates[idx];
                            });
                          }
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i >= 0 && i < dates.length) {
                                final d = DateTime.parse(dates[i]);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(DateFormat('MM/dd').format(d),
                                      style: const TextStyle(fontSize: 10)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(dates.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 6,
                          barRods: [
                            // Assigned bar
                            BarChartRodData(
                              toY: assignedList[i],
                              color: Colors.blue,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            // Completed bar
                            BarChartRodData(
                              toY: completedList[i],
                              color: Colors.green,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                          showingTooltipIndicators: const [0, 1],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // ---------- Selected Date Header ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(selectedDate!))
                      : 'Select a date from graph',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (selectedDate != null)
                  TextButton.icon(
                    onPressed: () async {
                      // manual picker to jump
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(selectedDate!),
                        firstDate: DateTime(2023, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final key = DateFormat('yyyy-MM-dd').format(picked);
                        if (allHistory.containsKey(key)) {
                          setState(() => selectedDate = key);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No history for selected date')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text("Pick Date"),
                  ),
              ],
            ),
            const Divider(),

            // ---------- Listing for selected date ----------
            Expanded(
              child: (selectedDate == null || !allHistory.containsKey(selectedDate))
                  ? const Center(child: Text('Tap any date bar to view details'))
                  : ListView.separated(
                itemCount: allHistory[selectedDate!]!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final h = allHistory[selectedDate!]![idx];
                  final pct = h.targetCount == 0
                      ? 0.0
                      : (h.completedCount / h.targetCount).clamp(0, 1).toDouble();
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(
                        h.done ? Icons.check_circle : Icons.cancel,
                        color: h.done ? Colors.green : Colors.red,
                      ),
                      title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        "Target: ${h.targetCount}  •  Done: ${h.completedCount}"
                            "${(h.notes != null && h.notes!.isNotEmpty) ? "\nNotes: ${h.notes}" : ""}",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


