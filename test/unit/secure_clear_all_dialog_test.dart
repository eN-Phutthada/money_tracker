import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/data_management/views/data_management_view.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/theme/app_theme.dart';
import 'package:money_tracker/app/translations/app_translations.dart';
import 'package:money_tracker/app/widgets/app_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DashboardController dashboardController;

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
    dashboardController = Get.put(DashboardController());
  });

  tearDown(() {
    AppFeedback.dismiss();
    Get.reset();
  });

  group('SecureClearAllDialog Anti-Accidental Protection Tests', () {
    testWidgets('1. Confirm button remains locked until keyword and checkbox are completed', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      // Add a dummy transaction so count is 1
      dashboardController.transactions.assignAll([
        TransactionItem(
          id: 'tx-1',
          title: 'ข้าวกะเพรา',
          amount: 60.0,
          date: DateTime.now(),
          type: TransactionType.expense,
          categoryName: 'อาหาร/ของกิน',
        ),
      ]);

      bool onConfirmedCalled = false;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: Scaffold(
            body: SecureClearAllDialog(
              controller: dashboardController,
              onConfirmed: () async {
                onConfirmedCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and impact count
      expect(find.text('ยืนยันล้างข้อมูลธุรกรรมทั้งหมด?'), findsOneWidget);
      expect(find.text('จะลบประวัติธุรกรรมทั้งหมด 1 รายการ'), findsOneWidget);

      // Confirm button must initially be locked
      expect(find.text('ถูกล็อกไว้'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      // Attempting to tap the locked button must NOT call onConfirmed
      await tester.tap(find.text('ถูกล็อกไว้'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(onConfirmedCalled, isFalse);

      // Enter wrong keyword
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'สวัสดี');
      await tester.pumpAndSettle();
      expect(find.text('ถูกล็อกไว้'), findsOneWidget);

      // Enter correct keyword 'ล้างข้อมูล'
      await tester.enterText(textFields.first, 'ล้างข้อมูล');
      await tester.pumpAndSettle();

      // Still locked because checkbox is not checked yet!
      expect(find.text('ถูกล็อกไว้'), findsOneWidget);

      // Check the risk checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Now button must become unlocked!
      expect(find.text('ล้างเป็น 0'), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);

      // Tap confirm button
      final confirmBtn = find.text('ล้างเป็น 0');
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // onConfirmed must be called now
      expect(onConfirmedCalled, isTrue);
    });

    testWidgets('2. English locale requires "CLEAR" or "DELETE" keyword to unlock', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      Get.locale = const Locale('en', 'US');
      dashboardController.currentLanguage.value = 'en';

      bool onConfirmedCalled = false;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('en', 'US'),
          translations: AppTranslations(),
          home: Scaffold(
            body: SecureClearAllDialog(
              controller: dashboardController,
              onConfirmed: () async {
                onConfirmedCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clear All Transactions?'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);

      // Type CLEAR
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'CLEAR');
      await tester.pumpAndSettle();

      // Check the checkbox
      final checkboxFinder = find.byType(Checkbox);
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Now unlocked
      expect(find.text('Clear to 0'), findsOneWidget);
      final confirmBtn = find.text('Clear to 0');
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(onConfirmedCalled, isTrue);
    });

    testWidgets('3. When Security PIN is active, requires valid 4-digit PIN in addition to keyword and checkbox', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final sec = Get.put(SecurityController());
      await sec.setPin('1234');

      bool onConfirmedCalled = false;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: Scaffold(
            body: SecureClearAllDialog(
              controller: dashboardController,
              onConfirmed: () async {
                onConfirmedCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PIN section must be rendered
      expect(find.text('2. ใส่รหัส PIN 4 หลักของระบบความปลอดภัย:'), findsOneWidget);

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2)); // Keyword + PIN

      // Type keyword
      await tester.enterText(textFields.first, 'ล้างข้อมูล');
      await tester.pumpAndSettle();

      // Check checkbox
      final checkboxFinder = find.byType(Checkbox);
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Still locked because PIN is not entered yet!
      expect(find.text('ถูกล็อกไว้'), findsOneWidget);

      // Enter wrong PIN
      await tester.enterText(textFields.last, '9999');
      await tester.pumpAndSettle();
      expect(find.text('ถูกล็อกไว้'), findsOneWidget);

      // Enter correct PIN
      await tester.enterText(textFields.last, '1234');
      await tester.pumpAndSettle();

      // Now unlocked!
      expect(find.text('ล้างเป็น 0'), findsOneWidget);
      final confirmBtn = find.text('ล้างเป็น 0');
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(onConfirmedCalled, isTrue);

      await sec.disablePin();
    });
  });
}
