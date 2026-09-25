import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app/data/services/bank_slip_service.dart';
import 'app/data/services/security_service.dart';
import 'app/data/services/storage_service.dart';
import 'app/modules/security/controllers/security_controller.dart';
import 'app/modules/security/views/pin_lock_view.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/modern_page_transition.dart';
import 'app/theme/app_theme.dart';
import 'app/translations/app_translations.dart';

Locale resolveInitialLocale(String? savedLang) {
  if (savedLang == 'en') {
    return const Locale('en', 'US');
  }
  if (savedLang == 'th') {
    return const Locale('th', 'TH');
  }
  // Default to system locale
  try {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (deviceLocale.languageCode == 'th') {
      return const Locale('th', 'TH');
    }
  } catch (_) {}
  return const Locale('en', 'US');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityService().init();
  await BankSlipService().init();
  final savedLang = await StorageService().loadLanguage();
  final initialLocale = resolveInitialLocale(savedLang);
  runApp(MoneyTrackerApp(initialLocale: initialLocale));
}

class MoneyTrackerApp extends StatelessWidget {
  final Locale? initialLocale;
  const MoneyTrackerApp({super.key, this.initialLocale});

  Locale get _effectiveLocale {
    if (initialLocale != null) return initialLocale!;
    return resolveInitialLocale(null);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Money Tracker - FinTech 2026',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: _effectiveLocale,
      fallbackLocale: const Locale('en', 'US'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      defaultTransition: Transition.fadeIn,
      customTransition: ModernNothingTransition(),
      transitionDuration: const Duration(milliseconds: 220),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      initialBinding: DashboardBinding(),
      builder: (context, child) {
        final security = Get.put<SecurityController>(
          SecurityController(),
          permanent: true,
        );
        final mediaQuery = MediaQuery.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.05,
              ),
            ),
            child: Stack(
              children: [
                ?child,
                Obx(() {
                  if (security.isLocked.value) {
                    return const PinLockView();
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
