import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/modules/security/views/pin_lock_view.dart';
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

  group('PinLockView Responsive Layout & Overflow Tests', () {
    testWidgets('1. PinLockView on small viewport (360x560) with canCancel does not overflow', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 560));
      Get.locale = const Locale('th', 'TH');
      final controller = Get.find<SecurityController>();
      await controller.setPin('1234');
      controller.lock();

      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: const PinLockView(canCancel: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Money Tracker Security'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('2. PinLockView with 3+ failed attempts showing hint does not overflow on 375x667', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      Get.locale = const Locale('th', 'TH');
      final controller = Get.find<SecurityController>();
      await controller.setPin('1234');
      controller.lock();

      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: const PinLockView(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter wrong PIN 3 times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('9'));
        await tester.pump(const Duration(milliseconds: 30));
        await tester.tap(find.text('9'));
        await tester.pump(const Duration(milliseconds: 30));
        await tester.tap(find.text('9'));
        await tester.pump(const Duration(milliseconds: 30));
        await tester.tap(find.text('9'));
        await tester.pump(const Duration(milliseconds: 400));
      }

      expect(find.text('ลืมรหัสผ่าน? แตะเพื่อกู้คืน'), findsOneWidget);
      expect(find.text('forgot_pin'.tr), findsOneWidget);
    });

    testWidgets('3. PinLockView unlocks cleanly and plays celebration on compact viewport', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 580));
      Get.locale = const Locale('en', 'US');
      final controller = Get.find<SecurityController>();
      await controller.setPin('4321');
      controller.lock();

      bool unlocked = false;

      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('en', 'US'),
          translations: AppTranslations(),
          home: PinLockView(
            onUnlocked: () {
              unlocked = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('4'));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.text('3'));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.text('1'));
      await tester.pump();

      // Check celebration icon rendered on compact screen
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Complete exit animations
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
    });
  });
}
