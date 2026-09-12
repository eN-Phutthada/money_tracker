import '../models/krungthai_slip_model.dart';
import '../models/transaction_model.dart';
import 'slip_category_predictor.dart';

/// เครื่องยนต์ Regular Expression และ Semantic Analysis สำหรับถอดรหัสสลิปธนาคารกรุงไทย
class KrungthaiSlipParser {
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
    if (lower.contains('truemoney') || lower.contains('ทรูมันนี่') || lower.contains('true money')) {
      return 'ทรูมันนี่ (TrueMoney Wallet)';
    }
    if (lower.contains('เป๋าตัง') || lower.contains('paotang')) {
      return 'ธนาคารกรุงไทย (เป๋าตัง)';
    }
    // ค่าเริ่มต้นเป็นกรุงไทย NEXT (หลัก)
    return 'ธนาคารกรุงไทย (Krungthai NEXT)';
  }

  /// แปลงข้อความสลิปเป็น `KrungthaiSlipData`
  static KrungthaiSlipData parse(String rawText) {
    final normalized = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
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

    return KrungthaiSlipData(
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

    // 1. ค้นหาบรรทัดที่มีคีย์เวิร์ดจำนวนเงินบนบรรทัดเดียวกัน
    final amountKeywordRegex = RegExp(
      r'(?:จำนวนเงิน|จํานวนเงิน|ยอดเงิน|ยอดโอน|จำนวนโอน|จำนวน|จํานวน|Amount|Total|Amt|Transfer\s*Amount)\s*[:：\-]?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|\.[0-9]{1,2}|[0-9]+)\s*(?:บาท|บ\.|THB|baht)?',
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

        // ค้นหาในบรรทัดถัดไป 1-4 บรรทัด ข้ามบรรทัด Label ค่าธรรมเนียม
        for (int step = 1; step <= 4 && (i + step) < normalizedLines.length; step++) {
          final candidateLine = normalizedLines[i + step];
          if (candidateLine.contains('ค่าธรรมเนียม') || candidateLine.toLowerCase().contains('fee')) {
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

    // ตรวจสอบเดือนภาษาไทย
    final thaiMonths = {
      'ม.ค.': 1, 'มกราคม': 1,
      'ก.พ.': 2, 'กุมภาพันธ์': 2,
      'มี.ค.': 3, 'มีนาคม': 3,
      'เม.ย.': 4, 'เมษายน': 4,
      'พ.ค.': 5, 'พฤษภาคม': 5,
      'มิ.ย.': 6, 'มิถุนายน': 6,
      'ก.ค.': 7, 'กรกฎาคม': 7,
      'ส.ค.': 8, 'สิงหาคม': 8,
      'ก.ย.': 9, 'กันยายน': 9,
      'ต.ค.': 10, 'ตุลาคม': 10,
      'พ.ย.': 11, 'พฤศจิกายน': 11,
      'ธ.ค.': 12, 'ธันวาคม': 12,
    };

    final engMonths = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    // 1. ตรวจหาคู่ "วันที่แบบไทย + เวลา" ในบรรทัดเดียวกัน (Compound Thai Date-Time)
    // ตัวอย่าง: "วันที่ทำรายการ 02 ส.ค. 2569 - 22:02", "2 ส.ค. 69 เวลา 22.02 น.", "02 สิงหาคม 2569 / 22:02:30"
    final thaiMonthPattern = thaiMonths.keys.map(RegExp.escape).join('|');
    final compoundThaiRegex = RegExp(
      '(\\d{1,2})\\s*($thaiMonthPattern)\\s*(\\d{2,4})\\s*(?:[-–—,\\s/|•@·]+|(?:[-–—,\\s/|•@·]*เวลา\\s*[:：]?\\s*))(\\d{1,2})[:.](\\d{2})(?:[:.](\\d{2}))?\\s*(?:น\\.|น)?',
      caseSensitive: false,
    );

    final compoundMatch = compoundThaiRegex.firstMatch(fullText);
    if (compoundMatch != null) {
      day = int.tryParse(compoundMatch.group(1)!);
      month = thaiMonths[compoundMatch.group(2)!];
      final rawYear = int.tryParse(compoundMatch.group(3)!);
      if (rawYear != null) year = parseYear(rawYear);
      hour = int.tryParse(compoundMatch.group(4)!);
      minute = int.tryParse(compoundMatch.group(5)!);
      second = compoundMatch.group(6) != null ? int.tryParse(compoundMatch.group(6)!) : 0;

      if (day != null && month != null && year != null && hour != null && minute != null) {
        return DateTime(year, month, day, hour, minute, second ?? 0);
      }
    }

    // 2. ตรวจหาคู่ "วันที่แบบอังกฤษ + เวลา"
    // ตัวอย่าง: "02 Aug 2026 22:02:15", "2 Sep 2026, 22.02"
    final compoundEngRegex = RegExp(
      r'(\d{1,2})\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*(\d{2,4})\s*[-–—,\s/|•@·]+\s*(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?',
      caseSensitive: false,
    );
    final engMatch = compoundEngRegex.firstMatch(fullText);
    if (engMatch != null) {
      day = int.tryParse(engMatch.group(1)!);
      month = engMonths[engMatch.group(2)!.toLowerCase()];
      final rawYear = int.tryParse(engMatch.group(3)!);
      if (rawYear != null) year = parseYear(rawYear);
      hour = int.tryParse(engMatch.group(4)!);
      minute = int.tryParse(engMatch.group(5)!);
      second = engMatch.group(6) != null ? int.tryParse(engMatch.group(6)!) : 0;

      if (day != null && month != null && year != null && hour != null && minute != null) {
        return DateTime(year, month, day, hour, minute, second ?? 0);
      }
    }

    // 3. ตรวจหาคู่ "วันที่แบบตัวเลข + เวลา"
    // ตัวอย่าง: "02/08/2569 22:02", "02/08/2026 - 22.02"
    final compoundNumRegex = RegExp(
      r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\s*[-–—,\s/|•@·]+\s*(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?',
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
        return DateTime(year, month, day, hour, minute, second ?? 0);
      }
    }

    // 4. กรณีวันที่และเวลาอยู่คนละบรรทัดกัน (Multi-line Contextual Parsing)
    // 4.1 ค้นหาบรรทัดวันที่
    int? dateLineIndex;
    final thaiDateOnlyRegex = RegExp(
      '(\\d{1,2})\\s*($thaiMonthPattern)\\s*(\\d{2,4})',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final m = thaiDateOnlyRegex.firstMatch(line);
      if (m != null) {
        day = int.tryParse(m.group(1)!);
        month = thaiMonths[m.group(2)!];
        final rawYear = int.tryParse(m.group(3)!);
        if (rawYear != null) year = parseYear(rawYear);
        dateLineIndex = i;
        break;
      }
    }

    if (dateLineIndex == null) {
      final engDateOnlyRegex = RegExp(
        r'(\d{1,2})\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*(\d{2,4})',
        caseSensitive: false,
      );
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final m = engDateOnlyRegex.firstMatch(line);
        if (m != null) {
          day = int.tryParse(m.group(1)!);
          month = engMonths[m.group(2)!.toLowerCase()];
          final rawYear = int.tryParse(m.group(3)!);
          if (rawYear != null) year = parseYear(rawYear);
          dateLineIndex = i;
          break;
        }
      }
    }

    if (dateLineIndex == null) {
      final numDateOnlyRegex = RegExp(r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})');
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

    // 4.2 สกัดเวลาที่เกี่ยวข้องกับบรรทัดวันที่
    final timeContextRegex = RegExp(r'(?:เวลา|Time)?\s*[:：]?\s*(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?\s*(?:น\.|น)?');

    if (dateLineIndex != null) {
      // ตรวจบรรทัดวันที่
      final mSelf = timeContextRegex.firstMatch(lines[dateLineIndex]);
      if (mSelf != null && mSelf.group(1) != null && mSelf.group(2) != null) {
        hour = int.tryParse(mSelf.group(1)!);
        minute = int.tryParse(mSelf.group(2)!);
        second = mSelf.group(3) != null ? int.tryParse(mSelf.group(3)!) : 0;
      }

      // ตรวจบรรทัดถัดไป 1-2 บรรทัด
      if (hour == null) {
        for (int step = 1; step <= 2 && (dateLineIndex + step) < lines.length; step++) {
          final cand = lines[dateLineIndex + step];
          if (cand.contains('บาท') ||
              cand.contains('บ.') ||
              cand.toLowerCase().contains('thb') ||
              cand.contains('จำนวน') ||
              cand.contains('จํานวน') ||
              cand.contains('ค่าธรรมเนียม') ||
              cand.toLowerCase().contains('fee') ||
              cand.toLowerCase().contains('amount') ||
              cand.toLowerCase().contains('total')) {
            continue;
          }
          final mNext = timeContextRegex.firstMatch(cand);
          if (mNext != null && mNext.group(1) != null && mNext.group(2) != null) {
            hour = int.tryParse(mNext.group(1)!);
            minute = int.tryParse(mNext.group(2)!);
            second = mNext.group(3) != null ? int.tryParse(mNext.group(3)!) : 0;
            break;
          }
        }
      }
    }

    // 4.3 หากยังไม่พบเวลา ค้นหาบรรทัดที่มี "เวลา" หรือ "น." ในสลิป (ข้ามบรรทัดแรกเพื่อเลี่ยง status bar ของมือถือ)
    if (hour == null) {
      final explicitTimeRegex = RegExp(r'(?:เวลา|Time)\s*[:：]?\s*(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?|(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?\s*น\.');
      for (int i = 1; i < lines.length; i++) {
        final m = explicitTimeRegex.firstMatch(lines[i]);
        if (m != null) {
          final hStr = m.group(1) ?? m.group(3);
          final mStr = m.group(2) ?? m.group(4);
          final sStr = m.group(5);
          if (hStr != null && mStr != null) {
            hour = int.tryParse(hStr);
            minute = int.tryParse(mStr);
            second = sStr != null ? int.tryParse(sStr) : 0;
            break;
          }
        }
      }
    }

    // 4.4 Fallback ท้ายสุด: หาเวลาใดๆ ในสลิป (เริ่มจากบรรทัดที่ 1 ลงไป เพื่อข้าม status bar)
    // ข้ามบรรทัดที่มีสกุลเงิน บาท / บ. / THB หรือคีย์เวิร์ดจำนวนเงิน/ค่าธรรมเนียม เพื่อไม่ให้ตีเลขเงินทศนิยมเป็นเวลา
    if (hour == null) {
      final fallbackTimeRegex = RegExp(r'(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?');
      final startIndex = lines.length > 1 ? 1 : 0;
      for (int i = startIndex; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('บาท') ||
            line.contains('บ.') ||
            line.toLowerCase().contains('thb') ||
            line.contains('จำนวน') ||
            line.contains('จํานวน') ||
            line.contains('ค่าธรรมเนียม') ||
            line.toLowerCase().contains('fee') ||
            line.toLowerCase().contains('amount') ||
            line.toLowerCase().contains('total')) {
          continue;
        }
        final m = fallbackTimeRegex.firstMatch(line);
        if (m != null) {
          final h = int.tryParse(m.group(1)!);
          final min = int.tryParse(m.group(2)!);
          if (h != null && min != null && h >= 0 && h <= 23 && min >= 0 && min <= 59) {
            hour = h;
            minute = min;
            second = m.group(3) != null ? int.tryParse(m.group(3)!) : 0;
            break;
          }
        }
      }
    }

    if (day != null && month != null && year != null) {
      return DateTime(
        year,
        month,
        day,
        hour ?? 0,
        minute ?? 0,
        second ?? 0,
      );
    } else if (hour != null && minute != null) {
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        second ?? 0,
      );
    }

    return null;
  }

  /// สกัดเลขที่รายการ / รหัสอ้างอิง
  static String? _extractReferenceNumber(String fullText, List<String> lines) {
    // 1. ค้นหาบรรทัดที่มีคีย์เวิร์ด
    final refKeywordRegex = RegExp(
      r'(?:รหัสอ้างอิง|เลขที่รายการ|รหัสทำรายการ|Ref(?:\s*No)?|Transaction\s*ID)\s*[:：\-]?\s*([A-Za-z0-9]{8,30})',
      caseSensitive: false,
    );
    final match = refKeywordRegex.firstMatch(fullText);
    if (match != null) {
      return match.group(1);
    }

    // 2. ค้นหาในบรรทัดถัดไปหลังจากเจอคีย์เวิร์ด
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('รหัสอ้างอิง') || line.contains('เลขที่รายการ') || line.toLowerCase().contains('ref')) {
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].replaceAll(' ', '');
          final m = RegExp(r'^([A-Za-z0-9]{8,30})$').firstMatch(nextLine);
          if (m != null) return m.group(1);
        }
      }
    }

    // 3. ตรวจจับรหัสธุรกรรม Krungthai NEXT (มักเริ่มต้นด้วยปี ค.ศ. เช่น 2026... หรือ KTB...)
    final ktbIdRegex = RegExp(r'\b(202\d{13,22}|KTB\d{10,20})\b');
    final idMatch = ktbIdRegex.firstMatch(fullText);
    if (idMatch != null) {
      return idMatch.group(1);
    }

    return null;
  }

  /// สกัดชื่อผู้โอน (จาก / From)
  static String? _extractSender(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line == 'จาก' || line.startsWith('จาก:') || line.startsWith('จาก ') || line.toLowerCase().startsWith('from:') || line.toLowerCase().startsWith('from ')) {
        // ถัดจากคีย์เวิร์ดในบรรทัดเดียวกัน
        final inline = line.replaceFirst(RegExp(r'^(?:จาก|from)\s*[:：]?\s*', caseSensitive: false), '').trim();
        if (inline.isNotEmpty && !inline.contains('xxx-')) return _cleanName(inline);
        // ในบรรทัดถัดไป
        if (i + 1 < lines.length) {
          final candidate = lines[i + 1].trim();
          if (!candidate.contains('xxx-') && !candidate.contains('กรุงไทย') && candidate.length > 2) {
            return _cleanName(candidate);
          }
        }
      }
    }
    return null;
  }

  /// สกัดเลขบัญชีผู้โอน (ถ้ามี)
  static String? _extractSenderAccount(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line == 'จาก' || line.startsWith('จาก:') || line.startsWith('จาก ') || line.toLowerCase().startsWith('from:')) {
        for (int j = i + 1; j <= i + 3 && j < lines.length; j++) {
          final l = lines[j].trim();
          if (RegExp(r'[xX0-9\-]{8,20}').hasMatch(l)) {
            return l;
          }
        }
      }
    }
    return null;
  }

  /// สกัดชื่อผู้รับเงิน (ไปยัง / To)
  static String? _extractReceiver(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line == 'ไปยัง' || line.startsWith('ไปยัง:') || line.startsWith('ไปยัง ') || line.toLowerCase().startsWith('to:') || line.toLowerCase().startsWith('to ')) {
        // ถัดจากคีย์เวิร์ดในบรรทัดเดียวกัน
        final inline = line.replaceFirst(RegExp(r'^(?:ไปยัง|to)\s*[:：]?\s*', caseSensitive: false), '').trim();
        if (inline.isNotEmpty && !inline.contains('xxx-')) return _cleanName(inline);
        // ในบรรทัดถัดไป
        if (i + 1 < lines.length) {
          final candidate = lines[i + 1].trim();
          if (!candidate.contains('xxx-') && !candidate.contains('พร้อมเพย์') && candidate.length > 2) {
            return _cleanName(candidate);
          }
        }
      }
    }
    return null;
  }

  /// สกัดเลขบัญชีหรือเลขพร้อมเพย์ผู้รับ (ถ้ามี)
  static String? _extractReceiverAccount(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line == 'ไปยัง' || line.startsWith('ไปยัง:') || line.startsWith('ไปยัง ') || line.toLowerCase().startsWith('to:')) {
        for (int j = i + 1; j <= i + 3 && j < lines.length; j++) {
          final l = lines[j].trim();
          if (RegExp(r'[xX0-9\s\-]{8,22}').hasMatch(l) && !l.contains('บาท') && !l.contains('THB')) {
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
        .replaceAll(RegExp(r'ธ\.(?:กรุงไทย|กสิกรไทย|ไทยพาณิชย์|กรุงเทพ|กรุงศรีอยุธยา|กรุงศรี|ออมสิน|ก\.ส\.|ทหารไทยธนชาต)', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:PromptPay|พร้อมเพย์)', caseSensitive: false), '')
        .replaceAll(RegExp(r'xxx[-x0-9]+', caseSensitive: false), '')
        .trim();
  }

  /// ค้นหารายการเดิมที่ตรงกับสลิปนี้ (ถ้ามี)
  static TransactionItem? findDuplicateTransaction(KrungthaiSlipData slip, List<TransactionItem> transactions) {
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
  static bool isDuplicate(KrungthaiSlipData slip, List<TransactionItem> transactions) {
    return findDuplicateTransaction(slip, transactions) != null;
  }
}
