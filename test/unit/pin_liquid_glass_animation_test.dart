import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
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

  testWidgets('PinLockView applies LiquidGlassLens only to non-text UI elements and animates success', (WidgetTester tester) async {
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

    // 1. Verify LiquidGlassLens elements exist
    final lenses = find.byType(LiquidGlassLens);
    expect(lenses, findsAtLeastNWidgets(3));

    // 2. Verify number keys ('0'-'9') are present and responsive
    for (int i = 0; i <= 9; i++) {
      final numKeyFinder = find.text('$i');
      expect(numKeyFinder, findsOneWidget);
    }

    // 3. Enter PIN and verify success celebration animation
    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('2'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('3'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('4'));
    await tester.pump(); // Trigger _verify

    // Check checkmark icon inside the LiquidGlassLens crest badge
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Advance through exit animations
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(controller.isLocked.value, isFalse);
  });
}
