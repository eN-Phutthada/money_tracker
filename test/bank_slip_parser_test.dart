import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/services/bank_slip_parser.dart';
import 'package:money_tracker/app/translations/app_translations.dart';

void main() {
  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.updateLocale(const Locale('th', 'TH'));
  });

  test('Test 7-Eleven receipt parsing with 3 ชิ้น', () {
    const rawText = '''
สาขา 7-Eleven ศูนย์อาหาร มมส.
รหัสร้าน : 08116
---------------------------------
รายการสินค้า

1   Hอิชิตันต้นตำรับ 420      20.00
1   บราวนี่LP_RNE          18.00
1   บัตเตอร์เค้กLP          14.00
ยอดสุทธิ   3 ชิ้น             52.00
ทรูวอลเล็ท7App              52.00
TID#2026090500000005200279973
R#0000079278P3 :7608289   05/09/69 00:49
* ศูนย์บริการสมาชิก All Member 0-2826-7777 *
''';

    final result = BankSlipParser.parse(rawText);

    expect(result.amount, 52.00);
    expect(result.receiptItemCount, 3);
    expect(result.receiptItems, [
      '1 Hอิชิตันต้นตำรับ 420',
      '1 บราวนี่LP_RNE',
      '1 บัตเตอร์เค้กLP',
    ]);
    expect(result.receiptSummaryText, 'ยอดสุทธิ 3 ชิ้น 52.00 บาท');
    expect(result.defaultTitle, '7-Eleven: Hอิชิตันต้นตำรับ 420 และอื่นๆ (3 รายการ)');
    expect(result.receiverName, '7-Eleven สาขา ศูนย์อาหาร มมส (08116)');
    expect(result.memo, '1 Hอิชิตันต้นตำรับ 420 (20.-), 1 บราวนี่LP_RNE (18.-), 1 บัตเตอร์เค้กLP (14.-)');
  });

  test('Test 7-Eleven receipt parsing with 3 ชั้น (OCR error on receipt image)', () {
    const rawText = '''
สาขา 7-Eleven ศูนย์อาหาร มมส.
รหัสร้าน : 08116
---------------------------------
รายการสินค้า

1   Hอิชิตันต้นตำรับ 420      20.00
1   บราวนี่LP_RNE          18.00
1   บัตเตอร์เค้กLP          14.00
ยอดสุทธิ   3 ชั้น             52.00
ทรูวอลเล็ท7App              52.00
TID#2026090500000005200279973
R#0000079278P3 :7608289   05/09/69 00:49
* ศูนย์บริการสมาชิก All Member 0-2826-7777 *
''';

    final result = BankSlipParser.parse(rawText);

    expect(result.amount, 52.00);
    expect(result.receiptItemCount, 3);
    expect(result.receiptItems, [
      '1 Hอิชิตันต้นตำรับ 420',
      '1 บราวนี่LP_RNE',
      '1 บัตเตอร์เค้กLP',
    ]);
    expect(result.receiptSummaryText, 'ยอดสุทธิ 3 ชิ้น 52.00 บาท');
  });

  test('Test 7-Eleven receipt with actual Android Tesseract OCR output', () {
    const rawText = '''
ซี            สาขา 7-Eleven ศูนย์อาหาร มมส.
รหัสร้าน : 08116

รายการสินค้า

1 #ฝอิชิตินต้นท๊ําริบ 420              20.00
1 บราวบวนี่เก คมผะ                   18.00
1 ขบิตแตอร์เค้กเ5                   14.00
ยอดสูทธิ    3 ชั้น         52.00

ทรวอลเล็ท7๒00           52.00

TID#2026090500000005200279973
R#QQ00079278P3 :7608289    05/09/69 00:49

* ศูนย์บริการสมาชิก All Member 0-2826-7777 *
''';

    final result = BankSlipParser.parse(rawText);

    expect(result.amount, 52.00);
    expect(result.receiptItemCount, 3);
    expect(result.receiptItems, [
      '1 Hอิชิตันต้นตำรับ 420',
      '1 บราวนี่LP_RNE',
      '1 บัตเตอร์เค้กLP',
    ]);
    expect(result.receiptSummaryText, 'ยอดสุทธิ 3 ชิ้น 52.00 บาท');
    expect(result.defaultTitle, '7-Eleven: Hอิชิตันต้นตำรับ 420 และอื่นๆ (3 รายการ)');
    expect(result.receiverName, '7-Eleven สาขา ศูนย์อาหาร มมส (08116)');
    expect(result.memo, '1 Hอิชิตันต้นตำรับ 420 (20.-), 1 บราวนี่LP_RNE (18.-), 1 บัตเตอร์เค้กLP (14.-)');
  });

  test('Test 7-Eleven receipt with user screenshot OCR variation', () {
    const rawText = '''
สาขา 7-Eleven ศูนย์อาหาร มมส (08116)
รายการสินค้า
1 Hอิชิตันต้นตำรับ 420 20.00
1 บราวนี่l6 ผุผะ 18.00
1 บิตเตอร์เค้กเ 14.00
ยอดสุทธิ 3 ชั้น 52.00
TID#2026090500000005200279973
''';

    final result = BankSlipParser.parse(rawText);

    expect(result.amount, 52.00);
    expect(result.receiptItemCount, 3);
    expect(result.receiptItems, [
      '1 Hอิชิตันต้นตำรับ 420',
      '1 บราวนี่LP_RNE',
      '1 บัตเตอร์เค้กLP',
    ]);
    expect(result.receiptSummaryText, 'ยอดสุทธิ 3 ชิ้น 52.00 บาท');
  });
}

