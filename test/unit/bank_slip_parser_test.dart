import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/bank_slip_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/data/services/bank_qr_decoder.dart';
import 'package:money_tracker/app/data/services/bank_slip_parser.dart';
import 'package:money_tracker/app/data/services/bank_slip_service.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('BankSlipParser Unit Tests', () {
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

      final slip = BankSlipParser.parse(rawText);

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

      final slip = BankSlipParser.parse(rawText);
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

      final slip = BankSlipParser.parse(rawText);
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

      final slip = BankSlipParser.parse(rawText);
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
      final utilSlip = BankSlipParser.parse('''
ธ.กรุงไทย
จำนวนเงิน 850.50 บาท
ไปยัง การไฟฟ้านครหลวง
บันทึกช่วยจำ ค่าไฟ
''');
      expect(utilSlip.suggestedCategory, equals('สาธารณูปโภค'));
      expect(utilSlip.suggestedCostNature, equals(CostNature.fixed));

      // Transport
      final transportSlip = BankSlipParser.parse('''
กรุงไทย
จำนวนเงิน 65.00 บาท
ไปยัง รถไฟฟ้า BTS
''');
      expect(transportSlip.suggestedCategory, equals('การเดินทาง'));
      expect(transportSlip.suggestedCostNature, equals(CostNature.variable));

      // Health
      final healthSlip = BankSlipParser.parse('''
KTB NEXT
จำนวนเงิน 1,500.00 บาท
ไปยัง โรงพยาบาลกรุงเทพ
บันทึก ค่ายา
''');
      expect(healthSlip.suggestedCategory, equals('สุขภาพ/ยา'));

      // Education
      final eduSlip = BankSlipParser.parse('''
ธนาคารกรุงไทย
จำนวนเงิน 2,000.00 บาท
บันทึกช่วยจำ ค่าเรียนพิเศษภาษาอังกฤษ
''');
      expect(eduSlip.suggestedCategory, equals('การศึกษา'));

      // Savings
      final savingsSlip = BankSlipParser.parse('''
กรุงไทย NEXT
จำนวนเงิน 5,000.00 บาท
บันทึกช่วยจำ ออมเงินกองทุนรวม
''');
      expect(savingsSlip.suggestedCategory, equals('เงินออม/DCA'));
      expect(savingsSlip.suggestedType, equals(TransactionType.savingsInvestment));
    });

    test('6. Converts BankSlipData to TransactionItem correctly', () {
      final slip = BankSlipData(
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
      final slip = BankSlipData(
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

      expect(BankSlipParser.isDuplicate(slip, existingTransactions), isTrue);

      final nonMatchingSlip = BankSlipData(
        bankName: 'ธนาคารกรุงไทย',
        amount: 250.0,
        transactionDate: DateTime(2026, 9, 12, 10, 0),
        referenceNo: 'KTB111222',
        rawText: '...',
        isKrungthai: true,
      );

      expect(BankSlipParser.isDuplicate(nonMatchingSlip, existingTransactions), isFalse);
    });

    test('8. BankSlipService sample slips contain valid data', () {
      final service = BankSlipService();
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

    test('9. BankSlipService supports toggling between Mode A and Mode B', () async {
      final service = BankSlipService();
      expect(service.isInstantAutoSave.value, isFalse); // Default Mode A (Preview & Confirm)

      await service.toggleAutoSave(true);
      expect(service.isInstantAutoSave.value, isTrue); // Switched to Mode B (Instant Auto-Save)

      await service.toggleAutoSave(false);
      expect(service.isInstantAutoSave.value, isFalse); // Restored to Mode A
    });

    test('10. BankSlipService.saveSlipTransaction saves to DashboardController', () {
      Get.reset();
      final controller = Get.put(DashboardController());

      final service = BankSlipService();
      final slip = BankSlipData(
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
      final slip = BankSlipData(
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

      expect(BankSlipParser.isDuplicate(slip, existingTxList), isTrue);
      final matched = BankSlipParser.findDuplicateTransaction(slip, existingTxList);
      expect(matched, isNotNull);
      expect(matched!.title, equals('ร้านก๋วยเตี๋ยวเรือ'));
    });

    test('12. Does not flag distinct transaction as duplicate', () {
      final slip = BankSlipData(
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

      expect(BankSlipParser.isDuplicate(slip, existingTxList), isFalse);
      expect(BankSlipParser.findDuplicateTransaction(slip, existingTxList), isNull);
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

      final slip = BankSlipParser.parse(userSlipText);

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
      final slip = BankQrDecoder.parsePromptPaySlipQr(qrText);

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
      final slip1 = BankSlipParser.parse(columnarText);
      expect(slip1.amount, equals(139.00));

      // Nikhahit Thai variant (U+0E4D + U+0E32)
      const nikhahitText = 'จ\u0E4D\u0E32นวนเงิน 139.00 บาท\nค่าธรรมเนียม 0.00 บาท';
      final slip2 = BankSlipParser.parse(nikhahitText);
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
      final slip = BankSlipParser.parse(latinOcrText);
      expect(slip.amount, equals(139.00));
    });

    test('17. Allows custom amount override when saving slip transaction', () {
      final slip = BankSlipData(
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
      final service = BankSlipService();
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

      final slip = BankSlipParser.parse(screenshotText);
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
      final slip1 = BankSlipParser.parse(textWithDot);
      expect(slip1.hasParsedDateTime, isTrue);
      expect(slip1.transactionDate.year, equals(2026));
      expect(slip1.transactionDate.month, equals(8));
      expect(slip1.transactionDate.day, equals(2));
      expect(slip1.transactionDate.hour, equals(22));
      expect(slip1.transactionDate.minute, equals(2));

      // 2. Multi-line date and time
      const textMultiLine = 'วันที่ทำรายการ\n02 ส.ค. 2569\nเวลา 22:02 น.';
      final slip2 = BankSlipParser.parse(textMultiLine);
      expect(slip2.hasParsedDateTime, isTrue);
      expect(slip2.transactionDate.hour, equals(22));
      expect(slip2.transactionDate.minute, equals(2));

      // 3. English month with second
      const textEnglish = 'Transaction Successful\n02 Aug 2026 22:02:15';
      final slip3 = BankSlipParser.parse(textEnglish);
      expect(slip3.hasParsedDateTime, isTrue);
      expect(slip3.transactionDate.hour, equals(22));
      expect(slip3.transactionDate.minute, equals(2));
      expect(slip3.transactionDate.second, equals(15));

      // 4. Numeric Buddhist era format
      const textNumeric = '02/08/2569 22:02';
      final slip4 = BankSlipParser.parse(textNumeric);
      expect(slip4.hasParsedDateTime, isTrue);
      expect(slip4.transactionDate.year, equals(2026));
      expect(slip4.transactionDate.month, equals(8));
      expect(slip4.transactionDate.day, equals(2));
      expect(slip4.transactionDate.hour, equals(22));
      expect(slip4.transactionDate.minute, equals(2));
    });

    test('20. Extracts time with "น." on separate line without "เวลา" prefix', () {
      const text = '''
ธนาคารกรุงไทย
โอนเงินสำเร็จ
วันที่ทำรายการ 12 ก.ย. 2569
15.45 น.
รหัสอ้างอิง 202609120006999999
จำนวนเงิน 500.00 บาท
''';
      final slip = BankSlipParser.parse(text);
      expect(slip.hasParsedDateTime, isTrue);
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(9));
      expect(slip.transactionDate.day, equals(12));
      expect(slip.transactionDate.hour, equals(15));
      expect(slip.transactionDate.minute, equals(45));
    });

    test('21. Does NOT mistake currency or fee amounts for transaction time', () {
      const text = '''
ธนาคารกรุงไทย
โอนเงินสำเร็จ
วันที่ 12 ก.ย. 2569
จำนวนเงิน 10.50 บาท
ค่าธรรมเนียม 0.00 บาท
รหัสอ้างอิง 202609120006112233
''';
      final slip = BankSlipParser.parse(text);
      expect(slip.hasParsedDateTime, isTrue);
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(9));
      expect(slip.transactionDate.day, equals(12));
      // 10.50 บาท และ 0.00 บาท ต้องไม่ถูกตีความเป็นเวลา 10:50 หรือ 00:00
      expect(slip.transactionDate.hour, equals(0));
      expect(slip.transactionDate.minute, equals(0));
    });

    test('22. Extracts date from reference number when date line OCR is missing', () {
      const text = '''
Krungthai NEXT
โอนเงินสำเร็จ
14:30 น.
รหัสอ้างอิง: 202609150006123456
จำนวนเงิน 250.00 บาท
''';
      final slip = BankSlipParser.parse(text);
      expect(slip.hasParsedDateTime, isTrue);
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(9));
      expect(slip.transactionDate.day, equals(15));
      expect(slip.transactionDate.hour, equals(14));
      expect(slip.transactionDate.minute, equals(30));
      expect(slip.referenceNo, equals('202609150006123456'));
    });

    test('23. BankSlipService.resolveAccurateDateTime fusions date and time correctly', () {
      final fileModTime = DateTime(2026, 9, 12, 16, 45, 20);

      // กรณี OCR มีเฉพาะวันที่ (เวลา 00:00) แต่มีไฟล์ภาพ -> ผสานวันจาก OCR และเวลาจากไฟล์ภาพ
      final ocrDateOnly = BankSlipData(
        amount: 300.0,
        transactionDate: DateTime(2026, 9, 10, 0, 0, 0),
        hasParsedDateTime: true,
      );
      final fused1 = BankSlipService.resolveAccurateDateTime(
        ocrSlip: ocrDateOnly,
        fileModTime: fileModTime,
      );
      expect(fused1.year, equals(2026));
      expect(fused1.month, equals(9));
      expect(fused1.day, equals(10)); // จาก OCR
      expect(fused1.hour, equals(16)); // จากไฟล์ภาพ
      expect(fused1.minute, equals(45)); // จากไฟล์ภาพ

      // กรณี QR มีเวลาสมบูรณ์ -> ใช้เวลาจาก QR
      final qrWithTime = BankSlipData(
        amount: 300.0,
        transactionDate: DateTime(2026, 9, 10, 11, 25, 0),
        hasParsedDateTime: true,
      );
      final fused2 = BankSlipService.resolveAccurateDateTime(
        ocrSlip: ocrDateOnly,
        qrSlip: qrWithTime,
        fileModTime: fileModTime,
      );
      expect(fused2.day, equals(10));
      expect(fused2.hour, equals(11)); // จาก QR
      expect(fused2.minute, equals(25));
    });

    test('24. Detects bank name for all major Thai banks, falling back to Krungthai NEXT as primary', () {
      expect(
        BankSlipParser.detectBankName('K PLUS ธนาคารกสิกรไทย โอนเงินสำเร็จ'),
        equals('ธนาคารกสิกรไทย (K PLUS)'),
      );
      expect(
        BankSlipParser.detectBankName('SCB EASY ธนาคารไทยพาณิชย์ จำกัด (มหาชน)'),
        equals('ธนาคารไทยพาณิชย์ (SCB EASY)'),
      );
      expect(
        BankSlipParser.detectBankName('Bangkok Bank ธนาคารกรุงเทพ โอนเงินเรียบร้อย'),
        equals('ธนาคารกรุงเทพ (Bualuang mBanking)'),
      );
      expect(
        BankSlipParser.detectBankName('KMA ธนาคารกรุงศรีอยุธยา krungsri'),
        equals('ธนาคารกรุงศรีอยุธยา (KMA)'),
      );
      expect(
        BankSlipParser.detectBankName('ttb touch ธนาคารทหารไทยธนชาต'),
        equals('ทีเอ็มบีธนชาต (ttb touch)'),
      );
      expect(
        BankSlipParser.detectBankName('MyMo ธนาคารออมสิน โอนเงินสำเร็จ'),
        equals('ธนาคารออมสิน (MyMo)'),
      );
      expect(
        BankSlipParser.detectBankName('BAAC A-Mobile ธ.ก.ส.'),
        equals('ธ.ก.ส. (BAAC Mobile)'),
      );
      expect(
        BankSlipParser.detectBankName('ทรูมันนี่ TrueMoney โอนเงินสำเร็จ'),
        equals('ทรูมันนี่ (TrueMoney Wallet)'),
      );

      // กรุงไทยและเป๋าตังยังคงเป็นหลัก
      expect(
        BankSlipParser.detectBankName('Krungthai NEXT โอนเงินสำเร็จ'),
        equals('ธนาคารกรุงไทย (Krungthai NEXT)'),
      );
      expect(
        BankSlipParser.detectBankName('เป๋าตัง G-Wallet โอนเงิน'),
        equals('ธนาคารกรุงไทย (เป๋าตัง)'),
      );

      // กรณีไม่ระบุธนาคาร -> ตั้งต้นเป็นกรุงไทยเป็นหลัก
      expect(
        BankSlipParser.detectBankName('โอนเงินสำเร็จ จำนวน 500 บาท วันที่ 12 ก.ย.'),
        equals('ธนาคารกรุงไทย (Krungthai NEXT)'),
      );

      // isKrungthaiSlip vs isValidBankSlip
      expect(BankSlipParser.isKrungthaiSlip('K PLUS โอนเงิน'), isFalse);
      expect(BankSlipParser.isValidBankSlip('K PLUS โอนเงินสำเร็จ'), isTrue);
      expect(BankSlipParser.isKrungthaiSlip('Krungthai NEXT โอนเงิน'), isTrue);
      expect(BankSlipParser.isValidBankSlip('Krungthai NEXT โอนเงิน'), isTrue);
    });

    test('25. Parses Kasikornbank (K PLUS) and SCB EASY slip OCR accurately', () {
      const kplusText = '''
K PLUS
โอนเงินสำเร็จ
12 ก.ย. 2569 15:45:00 น.
รหัสอ้างอิง: 014255123456789
จาก: นาย สมชาย มีสุข
ธ.กสิกรไทย xxx-x-xx888-x
ไปยัง: ร้านกาแฟ อเมซอน
พร้อมเพย์ 081-xxx-1234
จำนวนเงิน: 65.00 บาท
ค่าธรรมเนียม: 0.00 บาท
บันทึกช่วยจำ: ชาเขียวปั่น
''';

      final slip = BankSlipParser.parse(kplusText);
      expect(slip.bankName, equals('ธนาคารกสิกรไทย (K PLUS)'));
      expect(slip.isKrungthai, isFalse);
      expect(slip.amount, equals(65.0));
      expect(slip.senderName, equals('นาย สมชาย มีสุข'));
      expect(slip.receiverName, equals('ร้านกาแฟ อเมซอน'));
      expect(slip.referenceNo, equals('014255123456789'));
      expect(slip.memo, equals('ชาเขียวปั่น'));
      expect(slip.defaultTitle, equals('ชาเขียวปั่น'));
    });

    test('26. Decodes QR codes from various Thai banks using BOT codes', () {
      // PromptPay QR Tag 000201 พร้อม Sending Bank Tag 004 (KBank)
      const kbankQr = '00020101021229360016A00000067701011101120041234567895406150.005802TH5303764';
      final kbankSlip = BankQrDecoder.decodeSlipQr(kbankQr);
      expect(kbankSlip, isNotNull);
      expect(kbankSlip!.bankName, equals('ธนาคารกสิกรไทย (K PLUS)'));
      expect(kbankSlip.isKrungthai, isFalse);
      expect(kbankSlip.amount, equals(150.0));

      // Sending Bank Tag 014 (SCB)
      const scbQr = '00020101021229360016A000000677010111011201498765432154071250.005802TH5303764';
      final scbSlip = BankQrDecoder.decodeSlipQr(scbQr);
      expect(scbSlip, isNotNull);
      expect(scbSlip!.bankName, equals('ธนาคารไทยพาณิชย์ (SCB EASY)'));
      expect(scbSlip.isKrungthai, isFalse);
      expect(scbSlip.amount, equals(1250.0));

      // Sending Bank Tag 006 (Krungthai)
      const ktbQr = '00020101021229360016A00000067701011101120061122334455406500.005802TH5303764';
      final ktbSlip = BankQrDecoder.decodeSlipQr(ktbQr);
      expect(ktbSlip, isNotNull);
      expect(ktbSlip!.bankName, equals('ธนาคารกรุงไทย (Krungthai NEXT)'));
      expect(ktbSlip.isKrungthai, isTrue);
      expect(ktbSlip.amount, equals(500.0));
    });

    test('27. BankSlipData.toTransactionItem prefixes ID and formats note dynamically', () {
      final ktbSlip = BankSlipData(
        bankName: 'ธนาคารกรุงไทย (Krungthai NEXT)',
        amount: 250.0,
        transactionDate: DateTime(2026, 9, 12, 10, 0),
        referenceNo: 'KTB12345',
        rawText: '...',
        isKrungthai: true,
      );
      final ktbTx = ktbSlip.toTransactionItem();
      expect(ktbTx.id, startsWith('ktb_'));
      expect(ktbTx.title, equals('รายการโอนเงิน'));
      expect(ktbTx.note, contains('สลิป: ธนาคารกรุงไทย (Krungthai NEXT)'));

      final scbSlip = BankSlipData(
        bankName: 'ธนาคารไทยพาณิชย์ (SCB EASY)',
        amount: 300.0,
        transactionDate: DateTime(2026, 9, 12, 11, 0),
        referenceNo: 'SCB999',
        rawText: '...',
        isKrungthai: false,
      );
      final scbTx = scbSlip.toTransactionItem();
      expect(scbTx.id, startsWith('slip_'));
      expect(scbTx.title, equals('รายการโอนเงิน'));
      expect(scbTx.note, contains('สลิป: ธนาคารไทยพาณิชย์ (SCB EASY)'));
    });

    test('28. Parses exact date and time from user real slip format (02 ส.ค. 2569 - 22:02)', () {
      const realSlipText = '''
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

      final slip = BankSlipParser.parse(realSlipText);
      expect(slip.amount, equals(139.0));
      expect(slip.hasParsedDateTime, isTrue);
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(8));
      expect(slip.transactionDate.day, equals(2));
      expect(slip.transactionDate.hour, equals(22));
      expect(slip.transactionDate.minute, equals(2));
      expect(slip.referenceNo, equals('A308e920c27594e4c'));
      expect(slip.receiverName, equals('บจก. เอ็นเอฟ สตรีมมิ่ง'));
      expect(slip.defaultTitle, equals('โอนให้ บจก. เอ็นเอฟ สตรีมมิ่ง'));
      expect(slip.defaultTitle, isNot(contains('โอนเงินกรุงไทย')));
    });

    test('29. resolveAccurateDateTime preserves slip date/time and does not overwrite with upload cache timestamp', () {
      final slipDate = DateTime(2026, 8, 2, 22, 2);
      final ocrSlip = BankSlipData(
        amount: 139.0,
        transactionDate: slipDate,
        hasParsedDateTime: true,
      );

      // สมมติไฟล์ภาพถูกแคชโดย image_picker ณ เวลาปัจจุบัน
      final uploadTimeNow = DateTime.now();

      final resolvedDate = BankSlipService.resolveAccurateDateTime(
        ocrSlip: ocrSlip,
        fileModTime: uploadTimeNow,
      );

      // วันและเวลาต้องตรงกับสลิปจริง (2026-08-02 22:02:00) ไม่ใช่ uploadTimeNow
      expect(resolvedDate.year, equals(2026));
      expect(resolvedDate.month, equals(8));
      expect(resolvedDate.day, equals(2));
      expect(resolvedDate.hour, equals(22));
      expect(resolvedDate.minute, equals(2));
    });

    test('30. Extracts amount with bracketed currency units (บาท / THB)', () {
      const textWithBracketThai = '''
ธนาคารกรุงไทย
โอนเงินสำเร็จ
จำนวนเงิน (บาท) 139.00
ค่าธรรมเนียม (บาท) 0.00
ไปยัง: นาย สมพงษ์ ใจดี
''';
      final slip1 = BankSlipParser.parse(textWithBracketThai);
      expect(slip1.amount, equals(139.0));

      const textWithBracketEng = '''
K PLUS
Transfer Successful
Amount (THB) : 1,500.50
Fee (THB) : 0.00
To: Central Department Store
''';
      final slip2 = BankSlipParser.parse(textWithBracketEng);
      expect(slip2.amount, equals(1500.50));
    });

    test('31. Skips bank name and channel between "ไปยัง" and actual receiver name', () {
      const slipWithBankLine = '''
SCB EASY
โอนเงินสำเร็จ
12 ก.ย. 2569 10:20 น.
จาก: นาย ทดสอบ ระบบ
ไปยัง:
ธนาคารกสิกรไทย
นาย สมชาย มีสุข
xxx-x-xx888-x
จำนวนเงิน 450.00 บาท
''';
      final slip = BankSlipParser.parse(slipWithBankLine);
      expect(slip.receiverName, equals('นาย สมชาย มีสุข'));
      expect(slip.defaultTitle, equals('โอนให้ นาย สมชาย มีสุข'));

      const slipWithPromptPay = '''
Krungthai NEXT
ไปยัง
พร้อมเพย์
089-xxx-1234
ร้านส้มตำแซ่บหลาย
จำนวนเงิน 280.00 บาท
''';
      final slip2 = BankSlipParser.parse(slipWithPromptPay);
      expect(slip2.receiverName, equals('ร้านส้มตำแซ่บหลาย'));
    });

    test('32. Normalizes OCR spaced decimals (139 . 00 -> 139.00)', () {
      const spacedText = '''
Krungthai NEXT
โอนเงินสำเร็จ
จำนวนเงิน 139 . 00 บาท
ไปยัง: ร้านหนังสือซีเอ็ด
''';
      final slip = BankSlipParser.parse(spacedText);
      expect(slip.amount, equals(139.0));
      expect(slip.suggestedCategory, equals('การศึกษา'));
    });

    test('33. Detects income transfer slip and classifies salary / side income', () {
      const incomeSalaryText = '''
ธนาคารกรุงไทย
เงินโอนเข้าสำเร็จ
01 ก.ย. 2569 05:30 น.
จาก: บจก. เทคโนโลยีล้ำหน้า
ไปยัง: นาย ธนากร มั่งคั่ง
จำนวนเงิน: 45,000.00 บาท
บันทึก: เงินเดือนประจำเดือนสิงหาคม
''';
      final slip1 = BankSlipParser.parse(incomeSalaryText);
      expect(slip1.suggestedType, equals(TransactionType.income));
      expect(slip1.suggestedCategory, equals('เงินเดือน'));
      expect(slip1.defaultTitle, equals('เงินเดือนประจำเดือนสิงหาคม'));
      expect(slip1.formattedNote, contains('ผู้โอน: บจก. เทคโนโลยีล้ำหน้า'));

      const incomeSideJobText = '''
K PLUS
เงินเข้า
จาก: ร้านเจ๊ดาว
จำนวนเงิน 1,200.00 บาท
บันทึกช่วยจำ: ค่าแรงสอนพิเศษ
''';
      final slip2 = BankSlipParser.parse(incomeSideJobText);
      expect(slip2.suggestedType, equals(TransactionType.income));
    });

    test('34. Detects expanded Thai banks (KKP, UOB, CIMB, TISCO, LH Bank, ShopeePay)', () {
      expect(BankSlipParser.detectBankName('ธนาคารเกียรตินาคินภัทร KKP Dime โอนเงินสำเร็จ'), equals('ธนาคารเกียรตินาคินภัทร (KKP)'));
      expect(BankSlipParser.detectBankName('UOB TMRW โอนเงินสำเร็จ'), equals('ธนาคารยูโอบี (UOB TMRW)'));
      expect(BankSlipParser.detectBankName('ธนาคารซีไอเอ็มบี ไทย CIMB Transfer'), equals('ธนาคารซีไอเอ็มบี ไทย'));
      expect(BankSlipParser.detectBankName('TISCO Bank โอนเงินสำเร็จ'), equals('ธนาคารทิสโก้'));
      expect(BankSlipParser.detectBankName('ธนาคารแลนด์ แอนด์ เฮ้าส์ LHB You'), equals('ธนาคารแลนด์ แอนด์ เฮ้าส์ (LHB You)'));
      expect(BankSlipParser.detectBankName('ShopeePay ช้อปปี้เพย์ วอลเล็ท'), equals('ช้อปปี้เพย์ (ShopeePay)'));
    });

    test('35. QR Category Prediction passes receiverName and leverages History Learning', () {
      const clinicName = 'คลินิกทันตกรรมยิ้มสวย';
      final lenStr = clinicName.length < 10 ? '0${clinicName.length}' : '${clinicName.length}';
      final qrWithMerchant = '00020101021229360016A00000067701011101120141234567895406800.005802TH59$lenStr$clinicName';

      final slip = BankQrDecoder.decodeSlipQr(qrWithMerchant);
      expect(slip, isNotNull);
      expect(slip!.receiverName, equals(clinicName));
      expect(slip.suggestedCategory, equals('สุขภาพ/ยา'));
    });
  });
}



