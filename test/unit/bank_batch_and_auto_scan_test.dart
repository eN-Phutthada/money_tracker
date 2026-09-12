import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/bank_slip_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/data/services/bank_slip_service.dart';
import 'package:money_tracker/app/data/services/storage_service.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/dashboard/widgets/smart_auto_scan_slips_banner.dart';
import 'package:money_tracker/app/modules/transactions/views/bank_batch_slip_sheet.dart';
import 'package:money_tracker/app/theme/app_theme.dart';
import 'package:money_tracker/app/translations/app_translations.dart';
import 'package:money_tracker/app/widgets/app_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
  });

  tearDown(() {
    AppFeedback.dismiss();
    Get.reset();
  });

  group('StorageService Slip Folder Settings Tests', () {
    test('Can save and load slip folder auto-scan preference', () async {
      final storage = StorageService();

      await storage.saveSlipFolderAutoScanPref(true);
      expect(await storage.loadSlipFolderAutoScanPref(), isTrue);

      await storage.saveSlipFolderAutoScanPref(false);
      expect(await storage.loadSlipFolderAutoScanPref(), isFalse);
    });

    test('Can save and load slip target folder path and name', () async {
      final storage = StorageService();

      await storage.saveSlipTargetFolder(
        '/storage/emulated/0/DCIM/Screenshots',
        'Screenshots',
      );

      final loaded = await storage.loadSlipTargetFolder();
      expect(loaded, isNotNull);
      expect(loaded?['path'], '/storage/emulated/0/DCIM/Screenshots');
      expect(loaded?['name'], 'Screenshots');
    });

    test('Can save and load last scanned timestamp', () async {
      final storage = StorageService();

      final now = DateTime(2026, 9, 12, 14, 0);
      await storage.saveSlipLastScannedTime(now);

      final loaded = await storage.loadSlipLastScannedTime();
      expect(loaded, isNotNull);
      expect(loaded?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });
  });

  group('BankSlipService Batch & Folder Logic Tests', () {
    test('BankBatchResult computes counts correctly', () {
      final slip1 = BankSlipData(
        bankName: 'Krungthai NEXT',
        amount: 250.0,
        transactionDate: DateTime(2026, 9, 12, 10, 0),
        senderName: 'ผู้โอน 1',
        receiverName: 'ผู้รับ 1',
        referenceNo: 'REF001',
        suggestedCategory: 'อาหาร/ของกิน',
        suggestedCostNature: CostNature.variable,
        suggestedType: TransactionType.expense,
        rawText: '...',
        isKrungthai: true,
      );

      final slip2 = BankSlipData(
        bankName: 'Krungthai NEXT',
        amount: 500.0,
        transactionDate: DateTime(2026, 9, 12, 11, 0),
        senderName: 'ผู้โอน 2',
        receiverName: 'ผู้รับ 2',
        referenceNo: 'REF002',
        suggestedCategory: 'ช้อปปิ้ง',
        suggestedCostNature: CostNature.variable,
        suggestedType: TransactionType.expense,
        rawText: '...',
        isKrungthai: true,
      );

      final result = BankBatchResult(
        validSlips: [slip1, slip2],
        duplicateSlips: [
          {'referenceNo': 'REF000', 'reason': 'เคยบันทึกไปแล้ว'}
        ],
        invalidCount: 1,
        totalCount: 3,
      );

      expect(result.validSlips.length, 2);
      expect(result.validCount, 2);
      expect(result.duplicateSlips.length, 1);
      expect(result.duplicateCount, 1);
      expect(result.invalidCount, 1);
      expect(result.totalCount, 3);
    });

    test('SlipService updates target folder and auto-scan toggle reactively', () async {
      final service = BankSlipService();
      await service.init();

      await service.toggleFolderAutoScan(true);
      expect(service.isFolderAutoScanEnabled.value, isTrue);

      await service.setTargetFolder(
        path: '/sdcard/Download',
        name: 'เป๋าตัง (Paotang)',
      );

      expect(service.targetFolderPath.value, '/sdcard/Download');
      expect(service.targetFolderName.value, 'เป๋าตัง (Paotang)');
    });
  });

  group('BankBatchSlipSheet Widget Tests', () {
    testWidgets('Renders batch slip sheet with items, totals, and exclusion toggling', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      Get.put(DashboardController());

      final slipA = BankSlipData(
        bankName: 'Krungthai NEXT',
        amount: 320.0,
        transactionDate: DateTime(2026, 9, 12, 12, 15),
        senderName: 'ผู้โอน A',
        receiverName: 'ร้านป้าสมใจ ข้าวแกง',
        referenceNo: 'BATCH001',
        memo: 'อาหารเที่ยง',
        suggestedCategory: 'อาหาร/ของกิน',
        suggestedCostNature: CostNature.variable,
        suggestedType: TransactionType.expense,
        rawText: '...',
        isKrungthai: true,
      );

      final slipB = BankSlipData(
        bankName: 'Krungthai NEXT',
        amount: 680.0,
        transactionDate: DateTime(2026, 9, 12, 12, 30),
        senderName: 'ผู้โอน A',
        receiverName: 'ห้างสรรพสินค้า',
        referenceNo: 'BATCH002',
        memo: 'ของใช้ในบ้าน',
        suggestedCategory: 'ของใช้ในบ้าน',
        suggestedCostNature: CostNature.variable,
        suggestedType: TransactionType.expense,
        rawText: '...',
        isKrungthai: true,
      );

      final slipDuplicate = BankSlipData(
        bankName: 'Krungthai NEXT',
        amount: 100.0,
        transactionDate: DateTime(2026, 9, 12, 11, 0),
        senderName: 'ผู้โอน A',
        receiverName: 'ร้านค้าที่ซ้ำ',
        referenceNo: 'DUP999',
        memo: 'รายการซ้ำ',
        suggestedCategory: 'อื่นๆ',
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
            body: BankBatchSlipSheet(
              initialSlips: [slipA, slipB],
              duplicateSlips: [
                {'slip': slipDuplicate, 'reason': 'เคยบันทึกไปแล้ว'}
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header title and count badge
      expect(find.text('ตรวจสอบสลิปแบบกลุ่ม'), findsOneWidget);
      expect(find.text('3 รายการ'), findsOneWidget);
      expect(find.text('ตรวจพบซ้ำ'), findsOneWidget);

      // Check slip cards content
      expect(find.text('ร้านป้าสมใจ ข้าวแกง'), findsOneWidget);
      expect(find.text('ห้างสรรพสินค้า'), findsOneWidget);
      expect(find.text('฿320.00'), findsOneWidget);
      expect(find.text('฿680.00'), findsOneWidget);

      // Check bottom total summary (320 + 680 = 1,000.00)
      expect(find.text('฿1,000.00'), findsOneWidget);
      expect(find.text('บันทึกที่เลือก (2)'), findsOneWidget);

      // Tap to deselect first slip (checkbox)
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsNWidgets(3));
      await tester.tap(checkboxFinder.first);
      await tester.pumpAndSettle();

      // Total should update to 680.00 (present both in card and total summary) and button to 1 item
      expect(find.text('฿680.00'), findsNWidgets(2));
      expect(find.text('บันทึกที่เลือก (1)'), findsOneWidget);
    });
  });

  group('SmartAutoScanSlipsBanner Widget Tests', () {
    testWidgets('Renders smart banner when slips are detected and handles action taps', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final controller = Get.put(DashboardController());

      final detectedSlips = [
        BankSlipData(
          bankName: 'Krungthai NEXT',
          amount: 150.0,
          transactionDate: DateTime(2026, 9, 12, 8, 30),
          senderName: 'ผู้โอน',
          receiverName: 'ร้านกาแฟโบราณ',
          referenceNo: 'AUTO001',
          suggestedCategory: 'อาหาร/ของกิน',
          suggestedCostNature: CostNature.variable,
          suggestedType: TransactionType.expense,
          rawText: '...',
          isKrungthai: true,
        ),
        BankSlipData(
          bankName: 'Krungthai NEXT',
          amount: 450.0,
          transactionDate: DateTime(2026, 9, 12, 9, 0),
          senderName: 'ผู้โอน',
          receiverName: 'ปั๊มน้ำมัน ปตท.',
          referenceNo: 'AUTO002',
          suggestedCategory: 'เดินทาง/น้ำมัน',
          suggestedCostNature: CostNature.variable,
          suggestedType: TransactionType.expense,
          rawText: '...',
          isKrungthai: true,
        ),
      ];

      controller.detectedFolderSlips.assignAll(detectedSlips);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('th', 'TH'),
          translations: AppTranslations(),
          home: const Scaffold(
            body: SmartAutoScanSlipsBanner(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check banner header and amounts
      expect(find.text('ตรวจพบสลิปใหม่'), findsOneWidget);
      expect(find.text('2 รายการ'), findsOneWidget);
      expect(find.textContaining('รวม ฿600.00'), findsOneWidget);

      // Check action buttons
      expect(find.text('บันทึกทั้งหมด (2)'), findsOneWidget);
      expect(find.text('ตรวจสอบ'), findsOneWidget);

      // Tap Dismiss button
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Detected slips should now be cleared
      expect(controller.detectedFolderSlips.isEmpty, isTrue);
    });
  });
}
