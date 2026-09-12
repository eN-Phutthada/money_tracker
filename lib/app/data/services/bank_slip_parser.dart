import '../models/bank_slip_model.dart';
import '../models/transaction_model.dart';
import 'slip_category_predictor.dart';

/// เครื่องยนต์ Regular Expression และ Semantic Analysis สำหรับถอดรหัสสลิปธนาคารกรุงไทย
class BankSlipParser {
  /// ตรวจสอบว่าเป็นข้อความสลิปของธนาคารกรุงไทยหรือไม่
  static bool isKrungthaiSlip(String text) {
    final lower = text.toLowerCase();
    return lower.contains('กรุงไทย') ||
        lower.contains('krungthai') ||
        lower.contains('ktb') ||
        lower.contains('006') ||
        lower.contains('เป๋าตัง');
  }

  /// ตรวจสอบว่าเป็นข้อความสลิปโอนเงินของธนาคารใดๆ ในไทยหรือไม่
  static bool isValidBankSlip(String text) {
    final lower = text.toLowerCase();
    return isKrungthaiSlip(text) ||
        lower.contains('กสิกร') ||
        lower.contains('k plus') ||
        lower.contains('kbank') ||
        lower.contains('ไทยพาณิชย์') ||
        lower.contains('scb') ||
        lower.contains('กรุงเทพ') ||
        lower.contains('bangkok bank') ||
        lower.contains('กรุงศรี') ||
        lower.contains('krungsri') ||
        lower.contains('kma') ||
        lower.contains('ทหารไทยธนชาต') ||
        lower.contains('ttb') ||
        lower.contains('ออมสิน') ||
        lower.contains('mymo') ||
        lower.contains('ธ.ก.ส.') ||
        lower.contains('baac') ||
        lower.contains('truemoney') ||
        lower.contains('ทรูมันนี่') ||
        lower.contains('kkp') ||
        lower.contains('เกียรตินาคิน') ||
        lower.contains('dime') ||
        lower.contains('uob') ||
        lower.contains('ยูโอบี') ||
        lower.contains('cimb') ||
        lower.contains('ซีไอเอ็มบี') ||
        lower.contains('tisco') ||
        lower.contains('ทิสโก้') ||
        lower.contains('แลนด์ แอนด์ เฮ้าส์') ||
        lower.contains('lhb') ||
        lower.contains('shopeepay') ||
        lower.contains('ช้อปปี้') ||
        lower.contains('icbc') ||
        lower.contains('พร้อมเพย์') ||
        lower.contains('promptpay') ||
        lower.contains('โอนเงิน') ||
        lower.contains('สำเร็จ') ||
        lower.contains('transfer') ||
        lower.contains('successful');
  }

  /// ตรวจจับชื่อธนาคารจากข้อความสลิป (รองรับทุกธนาคาร โดยมีกรุงไทย NEXT เป็นหลัก)
  static String detectBankName(String fullText) {
    final lower = fullText.toLowerCase();
    if (lower.contains('k plus') || lower.contains('กสิกร') || lower.contains('kbank') || lower.contains('kasikorn')) {
      return 'ธนาคารกสิกรไทย (K PLUS)';
    }
    if (lower.contains('scb') || lower.contains('ไทยพาณิชย์') || lower.contains('แม่มณี') || lower.contains('siam commercial')) {
      return 'ธนาคารไทยพาณิชย์ (SCB EASY)';
    }
    if (lower.contains('bangkok bank') || lower.contains('กรุงเทพ') || lower.contains('bualuang')) {
      return 'ธนาคารกรุงเทพ (Bualuang mBanking)';
    }
    if (lower.contains('krungsri') || lower.contains('กรุงศรี') || lower.contains('kma') || lower.contains('ayudhya')) {
      return 'ธนาคารกรุงศรีอยุธยา (KMA)';
    }
    if (lower.contains('ttb') || lower.contains('ทหารไทยธนชาต') || lower.contains('tmb') || lower.contains('thanachart')) {
      return 'ทีเอ็มบีธนชาต (ttb touch)';
    }
    if (lower.contains('mymo') || lower.contains('ออมสิน') || lower.contains('gsb') || lower.contains('government savings')) {
      return 'ธนาคารออมสิน (MyMo)';
    }
    if (lower.contains('baac') || lower.contains('ธ.ก.ส.') || lower.contains('ธกส') || lower.contains('agricultural')) {
      return 'ธ.ก.ส. (BAAC Mobile)';
    }
    if (lower.contains('kkp') || lower.contains('เกียรตินาคิน') || lower.contains('dime')) {
      return 'ธนาคารเกียรตินาคินภัทร (KKP)';
    }
    if (lower.contains('uob') || lower.contains('ยูโอบี') || lower.contains('tmrw')) {
      return 'ธนาคารยูโอบี (UOB TMRW)';
    }
    if (lower.contains('cimb') || lower.contains('ซีไอเอ็มบี')) {
      return 'ธนาคารซีไอเอ็มบี ไทย';
    }
    if (lower.contains('tisco') || lower.contains('ทิสโก้')) {
      return 'ธนาคารทิสโก้';
    }
    if (lower.contains('lh bank') || lower.contains('lhb') || lower.contains('แลนด์ แอนด์ เฮ้าส์')) {
      return 'ธนาคารแลนด์ แอนด์ เฮ้าส์ (LHB You)';
    }
    if (lower.contains('shopeepay') || lower.contains('ช้อปปี้เพย์') || lower.contains('shopee pay')) {
      return 'ช้อปปี้เพย์ (ShopeePay)';
    }
    if (lower.contains('icbc') || lower.contains('ไอซีบีซี')) {
      return 'ธนาคารไอซีบีซี (ไทย)';
    }
    if (lower.contains('truemoney') || lower.contains('ทรูมันนี่') || lower.contains('true money')) {
      return 'ทรูมันนี่ (TrueMoney Wallet)';
    }
    if (lower.contains('เป๋าตัง') || lower.contains('paotang')) {
      return 'ธนาคารกรุงไทย (เป๋าตัง)';
    }
    // ค่าเริ่มต้นเป็นกรุงไทย NEXT (หลัก)
    return 'ธนาคารกรุงไทย (Krungthai NEXT)';
  }

