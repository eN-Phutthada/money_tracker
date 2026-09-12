import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/krungthai_slip_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/transactions/views/krungthai_slip_sheet.dart';
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
  });

  tearDown(() {
    AppFeedback.dismiss();
    Get.reset();
  });

  group('Krungthai Slip UI & Modal Tests', () {
    testWidgets('1. KrungthaiSlipScanModal renders all options and Mode A/B toggle', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: const Scaffold(
            body: KrungthaiSlipScanModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and branding
      expect(find.text('อ่านสลิปกรุงไทย'), findsOneWidget);
      expect(find.text('รองรับสลิป Krungthai NEXT และเป๋าตัง'), findsOneWidget);

      // Check all 3 real scan methods (Sample demo removed)
      expect(find.text('เลือกจากคลังภาพ'), findsOneWidget);
      expect(find.text('ถ่ายภาพสลิป'), findsOneWidget);
      expect(find.text('วางข้อความสลิป'), findsOneWidget);
      expect(find.text('ทดสอบด้วยสลิปตัวอย่าง (Sample Demo)'), findsNothing);

      // Check Mode A/B toggle switch
      expect(find.text('โหมด A: ตรวจสอบก่อนบันทึก'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Toggle switch to Mode B
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(find.text('โหมด B: บันทึกทันทีอัตโนมัติ'), findsOneWidget);
    });

    testWidgets('2. KrungthaiSlipSheet renders extracted slip data in Mode A for confirmation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));

      final slip = KrungthaiSlipData(
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
            body: KrungthaiSlipSheet(slip: slip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check extracted fields
      expect(find.text('Krungthai NEXT Verified'), findsOneWidget);
      expect(find.text('ยอดเงินโอนสำเร็จ'), findsOneWidget);
      expect(find.text('฿350.00'), findsOneWidget);
      expect(find.text('ร้านก๋วยเตี๋ยวเรือป้าเล็ก'), findsWidgets);
      expect(find.text('202609110006992211'), findsOneWidget);

      // Check save button
      final saveBtn = find.text('บันทึกรายการโอนเงิน');
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

    testWidgets('3. KrungthaiSlipSheet displays duplicate warning banner when duplicate transaction exists', (tester) async {
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

      final slip = KrungthaiSlipData(
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
            body: KrungthaiSlipSheet(slip: slip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check duplicate warning banner
      expect(find.text('สลิปนี้อาจเคยถูกบันทึกไปแล้ว'), findsOneWidget);
      expect(find.text('ตรวจพบซ้ำ'), findsOneWidget);
      expect(find.textContaining('ร้านก๋วยเตี๋ยวเรือป้าเล็ก'), findsWidgets);
    });

    testWidgets('4. KrungthaiSlipScanModal.showScanErrorDialog renders warning dialog on non-slip image', (tester) async {
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
                  onPressed: () => KrungthaiSlipScanModal.showScanErrorDialog(ctx),
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
      expect(find.text('ไม่พบข้อมูลสลิปโอนเงิน'), findsOneWidget);
      expect(find.textContaining('รูปภาพที่เลือกไม่ใช่ภาพสลิป'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('ยกเลิก'), findsOneWidget);
      expect(find.text('วางข้อความ'), findsOneWidget);
    });
  });
}
