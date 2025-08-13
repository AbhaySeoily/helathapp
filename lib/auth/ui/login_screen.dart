import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../dashboard/ui/dashboard_screen.dart';
import '../../main.dart';
import '../controller/AuthController.dart';

/// ---------------- Login Screen ----------------
class LoginScreen extends StatelessWidget {
  final auth = Get.find<AuthController>();
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final otpSent = false.obs;

  LoginScreen({Key? key}) : super(key: key);

  Widget _header() {
    return Row(children: [
      Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(Iconsax.heart, color: kPrimary, size: 36)),
      SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        SizedBox(height: 4),
        Text('Sign in to your wellness dashboard', style: TextStyle(color: Colors.grey[700])),
      ])
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: EdgeInsets.all(kPad),
        child: SingleChildScrollView(child: Column(children: [
          SizedBox(height: 20),
          _header(),
          SizedBox(height: 20),
          Obx(() => Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [
            TextField(controller: otpSent.value ? otpCtrl : phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(prefixIcon: Icon(Iconsax.mobile), hintText: otpSent.value ? 'Enter OTP' : 'Phone number')),
            SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
              if (!otpSent.value) {
                final p = phoneCtrl.text.trim();
                if (p.length < 6) { Get.snackbar('Error', 'Enter valid phone'); return; }
                otpSent.value = true;
                await auth.sendOtp(p);
              } else {
                final code = otpCtrl.text.trim();
                await auth.verifyOtp(code);
              }
            }, child: Obx(()=> Text(otpSent.value ? 'Verify OTP' : 'Send OTP'))))
          ])))),
          SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => Get.to(() => DashboardScreen()), icon: Icon(Iconsax.arrow_right_2), label: Text('Continue as Guest')),
        ])),
      )),
    );
  }
}