import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wellness_getx_app/screen_time/ui/screen_full_report.dart';

import '../../main.dart';
import '../controller/screen_time_controller.dart';

class ScreenTimeScreen extends StatelessWidget {
  final ctrl = Get.find<ScreenTimeController>();
  ScreenTimeScreen({Key? key}) : super(key: key);

  void _openLimitDialog(BuildContext ctx, String appName, int initial, bool active) {
    int val = initial;
    bool isActive = active;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Set limit for $appName'),
        content: StatefulBuilder(
          builder: (c, s) {
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Slider(
                value: val.toDouble(),
                min: 0,
                max: 180,
                divisions: 18,
                onChanged: (v) => s(() => val = v.round()),
              ),
              Row(children: [
                const Text('Active'),
                const Spacer(),
                Switch(
                  value: isActive,
                  onChanged: (v) => s(() => isActive = v),
                )
              ]),
              const SizedBox(height: 6),
              Text('$val minutes')
            ]);
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ctrl.setLimit(appName, val, isActive);
              Get.back();
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Widget _permissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Usage Access Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'To show app usage statistics, please grant Usage Access in Settings.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: ctrl.requestPermission,
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loading() => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Loading usage statistics...')
      ]),
    ),
  );

  Widget _error(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 72, color: Colors.red[400]),
          const SizedBox(height: 12),
          const Text('Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: ctrl.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          )
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: ctrl.refresh),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return _loading();
        if (ctrl.error.value.isNotEmpty) return _error(ctrl.error.value);
        if (!ctrl.hasPermission.value) return _permissionRequest();

        // data state
        return Padding(
          padding: EdgeInsets.all(kPad),
          child: Column(
            children: [
              Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.indigo.shade50,
                  child: Text('${ctrl.total.value}m',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                const Text('Today')
              ]),
              const SizedBox(height: 12),
              // You can plug your chart back in here later
              Card(child: Padding(padding: const EdgeInsets.all(8), child: const SizedBox())),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() => ctrl.apps.isEmpty
                    ? const Center(child: Text('No usage for the last 24 hours'))
                    : ListView.separated(
                  itemCount: ctrl.apps.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, idx) {
                    final a = ctrl.apps[idx];
                    final limit = ctrl.limits[a.name];
                    return ListTile(
                      leading: CircleAvatar(child: Text(a.name.isNotEmpty ? a.name[0] : '?')),
                      title: Text(a.name),
                      subtitle: Text(
                        '${a.minutes} min${limit != null ? ' • Limit ${limit}m' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Iconsax.timer),
                        onPressed: () => _openLimitDialog(
                          context,
                          a.name,
                          limit ?? 30,
                          limit != null,
                        ),
                      ),
                    );
                  },
                )),
              ),
              ElevatedButton(
                onPressed: () => Get.to(() => ScreenFullReport()),
                child: const Text('View Full Report'),
              )
            ],
          ),
        );
      }),
    );
  }
}
