import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/data/services/security_service.dart';
import 'app/data/services/storage_service.dart';
import 'app/modules/security/controllers/security_controller.dart';
import 'app/modules/security/views/pin_lock_view.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityService().init();
  final savedLang = await StorageService().loadLanguage();
  final initialLocale = savedLang == 'en' ? const Locale('en', 'US') : const Locale('th', 'TH');
  runApp(MoneyTrackerApp(initialLocale: initialLocale));
}

/// Root Application Widget ด้วย GetX 4.7.3 (Simplified Architecture)
class MoneyTrackerApp extends StatelessWidget {
  final Locale initialLocale;
  const MoneyTrackerApp({super.key, this.initialLocale = const Locale('th', 'TH')});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Money Tracker - FinTech 2026',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('th', 'TH'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      initialBinding: DashboardBinding(),
      builder: (context, child) {
        final security = Get.put<SecurityController>(SecurityController(), permanent: true);
        return Stack(
          children: [
            ?child,
            Obx(() {
              if (security.isLocked.value) {
                return const PinLockView();
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }
}
