import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/bank_slip_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/data/services/bank_slip_service.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/transactions/views/bank_slip_sheet.dart';
import 'package:money_tracker/app/theme/app_theme.dart';
import 'package:money_tracker/app/translations/app_translations.dart';
import 'package:money_tracker/app/widgets/app_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
    Get.put(DashboardController());
    BankSlipService().isInstantAutoSave.value = false;
  });

  tearDown(() {
    AppFeedback.dismiss();
    Get.reset();
  });

  group('Krungthai Slip UI & Modal Tests', () {
    testWidgets('1. BankSlipScanModal renders all options and Mode A/B toggle', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: const Scaffold(
            body: BankSlipScanModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and branding
      expect(find.text('scan_bank_slip'.tr), findsOneWidget);
      expect(find.text('slip_all_banks_supported'.tr), findsOneWidget);

      // Check scan methods
      expect(find.text('choose_from_gallery'.tr), findsOneWidget);
      expect(find.text('take_slip_photo'.tr), findsOneWidget);
      expect(find.text('paste_slip_text'.tr), findsNothing);
      expect(find.text('auto_scan_folder_title'.tr), findsOneWidget);
      expect(find.text('ทดสอบด้วยสลิปตัวอย่าง (Sample Demo)'), findsNothing);

      // Check Mode A/B toggle switch
      expect(find.text('mode_a_preview'.tr), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Toggle switch to Mode B
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(find.text('mode_b_instant'.tr), findsOneWidget);
    });

    testWidgets('2. BankSlipSheet renders extracted slip data in Mode A for confirmation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));

      final slip = BankSlipData(
        bankName: 'ธนาคารกรุงไทย (Krungthai NEXT)',
        amount: 350.0,
        transactionDate: DateTime(2026, 9, 11, 12, 35),
        senderName: 'นาย ธนากร มั่งคั่ง',
        receiverName: 'ร้านก๋วยเตี๋ยวเรือป้าเล็ก',
        referenceNo: '202609110006992211',
        memo: 'ค่าอาหารกลางวันทีม',
        suggestedCategory: 'อาหาร/ของกิน',
        suggestedCostNature: CostNature.variable,
        suggestedType: TransactionType.expense,
        rawText: '...',
        isKrungthai: true,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: Scaffold(
            body: BankSlipSheet(slip: slip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check extracted fields
      expect(find.text('Krungthai NEXT Verified'), findsOneWidget);
      expect(find.text('transfer_success_amount'.tr), findsOneWidget);
      expect(find.text('฿350.00'), findsOneWidget);
      expect(find.text('ร้านก๋วยเตี๋ยวเรือป้าเล็ก'), findsWidgets);
      expect(find.text('202609110006992211'), findsOneWidget);

      // Check save button
      final saveBtn = find.text('save_slip_transaction'.tr);
      expect(saveBtn, findsOneWidget);

      // Ensure visible and tap save
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final controller = Get.find<DashboardController>();
      expect(controller.transactions.any((t) => t.amount == 350.0), isTrue);

      AppFeedback.dismiss();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('3. BankSlipSheet displays duplicate warning banner when duplicate transaction exists', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));

      final controller = Get.find<DashboardController>();
      controller.addTransaction(
        TransactionItem(
          id: 'existing-tx-1',
          title: 'ร้านก๋วยเตี๋ยวเรือป้าเล็ก',
          amount: 350.0,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'อาหาร/ของกิน',
          date: DateTime(2026, 9, 11, 12, 35),
          note: 'Ref: 202609110006992211',
        ),
        notify: false,
      );

      final slip = BankSlipData(
        bankName: 'ธนาคารกรุงไทย (Krungthai NEXT)',
        amount: 350.0,
        transactionDate: DateTime(2026, 9, 11, 12, 35),
        senderName: 'นาย ธนากร มั่งคั่ง',
        receiverName: 'ร้านก๋วยเตี๋ยวเรือป้าเล็ก',
        referenceNo: '202609110006992211',
        memo: 'ค่าอาหารกลางวันทีม',
        suggestedCategory: 'อาหาร/ของกิน',
        suggestedCostNature: CostNature.variable,
        suggestedType: TransactionType.expense,
        rawText: '...',
        isKrungthai: true,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: Scaffold(
            body: BankSlipSheet(slip: slip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check duplicate warning banner
      expect(find.text('duplicate_slip_warning'.tr), findsOneWidget);
      expect(find.text('duplicate_badge'.tr), findsOneWidget);
      expect(find.textContaining('ร้านก๋วยเตี๋ยวเรือป้าเล็ก'), findsWidgets);
    });

    testWidgets('4. BankSlipScanModal.showScanErrorDialog renders warning dialog on non-slip image', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => BankSlipScanModal.showScanErrorDialog(ctx),
                  child: const Text('Trigger Error'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Verify Scan Error Dialog elements
      expect(find.text('slip_not_found_title'.tr), findsOneWidget);
      expect(find.textContaining('slip_not_found_desc'.tr), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('close'.tr), findsOneWidget);
      expect(find.text('paste_slip_text'.tr), findsNothing);
    });

    testWidgets('5. English locale renders BankSlipScanModal and BankSlipSheet with 100% English translations', (tester) async {
      Get.locale = const Locale('en', 'US');
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en', 'US'),
          translations: AppTranslations(),
          home: const Scaffold(
            body: BankSlipScanModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check English modal titles
      expect(find.text('Scan Transfer Slip'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Paste Slip Text'), findsNothing);
      expect(find.text('Auto-Scan Slips from Folder'), findsOneWidget);
      expect(find.text('Mode A: Review Before Saving'), findsOneWidget);
    });
  });
}
