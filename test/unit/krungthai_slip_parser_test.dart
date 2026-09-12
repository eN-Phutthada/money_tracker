import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/krungthai_slip_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/data/services/krungthai_qr_decoder.dart';
import 'package:money_tracker/app/data/services/krungthai_slip_parser.dart';
import 'package:money_tracker/app/data/services/krungthai_slip_service.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('KrungthaiSlipParser Unit Tests', () {
    test('1. Parses Thai Krungthai NEXT slip accurately', () {
      const rawText = '''
ธนาคารกรุงไทย
Krungthai NEXT
โอนเงินสำเร็จ
11 ก.ย. 2569 12:35:10 น.
รหัสอ้างอิง: 202609110006992211

จาก: นาย ธนากร มั่งคั่ง
ธ.กรุงไทย xxx-x-xx123-x

ไปยัง: ร้านก๋วยเตี๋ยวเรือป้าเล็ก
พร้อมเพย์ 089-xxx-4567

จำนวนเงิน: 350.00 บาท
ค่าธรรมเนียม: 0.00 บาท

บันทึกช่วยจำ: ค่าอาหารกลางวันทีม
''';

      final slip = KrungthaiSlipParser.parse(rawText);

      expect(slip.isKrungthai, isTrue);
      expect(slip.bankName, equals('ธนาคารกรุงไทย (Krungthai NEXT)'));
      expect(slip.amount, equals(350.00));
      expect(slip.senderName, contains('ธนากร มั่งคั่ง'));
      expect(slip.receiverName, contains('ร้านก๋วยเตี๋ยวเรือป้าเล็ก'));
      expect(slip.referenceNo, equals('202609110006992211'));
      expect(slip.memo, equals('ค่าอาหารกลางวันทีม'));
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(9));
      expect(slip.transactionDate.day, equals(11));
      expect(slip.transactionDate.hour, equals(12));
      expect(slip.transactionDate.minute, equals(35));
      expect(slip.suggestedCategory, equals('อาหาร/ของกิน'));
      expect(slip.suggestedCostNature, equals(CostNature.variable));
    });

    test('2. Converts Buddhist Year 2569 to Gregorian Year 2026', () {
      const rawText = '''
Krungthai
05 ม.ค. 2569 08:30 น.
จำนวนเงิน: 120.00 บาท
ไปยัง: กาแฟพันธุ์ไทย
''';

      final slip = KrungthaiSlipParser.parse(rawText);
      expect(slip.amount, equals(120.00));
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(1));
      expect(slip.transactionDate.day, equals(5));
      expect(slip.suggestedCategory, equals('กาแฟ/เครื่องดื่ม'));
    });

    test('3. Parses Thai เป๋าตัง slip with Fixed Cost Housing', () {
      const rawText = '''
ธนาคารกรุงไทย
เป๋าตัง Pay
โอนเงินสำเร็จ
01 ก.ย. 2569 09:15:00 น.
เลขที่รายการ 202609010006778899

จาก
นาย ธนากร มั่งคั่ง
ธ.กรุงไทย xxx-x-xx123-x

ไปยัง
นิติบุคคล อาคารชุดสุขสบาย
ธ.กรุงไทย xxx-x-xx888-x

จำนวนเงิน
4,500.00 บาท
ค่าธรรมเนียม 0.00 บาท

บันทึกช่วยจำ
ค่าห้อง 502 เดือนกันยายน
''';

      final slip = KrungthaiSlipParser.parse(rawText);
      expect(slip.isKrungthai, isTrue);
      expect(slip.amount, equals(4500.00));
      expect(slip.receiverName, contains('นิติบุคคล อาคารชุดสุขสบาย'));
      expect(slip.referenceNo, equals('202609010006778899'));
      expect(slip.suggestedCategory, equals('ที่อยู่อาศัย'));
      expect(slip.suggestedCostNature, equals(CostNature.fixed));
    });

    test('4. Parses English Krungthai slip with shopping classification', () {
      const rawText = '''
Krungthai NEXT
Transfer Successful
10 Sep 2026 18:42
Transaction ID: 202609100006334455

From: Mr. Thanakorn M.
To: ShopeePay Thailand
Amount: 1,290.00 THB
Fee: 0.00 THB
Memo: หูฟังบลูทูธไร้สาย
''';

      final slip = KrungthaiSlipParser.parse(rawText);
      expect(slip.isKrungthai, isTrue);
      expect(slip.amount, equals(1290.00));
      expect(slip.receiverName, equals('ShopeePay Thailand'));
      expect(slip.referenceNo, equals('202609100006334455'));
      expect(slip.memo, equals('หูฟังบลูทูธไร้สาย'));
      expect(slip.suggestedCategory, equals('ช้อปปิ้ง'));
      expect(slip.suggestedCostNature, equals(CostNature.variable));
    });

    test('5. Correctly classifies various categories from keywords', () {
      // Utilities
      final utilSlip = KrungthaiSlipParser.parse('''
ธ.กรุงไทย
จำนวนเงิน 850.50 บาท
ไปยัง การไฟฟ้านครหลวง
บันทึกช่วยจำ ค่าไฟ
''');
      expect(utilSlip.suggestedCategory, equals('สาธารณูปโภค'));
      expect(utilSlip.suggestedCostNature, equals(CostNature.fixed));

      // Transport
      final transportSlip = KrungthaiSlipParser.parse('''
กรุงไทย
จำนวนเงิน 65.00 บาท
ไปยัง รถไฟฟ้า BTS
''');
      expect(transportSlip.suggestedCategory, equals('การเดินทาง'));
      expect(transportSlip.suggestedCostNature, equals(CostNature.variable));

      // Health
      final healthSlip = KrungthaiSlipParser.parse('''
KTB NEXT
จำนวนเงิน 1,500.00 บาท
ไปยัง โรงพยาบาลกรุงเทพ
บันทึก ค่ายา
''');
      expect(healthSlip.suggestedCategory, equals('สุขภาพ/ยา'));

      // Education
      final eduSlip = KrungthaiSlipParser.parse('''
ธนาคารกรุงไทย
จำนวนเงิน 2,000.00 บาท
บันทึกช่วยจำ ค่าเรียนพิเศษภาษาอังกฤษ
''');
      expect(eduSlip.suggestedCategory, equals('การศึกษา'));

      // Savings
      final savingsSlip = KrungthaiSlipParser.parse('''
กรุงไทย NEXT
จำนวนเงิน 5,000.00 บาท
บันทึกช่วยจำ ออมเงินกองทุนรวม
''');
      expect(savingsSlip.suggestedCategory, equals('เงินออม/DCA'));
      expect(savingsSlip.suggestedType, equals(TransactionType.savingsInvestment));
    });

    test('6. Converts KrungthaiSlipData to TransactionItem correctly', () {
      final slip = KrungthaiSlipData(
        bankName: 'ธนาคารกรุงไทย',
        amount: 350.0,
        transactionDate: DateTime(2026, 9, 11, 12, 35),
        senderName: 'ผู้โอน',
        receiverName: 'ร้านป้าเล็ก',
        referenceNo: 'KTB2026091101',
        memo: 'ก๋วยเตี๋ยว',
        suggestedCategory: 'อาหาร/ของกิน',
        suggestedCostNature: CostNature.variable,
        suggestedType: TransactionType.expense,
        rawText: '...',
        isKrungthai: true,
      );

      final item = slip.toTransactionItem();
      expect(item.amount, equals(350.0));
      expect(item.title, equals('ก๋วยเตี๋ยว'));
      expect(item.categoryName, equals('อาหาร/ของกิน'));
      expect(item.type, equals(TransactionType.expense));
      expect(item.costNature, equals(CostNature.variable));
      expect(item.note, contains('KTB2026091101'));
      expect(item.note, contains('ก๋วยเตี๋ยว'));

      // Custom override
      final customItem = slip.toTransactionItem(
        customTitle: 'มื้อเที่ยงทีมงาน',
        customCategory: 'บันเทิง/พักผ่อน',
        customCostNature: CostNature.fixed,
      );
      expect(customItem.title, equals('มื้อเที่ยงทีมงาน'));
      expect(customItem.categoryName, equals('บันเทิง/พักผ่อน'));
      expect(customItem.costNature, equals(CostNature.fixed));
    });

    test('7. Detects duplicate slip based on reference number or date+amount', () {
      final slip = KrungthaiSlipData(
        bankName: 'ธนาคารกรุงไทย',
        amount: 500.0,
        transactionDate: DateTime(2026, 9, 11, 14, 0),
        referenceNo: 'KTB999888',
        rawText: '...',
        isKrungthai: true,
      );

      final existingTransactions = [
        TransactionItem(
          id: 'tx-1',
          title: 'รายการอื่น',
          amount: 500.0,
          date: DateTime(2026, 9, 11, 14, 0),
          categoryName: 'อาหาร/ของกิน',
          type: TransactionType.expense,
          note: 'สลิปอ้างอิง: KTB999888',
        ),
      ];

      expect(KrungthaiSlipParser.isDuplicate(slip, existingTransactions), isTrue);

      final nonMatchingSlip = KrungthaiSlipData(
        bankName: 'ธนาคารกรุงไทย',
        amount: 250.0,
        transactionDate: DateTime(2026, 9, 12, 10, 0),
        referenceNo: 'KTB111222',
        rawText: '...',
        isKrungthai: true,
      );

      expect(KrungthaiSlipParser.isDuplicate(nonMatchingSlip, existingTransactions), isFalse);
    });

    test('8. KrungthaiSlipService sample slips contain valid data', () {
      final service = KrungthaiSlipService();
      final samples = service.getSampleKrungthaiSlips();

      expect(samples.length, equals(4));
      for (final s in samples) {
        expect(s['title'], isNotEmpty);
        expect(s['rawText'], isNotEmpty);

        final parsed = service.parseSlipText(s['rawText'] as String);
        expect(parsed.isKrungthai, isTrue);
        expect(parsed.amount, greaterThan(0));
        expect(parsed.transactionDate.year, equals(2026));
      }
    });

    test('9. KrungthaiSlipService supports toggling between Mode A and Mode B', () async {
      final service = KrungthaiSlipService();
      expect(service.isInstantAutoSave.value, isFalse); // Default Mode A (Preview & Confirm)

      await service.toggleAutoSave(true);
      expect(service.isInstantAutoSave.value, isTrue); // Switched to Mode B (Instant Auto-Save)

      await service.toggleAutoSave(false);
      expect(service.isInstantAutoSave.value, isFalse); // Restored to Mode A
    });

    test('10. KrungthaiSlipService.saveSlipTransaction saves to DashboardController', () {
      Get.reset();
      final controller = Get.put(DashboardController());

      final service = KrungthaiSlipService();
      final slip = KrungthaiSlipData(
        amount: 888.0,
        transactionDate: DateTime(2026, 9, 11, 15, 30),
        receiverName: 'ร้านค้าไอที',
        referenceNo: '202609110006777',
        memo: 'ซื้อสายชาร์จ',
        suggestedCategory: 'ช้อปปิ้ง',
        suggestedCostNature: CostNature.variable,
        rawText: '...',
        isKrungthai: true,
      );

      final savedTx = service.saveSlipTransaction(slip, notify: false);

      expect(savedTx.amount, equals(888.0));
      expect(controller.transactions.any((t) => t.id == savedTx.id), isTrue);
      final found = controller.transactions.firstWhere((t) => t.id == savedTx.id);
      expect(found.amount, equals(888.0));
      expect(found.categoryName, equals('ช้อปปิ้ง'));
      expect(found.note, contains('202609110006777'));
    });

    test('11. Detects duplicate transaction by reference number and amount/time', () {
      final slip = KrungthaiSlipData(
        amount: 350.0,
        transactionDate: DateTime(2026, 9, 11, 12, 35),
        referenceNo: '202609110006992211',
        rawText: '...',
        isKrungthai: true,
      );

      final existingTxList = [
        TransactionItem(
          id: 'tx-1',
          title: 'ร้านก๋วยเตี๋ยวเรือ',
          amount: 350.0,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'อาหาร/ของกิน',
          date: DateTime(2026, 9, 11, 12, 36), // 1 minute difference
          note: 'โอนเงิน Krungthai NEXT [รหัสอ้างอิง: 202609110006992211]',
        ),
      ];

      expect(KrungthaiSlipParser.isDuplicate(slip, existingTxList), isTrue);
      final matched = KrungthaiSlipParser.findDuplicateTransaction(slip, existingTxList);
      expect(matched, isNotNull);
      expect(matched!.title, equals('ร้านก๋วยเตี๋ยวเรือ'));
    });

    test('12. Does not flag distinct transaction as duplicate', () {
      final slip = KrungthaiSlipData(
        amount: 500.0,
        transactionDate: DateTime(2026, 9, 12, 10, 0),
        referenceNo: '20260912999999',
        rawText: '...',
        isKrungthai: true,
      );

      final existingTxList = [
        TransactionItem(
          id: 'tx-1',
          title: 'ร้านก๋วยเตี๋ยวเรือ',
          amount: 350.0,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'อาหาร/ของกิน',
          date: DateTime(2026, 9, 11, 12, 36),
          note: 'โอนเงิน Krungthai NEXT',
        ),
      ];

      expect(KrungthaiSlipParser.isDuplicate(slip, existingTxList), isFalse);
      expect(KrungthaiSlipParser.findDuplicateTransaction(slip, existingTxList), isNull);
    });

    test('13. Accurately parses user real Krungthai NEXT streaming slip', () {
      const userSlipText = '''
Krungthai
กรุงไทย
โอนเงินสำเร็จ
รหัสอ้างอิง A308e920c27594e4c

จาก
นายพุทธดา ห * * *
กรุงไทย
XXX-X-XX167-8

ไปยัง
บจก. เอ็นเอฟ สตรีมมิ่ง
พร้อมเพย์
X XXXX XXXX6 48 2

จำนวนเงิน 139.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 02 ส.ค. 2569 - 22:02
''';

      final slip = KrungthaiSlipParser.parse(userSlipText);

      expect(slip.isKrungthai, isTrue);
      expect(slip.amount, equals(139.00));
      expect(slip.referenceNo, equals('A308e920c27594e4c'));
      expect(slip.senderName, equals('นายพุทธดา ห * * *'));
      expect(slip.senderAccount, equals('XXX-X-XX167-8'));
      expect(slip.receiverName, equals('บจก. เอ็นเอฟ สตรีมมิ่ง'));
      expect(slip.receiverAccount, equals('X XXXX XXXX6 48 2'));
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(8));
      expect(slip.transactionDate.day, equals(2));
      expect(slip.transactionDate.hour, equals(22));
      expect(slip.transactionDate.minute, equals(2));
      expect(slip.suggestedCategory, equals('บันเทิง/พักผ่อน'));
      expect(slip.suggestedCostNature, equals(CostNature.variable));
    });

    test('14. Parses BOT EMVCo QR code payload from Krungthai NEXT slip', () {
      const qrText = '0038000600000101030060217A308e920c27594e4c5102TH91045259';
      final slip = KrungthaiQrDecoder.parsePromptPaySlipQr(qrText);

      expect(slip, isNotNull);
      expect(slip!.isKrungthai, isTrue);
      expect(slip.referenceNo, equals('A308e920c27594e4c'));
      expect(slip.bankName, contains('Krungthai'));
    });

    test('15. Robustly extracts amount from columnar OCR layouts and Nikhahit Thai', () {
      // Columnar layout: labels on left, values on right
      const columnarText = '''
Krungthai NEXT
โอนเงินสำเร็จ
จำนวนเงิน
ค่าธรรมเนียม
วันที่ทำรายการ
139.00 บาท
0.00 บาท
02 ส.ค. 2569 - 22:02
''';
      final slip1 = KrungthaiSlipParser.parse(columnarText);
      expect(slip1.amount, equals(139.00));

      // Nikhahit Thai variant (U+0E4D + U+0E32)
      const nikhahitText = 'จ\u0E4D\u0E32นวนเงิน 139.00 บาท\nค่าธรรมเนียม 0.00 บาท';
      final slip2 = KrungthaiSlipParser.parse(nikhahitText);
      expect(slip2.amount, equals(139.00));
    });

    test('16. Robustly extracts amount when Latin OCR strips Thai words', () {
      const latinOcrText = '''
Krungthai
A308e920c27594e4c
XXX-X-XX167-8
X XXXX XXXX6 48 2
139.00
0.00
02 2569 - 22:02
''';
      final slip = KrungthaiSlipParser.parse(latinOcrText);
      expect(slip.amount, equals(139.00));
    });

    test('17. Allows custom amount override when saving slip transaction', () {
      final slip = KrungthaiSlipData(
        amount: 0.0,
        transactionDate: DateTime(2026, 8, 2, 22, 2),
        referenceNo: 'A308e920c27594e4c',
        receiverName: 'บจก. เอ็นเอฟ สตรีมมิ่ง',
        isKrungthai: true,
      );

      // toTransactionItem with customAmount
      final item = slip.toTransactionItem(customAmount: 139.00);
      expect(item.amount, equals(139.00));

      // saveSlipTransaction with customAmount
      Get.reset();
      final controller = Get.put(DashboardController());
      final service = KrungthaiSlipService();
      final saved = service.saveSlipTransaction(slip, customAmount: 139.00, notify: false);
      expect(saved.amount, equals(139.00));
      expect(controller.transactions.first.amount, equals(139.00));
    });

    test('18. Accurately extracts slip transaction time and ignores phone status bar clock', () {
      // Mobile screenshot with phone clock at line 0 (09:41)
      const screenshotText = '''
09:41
Krungthai
กรุงไทย
โอนเงินสำเร็จ
รหัสอ้างอิง A308e920c27594e4c

จาก
นายพุทธดา ห * * *
กรุงไทย
XXX-X-XX167-8

ไปยัง
บจก. เอ็นเอฟ สตรีมมิ่ง
พร้อมเพย์
X XXXX XXXX6 48 2

จำนวนเงิน 139.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 02 ส.ค. 2569 - 22:02
''';

      final slip = KrungthaiSlipParser.parse(screenshotText);
      expect(slip.hasParsedDateTime, isTrue);
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(8));
      expect(slip.transactionDate.day, equals(2));
      // Must NOT be 09:41 (the status bar), MUST be 22:02 (the slip's transaction time)
      expect(slip.transactionDate.hour, equals(22));
      expect(slip.transactionDate.minute, equals(2));
    });

    test('19. Extracts diverse real-world slip date and time formats', () {
      // 1. Thai with "เวลา" and dot format (22.02 น.)
      const textWithDot = 'โอนเงินสำเร็จ\n2 ส.ค. 69 เวลา 22.02 น.\nรหัสอ้างอิง A308';
      final slip1 = KrungthaiSlipParser.parse(textWithDot);
      expect(slip1.hasParsedDateTime, isTrue);
      expect(slip1.transactionDate.year, equals(2026));
      expect(slip1.transactionDate.month, equals(8));
      expect(slip1.transactionDate.day, equals(2));
      expect(slip1.transactionDate.hour, equals(22));
      expect(slip1.transactionDate.minute, equals(2));

      // 2. Multi-line date and time
      const textMultiLine = 'วันที่ทำรายการ\n02 ส.ค. 2569\nเวลา 22:02 น.';
      final slip2 = KrungthaiSlipParser.parse(textMultiLine);
      expect(slip2.hasParsedDateTime, isTrue);
      expect(slip2.transactionDate.hour, equals(22));
      expect(slip2.transactionDate.minute, equals(2));

      // 3. English month with second
      const textEnglish = 'Transaction Successful\n02 Aug 2026 22:02:15';
      final slip3 = KrungthaiSlipParser.parse(textEnglish);
      expect(slip3.hasParsedDateTime, isTrue);
      expect(slip3.transactionDate.hour, equals(22));
      expect(slip3.transactionDate.minute, equals(2));
      expect(slip3.transactionDate.second, equals(15));

      // 4. Numeric Buddhist era format
      const textNumeric = '02/08/2569 22:02';
      final slip4 = KrungthaiSlipParser.parse(textNumeric);
      expect(slip4.hasParsedDateTime, isTrue);
      expect(slip4.transactionDate.year, equals(2026));
      expect(slip4.transactionDate.month, equals(8));
      expect(slip4.transactionDate.day, equals(2));
      expect(slip4.transactionDate.hour, equals(22));
      expect(slip4.transactionDate.minute, equals(2));
    });
  });
}



