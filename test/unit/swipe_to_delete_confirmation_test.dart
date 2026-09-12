import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/dashboard/widgets/recent_transactions_card.dart';
import 'package:money_tracker/app/modules/transactions/views/transactions_list_view.dart';
import 'package:money_tracker/app/theme/app_popup_decorations.dart';
import 'package:money_tracker/app/theme/app_theme.dart';
import 'package:money_tracker/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DashboardController controller;

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
    controller = Get.put(DashboardController());
  });

  tearDown(() {
    AppFeedback.dismiss();
    Get.reset();
  });

  group('Swipe-to-Delete with Instant Undo Tests', () {
    testWidgets('1. Swiping left in TransactionsListView deletes directly and allows 1-tap Undo restoration', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      final testItem = TransactionItem(
        id: 'tx-swipe-1',
        title: 'ชานมไข่มุก',
        amount: 55.0,
        date: DateTime(2026, 9, 12, 10, 0),
        type: TransactionType.expense,
        categoryName: 'กาแฟ/เครื่องดื่ม',
      );
      controller.transactions.assignAll([testItem]);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: const Scaffold(
            body: TransactionsListView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ชานมไข่มุก'), findsOneWidget);

      // Swipe left on the transaction
      final itemFinder = find.text('ชานมไข่มุก');
      await tester.drag(itemFinder, const Offset(-500, 0));
      // Dismissible slide-off animation (300ms)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // AppFeedback notification HUD entrance spring animation (380ms)
      await tester.pump(const Duration(milliseconds: 500));

      // Transaction is deleted directly without blocking dialog
      expect(controller.transactions.isEmpty, isTrue);

      // Notification HUD appears with Undo button
      expect(find.text('เลิกทำ'), findsOneWidget);
      expect(find.text('ลบรายการเรียบร้อย'), findsOneWidget);

      // Tap Undo button to restore
      await tester.tap(find.text('เลิกทำ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Transaction is immediately restored!
      expect(controller.transactions.length, equals(1));
      expect(controller.transactions.first.id, equals('tx-swipe-1'));
    });

    testWidgets('2. Swiping left in RecentTransactionsCard deletes directly and allows 1-tap Undo restoration', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      final testItem = TransactionItem(
        id: 'tx-swipe-2',
        title: 'บัตรรถไฟฟ้า BTS',
        amount: 40.0,
        date: DateTime(2026, 9, 12, 10, 30),
        type: TransactionType.expense,
        categoryName: 'การเดินทาง',
      );
      controller.transactions.assignAll([testItem]);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: RecentTransactionsCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('บัตรรถไฟฟ้า BTS'), findsOneWidget);

      // Swipe left on the transaction
      final itemFinder = find.text('บัตรรถไฟฟ้า BTS');
      await tester.drag(itemFinder, const Offset(-500, 0));
      // Dismissible slide-off animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // AppFeedback notification HUD entrance
      await tester.pump(const Duration(milliseconds: 500));

      // Transaction is deleted
      expect(controller.transactions.isEmpty, isTrue);

      // Undo button is shown in notification HUD
      expect(find.text('เลิกทำ'), findsOneWidget);
      expect(find.text('ลบรายการเรียบร้อย'), findsOneWidget);

      // Tap Undo button to restore
      await tester.tap(find.text('เลิกทำ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Transaction is restored!
      expect(controller.transactions.length, equals(1));
      expect(controller.transactions.first.id, equals('tx-swipe-2'));
    });
  });
}
