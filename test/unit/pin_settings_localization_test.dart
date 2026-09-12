import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/modules/security/views/pin_settings_view.dart';
import 'package:money_tracker/app/theme/app_theme.dart';
import 'package:money_tracker/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.put<SecurityController>(SecurityController());
  });

  tearDown(() {
    Get.reset();
  });

  group('PinSettingsView Localization Tests', () {
    testWidgets('1. PinSettingsView renders in Thai mode with 100% Thai localization', (tester) async {
      Get.locale = const Locale('th', 'TH');
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: const PinSettingsView(),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('pin_security'.tr), findsOneWidget);
      expect(find.text('pin_subtitle'.tr), findsOneWidget);
      expect(find.text('pin_status_disabled'.tr), findsOneWidget);

      // Check hero card
      expect(find.text('pin_security_disabled'.tr), findsOneWidget);
      expect(find.text('pin_badge_open'.tr), findsOneWidget);
      expect(find.text('pin_disabled_desc'.tr), findsOneWidget);

      // Check switches and titles
      expect(find.text('lock_app_with_pin'.tr), findsOneWidget);
      expect(find.text('lock_app_with_pin_desc'.tr), findsOneWidget);

      // Check info cards
      expect(find.text('hardware_security_title'.tr), findsOneWidget);
      expect(find.text('hardware_security_desc'.tr), findsOneWidget);
      expect(find.text('forgot_pin_faq_title'.tr), findsOneWidget);
      expect(find.text('forgot_pin_faq_desc'.tr), findsOneWidget);
    });

    testWidgets('2. PinSettingsView renders in English mode with 100% English localization', (tester) async {
      Get.locale = const Locale('en', 'US');
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en', 'US'),
          translations: AppTranslations(),
          home: const PinSettingsView(),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Security & PIN'), findsOneWidget);
      expect(find.text('Protect financial records and privacy'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);

      // Check hero card
      expect(find.text('PIN Security Disabled'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('Access directly without entering passcode'), findsOneWidget);

      // Check switches
      expect(find.text('Lock App with PIN'), findsOneWidget);
      expect(find.text('Require 4-digit PIN to open app'), findsOneWidget);

      // Check info cards
      expect(find.text('Hardware-Level Security'), findsOneWidget);
      expect(find.text('What if I forget my PIN?'), findsOneWidget);
    });

    testWidgets('3. Set PIN Dialog renders localized strings in English', (tester) async {
      Get.locale = const Locale('en', 'US');
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en', 'US'),
          translations: AppTranslations(),
          home: const PinSettingsView(),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle switch to trigger Set PIN dialog
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Verify Set PIN Dialog in English
      expect(find.text('Set New 4-Digit PIN'), findsOneWidget);
      expect(find.text('Enter 4 digits to set passcode'), findsOneWidget);
      expect(find.text('STEP 1: Set PIN'), findsOneWidget);
      expect(find.text('STEP 2: Confirm PIN'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
