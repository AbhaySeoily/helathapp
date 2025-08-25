import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../auth/controller/AuthController.dart';
import '../../habit/ui/habit_screen.dart';
import '../../main.dart' hide DashboardController;
import '../../meal/controller/meal_controller.dart';
import '../../meal/ui/meal_screen.dart';
import '../../meal/ui/reipes_screen.dart';
import '../../screen_time/ui/screen_time_screen.dart';
import '../../sleep/ui/sleep_screen.dart';
import '../../steps/ui/step_screen.dart';
import '../../water/ui/water_screen.dart';
import '../controller/dashboard_controller.dart';

/// ---------------- Dashboard ----------------
class DashboardScreen extends StatelessWidget {
  final dc = Get.put(DashboardController());
  DashboardScreen({Key? key}) : super(key: key);

  Widget _card({required Widget leading, required String title, required Widget subtitle, List<Widget>? actions}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(children: [
          leading,
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            subtitle,
            if (actions != null) ...[SizedBox(height: 8), Wrap(spacing: 8, children: actions)]
          ]))
        ]),
      ),
    );
  }

  Widget _smallAction(IconData ic, String label, VoidCallback onTap) => OutlinedButton.icon(onPressed: onTap, icon: Icon(ic, size: 16), label: Text(label));

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: Text('Health Dashboard'), actions: [IconButton(icon: Icon(Iconsax.refresh), onPressed: () {  Get.snackbar('Refreshed','Mock data updated'); }), IconButton(icon: Icon(Iconsax.logout), onPressed: () => auth.logout())]),
      body: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.all(kPad), child: Column(children: [
        // Steps

// Steps Card for Dashboard
        Obx(() {
          final s = dc.steps.model.value;
          final pct = (s.today / (s.goal == 0 ? 1 : s.goal)).clamp(0.0, 1.0);
          final remainingSteps = (s.goal - s.today).clamp(0, s.goal);

          return _card(
            leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Icon(Iconsax.activity, color: kPrimary)
            ),
            title: 'Steps',
            subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${NumberFormat().format(s.today)}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kPrimary
                          )
                      ),
                      Text(
                          '/ ${NumberFormat().format(s.goal)}',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey
                          )
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 1 ? Colors.green : kPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey
                          )
                      ),
                      Text(
                          '${NumberFormat().format(remainingSteps)} left',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey
                          )
                      ),
                    ],
                  ),
                ]
            ),
            actions: [
              _smallAction(Iconsax.scan, 'Details', () => Get.to(() => StepsScreen())),
              _smallAction(Iconsax.setting, 'Set Goal', () => _openSetStepsGoal(context))
            ],
          );
        }),
        SizedBox(height: 8),

        Obx(() {
          final w = dc.water.model.value;
          final todayIntake = w.intakeToday(); // gets today's total
          final pct = (todayIntake / (w.goal == 0 ? 1 : w.goal)).clamp(0.0, 1.0);
          final points = dc.water.box.read(KS_WATER_REWARD) ?? 0;

          /// Helper to add water with reward points based on reminder
          void _addWaterWithReward(int ml) {
            final beforeReminder = dc.water.isBeforeNextReminder();
            dc.water.addWater(ml, beforeReminder: beforeReminder);

            // Optional: show snackbar for points
            Get.snackbar(
              "Water Logged",
              beforeReminder
                  ? "+15 points (before reminder)"
                  : "+10 points (after reminder)",
              snackPosition: SnackPosition.BOTTOM,
            );
          }

          return _card(
            leading: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.water_drop, color: Colors.blue),
            ),
            title: 'Water',
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$todayIntake / ${w.goal} ml', style: TextStyle(fontSize: 16)),
                SizedBox(height: 4),
                Text('Reward Points: $points', style: TextStyle(fontSize: 14, color: Colors.green)),
                SizedBox(height: 6),
                LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.blue,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => _addWaterWithReward(100),
                child: Text('+100ml'),
              ),
              ElevatedButton(
                onPressed: () => _addWaterWithReward(250),
                child: Text('+250ml'),
              ),
              ElevatedButton(
                onPressed: () => _addWaterWithReward(500),
                child: Text('+500ml'),
              ),
              OutlinedButton(
                onPressed: () => Get.to(() => WaterScreen()),
                child: Text('Open'),
              ),
            ],
          );
        }),





        SizedBox(height: 8),

        // Sleep
        _card(
          leading: Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Iconsax.moon, color: Colors.deepPurple)),
          title: 'Sleep',
          subtitle: Obx(() {
            final hist = dc.sleep.history;
            if (hist.isEmpty) return Text('No recent screen_time logged');
            final last = hist.first;
            return Text('${last.duration.inHours}h ${last.duration.inMinutes%60}m • ${last.quality}');
          }),
          actions: [ _smallAction(Iconsax.scan, 'Log / History', () => Get.to(()=> SleepScreen())) ],
        ),

        SizedBox(height: 8),

        // Screen Time
        Obx(() {
          final total = dc.screen.total.value;
          final top = dc.screen.apps.isNotEmpty ? dc.screen.apps.first.name : '-';
          return _card(
            leading: Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Iconsax.device_message, color: Colors.indigo)),
            title: 'Screen Time',
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$total minutes today', style: TextStyle(fontSize: 16)), SizedBox(height:6), Text('Top: $top')]),
            actions: [ _smallAction(Iconsax.scan, 'Open', ()=> Get.to(()=> ScreenTimeScreen())), _smallAction(Iconsax.setting, 'Set Limits', ()=> Get.to(()=> ScreenTimeScreen())) ],
          );
        }),

        SizedBox(height: 8),

        // Meals

        Obx(() {
          // aaj ke date ke planned meals
          final todaysPlain = dc.meal.plainMeals
              .where((m) =>
          m.date.year == DateTime.now().year &&
              m.date.month == DateTime.now().month &&
              m.date.day == DateTime.now().day)
              .length;

          // aaj ke date ke eaten meals
          final todaysEaten = dc.meal.eatenMeals
              .where((m) =>
          m.date.year == DateTime.now().year &&
              m.date.month == DateTime.now().month &&
              m.date.day == DateTime.now().day)
              .length;

          final total = todaysPlain + todaysEaten;

          return _card(
            leading: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.receipt, color: Colors.orange),
            ),
            title: 'Meals',
            subtitle: Text('$total logged today'), // count dikhane ka sahi tarika
            actions: [
              _smallAction(Iconsax.add_circle, 'Add Meal',
                      () => Get.to(() => MealScreen())),
              _smallAction(Iconsax.scan, 'Recipes',
                      () => Get.to(() => RecipesScreen())),
            ],
          );
        }),

        SizedBox(height: 8),

        // Habits
        Obx(() {
          final done = dc.habit.habits.where((h) => h.done).length;
          final total = dc.habit.habits.length;
          return _card(
            leading: Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Iconsax.tick_circle, color: Colors.green)),
            title: 'Habits',
            subtitle: Text('$done / $total completed'),
            actions: [ _smallAction(Iconsax.scan, 'Open', ()=> Get.to(()=> HabitScreen())) ],
          );
        }),

        SizedBox(height: 8),

        // Menstrual
        // Obx(() {
        //   return _card(
        //     leading: Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Iconsax.calendar_1, color: Colors.pink)),
        //     title: 'Menstrual Cycle',
        //     subtitle: Obx(()=> Text('Day ${dc.menstrual.cycleDay.value} • Next ${fmtDate(dc.menstrual.nextPeriod.value)}')),
        //     actions: [ _smallAction(Iconsax.edit, 'Log', ()=> Get.to(()=> MenstrualScreen())), _smallAction(Iconsax.scan, 'History', ()=> Get.to(()=> MenstrualScreen())) ],
        //   );
        // }),

        SizedBox(height: 16),
      ]))),
    );
  }

  void _openSetStepsGoal(BuildContext ctx) {
    final tc = TextEditingController(text: dc.steps.model.value.goal.toString());
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('Set step goal'),
      content: TextField(controller: tc, keyboardType: TextInputType.number),
      actions: [ TextButton(onPressed: ()=> Get.back(), child: Text('Cancel')), TextButton(onPressed: (){
        final v = int.tryParse(tc.text.trim());
        if (v!=null) dc.steps.setDailyGoal(v);
        Get.back();
      }, child: Text('Save')) ],
    ));
  }
}