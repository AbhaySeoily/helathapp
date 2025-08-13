// AuthController: mock login via OTP (persisted)
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../dashboard/ui/dashboard_screen.dart';
import '../../main.dart';
import '../ui/login_screen.dart';

class AuthController extends GetxController {
  final store = GetStorage();
  final logged = false.obs;
  @override
  void onInit() {
    super.onInit();
    logged.value = store.read(KS_LOGGED) ?? false;
  }

  Future<void> sendOtp(String phone) async {
    await Future.delayed(Duration(milliseconds: 400));
    Get.snackbar('OTP', 'Mock OTP sent to $phone');
  }

  Future<void> verifyOtp(String code) async {
    if (code.trim().length >= 3) {
      store.write(KS_LOGGED, true);
      logged.value = true;
      Get.offAll(() => DashboardScreen());
    } else {
      Get.snackbar('Error', 'Invalid OTP');
    }
  }

  void logout() {
    store.remove(KS_LOGGED);
    logged.value = false;
    Get.offAll(() => LoginScreen());
  }
}