  /// แปลงข้อความสลิปเป็น `BankSlipData`
  static BankSlipData parse(String rawText) {
    // 1. แปลงเลขไทยเป็นเลขอารบิก
    const thaiDigits = ['๐', '๑', '๒', '๓', '๔', '๕', '๖', '๗', '๘', '๙'];
    const arabicDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var convertedText = rawText;
    for (int i = 0; i < 10; i++) {
      convertedText = convertedText.replaceAll(thaiDigits[i], arabicDigits[i]);
    }

    // 2. ขจัด Zero-width และ Invisible Spaces ที่ OCR มักสร้างขึ้น
    convertedText = convertedText
        .replaceAll('\u200B', '')
        .replaceAll('\u200C', '')
        .replaceAll('\u200D', '')
        .replaceAll('\uFEFF', '')
        .replaceAll('\u00A0', ' ');

    // 3. ปรับ Nikhahit + Sara Aa ให้เป็น Sara Am สากล
    convertedText = convertedText.replaceAll('\u0E4D\u0E32', '\u0E33');

    // 4. แก้ปัญหา OCR เคาะวรรครอบทศนิยม เช่น "139 . 00" -> "139.00"
    convertedText = convertedText.replaceAllMapped(
      RegExp(r'(\d+)\s*\.\s*(\d{2})\b'),
      (m) => '${m.group(1)}.${m.group(2)}',
    );

    final normalized = convertedText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final bankName = detectBankName(normalized);
    final isKrungthai = isKrungthaiSlip(normalized) || bankName.contains('กรุงไทย');
    final amount = _extractAmount(normalized, lines);
    final parsedDate = _extractDateTime(normalized, lines);
    final date = parsedDate ?? DateTime.now();
    final refNo = _extractReferenceNumber(normalized, lines);
    final sender = _extractSender(lines);
    final senderAccount = _extractSenderAccount(lines);
    final receiver = _extractReceiver(lines);
    final receiverAccount = _extractReceiverAccount(lines);
    final memo = _extractMemo(lines);

    final prediction = SlipCategoryPredictor.predict(
      memo: memo,
      receiverName: receiver,
      fullText: normalized,
      amount: amount,
      transactionDate: date,
    );

    return BankSlipData(
      amount: amount,
      transactionDate: date,
      senderName: sender,
      senderAccount: senderAccount,
      receiverName: receiver,
      receiverAccount: receiverAccount,
      referenceNo: refNo,
      memo: memo,
      bankName: bankName,
      isKrungthai: isKrungthai,
      suggestedCategory: prediction.category,
      suggestedType: prediction.type,
      suggestedCostNature: prediction.costNature,
      rawText: rawText,
      hasParsedDateTime: parsedDate != null,
      predictionConfidence: prediction.confidence,
      predictionReason: prediction.reason,
    );
  }

