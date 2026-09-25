import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/routes/app_pages.dart';
import 'package:money_tracker/app/routes/modern_page_transition.dart';
import 'package:money_tracker/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModernNothingTransition & Page Routing Tests', () {
    testWidgets('ModernNothingTransition builds slide, fade, and scale hierarchy', (tester) async {
      final transition = ModernNothingTransition();
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 320),
      );
      final secondaryController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 320),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return transition.buildTransition(
                context,
                Curves.easeOutCubic,
                Alignment.center,
                animationController,
                secondaryController,
                const Text('Transition Content'),
              );
            },
          ),
        ),
      );

      expect(find.text('Transition Content'), findsOneWidget);
      expect(find.byType(SlideTransition), findsAtLeastNWidgets(2));
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(2));
      expect(find.byType(ScaleTransition), findsOneWidget);

      animationController.dispose();
      secondaryController.dispose();
    });

    test('All AppPages routes define smooth modern transitions', () {
      for (final page in AppPages.routes) {
        final hasTransition = page.customTransition != null || page.transition != null;
        expect(hasTransition, isTrue, reason: 'Route ${page.name} should define a transition');
        expect(page.transitionDuration, isNotNull, reason: 'Route ${page.name} should define duration');
        expect(
          page.transitionDuration!.inMilliseconds,
          greaterThanOrEqualTo(200),
          reason: 'Route ${page.name} transition should be smooth (>=200ms)',
        );
      }
    });
  });

  group('SecurityController & Biometrics Unlock Tests', () {
    late SecurityController controller;

    setUp(() {
      Get.clearTranslations();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('th', 'TH');
      controller = SecurityController();
    });

    test('authenticateWithBiometricsDetailed succeeds in test environment', () async {
      final result = await controller.authenticateWithBiometricsDetailed(
        localizedReason: 'biometric_prompt_unlock'.tr,
      );

      expect(result.success, isTrue);
      expect(controller.isLocked.value, isFalse);
    });

    test('authenticateWithBiometrics boolean API succeeds', () async {
      final success = await controller.authenticateWithBiometrics(
        localizedReason: 'biometric_prompt_unlock'.tr,
      );

      expect(success, isTrue);
      expect(controller.isLocked.value, isFalse);
    });

    test('Lock and Unlock state cycle works cleanly', () async {
      await controller.setPin('1234');
      controller.lock();
      expect(controller.isLocked.value, isTrue);

      final unlocked = controller.verifyPin('1234');
      expect(unlocked, isTrue);
      expect(controller.isLocked.value, isFalse);

      await controller.disablePin();
    });
  });
}
