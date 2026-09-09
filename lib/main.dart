import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/data/services/security_service.dart';
import 'app/modules/security/controllers/security_controller.dart';
import 'app/modules/security/views/pin_lock_view.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityService().init();
  runApp(const MoneyTrackerApp());
}

/// Root Application Widget ด้วย GetX 4.7.3 (Simplified Architecture)
class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Money Tracker - FinTech 2026',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      initialBinding: DashboardBinding(),
      builder: (context, child) {
        final security = Get.put<SecurityController>(SecurityController(), permanent: true);
        return Obx(() {
          if (security.isLocked.value) {
            return const PinLockView();
          }
          return child ?? const SizedBox();
        });
      },
    );
  }
}
