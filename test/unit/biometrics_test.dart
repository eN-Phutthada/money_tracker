import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/services/security_service.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/modules/security/views/pin_lock_view.dart';
import 'package:money_tracker/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
  });

  tearDown(() {
    Get.reset();
  });

  group('Real Biometrics Integration & Flow Tests', () {
    test('SecurityService checks biometrics support and executes authentication', () async {
      final service = SecurityService();
      final canCheck = await service.canCheckBiometrics();
      expect(canCheck, isTrue);

      final biometrics = await service.getAvailableBiometrics();
      expect(biometrics, isNotEmpty);

      final authenticated = await service.authenticateWithBiometrics();
      expect(authenticated, isTrue);
      expect(service.isLocked, isFalse);
    });

    test('SecurityController manages biometrics state and authentication', () async {
      final controller = Get.put<SecurityController>(SecurityController());
      await controller.setPin('5678');
      controller.lock();
      expect(controller.isLocked.value, isTrue);

      await controller.setBiometricsEnabled(true);
      expect(controller.isBiometricsEnabled.value, isTrue);

      final success = await controller.authenticateWithBiometrics();
      expect(success, isTrue);
      expect(controller.isLocked.value, isFalse);
    });

    testWidgets('PinLockView triggers biometrics and unlocks successfully', (WidgetTester tester) async {
      final controller = Get.put<SecurityController>(SecurityController());
      await controller.setPin('1234');
      await controller.setBiometricsEnabled(true);
      controller.lock();

      bool onUnlockedCalled = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('th', 'TH'),
          home: PinLockView(
            onUnlocked: () {
              onUnlockedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Biometrics button on keypad
      final bioBtn = find.byIcon(Icons.fingerprint_rounded);
      expect(bioBtn, findsOneWidget);

      // Tap the BIO button
      await tester.tap(bioBtn);
      await tester.pump(); // starts biometric verification
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isLocked.value, isFalse);
      expect(onUnlockedCalled, isTrue);
    });

    test('Detailed biometric availability and failure reason models work correctly', () async {
      final service = SecurityService();
      final availability = await service.checkBiometricAvailability();
      expect(availability.isAvailable, isTrue);
      expect(availability.status, BiometricAvailabilityStatus.available);

      final detailedResult = await service.authenticateWithBiometricsDetailed();
      expect(detailedResult.success, isTrue);
      expect(detailedResult.failureReason, isNull);

      final controller = Get.put<SecurityController>(SecurityController());
      await controller.checkBiometricAvailability();
      expect(controller.biometricAvailability.value?.isAvailable, isTrue);
      expect(controller.biometricStatusSubtitle, contains('ปลดล็อกอย่างรวดเร็ว'));
    });

    test('Biometric failure reason translation dictionary keys exist in th_TH and en_US', () {
      final th = AppTranslations().keys['th_TH']!;
      final en = AppTranslations().keys['en_US']!;

      expect(th['biometric_not_supported'], 'อุปกรณ์นี้ไม่รองรับการสแกนชีวมิติ');
      expect(th['biometric_not_enrolled'], contains('ยังไม่ได้ลงทะเบียน'));
      expect(th['biometric_locked_out'], contains('ถูกระงับชั่วคราว'));
      expect(th['biometric_permanently_locked_out'], contains('ถูกล็อกถาวร'));
      expect(th['biometric_failed'], contains('สแกนชีวมิติไม่ผ่าน'));
      expect(th['biometric_canceled'], 'ยกเลิกการยืนยันตัวตนด้วยชีวมิติ');

      expect(en['biometric_not_supported'], contains('not supported'));
      expect(en['biometric_not_enrolled'], contains('No biometrics enrolled'));
      expect(en['biometric_locked_out'], contains('Too many attempts'));
      expect(en['biometric_permanently_locked_out'], contains('permanently locked'));
      expect(en['biometric_failed'], contains('verification failed'));
      expect(en['biometric_canceled'], contains('canceled'));
    });
  });
}
