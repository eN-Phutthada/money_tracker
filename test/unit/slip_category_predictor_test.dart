import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/data/models/krungthai_slip_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/data/services/slip_category_predictor.dart';
import 'package:money_tracker/app/data/services/krungthai_slip_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlipCategoryPredictor — Multi-Signal Scoring Tests', () {
    test('Predicts food & beverage from keywords', () {
      final pred = SlipCategoryPredictor.predict(
        memo: 'ข้าวผัดกะเพราหมูกรอบ',
        receiverName: 'ร้านป้าศรี',
        fullText: 'จำนวนเงิน 65.00 บาท',
        amount: 65.0,
        transactionDate: DateTime(2026, 9, 12, 12, 30),
      );

      expect(pred.category, equals('อาหาร/ของกิน'));
      expect(pred.type, equals(TransactionType.expense));
      expect(pred.costNature, equals(CostNature.variable));
      expect(pred.confidence, greaterThanOrEqualTo(0.60));
      expect(pred.reason, isNotEmpty);
    });

    test('Predicts coffee & drinks from keywords', () {
      final pred = SlipCategoryPredictor.predict(
        memo: 'Iced Latte',
        receiverName: 'Starbucks Coffee',
        fullText: 'จำนวนเงิน 165.00 บาท starbucks amazon กาแฟ',
        amount: 165.0,
        transactionDate: DateTime(2026, 9, 12, 9, 0),
      );

      expect(pred.category, equals('กาแฟ/เครื่องดื่ม'));
      expect(pred.type, equals(TransactionType.expense));
      expect(pred.costNature, equals(CostNature.variable));
      expect(pred.confidence, greaterThanOrEqualTo(0.70));
    });

    test('Predicts transportation from keywords', () {
      final pred = SlipCategoryPredictor.predict(
        memo: 'BTS หมอชิต',
        receiverName: 'BTS Siam Station',
        fullText: 'เติมเงิน bts sky train',
        amount: 300.0,
        transactionDate: DateTime(2026, 9, 12, 8, 15),
      );

      expect(pred.category, equals('การเดินทาง'));
      expect(pred.type, equals(TransactionType.expense));
      expect(pred.costNature, equals(CostNature.variable));
    });

    test('Predicts housing fixed cost from keywords', () {
      final pred = SlipCategoryPredictor.predict(
        memo: 'ค่าห้องเดือนกันยายน',
        receiverName: 'นิติบุคคล คอนโด กรีนวิว',
        fullText: 'ค่าเช่าห้องและค่าส่วนกลาง',
        amount: 8500.0,
        transactionDate: DateTime(2026, 9, 1, 10, 0),
      );

      expect(pred.category, equals('ที่อยู่อาศัย'));
      expect(pred.type, equals(TransactionType.expense));
      expect(pred.costNature, equals(CostNature.fixed));
      expect(pred.confidence, greaterThanOrEqualTo(0.70));
    });

    test('Predicts utilities fixed cost from keywords', () {
      final pred = SlipCategoryPredictor.predict(
        memo: 'บิลค่าไฟ MEA',
        receiverName: 'การไฟฟ้านครหลวง',
        fullText: 'การไฟฟ้านครหลวง ค่าไฟประจำเดือน',
        amount: 1450.0,
        transactionDate: DateTime(2026, 9, 5, 14, 0),
      );

      expect(pred.category, equals('สาธารณูปโภค'));
      expect(pred.type, equals(TransactionType.expense));
      expect(pred.costNature, equals(CostNature.fixed));
    });

    test('Predicts healthcare from keywords', () {
      final pred = SlipCategoryPredictor.predict(
        memo: 'ค่ายาแก้แพ้',
        receiverName: 'ร้านขายยาฟาร์มาซี',
        fullText: 'ใบเสร็จ คลินิก ทันตกรรม',
        amount: 450.0,
        transactionDate: DateTime(2026, 9, 12, 17, 0),
      );

      expect(pred.category, equals('สุขภาพ/ยา'));
      expect(pred.type, equals(TransactionType.expense));
      expect(pred.costNature, equals(CostNature.variable));
    });

    test('Predicts savings & investments as savingsInvestment type', () {
      final pred = SlipCategoryPredictor.predict(
        memo: 'DCA กองทุนรวม',
        receiverName: 'บลจ. กรุงไทย KTAM',
        fullText: 'dca หุ้น กองทุนรวม savings invest',
        amount: 5000.0,
        transactionDate: DateTime(2026, 9, 1, 9, 30),
      );

      expect(pred.category, equals('เงินออม/DCA'));
      expect(pred.type, equals(TransactionType.savingsInvestment));
      expect(pred.costNature, equals(CostNature.notApplicable));
      expect(pred.confidence, greaterThanOrEqualTo(0.70));
    });

    test('Predicts entertainment/streaming services', () {
      final pred = SlipCategoryPredictor.predict(
        memo: 'Netflix Family Plan',
        receiverName: 'Netflix Inc',
        fullText: 'netflix subscription ค่าบริการสตรีมมิ่ง',
        amount: 419.0,
        transactionDate: DateTime(2026, 9, 10, 20, 0),
      );

      expect(pred.category, equals('บันเทิง/พักผ่อน'));
      expect(pred.type, equals(TransactionType.expense));
      expect(pred.costNature, equals(CostNature.variable));
    });

    test('Falls back to sensible defaults for unknown receiver without hints', () {
      final pred = SlipCategoryPredictor.predict(
        memo: '',
        receiverName: 'นาย สมเกียรติ พรประเสริฐ',
        fullText: 'โอนเงินสำเร็จ รหัสอ้างอิง 999111',
        amount: 120.0,
        transactionDate: DateTime(2026, 9, 12, 15, 0),
      );

      expect(pred.confidence, lessThan(0.70));
      expect(pred.reason, isNotEmpty);
    });
  });

  group('SlipCategoryPredictor — History Learning Tests', () {
    test('Learns category from user past transactions to the same receiver', () {
      final history = [
        TransactionItem(
          id: 't1',
          title: 'โอนให้ ป้าพร',
          amount: 50.0,
          type: TransactionType.expense,
          categoryName: 'อาหาร/ของกิน',
          date: DateTime(2026, 9, 10),
          note: 'ผู้รับ: ป้าพร ส้มตำแซ่บ | สลิป: กรุงไทย',
        ),
        TransactionItem(
          id: 't2',
          title: 'โอนให้ ป้าพร',
          amount: 80.0,
          type: TransactionType.expense,
          categoryName: 'อาหาร/ของกิน',
          date: DateTime(2026, 9, 11),
          note: 'ผู้รับ: ป้าพร ส้มตำแซ่บ | สลิป: กรุงไทย',
        ),
        TransactionItem(
          id: 't3',
          title: 'โอนให้ ป้าพร',
          amount: 100.0,
          type: TransactionType.expense,
          categoryName: 'อาหาร/ของกิน',
          date: DateTime(2026, 9, 11),
          note: 'ผู้รับ: ป้าพร ส้มตำแซ่บ | สลิป: กรุงไทย',
        ),
      ];

      final pred = SlipCategoryPredictor.predict(
        memo: '',
        receiverName: 'ป้าพร ส้มตำแซ่บ',
        fullText: 'โอนเงินสำเร็จ ป้าพร ส้มตำแซ่บ 90.00 บาท',
        amount: 90.0,
        transactionDate: DateTime(2026, 9, 12, 14, 0),
        history: history,
      );

      expect(pred.category, equals('อาหาร/ของกิน'));
      expect(pred.confidence, greaterThanOrEqualTo(0.70));
      expect(pred.reason, contains('3'));
    });

    test('Prioritizes history over ambiguous keyword matches', () {
      // Receiver was previously categorized as "ช้อปปิ้ง" by user
      final history = [
        TransactionItem(
          id: 't1',
          title: 'โอนให้ คุณนัท',
          amount: 500.0,
          type: TransactionType.expense,
          categoryName: 'ช้อปปิ้ง',
          date: DateTime(2026, 9, 5),
          note: 'ผู้รับ: คุณนัท ของสะสม',
        ),
        TransactionItem(
          id: 't2',
          title: 'โอนให้ คุณนัท',
          amount: 750.0,
          type: TransactionType.expense,
          categoryName: 'ช้อปปิ้ง',
          date: DateTime(2026, 9, 7),
          note: 'ผู้รับ: คุณนัท ของสะสม',
        ),
      ];

      final pred = SlipCategoryPredictor.predict(
        receiverName: 'คุณนัท ของสะสม',
        fullText: 'โอนเงินสำเร็จ',
        amount: 600.0,
        transactionDate: DateTime(2026, 9, 12, 16, 0),
        history: history,
      );

      expect(pred.category, equals('ช้อปปิ้ง'));
      expect(pred.reason, contains('ประวัติ'));
    });
  });

  group('KrungthaiSlipData Model & Parser Integration Tests', () {
    test('KrungthaiSlipData toJson and fromJson preserves prediction fields', () {
      final original = KrungthaiSlipData(
        amount: 250.0,
        transactionDate: DateTime(2026, 9, 12, 11, 0),
        receiverName: 'ร้านส้มตำ',
        suggestedCategory: 'อาหาร/ของกิน',
        suggestedType: TransactionType.expense,
        suggestedCostNature: CostNature.variable,
        predictionConfidence: 0.85,
        predictionReason: 'คีย์เวิร์ด: ส้มตำ',
      );

      final json = original.toJson();
      expect(json['predictionConfidence'], equals(0.85));
      expect(json['predictionReason'], equals('คีย์เวิร์ด: ส้มตำ'));

      final restored = KrungthaiSlipData.fromJson(json);
      expect(restored.predictionConfidence, equals(0.85));
      expect(restored.predictionReason, equals('คีย์เวิร์ด: ส้มตำ'));
      expect(restored.suggestedCategory, equals('อาหาร/ของกิน'));
    });

    test('KrungthaiSlipData copyWith allows updating prediction attributes', () {
      final original = KrungthaiSlipData(
        amount: 100.0,
        transactionDate: DateTime(2026, 9, 12),
        predictionConfidence: 0.5,
        predictionReason: 'ค่าเริ่มต้น',
      );

      final updated = original.copyWith(
        suggestedCategory: 'การเดินทาง',
        predictionConfidence: 0.9,
        predictionReason: 'ประวัติ 5 รายการก่อนหน้า',
      );

      expect(updated.suggestedCategory, equals('การเดินทาง'));
      expect(updated.predictionConfidence, equals(0.9));
      expect(updated.predictionReason, equals('ประวัติ 5 รายการก่อนหน้า'));
      expect(updated.amount, equals(100.0));
    });

    test('KrungthaiSlipParser.parse populates prediction confidence and reason', () {
      const text = '''
ธนาคารกรุงไทย Krungthai NEXT
โอนเงินสำเร็จ
12 ก.ย. 2569 13:00 น.
ไปยัง: ร้านกาแฟอเมซอน ปตท
จำนวนเงิน: 85.00 บาท
รหัสอ้างอิง: 202609120006123456
บันทึก: ชาเขียวนมสด
''';

      final slip = KrungthaiSlipParser.parse(text);
      expect(slip.suggestedCategory, equals('กาแฟ/เครื่องดื่ม'));
      expect(slip.predictionConfidence, greaterThan(0.50));
      expect(slip.predictionReason, isNotEmpty);
    });
  });
}
