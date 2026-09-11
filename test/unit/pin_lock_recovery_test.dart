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
    Get.locale = const Locale('th', 'TH');
    Get.put<SecurityController>(SecurityController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('PinLockView Forgot PIN in-stack popup and reset confirmation flow', (WidgetTester tester) async {
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

    // Verify forgot PIN button is visible on lock screen
    final forgotPinBtn = find.text('ลืมรหัส PIN หรือไม่?');
    expect(forgotPinBtn, findsOneWidget);

    // Tap forgot PIN button
    await tester.tap(forgotPinBtn);
    await tester.pumpAndSettle();

    // Recovery options modal should be immediately displayed on screen!
    expect(find.byKey(const ValueKey('recovery_options')), findsOneWidget);
    expect(find.text('ลืมรหัส PIN?'), findsOneWidget);
    expect(find.text('รีเซ็ตรหัส PIN เพื่อเข้าใช้งาน'), findsOneWidget);

    // Tap Reset PIN option
    await tester.tap(find.text('รีเซ็ตรหัส PIN เพื่อเข้าใช้งาน'));
    await tester.pumpAndSettle();

    // Confirm card should now be displayed
    expect(find.byKey(const ValueKey('recovery_confirm')), findsOneWidget);
    expect(find.text('ยืนยันการรีเซ็ต PIN'), findsOneWidget);

    // Countdown button is initially disabled
    expect(find.textContaining('รอ'), findsOneWidget);

    // Advance 4 seconds
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Confirm button is now active
    final confirmBtn = find.widgetWithText(ElevatedButton, 'ยืนยันการรีเซ็ต PIN');
    expect(confirmBtn, findsOneWidget);

    // Tap confirm reset
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify PIN is now disabled and onUnlocked was called
    expect(controller.isPinEnabled.value, isFalse);
    expect(controller.isLocked.value, isFalse);
    expect(unlockedCalled, isTrue);
  });
}
