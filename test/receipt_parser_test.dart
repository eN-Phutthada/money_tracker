import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/data/services/bank_slip_parser.dart';

void main() {
  group('7-Eleven Receipt Parsing - Net Total (ยอดสุทธิ)', () {
    test('Case 1: 7-Eleven with ALL Member discount and VAT note extracts net total (89.00)', () {
      const rawText = '''
7-ELEVEN
บมจ. ซีพี ออลล์
สาขา 01234 อโศกมนตรี
ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ
วันที่ 13/09/2569 12:45:30
R# 12345/6789 T#02

1 ข้าวกะเพราไก่ไข่ดาว 47.00
1 ชาเขียวโออิชิ 20.00
1 แซนวิชอบร้อน 32.00

รวม 3 รายการ
รวมเป็นเงิน 99.00
ส่วนลด ALL member -10.00
ยอดสุทธิ 89.00
เงินสด 100.00
เงินทอน 11.00
V=VAT 7% รวมในยอดสุทธิ 5.82

ALL member
คะแนนที่ได้รับ 10
คะแนนสะสมสุทธิ 1250
''';
      final result = BankSlipParser.parse(rawText);
      expect(result.amount, 89.00);
      expect(result.bankName, '7-Eleven');
      expect(result.memo, contains('ข้าวกะเพราไก่ไข่ดาว'));
    });

    test('Case 2: 7-Eleven with no discount extracts net total (40.00)', () {
      const rawText = '''
7-ELEVEN
สาขา 09876
TAX INV (ABB)
1 ไส้กรอก 30.00
1 น้ำดื่ม 10.00
รวมเป็นเงิน 40.00
ยอดสุทธิ 40.00
เงินสด 50.00
เงินทอน 10.00
ภาษีมูลค่าเพิ่ม รวมในยอดสุทธิ 2.62
''';
      final result = BankSlipParser.parse(rawText);
      expect(result.amount, 40.00);
      expect(result.bankName, '7-Eleven');
    });

    test('Case 3: 7-Eleven with multiline label and amount extracts net total (60.00)', () {
      const rawText = '''
7-Eleven สาขา พระราม 9
TAX INV (ABB)
1 ขนมปัง 25.00
1 นมสด 35.00
รวมเป็นเงิน 60.00
ยอดสุทธิ
60.00
เงินสด 100.00
เงินทอน 40.00
(V) รวมในยอดสุทธิ 3.93
''';
      final result = BankSlipParser.parse(rawText);
      expect(result.amount, 60.00);
      expect(result.bankName, '7-Eleven');
    });

    test('Case 4: 7-Eleven paid by TrueMoney Wallet extracts net total (50.00)', () {
      const rawText = '''
7-ELEVEN สาขา สาทร
1 ข้าวกล่อง 55.00
รวมเป็นเงิน 55.00
ส่วนลด -5.00
ยอดสุทธิ 50.00
TrueMoney Wallet 50.00
VAT 7% รวมในยอดสุทธิ 3.27
''';
      final result = BankSlipParser.parse(rawText);
      expect(result.amount, 50.00);
      expect(result.bankName, '7-Eleven');
    });

    test('Case 5: 7-Eleven with blurred ยอดสุทธิ deduced from Cash - Change (75.00)', () {
      const rawText = '''
7-ELEVEN
บมจ. ซีพี ออลล์
1 ขนมปัง 40.00
1 น้ำผลไม้ 35.00
เงินสด 100.00
เงินทอน 25.00
VAT 7% รวมในยอดสุทธิ 4.91
''';
      final result = BankSlipParser.parse(rawText);
      expect(result.amount, 75.00);
      expect(result.bankName, '7-Eleven');
    });

    test('Case 6: 7-Eleven with blurred ยอดสุทธิ deduced from Subtotal - Discount (85.00)', () {
      const rawText = '''
7-ELEVEN สาขา ลาดพร้าว
รวมเป็นเงิน 100.00
ส่วนลดคูปอง 15.00
''';
      final result = BankSlipParser.parse(rawText);
      expect(result.amount, 85.00);
      expect(result.bankName, '7-Eleven');
    });

    test('Case 7: Standard Krungthai bank slip parsing remains 100% accurate', () {
      const rawText = '''
Krungthai NEXT
โอนเงินสำเร็จ
12 ก.ย. 2569 14:30
จำนวนเงิน 500.00 บาท
ค่าธรรมเนียม 0.00 บาท
จาก นาย สมชาย
ไปยัง นาย สมศักดิ์
รหัสอ้างอิง: 20260912123456
''';
      final result = BankSlipParser.parse(rawText);
      expect(result.amount, 500.00);
      expect(result.isKrungthai, isTrue);
    });
  });
}
