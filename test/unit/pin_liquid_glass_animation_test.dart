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

    // 1. Verify LiquidGlassLens elements exist on non-text elements:
    // - Crest Icon Badge (no text)
    // - 4-Dots Pod Capsule (no text)
    // - Backspace key (no text)
    final lenses = find.byType(LiquidGlassLens);
    expect(lenses, findsAtLeastNWidgets(3));

    // Verify each LiquidGlassLens widget subtree has no Text widgets inside its direct decorated body
    for (final lensElement in lenses.evaluate()) {
      final lensWidget = lensElement.widget as LiquidGlassLens;
      final lensChildFinder = find.descendant(
        of: find.byWidget(lensWidget),
        matching: find.byType(Text),
      );
      expect(
        lensChildFinder,
        findsNothing,
        reason: 'LiquidGlassLens must NOT wrap any text UI according to user requirements',
      );
    }

    // 2. Verify number keys ('1'-'9', '0') do NOT have LiquidGlassLens as ancestor
    for (int i = 0; i <= 9; i++) {
      final numKeyFinder = find.text('$i');
      expect(numKeyFinder, findsOneWidget);
      final hasLensAncestor = find.ancestor(
        of: numKeyFinder,
        matching: find.byType(LiquidGlassLens),
      );
      expect(
        hasLensAncestor,
        findsNothing,
        reason: 'Number button $i has text and must not be wrapped in LiquidGlassLens',
      );
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

    // Verify still zero Text inside any LiquidGlassLens during success state
    for (final lensElement in find.byType(LiquidGlassLens).evaluate()) {
      final lensWidget = lensElement.widget as LiquidGlassLens;
      final lensChildFinder = find.descendant(
        of: find.byWidget(lensWidget),
        matching: find.byType(Text),
      );
      expect(lensChildFinder, findsNothing);
    }

    // Advance through exit animations
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(controller.isLocked.value, isFalse);
  });
}