  /// สกัดยอดเงิน (Amount) ด้วย Multi-Tier Recognition Engine
  static double _extractAmount(String fullText, List<String> lines) {
    // 0. ปรับข้อความภาษาไทยให้อยู่ในรูปมาตรฐาน (Normalize Nikhahit U+0E4D + Sara Aa U+0E32 -> Sara Am U+0E33)
    final normalizedText = fullText.replaceAll('\u0E4D\u0E32', '\u0E33');
    final normalizedLines = lines.map((l) => l.replaceAll('\u0E4D\u0E32', '\u0E33')).toList();

    // 1. ค้นหาบรรทัดที่มีคีย์เวิร์ดจำนวนเงินบนบรรทัดเดียวกัน (รองรับวงเล็บ เช่น "จำนวนเงิน (บาท) 139.00", "Amount (THB): 139.00")
    final amountKeywordRegex = RegExp(
      r'(?:จำนวนเงิน|จํานวนเงิน|ยอดเงิน|ยอดโอน|จำนวนโอน|จำนวน|จํานวน|Amount|Total|Amt|Transfer\s*Amount)(?:\s*\((?:บาท|THB|baht|บ\.|[^\)]+)\))?\s*[:：\-]?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|\.[0-9]{1,2}|[0-9]+)\s*(?:บาท|บ\.|THB|baht)?',
      caseSensitive: false,
    );
    for (final match in amountKeywordRegex.allMatches(normalizedText)) {
      final str = match.group(1)?.replaceAll(',', '');
      if (str != null) {
        final val = double.tryParse(str);
        if (val != null && val > 0) return val;
      }
    }

    // 2. ค้นหาบรรทัดที่มีคีย์เวิร์ด และดูบรรทัดถัดไป 1 - 4 บรรทัด (รองรับ Columnar OCR ที่ฝั่งซ้ายเป็น Label ฝั่งขวาเป็นตัวเลข)
    for (int i = 0; i < normalizedLines.length; i++) {
      final line = normalizedLines[i].toLowerCase();
      final isAmountLine = line.contains('จำนวนเงิน') ||
          line.contains('จํานวนเงิน') ||
          line.contains('ยอดเงิน') ||
          line.contains('ยอดโอน') ||
          line.contains('จำนวน') ||
          line.contains('amount') ||
          line.contains('total');

      if (isAmountLine) {
        // ตรวจในบรรทัดเดียวกัน
        final inlineNum = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)').firstMatch(line);
        if (inlineNum != null) {
          final val = double.tryParse(inlineNum.group(1)!.replaceAll(',', ''));
          if (val != null && val > 0) return val;
        }

        // ค้นหาในบรรทัดถัดไป 1-4 บรรทัด ข้ามบรรทัด Label ค่าธรรมเนียม หรือบรรทัดที่มีแต่คำว่า บาท/THB
        for (int step = 1; step <= 4 && (i + step) < normalizedLines.length; step++) {
          final candidateLine = normalizedLines[i + step].trim();
          if (candidateLine.contains('ค่าธรรมเนียม') ||
              candidateLine.toLowerCase().contains('fee') ||
              candidateLine.toLowerCase() == 'บาท' ||
              candidateLine.toLowerCase() == 'thb') {
            continue;
          }
          final numMatch = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(candidateLine);
          if (numMatch != null) {
            final val = double.tryParse(numMatch.group(1)!.replaceAll(',', ''));
            if (val != null && val > 0) return val;
          }
        }
      }
    }

