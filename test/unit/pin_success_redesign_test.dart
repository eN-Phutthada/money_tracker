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

  testWidgets('PinLockView redesigned success experience in Thai mode', (WidgetTester tester) async {
    Get.locale = const Locale('th', 'TH');
    final controller = Get.find<SecurityController>();
    await controller.setPin('1234');
    controller.lock();

    bool unlockedCalled = false;

    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('th', 'TH'),
        translations: AppTranslations(),
        home: PinLockView(
          onUnlocked: () {
            unlockedCalled = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial locked security state
    expect(find.text('pin_security_title'.tr), findsOneWidget);
    expect(find.text('กรุณาใส่รหัส PIN 4 หลัก'), findsOneWidget);
    expect(find.text('ระบบความปลอดภัยทำงาน'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    // Enter correct PIN (1, 2, 3, 4)
    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('2'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('3'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('4'));
    await tester.pump(); // Trigger _verify

    // Check celebration elements rendered
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('ยืนยันตัวตนสำเร็จ'), findsOneWidget);
    expect(find.text('ปลดล็อกสำเร็จ'), findsOneWidget);
    expect(find.text('ยินดีต้อนรับกลับสู่ Money Tracker'), findsOneWidget);

    // Complete exit animations
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(controller.isLocked.value, isFalse);
    expect(unlockedCalled, isTrue);
  });

  testWidgets('PinLockView redesigned success experience in English mode', (WidgetTester tester) async {
    Get.locale = const Locale('en', 'US');
    final controller = Get.find<SecurityController>();
    await controller.setPin('9876');
    controller.lock();

    bool unlockedCalled = false;

    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('en', 'US'),
        translations: AppTranslations(),
        home: PinLockView(
          onUnlocked: () {
            unlockedCalled = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial locked security state in English
    expect(find.text('Money Tracker Security'), findsOneWidget);
    expect(find.text('Enter 4-Digit PIN'), findsOneWidget);
    expect(find.text('Vault Encryption Active'), findsOneWidget);

    // Enter correct PIN (9, 8, 7, 6)
    await tester.tap(find.text('9'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('8'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('6'));
    await tester.pump(); // Trigger _verify

    // Check celebration elements rendered in English
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Secure Access Granted'), findsOneWidget);
    expect(find.text('Unlocked Successfully'), findsOneWidget);
    expect(find.text('Welcome back to Money Tracker'), findsOneWidget);

    // Complete exit animations
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(controller.isLocked.value, isFalse);
    expect(unlockedCalled, isTrue);
  });
}
