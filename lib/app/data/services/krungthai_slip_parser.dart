import '../models/krungthai_slip_model.dart';
import '../models/transaction_model.dart';

/// เครื่องยนต์ Regular Expression และ Semantic Analysis สำหรับถอดรหัสสลิปธนาคารกรุงไทย
class KrungthaiSlipParser {
  /// ตรวจสอบว่าเป็นข้อความสลิปของธนาคารกรุงไทยหรือไม่
  static bool isKrungthaiSlip(String text) {
    final lower = text.toLowerCase();
    return lower.contains('กรุงไทย') ||
        lower.contains('krungthai') ||
        lower.contains('ktb') ||
        lower.contains('006') ||
        lower.contains('เป๋าตัง') ||
        lower.contains('โอนเงินสำเร็จ') ||
        lower.contains('transfer successful');
  }

  /// แปลงข้อความสลิปเป็น `KrungthaiSlipData`
  static KrungthaiSlipData parse(String rawText) {
    final normalized = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final isKrungthai = isKrungthaiSlip(normalized);
    final amount = _extractAmount(normalized, lines);
    final date = _extractDateTime(normalized) ?? DateTime.now();
    final refNo = _extractReferenceNumber(normalized, lines);
    final sender = _extractSender(lines);
    final senderAccount = _extractSenderAccount(lines);
    final receiver = _extractReceiver(lines);
    final receiverAccount = _extractReceiverAccount(lines);
    final memo = _extractMemo(lines);

    String bankName = 'ธนาคารกรุงไทย';
    if (normalized.toLowerCase().contains('next')) {
      bankName = 'ธนาคารกรุงไทย (Krungthai NEXT)';
    } else if (normalized.toLowerCase().contains('เป๋าตัง')) {
      bankName = 'ธนาคารกรุงไทย (เป๋าตัง)';
    }

    final suggested = _classifyCategoryAndNature(memo, receiver, normalized);

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
      suggestedCategory: suggested.category,
      suggestedType: suggested.type,
      suggestedCostNature: suggested.costNature,
      rawText: rawText,
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

  /// สกัดวันและเวลา (Date & Time)
  static DateTime? _extractDateTime(String fullText) {
    int? day, month, year, hour, minute, second;

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

    // 1. วันที่แบบไทย: "11 ก.ย. 2569" หรือ "11 ก.ย. 69"
    final thaiDateRegex = RegExp(
      r'(\d{1,2})\s*(ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.|มกราคม|กุมภาพันธ์|มีนาคม|เมษายน|พฤษภาคม|มิถุนายน|กรกฎาคม|สิงหาคม|กันยายน|ตุลาคม|พฤศจิกายน|ธันวาคม)\s*(\d{2,4})',
    );
    final thaiMatch = thaiDateRegex.firstMatch(fullText);
    if (thaiMatch != null) {
      day = int.tryParse(thaiMatch.group(1)!);
      month = thaiMonths[thaiMatch.group(2)!];
      final rawYear = int.tryParse(thaiMatch.group(3)!);
      if (rawYear != null) {
        if (rawYear >= 2500) {
          year = rawYear - 543;
        } else if (rawYear >= 60 && rawYear <= 99) {
          year = (2500 + rawYear) - 543;
        } else if (rawYear >= 2000) {
          year = rawYear;
        } else {
          year = 2000 + rawYear;
        }
      }
    }

    // 2. วันที่แบบอังกฤษ: "11 Sep 2026"
    if (day == null || month == null || year == null) {
      final engDateRegex = RegExp(
        r'(\d{1,2})\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*(\d{2,4})',
        caseSensitive: false,
      );
      final engMatch = engDateRegex.firstMatch(fullText);
      if (engMatch != null) {
        day = int.tryParse(engMatch.group(1)!);
        month = engMonths[engMatch.group(2)!.toLowerCase()];
        final rawYear = int.tryParse(engMatch.group(3)!);
        if (rawYear != null) {
          year = rawYear > 2500 ? rawYear - 543 : (rawYear < 100 ? 2000 + rawYear : rawYear);
        }
      }
    }

    // 3. วันที่แบบตัวเลข: "11/09/2026" หรือ "11/09/2569"
    if (day == null || month == null || year == null) {
      final numDateRegex = RegExp(r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})');
      final numMatch = numDateRegex.firstMatch(fullText);
      if (numMatch != null) {
        day = int.tryParse(numMatch.group(1)!);
        month = int.tryParse(numMatch.group(2)!);
        final rawYear = int.tryParse(numMatch.group(3)!);
        if (rawYear != null) {
          year = rawYear > 2500 ? rawYear - 543 : (rawYear < 100 ? 2000 + rawYear : rawYear);
        }
      }
    }

    // สกัดเวลา: "14:35:22" หรือ "14:35"
    final timeRegex = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?');
    final timeMatch = timeRegex.firstMatch(fullText);
    if (timeMatch != null) {
      hour = int.tryParse(timeMatch.group(1)!);
      minute = int.tryParse(timeMatch.group(2)!);
      second = timeMatch.group(3) != null ? int.tryParse(timeMatch.group(3)!) : 0;
    }

    if (day != null && month != null && year != null) {
      return DateTime(
        year,
        month,
        day,
        hour ?? DateTime.now().hour,
        minute ?? DateTime.now().minute,
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
        .replaceAll('ธ.กรุงไทย', '')
        .replaceAll('พร้อมเพย์', '')
        .replaceAll(RegExp(r'xxx[-x0-9]+', caseSensitive: false), '')
        .trim();
  }

  /// จำแนกหมวดหมู่อัตโนมัติด้วย Semantic Keyword Matching
  static _CategoryClassification _classifyCategoryAndNature(String? memo, String? receiver, [String? fullText]) {
    final combined = '${memo ?? ''} ${receiver ?? ''} ${fullText ?? ''}'.toLowerCase();

    // 1. อาหารและเครื่องดื่ม
    if (_containsAny(combined, ['ข้าว', 'อาหาร', 'กิน', 'ก๋วยเตี๋ยว', 'ขนม', 'ชาบู', 'ส้มตำ', 'lunch', 'dinner', 'food', 'meal', 'กะเพรา', 'หมูกระทะ', 'เซเว่น', '7-eleven', '7-11'])) {
      return const _CategoryClassification('อาหาร/ของกิน', TransactionType.expense, CostNature.variable);
    }
    if (_containsAny(combined, ['กาแฟ', 'ชา', 'cafe', 'coffee', 'starbucks', 'amazon', 'tea', 'ชานม', 'เต่าบิน'])) {
      return const _CategoryClassification('กาแฟ/เครื่องดื่ม', TransactionType.expense, CostNature.variable);
    }

    // 2. การเดินทาง
    if (_containsAny(combined, ['bts', 'mrt', 'grab', 'bolt', 'น้ำมัน', 'แท็กซี่', 'ค่าทางด่วน', 'ตั๋ว', 'ปตท', 'บางจาก', 'shell', 'caltex', 'วิน', 'รถไฟ'])) {
      return const _CategoryClassification('การเดินทาง', TransactionType.expense, CostNature.variable);
    }

    // 3. ที่อยู่อาศัย & สาธารณูปโภค (Fixed Costs)
    if (_containsAny(combined, ['ค่าห้อง', 'ค่าเช่า', 'หอ', 'คอนโด', 'rent', 'นิติ'])) {
      return const _CategoryClassification('ที่อยู่อาศัย', TransactionType.expense, CostNature.fixed);
    }
    if (_containsAny(combined, ['ค่าน้ำ', 'ค่าไฟ', 'การไฟฟ้านครหลวง', 'การประปา', 'pea', 'mea', 'เน็ต', 'internet', 'โทรศัพท์', 'ais', 'true', 'dtac', 'nt broadband', 'tot'])) {
      return const _CategoryClassification('สาธารณูปโภค', TransactionType.expense, CostNature.fixed);
    }

    // 4. สุขภาพ & ยา
    if (_containsAny(combined, ['ยา', 'หมอ', 'คลินิก', 'โรงพยาบาล', 'hospital', 'pharmacy', 'ทันตกรรม', 'ฟัน'])) {
      return const _CategoryClassification('สุขภาพ/ยา', TransactionType.expense, CostNature.variable);
    }

    // 5. การศึกษา
    if (_containsAny(combined, ['เรียน', 'หนังสือ', 'คอร์ส', 'course', 'tuition', 'ค่าเทอม', 'มหาลัย'])) {
      return const _CategoryClassification('การศึกษา', TransactionType.expense, CostNature.variable);
    }

    // 6. เงินออมและการลงทุน
    if (_containsAny(combined, ['ออม', 'dca', 'กองทุน', 'หุ้น', 'savings', 'invest', 'สลาก', 'ทอง', 'crypto', 'binance', 'innovestx', 'dime'])) {
      return const _CategoryClassification('เงินออม/DCA', TransactionType.savingsInvestment, CostNature.notApplicable);
    }

    // 7. ช้อปปิ้ง
    if (_containsAny(combined, ['shopee', 'lazada', 'tiktok', 'เสื้อ', 'กางเกง', 'รองเท้า', 'ของเล่น', 'uniqlo', 'zara', 'shop', 'หูฟัง'])) {
      return const _CategoryClassification('ช้อปปิ้ง', TransactionType.expense, CostNature.variable);
    }

    // 8. บันเทิง/พักผ่อน (รวมบริการสตรีมมิ่ง เกม และตั๋วภาพยนตร์)
    if (_containsAny(combined, [
      'netflix',
      'spotify',
      'youtube',
      'สตรีมมิ่ง',
      'streaming',
      'เอ็นเอฟ',
      'nf',
      'disney',
      'prime',
      'hbo',
      'apple tv',
      'ตั๋วหนัง',
      'major',
      'sf',
      'เกม',
      'steam',
      'game',
    ])) {
      return const _CategoryClassification('บันเทิง/พักผ่อน', TransactionType.expense, CostNature.variable);
    }

    // ค่าเริ่มต้น
    return const _CategoryClassification('อื่นๆ', TransactionType.expense, CostNature.variable);
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final k in keywords) {
      if (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(k)) {
        final reg = RegExp(r'\b' + RegExp.escape(k) + r'\b', caseSensitive: false);
        if (reg.hasMatch(text)) return true;
      } else {
        if (text.contains(k)) return true;
      }
    }
    return false;
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

class _CategoryClassification {
  final String category;
  final TransactionType type;
  final CostNature costNature;

  const _CategoryClassification(this.category, this.type, this.costNature);
}