    // 3. ค้นหาตัวเลขทศนิยมสองตำแหน่งที่มีหน่วยสกุลเงิน บาท / บ. / THB กำกับ
    final currencySuffixRegex = RegExp(
      r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})\s*(?:บาท|บ\.|THB|baht)\b',
      caseSensitive: false,
    );
    for (final match in currencySuffixRegex.allMatches(normalizedText)) {
      final str = match.group(1)?.replaceAll(',', '');
      if (str != null) {
        final val = double.tryParse(str);
        if (val != null && val > 0) return val;
      }
    }

    // 4. ค้นหาตัวเลขทศนิยม 2 ตำแหน่งทั้งหมดในสลิป (Fallback สำหรับ OCR ภาษาอังกฤษ/ละตินที่ไม่สามารถอ่านตัวอักษรไทยได้)
    final allDecimals = RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})\b')
        .allMatches(normalizedText)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0.0)
        .where((val) => val > 0)
        .toList();

    if (allDecimals.isNotEmpty) {
      return allDecimals.first;
    }

    // 5. Fallback ตัวเลขจำนวนเต็มพร้อมสกุลเงิน (เช่น 139 บาท)
    final intCurrencyRegex = RegExp(
      r'([1-9][0-9]{0,2}(?:,[0-9]{3})*|[1-9][0-9]*)\s*(?:บาท|บ\.|THB)',
      caseSensitive: false,
    );
    final intMatch = intCurrencyRegex.firstMatch(normalizedText);
    if (intMatch != null) {
      final val = double.tryParse(intMatch.group(1)!.replaceAll(',', ''));
      if (val != null && val > 0) return val;
    }

    return 0.0;
  }

  /// สกัดวันและเวลา (Date & Time) จากข้อความสลิป
  /// พร้อมอัลกอริทึม Multi-Tier Recognition ป้องกันการสกัดเวลาผิด (เช่น เวลาบน Status Bar ของมือถือ)
  static DateTime? _extractDateTime(String fullText, List<String> lines) {
    int? day, month, year, hour, minute, second;

    int parseYear(int raw) {
      if (raw >= 2500) return raw - 543;
      if (raw >= 60 && raw <= 99) return (2500 + raw) - 543;
      if (raw >= 2000) return raw;
      return 2000 + raw;
    }

    // ตรวจสอบเดือนภาษาไทย (ครอบคลุมทั้งแบบมีจุด ไม่มีจุด และชื่อเต็ม)
    final thaiMonths = {
      'มกราคม': 1, 'ม.ค.': 1, 'ม.ค': 1, 'มค': 1,
      'กุมภาพันธ์': 2, 'ก.พ.': 2, 'ก.พ': 2, 'กพ': 2,
      'มีนาคม': 3, 'มี.ค.': 3, 'มี.ค': 3, 'มีค': 3,
      'เมษายน': 4, 'เม.ย.': 4, 'เม.ย': 4, 'เมย': 4,
      'พฤษภาคม': 5, 'พ.ค.': 5, 'พ.ค': 5, 'พค': 5,
      'มิถุนายน': 6, 'มิ.ย.': 6, 'มิ.ย': 6, 'มิย': 6,
      'กรกฎาคม': 7, 'ก.ค.': 7, 'ก.ค': 7, 'กค': 7,
      'สิงหาคม': 8, 'ส.ค.': 8, 'ส.ค': 8, 'สค': 8,
      'กันยายน': 9, 'ก.ย.': 9, 'ก.ย': 9, 'กย': 9,
      'ตุลาคม': 10, 'ต.ค.': 10, 'ต.ค': 10, 'ตค': 10,
      'พฤศจิกายน': 11, 'พ.ย.': 11, 'พ.ย': 11, 'พย': 11,
      'ธันวาคม': 12, 'ธ.ค.': 12, 'ธ.ค': 12, 'ธค': 12,
    };

    final engMonths = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    final thaiMonthPattern = (thaiMonths.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
        .map(RegExp.escape)
        .join('|');

    // 1. ตรวจหาคู่ "วันที่แบบไทย + เวลา" ในบรรทัดเดียวกัน (Compound Thai Date-Time)
    // ตัวอย่าง: "วันที่ทำรายการ 02 ส.ค. 2569 - 22:02", "2 ส.ค. 69 เวลา 22.02 น.", "02 สิงหาคม 2569 / 22:02:30", "12 ก.ย. 69 15:45:00 น."
    final compoundThaiRegex = RegExp(
      '(?:วันที่(?:ทำรายการ)?\\s*[:：]?\\s*)?(\\d{1,2})\\s*($thaiMonthPattern)\\s*(\\d{2,4})?\\s*(?:[-–—,\\s/|•@·]+|(?:[-–—,\\s/|•@·]*(?:เวลา|เมื่อเวลา|Time)?\\s*[:：]?\\s*))(\\d{1,2})[:.](\\d{2})(?:[:.](\\d{2}))?\\s*(?:น\\.|น)?',
      caseSensitive: false,
    );

    final compoundMatch = compoundThaiRegex.firstMatch(fullText);
    if (compoundMatch != null) {
      day = int.tryParse(compoundMatch.group(1)!);
      month = thaiMonths[compoundMatch.group(2)!];
      final rawYear = compoundMatch.group(3) != null ? int.tryParse(compoundMatch.group(3)!) : null;
      if (rawYear != null) {
        year = parseYear(rawYear);
      } else {
        year = DateTime.now().year;
      }
      hour = int.tryParse(compoundMatch.group(4)!);
      minute = int.tryParse(compoundMatch.group(5)!);
      second = compoundMatch.group(6) != null ? int.tryParse(compoundMatch.group(6)!) : 0;

      if (day != null && month != null && hour != null && minute != null) {
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return DateTime(year, month, day, hour, minute, second ?? 0);
        }
      }
    }

    // 2. ตรวจหาคู่ "วันที่แบบอังกฤษ + เวลา"
    // ตัวอย่าง: "02 Aug 2026 22:02:15", "2 Sep 2026, 22.02"
    final compoundEngRegex = RegExp(
      r'(?:Date\s*[:：]?\s*)?(\d{1,2})\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*(\d{2,4})?\s*[-–—,\s/|•@·]+\s*(?:(?:Time|เวลา)\s*[:：]?\s*)?(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?',
      caseSensitive: false,
    );
    final engMatch = compoundEngRegex.firstMatch(fullText);
    if (engMatch != null) {
      day = int.tryParse(engMatch.group(1)!);
      month = engMonths[engMatch.group(2)!.toLowerCase()];
      final rawYear = engMatch.group(3) != null ? int.tryParse(engMatch.group(3)!) : null;
      if (rawYear != null) {
        year = parseYear(rawYear);
      } else {
        year = DateTime.now().year;
      }
      hour = int.tryParse(engMatch.group(4)!);
      minute = int.tryParse(engMatch.group(5)!);
      second = engMatch.group(6) != null ? int.tryParse(engMatch.group(6)!) : 0;

      if (day != null && month != null && hour != null && minute != null) {
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return DateTime(year, month, day, hour, minute, second ?? 0);
        }
      }
    }

    // 3. ตรวจหาคู่ "วันที่แบบตัวเลข + เวลา"
    // ตัวอย่าง: "02/08/2569 22:02", "02/08/2026 - 22.02"
    final compoundNumRegex = RegExp(
      r'(?:วันที่\s*[:：]?\s*)?(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\s*[-–—,\s/|•@·]+\s*(?:(?:เวลา|Time)\s*[:：]?\s*)?(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?\s*(?:น\.|น)?',
    );
    final numMatch = compoundNumRegex.firstMatch(fullText);
    if (numMatch != null) {
      day = int.tryParse(numMatch.group(1)!);
      month = int.tryParse(numMatch.group(2)!);
      final rawYear = int.tryParse(numMatch.group(3)!);
      if (rawYear != null) year = parseYear(rawYear);
      hour = int.tryParse(numMatch.group(4)!);
      minute = int.tryParse(numMatch.group(5)!);
      second = numMatch.group(6) != null ? int.tryParse(numMatch.group(6)!) : 0;

      if (day != null && month != null && year != null && hour != null && minute != null) {
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return DateTime(year, month, day, hour, minute, second ?? 0);
        }
      }
    }

    // 4. กรณีวันที่และเวลาอยู่คนละบรรทัดกัน (Multi-line Contextual Parsing)
    // 4.1 ค้นหาบรรทัดวันที่
    int? dateLineIndex;
    final thaiDateOnlyRegex = RegExp(
      '(?:วันที่(?:ทำรายการ)?\\s*[:：]?\\s*)?(\\d{1,2})\\s*($thaiMonthPattern)\\s*(\\d{2,4})?',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final m = thaiDateOnlyRegex.firstMatch(line);
      if (m != null) {
        day = int.tryParse(m.group(1)!);
        month = thaiMonths[m.group(2)!];
        final rawYear = m.group(3) != null ? int.tryParse(m.group(3)!) : null;
        if (rawYear != null) {
          year = parseYear(rawYear);
        } else {
          year = DateTime.now().year;
        }
        dateLineIndex = i;
        break;
      }
    }

    if (dateLineIndex == null) {
      final engDateOnlyRegex = RegExp(
        r'(?:Date\s*[:：]?\s*)?(\d{1,2})\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*(\d{2,4})?',
        caseSensitive: false,
      );
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final m = engDateOnlyRegex.firstMatch(line);
        if (m != null) {
          day = int.tryParse(m.group(1)!);
          month = engMonths[m.group(2)!.toLowerCase()];
          final rawYear = m.group(3) != null ? int.tryParse(m.group(3)!) : null;
          if (rawYear != null) {
            year = parseYear(rawYear);
          } else {
            year = DateTime.now().year;
          }
          dateLineIndex = i;
          break;
        }
      }
    }

    if (dateLineIndex == null) {
      final numDateOnlyRegex = RegExp(r'(?:วันที่\s*[:：]?\s*)?(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final m = numDateOnlyRegex.firstMatch(line);
        if (m != null) {
          day = int.tryParse(m.group(1)!);
          month = int.tryParse(m.group(2)!);
          final rawYear = int.tryParse(m.group(3)!);
          if (rawYear != null) year = parseYear(rawYear);
          dateLineIndex = i;
          break;
        }
      }
    }

    // 4.1.1 หากยังไม่พบวันที่ ลองค้นหาจากรหัสอ้างอิง (เช่น 20260915...)
    if (day == null || month == null || year == null) {
      final refDateMatch = RegExp(r'\b(202\d)(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{6,}\b').firstMatch(fullText);
      if (refDateMatch != null) {
        year = int.tryParse(refDateMatch.group(1)!);
        month = int.tryParse(refDateMatch.group(2)!);
        day = int.tryParse(refDateMatch.group(3)!);
      }
    }

    // 4.2 สกัดเวลา: ตรวจสอบอย่างละเอียด
    bool setTimeIfValid(int? h, int? m, int? s) {
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        hour = h;
        minute = m;
        second = s ?? 0;
        return true;
      }
      return false;
    }

    // A. ค้นหาเวลาที่มีคำนำหน้า "เวลา" หรือลงท้าย "น." หรือใช้โคลอน (:)
    final explicitTimeRegex = RegExp(
      r'(?:เวลา|Time|เมื่อเวลา)\s*[:：]?\s*([01]?\d|2[0-3])[:.]([0-5]\d)(?:[:.]([0-5]\d))?|([01]?\d|2[0-3])\.([0-5]\d)(?:\.([0-5]\d))?\s*น\.?|\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b',
      caseSensitive: false,
    );

    // ตรวจสอบแถวใกล้เคียงกับแถววันที่ก่อน (dateLineIndex - 1, dateLineIndex, dateLineIndex + 1, dateLineIndex + 2)
    if (dateLineIndex != null) {
      final checkIndices = [
        dateLineIndex,
        if (dateLineIndex + 1 < lines.length) dateLineIndex + 1,
        if (dateLineIndex - 1 >= 0) dateLineIndex - 1,
        if (dateLineIndex + 2 < lines.length) dateLineIndex + 2,
      ];
      for (final idx in checkIndices) {
        final cand = lines[idx];
        if (cand.contains('บาท') || cand.contains('บ.') || cand.toLowerCase().contains('thb') || cand.contains('จำนวนเงิน') || cand.contains('ยอดเงิน') || cand.contains('ค่าธรรมเนียม')) {
          if (!cand.contains('เวลา') && !cand.contains('น.')) continue;
        }
        final m = explicitTimeRegex.firstMatch(cand);
        if (m != null) {
          final hStr = m.group(1) ?? m.group(4) ?? m.group(7);
          final mStr = m.group(2) ?? m.group(5) ?? m.group(8);
          final sStr = m.group(3) ?? m.group(6) ?? m.group(9);
          if (setTimeIfValid(int.tryParse(hStr ?? ''), int.tryParse(mStr ?? ''), int.tryParse(sStr ?? ''))) {
            break;
          }
        }
      }
    }

    // หากยังไม่พบเวลา สแกนทุกบรรทัดตั้งแต่บรรทัดที่ 1 (ข้ามบรรทัด 0 เพื่อเลี่ยง status bar ของมือถือ)
    if (hour == null) {
      final startIndex = lines.length > 1 ? 1 : 0;
      for (int i = startIndex; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('บาท') || line.contains('บ.') || line.toLowerCase().contains('thb') || line.contains('จำนวน') || line.contains('จํานวน') || line.contains('ค่าธรรมเนียม') || line.toLowerCase().contains('fee') || line.toLowerCase().contains('amount')) {
          if (!line.contains('เวลา') && !line.contains('น.')) continue;
        }
        final m = explicitTimeRegex.firstMatch(line);
        if (m != null) {
          final hStr = m.group(1) ?? m.group(4) ?? m.group(7);
          final mStr = m.group(2) ?? m.group(5) ?? m.group(8);
          final sStr = m.group(3) ?? m.group(6) ?? m.group(9);
          if (setTimeIfValid(int.tryParse(hStr ?? ''), int.tryParse(mStr ?? ''), int.tryParse(sStr ?? ''))) {
            break;
          }
        }
      }
    }

    final h = hour;
    final m = minute;

    if (day != null && month != null && year != null) {
      return DateTime(
        year,
        month,
        day,
        h ?? 0,
        m ?? 0,
        second ?? 0,
      );
    } else if (h != null && m != null) {
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        h,
        m,
        second ?? 0,
      );
    }

    return null;
  }

  /// สกัดเลขที่รายการ / รหัสอ้างอิง
  static String? _extractReferenceNumber(String fullText, List<String> lines) {
    // 1. ค้นหาบรรทัดที่มีคีย์เวิร์ด
    final refKeywordRegex = RegExp(
      r'(?:รหัสอ้างอิง|เลขที่รายการ|รหัสทำรายการ|หมายเลขอ้างอิง|เลขที่อ้างอิง|Ref(?:\s*No|\.\s*No)?|Transaction\s*ID|Txn\s*ID)\s*[:：\-]?\s*([A-Za-z0-9 ]{8,36})',
      caseSensitive: false,
    );
    final match = refKeywordRegex.firstMatch(fullText);
    if (match != null) {
      final ref = match.group(1)!.replaceAll(' ', '').trim();
      if (ref.length >= 8) return ref;
    }

    // 2. ค้นหาในบรรทัดถัดไปหลังจากเจอคีย์เวิร์ด
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('รหัสอ้างอิง') ||
          line.contains('เลขที่รายการ') ||
          line.contains('รหัสทำรายการ') ||
          line.contains('หมายเลขอ้างอิง') ||
          line.contains('ref')) {
        for (int next = i + 1; next <= i + 2 && next < lines.length; next++) {
          final nextLine = lines[next].replaceAll(' ', '').trim();
          final m = RegExp(r'^([A-Za-z0-9]{8,36})$').firstMatch(nextLine);
          if (m != null) return m.group(1);
        }
      }
    }

    // 3. ตรวจจับรหัสธุรกรรม Krungthai NEXT / ธนาคารทั่วไป (มักเริ่มต้นด้วยปี ค.ศ. เช่น 2026... หรือ KTB...)
    final ktbIdRegex = RegExp(r'\b(202\d{13,24}|KTB[0-9A-Za-z]{8,24})\b');
    final idMatch = ktbIdRegex.firstMatch(fullText);
    if (idMatch != null) {
      return idMatch.group(1);
    }

    return null;
  }

  /// ตรวจสอบว่าข้อความเป็นชื่อธนาคาร ช่องทาง หรือข้อความรบกวน (Noise) ที่ไม่ใช่ชื่อบุคคล/ร้านค้าหรือไม่
  static bool _isBankOrChannelOrNoise(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.isEmpty || lower.length < 2) return true;

    // ตรวจจับตัวเลขและ Masking บัญชี หรือเบอร์โทร เช่น "xxx-x-xx123-x", "081-xxx-1234", "123-4-56789-0"
    if (RegExp(r'^[0-9\s\-xX*•/.]+$').hasMatch(lower)) return true;

    // คำที่เกี่ยวข้องกับชื่อธนาคารและแอปธนาคาร (เมื่ออยู่โดดๆ หรือมีคำว่า ธนาคาร/ธ. นำหน้า)
    final bankTerms = [
      'ธนาคาร', 'ธ.', 'กสิกร', 'ไทยพาณิชย์', 'กรุงเทพ', 'กรุงศรี', 'ทหารไทยธนชาต', 'ทีเอ็มบี',
      'ธนชาต', 'ttb', 'ออมสิน', 'ธ.ก.ส.', 'ธกส', 'กรุงไทย', 'เกียรตินาคิน', 'kkp',
      'ยูโอบี', 'uob', 'ซีไอเอ็มบี', 'cimb', 'ทิสโก้', 'tisco', 'แลนด์ แอนด์ เฮ้าส์',
      'lhb', 'kbank', 'k plus', 'scb', 'scb easy', 'bbl', 'bualuang', 'ktb',
      'krungthai next', 'kma', 'mymo', 'baac', 'เป๋าตัง', 'paotang', 'kasikorn',
    ];
    for (final term in bankTerms) {
      if (lower == term ||
          lower == 'ธ.$term' ||
          lower == 'ธนาคาร$term' ||
          lower == 'ธนาคาร $term' ||
          lower == 'ธ.$termไทย' ||
          lower == 'ธนาคาร$termไทย' ||
          lower == 'ธนาคาร $termไทย') {
        return true;
      }
    }
    if (RegExp(r'^(?:ธ\.|ธนาคาร)\s*[ก-๙a-zA-Z\s]+(?:\(มหาชน\))?$').hasMatch(lower)) {
      return true;
    }

    // คำรบกวนโดดๆ หรือมีแค่ : เช่น "พร้อมเพย์", "พร้อมเพย์:", "บัญชีออมทรัพย์"
    final exactNoise = [
      'พร้อมเพย์', 'promptpay', 'วอลเล็ท', 'wallet', 'ออมทรัพย์', 'กระแสรายวัน',
      'savings', 'current', 'เลขที่บัญชี', 'account no', 'account number',
      'บัญชีผู้รับ', 'บัญชีผู้โอน', 'บัญชีเงินฝาก', 'ค่าธรรมเนียม', 'fee',
      'จำนวนเงิน', 'ยอดเงิน', 'ยอดโอน', 'amount', 'บาท', 'thb', 'baht',
      'สำเร็จ', 'successful', 'โอนสำเร็จ', 'transfer successful',
    ];
    for (final term in exactNoise) {
      if (lower == term || lower == '$term:' || lower == '$term：') return true;
    }

    // สำหรับคำที่ขึ้นต้นด้วย Label ประเภท "ค่าธรรมเนียม: ...", "จำนวนเงิน: ..."
    if (lower.startsWith('ค่าธรรมเนียม') ||
        lower.startsWith('fee') ||
        lower.startsWith('จำนวนเงิน') ||
        lower.startsWith('ยอดเงิน') ||
        lower.startsWith('ยอดโอน') ||
        lower.startsWith('amount:') ||
        lower.startsWith('amount :')) {
      return true;
    }

    return false;
  }

  /// สกัดชื่อผู้โอน (จาก / From / ผู้โอน)
  static String? _extractSender(List<String> lines) {
    final senderKeywords = ['จาก', 'from', 'ผู้โอน', 'sender'];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      for (final kw in senderKeywords) {
        if (lineLower == kw ||
            lineLower.startsWith('$kw:') ||
            lineLower.startsWith('$kw：') ||
            lineLower.startsWith('$kw ')) {
          final inline = line.replaceFirst(
            RegExp('^(?:$kw)\\s*[:：]?\\s*', caseSensitive: false),
            '',
          ).trim();

          if (!_isBankOrChannelOrNoise(inline)) {
            final cleanedInline = _cleanName(inline);
            if (cleanedInline.length >= 2 && !_isBankOrChannelOrNoise(cleanedInline)) {
              return cleanedInline;
            }
          }

          for (int nextIdx = i + 1; nextIdx <= i + 4 && nextIdx < lines.length; nextIdx++) {
            final candidate = lines[nextIdx].trim();
            if (_isBankOrChannelOrNoise(candidate)) continue;

            final cleanedCandidate = _cleanName(candidate);
            if (cleanedCandidate.length >= 2 && !_isBankOrChannelOrNoise(cleanedCandidate)) {
              return cleanedCandidate;
            }
          }
        }
      }
    }
    return null;
  }

  /// สกัดเลขบัญชีผู้โอน (ถ้ามี)
  static String? _extractSenderAccount(List<String> lines) {
    final senderKeywords = ['จาก', 'from', 'ผู้โอน'];
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase();
      if (senderKeywords.any((k) => lineLower == k || lineLower.startsWith('$k:') || lineLower.startsWith('$k '))) {
        for (int j = i + 1; j <= i + 4 && j < lines.length; j++) {
          final l = lines[j].trim();
          if (l.contains('บาท') || l.toLowerCase().contains('thb') || l.contains('ค่าธรรมเนียม')) continue;
          if (RegExp(r'[xX0-9\s\-*]{8,24}').hasMatch(l)) {
            return l;
          }
        }
      }
    }
    return null;
  }

  /// สกัดชื่อผู้รับเงิน (ไปยัง / To / ผู้รับ / เข้าบัญชี / ร้านค้า)
  static String? _extractReceiver(List<String> lines) {
    final receiverKeywords = [
      'ไปยัง',
      'ผู้รับเงิน',
      'เข้าบัญชี',
      'โอนให้',
      'โอนไปยัง',
      'ผู้รับ',
      'to',
      'receiver',
      'payee',
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      for (final kw in receiverKeywords) {
        if (lineLower == kw ||
            lineLower.startsWith('$kw:') ||
            lineLower.startsWith('$kw：') ||
            lineLower.startsWith('$kw ')) {
          final inline = line.replaceFirst(
            RegExp('^(?:$kw)\\s*[:：]?\\s*', caseSensitive: false),
            '',
          ).trim();

          if (!_isBankOrChannelOrNoise(inline)) {
            final cleanedInline = _cleanName(inline);
            if (cleanedInline.length >= 2 && !_isBankOrChannelOrNoise(cleanedInline)) {
              return cleanedInline;
            }
          }

          for (int nextIdx = i + 1; nextIdx <= i + 4 && nextIdx < lines.length; nextIdx++) {
            final candidate = lines[nextIdx].trim();
            if (_isBankOrChannelOrNoise(candidate)) continue;

            final cleanedCandidate = _cleanName(candidate);
            if (cleanedCandidate.length >= 2 && !_isBankOrChannelOrNoise(cleanedCandidate)) {
              return cleanedCandidate;
            }
          }
        }
      }

      // ตรวจหารูปแบบชื่อร้านค้า เช่น "ร้าน ...", "บจก. ...", "บริษัท ..."
      final merchantMatch = RegExp(r'^(?:ร้าน|บจก\.|บริษัท|หจก\.)\s*[^\s]+.*$').firstMatch(line.trim());
      if (merchantMatch != null) {
        final name = _cleanName(merchantMatch.group(0)!);
        if (name.length >= 3 && !_isBankOrChannelOrNoise(name)) return name;
      }
    }
    return null;
  }

  /// สกัดเลขบัญชีหรือเลขพร้อมเพย์ผู้รับ (ถ้ามี)
  static String? _extractReceiverAccount(List<String> lines) {
    final receiverKeywords = ['ไปยัง', 'to', 'เข้าบัญชี', 'ผู้รับเงิน'];
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase();
      if (receiverKeywords.any((k) => lineLower == k || lineLower.startsWith('$k:') || lineLower.startsWith('$k '))) {
        for (int j = i + 1; j <= i + 4 && j < lines.length; j++) {
          final l = lines[j].trim();
          if (l.contains('บาท') || l.toLowerCase().contains('thb') || l.contains('ค่าธรรมเนียม')) continue;
          if (RegExp(r'[xX0-9\s\-*]{8,24}').hasMatch(l)) {
            return l;
          }
        }
      }
    }
    return null;
  }

  /// สกัดบันทึกช่วยจำ (Memo / Note)
  static String? _extractMemo(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('บันทึกช่วยจำ') || line.contains('บันทึก:') || line.startsWith('บันทึก ') || line.toLowerCase().startsWith('memo:') || line.toLowerCase().startsWith('note:')) {
        final inline = line.replaceFirst(RegExp(r'^(?:บันทึกช่วยจำ|บันทึก|memo|note)\s*[:：]?\s*', caseSensitive: false), '').trim();
        if (inline.isNotEmpty && !inline.contains('QR') && !inline.contains('สแกน')) return inline;
        if (i + 1 < lines.length) {
          final candidate = lines[i + 1].trim();
          if (candidate.isNotEmpty && !candidate.contains('QR') && !candidate.contains('สแกน')) {
            return candidate;
          }
        }
      }
    }
    return null;
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'ธ\.(?:กรุงไทย|กสิกรไทย|ไทยพาณิชย์|กรุงเทพ|กรุงศรีอยุธยา|กรุงศรี|ออมสิน|ก\.ส\.|ทหารไทยธนชาต|เกียรตินาคิน|ยูโอบี|ซีไอเอ็มบี|ทิสโก้|แลนด์ แอนด์ เฮ้าส์)', caseSensitive: false), '')
        .replaceAll(RegExp(r'ธนาคาร(?:กรุงไทย|กสิกรไทย|ไทยพาณิชย์|กรุงเทพ|กรุงศรีอยุธยา|กรุงศรี|ออมสิน|เพื่อการเกษตรและสหกรณ์การเกษตร|ทหารไทยธนชาต|เกียรตินาคินภัทร|เกียรตินาคิน|ยูโอบี|ซีไอเอ็มบีไทย|ซีไอเอ็มบี|ทิสโก้|แลนด์ แอนด์ เฮ้าส์)', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:PromptPay|พร้อมเพย์)', caseSensitive: false), '')
        .replaceAll(RegExp(r'[xX*]{3,}[-xX*0-9]+', caseSensitive: false), '')
        .trim();
  }

  /// ค้นหารายการเดิมที่ตรงกับสลิปนี้ (ถ้ามี)
  static TransactionItem? findDuplicateTransaction(BankSlipData slip, List<TransactionItem> transactions) {
    for (final t in transactions) {
      // 1. ตรวจสอบรหัสอ้างอิง
      if (slip.referenceNo != null && slip.referenceNo!.isNotEmpty) {
        if (t.id.contains(slip.referenceNo!) || (t.note != null && t.note!.contains(slip.referenceNo!))) {
          return t;
        }
      }

      // 2. ตรวจสอบยอดเงิน และวันเวลาที่ตรงกัน (ความคลาดเคลื่อนไม่เกิน 2 นาที)
      if ((t.amount - slip.amount).abs() < 0.01) {
        final diff = t.date.difference(slip.transactionDate).inMinutes.abs();
        if (diff <= 2) {
          return t;
        }
      }
    }
    return null;
  }

  /// ตรวจสอบว่าสลิปนี้เคยถูกบันทึกไปแล้วหรือไม่ (ป้องกันการบันทึกซ้ำ)
  static bool isDuplicate(BankSlipData slip, List<TransactionItem> transactions) {
    return findDuplicateTransaction(slip, transactions) != null;
  }
}


/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100%
typedef KrungthaiSlipParser = BankSlipParser;
