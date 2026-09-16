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

  /// ตรวจสอบว่าเป็นข้อความสลิปโอนเงินของธนาคารหรือใบเสร็จรับเงิน (เช่น 7-Eleven) หรือไม่
  static bool isValidBankSlip(String text) {
    final lower = text.toLowerCase();
    return isKrungthaiSlip(text) ||
        lower.contains('7-eleven') ||
        lower.contains('7-11') ||
        lower.contains('เซเว่น') ||
        lower.contains('ซีพี ออลล์') ||
        lower.contains('ซีพีออลล์') ||
        lower.contains('cp all') ||
        lower.contains('cpall') ||
        lower.contains('ใบเสร็จรับเงิน') ||
        lower.contains('ใบกำกับภาษีอย่างย่อ') ||
        lower.contains('tax inv') ||
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

  /// ตรวจสอบว่าเป็นใบเสร็จรับเงินร้านค้า (เช่น 7-Eleven, ซูเปอร์มาร์เก็ต) หรือไม่
  static bool isStoreReceipt(String text) {
    final lower = text.toLowerCase();
    return is7ElevenSlip(text) ||
        lower.contains('ใบเสร็จรับเงิน') ||
        lower.contains('ใบกำกับภาษีอย่างย่อ') ||
        lower.contains('tax invoice (abb)') ||
        lower.contains('tax inv (abb)') ||
        lower.contains('tax inv(abb)') ||
        lower.contains('abb no') ||
        lower.contains('abb.') ||
        lower.contains('ยอดสุทธิ') ||
        lower.contains('ยอดเงินสุทธิ') ||
        lower.contains('รวมเงินสุทธิ') ||
        RegExp(r'\bnet\s*total\b', caseSensitive: false).hasMatch(lower);
  }

  /// ตรวจสอบว่าเป็นใบเสร็จ 7-Eleven หรือไม่ (รองรับทุกสำนวนและการสะกดของ OCR)
  static bool is7ElevenSlip(String text) {
    final lower = text.toLowerCase();
    return lower.contains('7-eleven') ||
        lower.contains('7 eleven') ||
        lower.contains('7-11') ||
        lower.contains('7 11') ||
        lower.contains('เซเว่น') ||
        lower.contains('ซีพี ออลล์') ||
        lower.contains('ซีพีออลล์') ||
        lower.contains('cp all') ||
        lower.contains('cpall') ||
        lower.contains('seven eleven') ||
        lower.contains('seven-eleven') ||
        lower.contains('all member') ||
        lower.contains('allmember') ||
        lower.contains('cp-all') ||
        lower.contains('c.p. all') ||
        lower.contains('c.p.all') ||
        lower.contains('7-e1even') ||
        lower.contains('7e1even') ||
        lower.contains('7eleven');
  }

  /// ตรวจจับชื่อธนาคาร/ร้านค้าจากข้อความสลิปหรือใบเสร็จ (รองรับทุกธนาคาร และ 7-Eleven)
  static String detectBankName(String fullText) {
    if (is7ElevenSlip(fullText)) {
      return '7-Eleven';
    }
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
  static BankSlipData parse(
    String rawText, {
    String? userProfileName,
  }) {
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
    final isStore = isStoreReceipt(normalized);
    final receiptItems = isStore ? _extractReceiptItems(lines) : <_ReceiptParsedItem>[];
    final amount = _extractAmount(normalized, lines, receiptItems);
    final dateResult = _extractDateTime(normalized, lines);
    final date = dateResult?.dateTime ?? DateTime.now();
    final hasParsedDateTime = dateResult != null;
    final hasParsedTime = dateResult?.hasTime ?? false;
    final refNo = _extractReferenceNumber(normalized, lines);
    final sender = _extractSender(lines);
    final senderAccount = _extractSenderAccount(lines);
    final receiver = _extractReceiver(lines);
    final receiverAccount = _extractReceiverAccount(lines);
    final memo = _extractMemo(lines, receiptItems: receiptItems);

    final prediction = SlipCategoryPredictor.predict(
      memo: memo,
      receiverName: receiver,
      senderName: sender,
      userProfileName: userProfileName,
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
      hasParsedDateTime: hasParsedDateTime,
      hasParsedTime: hasParsedTime,
      predictionConfidence: prediction.confidence,
      predictionReason: prediction.reason,
      receiptItems: receiptItems.map((e) => e.name).toList(),
    );
  }

  /// สกัดยอดเงิน (Amount) ด้วย Multi-Tier Recognition Engine รองรับทั้งใบเสร็จรับเงิน และสลิปธนาคาร
  static double _extractAmount(
    String fullText,
    List<String> lines, [
    List<_ReceiptParsedItem>? parsedItems,
  ]) {
    // 0. ปรับข้อความภาษาไทยให้อยู่ในรูปมาตรฐาน (Normalize Nikhahit U+0E4D + Sara Aa U+0E32 -> Sara Am U+0E33)
    final normalizedText = fullText.replaceAll('\u0E4D\u0E32', '\u0E33');
    final normalizedLines = lines.map((l) => l.replaceAll('\u0E4D\u0E32', '\u0E33')).toList();

    // หากเป็นใบเสร็จรับเงิน (เช่น 7-Eleven, Tops, ร้านค้า) หรือข้อความมีคีย์เวิร์ดยอดสุทธิ ให้ใช้อัลกอริทึมสำหรับใบเสร็จโดยเฉพาะ
    if (isStoreReceipt(normalizedText) ||
        normalizedText.contains('ยอดสุทธิ') ||
        normalizedText.contains('รวมสุทธิ') ||
        normalizedText.contains('ยอดเงินสุทธิ') ||
        normalizedText.contains('รวมเงินสุทธิ') ||
        RegExp(r'\bnet\s*total\b', caseSensitive: false).hasMatch(normalizedText)) {
      final receiptAmt = _extractReceiptAmount(
        normalizedText,
        normalizedLines,
        parsedItems ?? _extractReceiptItems(normalizedLines),
      );
      if (receiptAmt > 0) return receiptAmt;
    }

    // 1. ค้นหาบรรทัดที่มีคีย์เวิร์ดยอดสุทธิบนบรรทัดเดียวกันเป็นลำดับแรก (Net Total ก่อน Gross Total เสมอ)
    final netKeywordRegex = RegExp(
      r'(?:ยอดสุทธิ|รวมสุทธิ|ยอดเงินสุทธิ|รวมเงินสุทธิ|มูลค่าสุทธิ|Net\s*Total|Total\s*Net|Net\s*Amount|Net\s*Amt)(?:\s*\((?:บาท|THB|baht|บ\.|[^\)]+)\))?\s*[:：\-]?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|\.[0-9]{1,2}|[0-9]+)\s*(?:บาท|บ\.|THB|baht)?',
      caseSensitive: false,
    );
    for (final match in netKeywordRegex.allMatches(normalizedText)) {
      final str = match.group(1)?.replaceAll(',', '');
      if (str != null) {
        final val = double.tryParse(str);
        if (val != null && val > 0) return val;
      }
    }

    // 2. ค้นหาบรรทัดที่มีคีย์เวิร์ดจำนวนเงินทั่วไปบนบรรทัดเดียวกัน (สำหรับสลิปธนาคาร)
    final amountKeywordRegex = RegExp(
      r'(?:รวมทั้งสิ้น|รวมเงิน|จำนวนเงิน|จํานวนเงิน|ยอดเงิน|ยอดโอน|จำนวนโอน|Total|Amount|Amt|Transfer\s*Amount)(?:\s*\((?:บาท|THB|baht|บ\.|[^\)]+)\))?\s*[:：\-]?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|\.[0-9]{1,2}|[0-9]+)\s*(?:บาท|บ\.|THB|baht)?',
      caseSensitive: false,
    );
    for (final match in amountKeywordRegex.allMatches(normalizedText)) {
      final str = match.group(1)?.replaceAll(',', '');
      if (str != null) {
        final val = double.tryParse(str);
        if (val != null && val > 0) return val;
      }
    }

    // 3. ค้นหาบรรทัดที่มีคีย์เวิร์ด และดูบรรทัดถัดไป 1 - 4 บรรทัด (รองรับ Columnar OCR ที่ฝั่งซ้ายเป็น Label ฝั่งขวาเป็นตัวเลข)
    for (int i = 0; i < normalizedLines.length; i++) {
      final line = normalizedLines[i].toLowerCase();
      final isAmountLine = line.contains('ยอดสุทธิ') ||
          line.contains('รวมเงิน') ||
          line.contains('ยอดรวม') ||
          line.contains('รวมทั้งสิ้น') ||
          line.contains('จำนวนเงิน') ||
          line.contains('จํานวนเงิน') ||
          line.contains('ยอดเงิน') ||
          line.contains('ยอดโอน') ||
          line.contains('amount') ||
          (line.contains('total') && !line.contains('item'));

      if (isAmountLine) {
        // ตรวจในบรรทัดเดียวกัน
        final inlineNum = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)').firstMatch(line);
        if (inlineNum != null) {
          final val = double.tryParse(inlineNum.group(1)!.replaceAll(',', ''));
          if (val != null && val > 0) return val;
        }

        // ค้นหาในบรรทัดถัดไป 1-4 บรรทัด ข้ามบรรทัด Label ค่าธรรมเนียม เงินสด เงินทอน หรือ VAT
        for (int step = 1; step <= 4 && (i + step) < normalizedLines.length; step++) {
          final candidateLine = normalizedLines[i + step].trim();
          if (candidateLine.contains('ค่าธรรมเนียม') ||
              candidateLine.contains('เงินสด') ||
              candidateLine.contains('เงินทอน') ||
              candidateLine.toLowerCase().contains('cash') ||
              candidateLine.toLowerCase().contains('change') ||
              candidateLine.toLowerCase().contains('vat') ||
              candidateLine.toLowerCase().contains('tax') ||
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

    // 4. ค้นหาตัวเลขทศนิยมสองตำแหน่งที่มีหน่วยสกุลเงิน บาท / บ. / THB กำกับ
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

    // 5. ค้นหาตัวเลขทศนิยม 2 ตำแหน่งทั้งหมดในสลิป (Fallback สำหรับ OCR ภาษาอังกฤษ/ละตินที่ไม่สามารถอ่านตัวอักษรไทยได้)
    final allDecimals = RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})\b')
        .allMatches(normalizedText)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0.0)
        .where((val) => val > 0)
        .toList();

    if (allDecimals.isNotEmpty) {
      return allDecimals.first;
    }

    // 6. Fallback ตัวเลขจำนวนเต็มพร้อมสกุลเงิน (เช่น 139 บาท)
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

  /// สกัดยอดเงินจากใบเสร็จรับเงิน (Receipt / 7-Eleven) ด้วยการเน้น "ยอดสุทธิ" (Net Total) เป็นอันดับแรก
  /// ป้องกันการอ่านยอดผิดพลาดจาก VAT (รวมในยอดสุทธิ), ยอดรวมก่อนหักส่วนลด (รวมเป็นเงิน), เงินสด หรือคะแนนสมาชิก
  static double _extractReceiptAmount(
    String fullText,
    List<String> lines,
    List<_ReceiptParsedItem> items,
  ) {
    final normalizedLines = lines.map((l) => l.replaceAll('\u0E4D\u0E32', '\u0E33')).toList();

    // ตัวกรองเพื่อข้ามบรรทัดที่ไม่ใช่ยอดสุทธิอย่างเด็ดขาด (VAT, คะแนนสมาชิก ALL Member, ส่วนลด, เงินสด/เงินทอน, แพ็กเกจเน็ต)
    bool isInvalidNetTotalLine(String rawLine) {
      final l = rawLine.toLowerCase();

      // 1. ตรวจจับและข้ามบรรทัด VAT อย่างเด็ดขาด (เช่น "V=VAT 7% รวมในยอดสุทธิ 5.82", "(V) รวมในยอดสุทธิ", "ภาษีมูลค่าเพิ่ม รวมในยอดสุทธิ")
      if (l.contains('รวมใน') ||
          l.contains('vat') ||
          l.contains('ภาษี') ||
          l.contains('tax') ||
          l.contains('7%') ||
          l.contains('(v)') ||
          l.contains('v=')) {
        return true;
      }

      // 2. ตรวจจับและข้ามคะแนนสะสม ALL Member (เช่น "คะแนนสะสมสุทธิ 1250", "ยอดคะแนนสุทธิ", "แต้มสุทธิ")
      if (l.contains('คะแนน') ||
          l.contains('แต้ม') ||
          l.contains('point') ||
          l.contains('points') ||
          l.contains('member') ||
          l.contains('all member') ||
          l.contains('allmember')) {
        return true;
      }

      // 3. ตรวจจับและข้ามบรรทัดส่วนลด (เช่น "ส่วนลด ALL member -10.00", "คูปองส่วนลด", "ลดทันที")
      if (l.contains('ส่วนลด') ||
          l.contains('ลดราคา') ||
          l.contains('ลดทันที') ||
          l.contains('discount') ||
          l.contains('coupon') ||
          l.contains('คูปอง')) {
        return true;
      }

      // 4. ตรวจจับและข้ามบรรทัดเงินสด/เงินทอน/เงินคงเหลือ/สะสม
      if (l.contains('เงินสด') ||
          l.contains('เงินทอน') ||
          l.contains('cash') ||
          l.contains('change') ||
          l.contains('คงเหลือ') ||
          l.contains('balance') ||
          l.contains('สะสม') ||
          l.contains('เติมเงิน') ||
          l.contains('topup') ||
          l.contains('top-up')) {
        return true;
      }

      // 5. ตรวจจับและข้ามบรรทัดระบุจำนวนชิ้น/รายการ และแพ็กเกจเน็ตโฆษณาท้ายบิล
      if (l.contains('รายการ') ||
          l.contains('ชิ้น') ||
          l.contains('item') ||
          l.contains('qty') ||
          l.contains('แพ็กเกจ') ||
          l.contains('package') ||
          l.contains('เน็ต') ||
          l.contains('internet') ||
          l.contains('wifi')) {
        return true;
      }

      return false;
    }

    // ── Tier 1: ค้นหายอดสุทธิแท้จริง (Net Total / ยอดชำระสุทธิ / ยอดเงินสุทธิ) ──
    // สำคัญ: อ่านจากบนลงล่าง หรือเจาะจงบรรทัด ยอดสุทธิ โดยไม่ชนกับบรรทัด VAT ท้ายบิล
    final netTotalPattern = RegExp(
      r'(?:ยอด\s*สุทธิ|ยอด\s*เงิน\s*สุทธิ|รวม\s*เงิน\s*สุทธิ|รวม\s*สุทธิ|ยอด\s*รวม\s*สุทธิ|มูลค่า\s*สุทธิ|ยอด\s*ชำระ\s*สุทธิ|ยอด\s*ชำระ\s*ทั้งสิ้น|ยอด\s*ต้อง\s*ชำระ|ย[อ|ต]ด\s*ส[ทุ]?[ธิ์ฺื]?|net\s*total|total\s*net|net\s*amount|net\s*amt|amount\s*due|total\s*due)',
      caseSensitive: false,
    );

    for (int i = 0; i < normalizedLines.length; i++) {
      final line = normalizedLines[i];
      if (isInvalidNetTotalLine(line)) continue;

      if (netTotalPattern.hasMatch(line)) {
        // 1. ลองดึงตัวเลขที่อยู่หลังคีย์เวิร์ดยอดสุทธิโดยตรงก่อน
        final directMatch = RegExp(
          r'(?:ยอด\s*สุทธิ|ยอด\s*เงิน\s*สุทธิ|รวม\s*เงิน\s*สุทธิ|รวม\s*สุทธิ|ยอด\s*รวม\s*สุทธิ|มูลค่า\s*สุทธิ|ยอด\s*ชำระ\s*สุทธิ|ยอด\s*ชำระ\s*ทั้งสิ้น|ยอด\s*ต้อง\s*ชำระ|ย[อ|ต]ด\s*ส[ทุ]?[ธิ์ฺื]?|net\s*total|total\s*net|net\s*amount|net\s*amt|amount\s*due|total\s*due)\s*[:：\-\s]*([0-9]{1,4}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|\.[0-9]{1,2}|[0-9]+)\s*(?:บาท|บ\.|thb|baht)?',
          caseSensitive: false,
        ).firstMatch(line);

        if (directMatch != null) {
          final str = directMatch.group(1)?.replaceAll(',', '');
          if (str != null) {
            final val = double.tryParse(str);
            if (val != null && val > 0) return val;
          }
        }

        // 2. หากยังไม่พบ ให้ตรวจตัวเลขทศนิยมใดๆ บนบรรทัดเดียวกัน
        final inlineNum = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(line);
        if (inlineNum != null) {
          final val = double.tryParse(inlineNum.group(1)!.replaceAll(',', ''));
          if (val != null && val > 0) return val;
        }

        // 3. กรณี OCR แยกป้ายกำกับกับตัวเลขไว้คนละบรรทัด ให้ตรวจบรรทัดถัดไป 1-3 บรรทัด
        for (int step = 1; step <= 3 && (i + step) < normalizedLines.length; step++) {
          final nextLine = normalizedLines[i + step].trim();
          if (isInvalidNetTotalLine(nextLine)) continue;

          final nextNum = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*(?:\.[0-9]{2})?)').firstMatch(nextLine);
          if (nextNum != null) {
            final val = double.tryParse(nextNum.group(1)!.replaceAll(',', ''));
            if (val != null && val > 0) return val;
          }
        }
      }
    }

    // ── Tier 2: คำนวณยอดสุทธิจาก เงินสด (Cash) - เงินทอน (Change) หรือช่องทางชำระเงินดิจิทัล ──
    double? cashVal;
    double? changeVal;
    for (final line in normalizedLines) {
      final lower = line.toLowerCase();
      if (lower.contains('vat') || lower.contains('ภาษี') || lower.contains('คะแนน') || lower.contains('แต้ม')) {
        continue;
      }
      if (lower.contains('เงินสด') || (lower.contains('cash') && !lower.contains('cashier'))) {
        final m = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(line);
        if (m != null) {
          cashVal = double.tryParse(m.group(1)!.replaceAll(',', ''));
        }
      }
      if (lower.contains('เงินทอน') || lower.contains('change')) {
        final m = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(line);
        if (m != null) {
          changeVal = double.tryParse(m.group(1)!.replaceAll(',', ''));
        }
      }
    }
    if (cashVal != null && changeVal != null && cashVal >= changeVal) {
      final calculatedNet = (cashVal - changeVal);
      final rounded = double.parse(calculatedNet.toStringAsFixed(2));
      if (rounded > 0) return rounded;
    }

    // ตรวจสอบจากช่องทางชำระเงินดิจิทัล (TrueMoney / PromptPay / Credit Card) ซึ่งบนใบเสร็จ 7-Eleven จะเป็นยอดสุทธิเสมอ
    for (final line in normalizedLines) {
      final lower = line.toLowerCase();
      if (lower.contains('vat') || lower.contains('ภาษี') || lower.contains('คะแนน') || lower.contains('แต้ม')) {
        continue;
      }
      if (lower.contains('truemoney') ||
          lower.contains('true money') ||
          (lower.contains('wallet') && !lower.contains('balance')) ||
          lower.contains('promptpay') ||
          lower.contains('พร้อมเพย์') ||
          lower.contains('credit card') ||
          lower.contains('บัตรเครดิต')) {
        final m = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(line);
        if (m != null) {
          final val = double.tryParse(m.group(1)!.replaceAll(',', ''));
          if (val != null && val > 0) return val;
        }
      }
    }

    // ── Tier 3: ตรวจสอบและคำนวณจาก รวมเป็นเงิน (Subtotal) - ส่วนลด (Discount) ──
    double? subtotalVal;
    double? discountVal;
    for (final line in normalizedLines) {
      final lower = line.toLowerCase();
      if (lower.contains('vat') || lower.contains('ภาษี') || lower.contains('คะแนน') || lower.contains('แต้ม') || lower.contains('รวมใน')) {
        continue;
      }
      if (lower.contains('ส่วนลด') || lower.contains('discount') || lower.contains('คูปอง') || lower.contains('ลดทันที')) {
        final m = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(line);
        if (m != null) {
          discountVal = double.tryParse(m.group(1)!.replaceAll(',', ''));
        }
      }
      if ((lower.contains('รวมเป็นเงิน') || lower.contains('subtotal') || lower.contains('รวมเงิน')) &&
          !lower.contains('รายการ') && !lower.contains('ชิ้น') && !lower.contains('สุทธิ')) {
        final m = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(line);
        if (m != null) {
          subtotalVal = double.tryParse(m.group(1)!.replaceAll(',', ''));
        }
      }
    }
    if (subtotalVal != null && discountVal != null && subtotalVal > discountVal) {
      final calculatedNet = subtotalVal - discountVal;
      final rounded = double.parse(calculatedNet.toStringAsFixed(2));
      if (rounded > 0) return rounded;
    }

    // ── Tier 4: รวมเป็นเงิน / รวมทั้งสิ้น / รวมเงิน / ยอดรวม (กรณีไม่มีส่วนลดในใบเสร็จ) ──
    final totalKeywords = [
      'รวมทั้งสิ้น',
      'ยอดรวมทั้งสิ้น',
      'grand total',
      'รวมเป็นเงิน',
      'รวมเงิน',
      'ยอดรวม',
      'จำนวนเงินทั้งสิ้น',
      'จำนวนเงินรวม',
      'subtotal',
      'sub-total',
      'sub total',
      'total',
    ];

    for (int i = 0; i < normalizedLines.length; i++) {
      final line = normalizedLines[i];
      final lower = line.toLowerCase();

      // ข้ามบรรทัด VAT, คะแนน, ส่วนลด, เงินสด, เงินทอน, จำนวนชิ้น
      if (lower.contains('รายการ') ||
          lower.contains('ชิ้น') ||
          lower.contains('item') ||
          lower.contains('vat') ||
          lower.contains('ภาษี') ||
          lower.contains('tax') ||
          lower.contains('7%') ||
          lower.contains('รวมใน') ||
          lower.contains('คะแนน') ||
          lower.contains('แต้ม') ||
          lower.contains('เงินสด') ||
          lower.contains('เงินทอน') ||
          lower.contains('cash') ||
          lower.contains('change') ||
          lower.contains('ส่วนลด') ||
          lower.contains('discount')) {
        continue;
      }

      final hasKeyword = totalKeywords.any((kw) => lower.contains(kw)) ||
          lower.startsWith('รวม ') ||
          lower.startsWith('รวม:') ||
          lower == 'รวม';
      if (!hasKeyword) continue;

      final inlineNum = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(line);
      if (inlineNum != null) {
        final val = double.tryParse(inlineNum.group(1)!.replaceAll(',', ''));
        if (val != null && val > 0) return val;
      }

      for (int step = 1; step <= 3 && (i + step) < normalizedLines.length; step++) {
        final nextLine = normalizedLines[i + step].trim();
        final lowerNext = nextLine.toLowerCase();
        if (lowerNext.contains('เงินสด') ||
            lowerNext.contains('เงินทอน') ||
            lowerNext.contains('cash') ||
            lowerNext.contains('change') ||
            lowerNext.contains('vat') ||
            lowerNext.contains('ภาษี') ||
            lowerNext.contains('ส่วนลด') ||
            lowerNext.contains('รายการ') ||
            lowerNext.contains('ชิ้น') ||
            lowerNext.contains('คะแนน') ||
            lowerNext.contains('แต้ม')) {
          continue;
        }
        final nextNum = RegExp(r'([0-9]{1,4}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(nextLine);
        if (nextNum != null) {
          final val = double.tryParse(nextNum.group(1)!.replaceAll(',', ''));
          if (val != null && val > 0) return val;
        }
      }
    }

    // ── Tier 5: ค้นหาจากรายการสินค้า (Items) ──
    // สำคัญ: ห้ามรวมยอดสุทธิเข้าไปในผลรวมเด็ดขาด!
    if (items.isNotEmpty) {
      if (items.length >= 2) {
        // หากตัวสุดท้ายมีค่าเท่ากับผลรวมของรายการก่อนหน้า ให้ใช้ตัวสุดท้ายเป็นยอดสุทธิ
        final lastPrice = items.last.price;
        double sumPreceding = 0;
        for (int j = 0; j < items.length - 1; j++) {
          sumPreceding += items[j].price;
        }
        if ((lastPrice - sumPreceding).abs() < 0.05) {
          return lastPrice;
        }
      }

      // หากเป็นรายการสินค้าแท้จริงทั้งหมด จึงคำนวณผลรวม
      double itemSum = 0;
      for (final it in items) {
        itemSum += it.price;
      }
      if (itemSum > 0) {
        return double.parse(itemSum.toStringAsFixed(2));
      }
    }

    return 0.0;
  }

  /// ตรวจสอบว่าบรรทัดนี้เป็นข้อความประกอบใบเสร็จ (Header, Footer, Tax, Payment) หรือไม่ เพื่อไม่ให้สับสนกับรายการสินค้า
  static bool _isReceiptNoiseLine(String line) {
    final lower = line.toLowerCase().trim();
    if (lower.isEmpty) return true;

    // หัวกระดาษ / บรรทัดระบุร้าน
    if (lower.contains('7-eleven') ||
        lower.contains('7-11') ||
        lower.contains('เซเว่น') ||
        lower.contains('ซีพี ออลล์') ||
        lower.contains('ซีพีออลล์') ||
        lower.contains('cp all') ||
        lower.contains('cpall') ||
        lower.contains('public company') ||
        lower.contains('จำกัด (มหาชน)')) {
      return true;
    }

    // ข้อมูลสาขา เครื่อง และภาษี
    if (lower.contains('สาขา') ||
        lower.contains('store #') ||
        lower.contains('store#') ||
        lower.contains('branch') ||
        lower.contains('ใบเสร็จ') ||
        lower.contains('ใบกำกับภาษี') ||
        lower.contains('tax inv') ||
        lower.contains('tax id') ||
        lower.contains('เลขประจำตัว') ||
        lower.contains('abb') ||
        lower.contains('pos') ||
        lower.contains('r#') ||
        lower.contains('b#') ||
        lower.contains('เครื่อง') ||
        lower.contains('แคชเชียร์') ||
        lower.contains('cashier')) {
      return true;
    }

    // วันที่และเวลา
    if (lower.contains('วันที่') ||
        lower.contains('เวลา') ||
        lower.contains('date') ||
        lower.contains('time') ||
        RegExp(r'\b\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}\b').hasMatch(lower)) {
      return true;
    }

    // หัวตาราง
    if (lower == 'รายการ' ||
        (lower.contains('จำนวน') && lower.contains('ราคา')) ||
        (lower.contains('จํานวน') && lower.contains('ราคา')) ||
        lower.contains('description') ||
        (lower.contains('qty') && lower.contains('price')) ||
        lower.contains('item/desc')) {
      return true;
    }

    // เส้นคั่น
    if (RegExp(r'^[\-\=\*\.\_]{3,}$').hasMatch(lower)) {
      return true;
    }

    // สรุปยอดเงินและวิธีชำระเงิน (Noise สำหรับรายการสินค้า)
    // ยกเว้นชื่อสินค้าที่มีคำว่า รวม เช่น รวมมิตร, ผลไม้รวม, รวมรส, ถั่วรวม
    final isExcludedItemName = lower.contains('รวมมิตร') ||
        lower.contains('ผลไม้รวม') ||
        lower.contains('รวมรส') ||
        lower.contains('ถั่วรวม');

    if (!isExcludedItemName) {
      if (lower.startsWith('รวม') ||
          lower.contains('รวมเงิน') ||
          lower.contains('รวมเป็นเงิน') ||
          lower.contains('รวมทั้งสิ้น') ||
          lower.contains('ยอดรวมทั้งสิ้น') ||
          lower.contains('รวมสุทธิ') ||
          lower.contains('ยอดรวม') ||
          lower.contains('ยอดสุทธิ') ||
          lower.contains('ยอดเงินสุทธิ') ||
          lower.contains('รวมเงินสุทธิ') ||
          lower.contains('ยอดชำระ') ||
          lower.contains('ยอดชำระสุทธิ') ||
          lower.contains('ยอดชำระทั้งสิ้น') ||
          lower.contains('ยอดต้องชำระ') ||
          lower.contains('ยอดจ่าย') ||
          lower.contains('ยอดเงิน') ||
          lower.contains('จำนวนเงิน') ||
          lower.contains('จํานวนเงิน') ||
          lower.contains('จำนวนเงินทั้งสิ้น') ||
          lower.contains('จำนวนเงินรวม') ||
          lower.contains('จำนวนชิ้น') ||
          lower.contains('จำนวนรวม') ||
          lower.contains('จำนวนรายการ') ||
          lower.contains('มูลค่าสินค้า') ||
          lower.contains('มูลค่าสุทธิ') ||
          lower.contains('มูลค่ารวม') ||
          lower.contains('ราคารวม') ||
          lower.contains('ส่วนลด') ||
          lower.contains('ลดราคา') ||
          lower.contains('ลดทันที') ||
          lower.contains('ภาษี') ||
          lower.contains('vat') ||
          lower.contains('tax') ||
          lower.contains('net total') ||
          lower.contains('net amount') ||
          lower.contains('net amt') ||
          lower.contains('total due') ||
          lower.contains('amount due') ||
          lower.contains('total net') ||
          lower.contains('total') ||
          lower.contains('subtotal') ||
          lower.contains('sub-total') ||
          lower.contains('sub total') ||
          lower.contains('grand total') ||
          lower.startsWith('net ') ||
          lower.startsWith('net:') ||
          lower.startsWith('tot ') ||
          lower.startsWith('tot:') ||
          lower.startsWith('ttl ') ||
          lower.contains('เงินสด') ||
          lower.contains('เงินทอน') ||
          lower.contains('cash') ||
          lower.contains('change') ||
          lower.contains('all member') ||
          lower.contains('member') ||
          lower.contains('คะแนน') ||
          lower.contains('point') ||
          lower.contains('แต้ม') ||
          lower.contains('truemoney') ||
          lower.contains('true money') ||
          lower.contains('wallet') ||
          lower.contains('credit card') ||
          lower.contains('บัตรเครดิต') ||
          lower.contains('promptpay') ||
          lower.contains('พร้อมเพย์') ||
          lower.contains('qr code') ||
          lower.contains('qr') ||
          lower.contains('ขอบคุณ') ||
          lower.contains('thank you') ||
          lower.contains('call center') ||
          lower.contains('โทร')) {
        return true;
      }
    }

    // ตัวเลขโดดๆ รหัสบาร์โค้ด หรือสัญลักษณ์
    if (RegExp(r'^\d+$').hasMatch(lower)) return true;

    return false;
  }

  /// สกัดรายการสินค้าแต่ละรายการจากใบเสร็จ
  static List<_ReceiptParsedItem> _extractReceiptItems(List<String> lines) {
    final items = <_ReceiptParsedItem>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (_isReceiptNoiseLine(line)) continue;

      // รูปแบบ: [จำนวน (ถ้ามี)] [ชื่อสินค้า] [ราคา]
      final match = RegExp(
        r'^(?:(?:(\d{1,2})[\.\s\:\-xX]+)?)'
        r'([ก-๙a-zA-Z0-9\s\.\-_\(\)\/]{2,45}?)'
        r'\s+([0-9]{1,4}\.[0-9]{2})\s*(?:บาท|บ\.|THB)?$',
        caseSensitive: false,
      ).firstMatch(line);

      if (match != null) {
        final qtyStr = match.group(1);
        var name = match.group(2)!.trim();
        final priceStr = match.group(3)!;

        final qty = (qtyStr != null) ? (int.tryParse(qtyStr) ?? 1) : 1;
        final price = double.tryParse(priceStr) ?? 0.0;

        name = name.replaceAll(RegExp(r'^[\.\-\:\s]+|[\.\-\:\s]+$'), '').trim();

        // ป้องกันไม่ให้ชื่อสินค้ามีคำสรุปยอดที่หลุดมา
        if (name.length >= 2 &&
            price > 0 &&
            price < 50000 &&
            !RegExp(r'^\d+$').hasMatch(name) &&
            !_isReceiptNoiseLine(name)) {
          items.add(_ReceiptParsedItem(
            name: name,
            price: price,
            quantity: qty,
          ));
        }
      }
    }

    // ตรวจสอบกรณีที่แถวสุดท้ายคือยอดรวม (Total) แต่หลุดเข้ามาในรายการสินค้า
    // เช่น รายการ 1: 25.00, รายการ 2: 30.00, แถวสุดท้าย: 55.00
    if (items.length >= 2) {
      final lastItem = items.last;
      double sumOther = 0;
      for (int i = 0; i < items.length - 1; i++) {
        sumOther += items[i].price;
      }
      if ((lastItem.price - sumOther).abs() < 0.05) {
        items.removeLast();
      }
    }

    return items;
  }

  /// สกัดวันและเวลา (Date & Time) จากข้อความสลิป
  /// พร้อมอัลกอริทึม Multi-Tier Recognition ป้องกันการสกัดเวลาผิด (เช่น เวลาบน Status Bar ของมือถือ)
  static _ExtractedDateTime? _extractDateTime(String fullText, List<String> lines) {
    int? day, month, year, hour, minute, second;
    bool hasExplicitTime = false;

    int parseYear(int raw) {
      if (raw >= 2500) return raw - 543;
      if (raw >= 60 && raw <= 99) return (2500 + raw) - 543;
      if (raw >= 2000 && raw < 2100) return raw;
      if (raw >= 20 && raw < 60) return 2000 + raw;
      return 2000 + raw;
    }

    // ตรวจสอบเดือนภาษาไทย (ครอบคลุมทั้งแบบมีจุด ไม่มีจุด มีเว้นวรรค จุลภาค และความผิดเพี้ยนจากโมบาย OCR)
    final thaiMonths = {
      'มกราคม': 1, 'ม.ค.': 1, 'ม.ค': 1, 'มค': 1, 'ม. ค.': 1, 'ม. ค': 1, 'ม,ค,': 1, 'ม,ค': 1, 'ม ค': 1, 'u.a.': 1, 'u.a': 1, 'w.a.': 1,
      'กุมภาพันธ์': 2, 'ก.พ.': 2, 'ก.พ': 2, 'กพ': 2, 'ก. พ.': 2, 'ก. พ': 2, 'ก,พ,': 2, 'ก,พ': 2, 'ก พ': 2, 'n.w.': 2, 'n.w': 2,
      'มีนาคม': 3, 'มี.ค.': 3, 'มี.ค': 3, 'มีค': 3, 'มี. ค.': 3, 'มี. ค': 3, 'มี,ค,': 3, 'มี,ค': 3, 'มี ค': 3,
      'เมษายน': 4, 'เม.ย.': 4, 'เม.ย': 4, 'เมย': 4, 'เม. ย.': 4, 'เม. ย': 4, 'เม,ย,': 4, 'เม,ย': 4, 'เม ย': 4, 'iu.d.': 4, 'iu.e.': 4,
      'พฤษภาคม': 5, 'พ.ค.': 5, 'พ.ค': 5, 'พค': 5, 'พ. ค.': 5, 'พ. ค': 5, 'พ,ค,': 5, 'พ,ค': 5, 'พ ค': 5, 'w.ค.': 5, 'w.c.': 5,
      'มิถุนายน': 6, 'มิ.ย.': 6, 'มิ.ย': 6, 'มิย': 6, 'มิ. ย.': 6, 'มิ. ย': 6, 'มิ,ย,': 6, 'มิ,ย': 6, 'มิ ย': 6, 'u.d.': 6, 'u.e.': 6,
      'กรกฎาคม': 7, 'ก.ค.': 7, 'ก.ค': 7, 'กค': 7, 'ก. ค.': 7, 'ก. ค': 7, 'ก,ค,': 7, 'ก,ค': 7, 'ก ค': 7, 'n.a.': 7, 'n.a': 7,
      'สิงหาคม': 8, 'ส.ค.': 8, 'ส.ค': 8, 'สค': 8, 'ส. ค.': 8, 'ส. ค': 8, 'ส,ค,': 8, 'ส,ค': 8, 'ส ค': 8, 'a.ค.': 8, 'a.a.': 8, 'a.a': 8,
      'กันยายน': 9, 'ก.ย.': 9, 'ก.ย': 9, 'กย': 9, 'ก. ย.': 9, 'ก. ย': 9, 'ก,ย,': 9, 'ก,ย': 9, 'ก ย': 9, 'n.ย.': 9, 'n.e.': 9, 'n.d.': 9, 'n.d': 9, 'n.u.': 9, 'n.u': 9, 'ภ.ย.': 9, 'ค.ย.': 9,
      'ตุลาคม': 10, 'ต.ค.': 10, 'ต.ค': 10, 'ตค': 10, 'ต. ค.': 10, 'ต. ค': 10, 'ต,ค,': 10, 'ต,ค': 10, 'ต ค': 10, 'm.a.': 10, 'm.a': 10,
      'พฤศจิกายน': 11, 'พ.ย.': 11, 'พ.ย': 11, 'พย': 11, 'พ. ย.': 11, 'พ. ย': 11, 'พ,ย,': 11, 'พ,ย': 11, 'พ ย': 11, 'w.d.': 11, 'w.d': 11, 'w.e.': 11,
      'ธันวาคม': 12, 'ธ.ค.': 12, 'ธ.ค': 12, 'ธค': 12, 'ธ. ค.': 12, 'ธ. ค': 12, 'ธ,ค,': 12, 'ธ,ค': 12, 'ธ ค': 12, 's.a.': 12, 's.a': 12,
    };

    final engMonths = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    final thaiMonthPattern = (thaiMonths.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
        .map(RegExp.escape)
        .join('|');

    // ตัวช่วยสกัดส่วนของเวลาพร้อมรองรับ AM/PM และตัดยอดเงินที่สับสนออก
    ({int hour, int minute, int second})? parseTimeParts(
      String hStr,
      String mStr,
      String? sStr, {
      String? period,
      bool isDot = false,
      bool hasTimeWordOrUnit = false,
    }) {
      var h = int.tryParse(hStr);
      final m = int.tryParse(mStr);
      final s = sStr != null ? int.tryParse(sStr) ?? 0 : 0;

      if (h == null || m == null) return null;
      if (m < 0 || m > 59 || s < 0 || s > 59) return null;

      // หากคั่นด้วยจุด เช่น 10.50 ต้องมีคำว่า เวลา หรือ น. หรือ am/pm กำกับ เพื่อไม่ให้สับสนกับยอดเงิน
      if (isDot && !hasTimeWordOrUnit) {
        return null;
      }

      final p = period?.toLowerCase().replaceAll('.', '').trim();
      if (p == 'pm' || p == 'p') {
        if (h < 12) h += 12;
      } else if (p == 'am' || p == 'a') {
        if (h == 12) h = 0;
      }

      if (h < 0 || h > 23) return null;
      return (hour: h, minute: m, second: s);
    }

    // 1. ตรวจหาคู่ "วันที่แบบไทย + เวลา" ในบรรทัดเดียวกัน (Compound Thai Date-Time)
    // ตัวอย่าง: "วันที่ทำรายการ 02 ส.ค. 2569 - 22:02", "2 ส.ค. 69 เวลา 22.02 น.", "02 สิงหาคม 2569 / 22:02:30", "12 ก.ย. 69 15:45:00 น.", "12 ก.ย. 69 14.35 น."
    final compoundThaiRegex = RegExp(
      r'(?:(?:วันที่(?:ทำรายการ)?|เมื่อวันที่|วันและเวลา(?:ทำรายการ)?|วัน-เวลา(?:ที่ทำรายการ)?|วัน/เวลา(?:ที่ทำรายการ)?|วันเวลา(?:ที่ทำรายการ)?|Date)\s*[:：]?\s*)?([0-2]?\d|3[01])\s*(' +
          thaiMonthPattern +
          r')\s*(25\d{2}|20\d{2}|[5-9]\d|[2-3]\d)?\s*(?:[-–—,\s/|•@·]+|(?:[-–—,\s/|•@·]*(?:เวลา|เมื่อเวลา|Time)?\s*[:：]?\s*))(\d{1,2})\s*([:.;])\s*(\d{2})(?:\s*[:.;]\s*(\d{2}))?\s*(น\.|น|hrs?|am|pm|a\.m\.|p\.m\.)?',
      caseSensitive: false,
    );

    final compoundMatch = compoundThaiRegex.firstMatch(fullText);
    if (compoundMatch != null) {
      final matchEnd = compoundMatch.end;
      final remainder = fullText.substring(matchEnd).trimLeft();
      final isAmountSuffix = remainder.startsWith('บาท') ||
          remainder.startsWith('บ.') ||
          remainder.toLowerCase().startsWith('thb');

      if (!isAmountSuffix) {
        final d = int.tryParse(compoundMatch.group(1)!);
        final mo = thaiMonths[compoundMatch.group(2)!];
        final rawYear = compoundMatch.group(3) != null ? int.tryParse(compoundMatch.group(3)!) : null;
        final y = rawYear != null ? parseYear(rawYear) : DateTime.now().year;

        final sep = compoundMatch.group(5)!;
        final sStr = compoundMatch.group(7);
        final unit = compoundMatch.group(8);
        final isDot = sep == '.';
        // ตัวเลขเวลาที่ตามหลังวันที่ภาษาไทยโดยตรง และไม่ได้ลงท้ายด้วยบาท จัดเป็นเวลาที่ถูกต้องแน่นอน
        const hasUnit = true;

        final t = parseTimeParts(
          compoundMatch.group(4)!,
          compoundMatch.group(6)!,
          sStr,
          period: unit,
          isDot: isDot,
          hasTimeWordOrUnit: hasUnit,
        );

        if (d != null && mo != null && t != null) {
          return _ExtractedDateTime(
            DateTime(y, mo, d, t.hour, t.minute, t.second),
            hasTime: true,
          );
        }
      }
    }

    // 2. ตรวจหาคู่ "วันที่แบบอังกฤษ + เวลา"
    // ตัวอย่าง: "02 Aug 2026 22:02:15", "2 Sep 2026, 22.02", "10 Sep 2026 02:30 PM"
    final compoundEngRegex = RegExp(
      r'(?:Date\s*[:：]?\s*)?([0-2]?\d|3[01])\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*(20\d{2}|25\d{2}|\d{2})?\s*[-–—,\s/|•@·]+\s*(?:(?:Time|เวลา)\s*[:：]?\s*)?([01]?\d|2[0-3])\s*([:.;])\s*([0-5]\d)(?:\s*[:.;]\s*([0-5]\d))?\s*(am|pm|a\.m\.|p\.m\.)?',
      caseSensitive: false,
    );
    final engMatch = compoundEngRegex.firstMatch(fullText);
    if (engMatch != null) {
      final matchEnd = engMatch.end;
      final remainder = fullText.substring(matchEnd).trimLeft();
      final isAmountSuffix = remainder.startsWith('บาท') ||
          remainder.startsWith('บ.') ||
          remainder.toLowerCase().startsWith('thb');

      if (!isAmountSuffix) {
        final d = int.tryParse(engMatch.group(1)!);
        final mo = engMonths[engMatch.group(2)!.toLowerCase()];
        final rawYear = engMatch.group(3) != null ? int.tryParse(engMatch.group(3)!) : null;
        final y = rawYear != null ? parseYear(rawYear) : DateTime.now().year;

        final t = parseTimeParts(
          engMatch.group(4)!,
          engMatch.group(6)!,
          engMatch.group(7),
          period: engMatch.group(8),
          isDot: engMatch.group(5) == '.',
          hasTimeWordOrUnit: true,
        );

        if (d != null && mo != null && t != null) {
          return _ExtractedDateTime(
            DateTime(y, mo, d, t.hour, t.minute, t.second),
            hasTime: true,
          );
        }
      }
    }

    // 3. ตรวจหาคู่ "วันที่แบบตัวเลข + เวลา" (รองรับทั้ง DD/MM/YYYY และ ISO YYYY-MM-DD)
    // ตัวอย่าง: "02/08/2569 22:02", "2026-09-12 14:35:10", "02-08-2026 - 22.02"
    final compoundNumRegex = RegExp(
      r'(?:(?:วันที่|Date)\s*[:：]?\s*)?(?:([0-2]?\d|3[01])[/.-](0?[1-9]|1[0-2])[/.-](20\d{2}|25\d{2}|\d{2})|(20\d{2}|25\d{2})[/.-](0?[1-9]|1[0-2])[/.-]([0-2]?\d|3[01]))\s*[-–—,\s/|•@·]+\s*(?:(?:เวลา|Time)\s*[:：]?\s*)?([01]?\d|2[0-3])\s*([:.;])\s*([0-5]\d)(?:\s*[:.;]\s*([0-5]\d))?\s*(น\.|น|am|pm|a\.m\.|p\.m\.)?',
      caseSensitive: false,
    );
    final numMatch = compoundNumRegex.firstMatch(fullText);
    if (numMatch != null) {
      final matchEnd = numMatch.end;
      final remainder = fullText.substring(matchEnd).trimLeft();
      final isAmountSuffix = remainder.startsWith('บาท') ||
          remainder.startsWith('บ.') ||
          remainder.toLowerCase().startsWith('thb');

      if (!isAmountSuffix) {
        int? d, mo, y;
        if (numMatch.group(1) != null) {
          d = int.tryParse(numMatch.group(1)!);
          mo = int.tryParse(numMatch.group(2)!);
          final rawYear = int.tryParse(numMatch.group(3)!);
          if (rawYear != null) y = parseYear(rawYear);
        } else if (numMatch.group(4) != null) {
          final rawYear = int.tryParse(numMatch.group(4)!);
          if (rawYear != null) y = parseYear(rawYear);
          mo = int.tryParse(numMatch.group(5)!);
          d = int.tryParse(numMatch.group(6)!);
        }

        final sep = numMatch.group(8)!;
        final unit = numMatch.group(11);
        final isDot = sep == '.';
        final hasUnit = (unit != null && unit.isNotEmpty) || numMatch.group(0)!.contains('เวลา');

        final t = parseTimeParts(
          numMatch.group(7)!,
          numMatch.group(9)!,
          numMatch.group(10),
          period: unit,
          isDot: isDot,
          hasTimeWordOrUnit: hasUnit,
        );

        if (d != null && mo != null && y != null && t != null) {
          return _ExtractedDateTime(
            DateTime(y, mo, d, t.hour, t.minute, t.second),
            hasTime: true,
          );
        }
      }
    }

    // 3.5 ตรวจหาคู่ "วันที่ (ปี พ.ศ. ชัดเจน 256x/257x) + เวลา" กรณี OCR อ่านชื่อเดือนผิดเพี้ยนหรือไม่พบชื่อเดือน
    // เช่น "12 ... 2569 - 15:28" หรือ "11 2569 - 20:00"
    final fuzzyThaiYearRegex = RegExp(
      r'(?:(?:วันที่(?:ทำรายการ)?|เมื่อวันที่|Date)\s*[:：]?\s*)?([0-2]?\d|3[01])\s*[^\d\w\r\n]{0,10}\s*(25[6-7]\d)\s*[-–—,\s/|•@·]+\s*(?:(?:เวลา|Time)\s*[:：]?\s*)?([01]?\d|2[0-3])\s*([:.;])\s*([0-5]\d)(?:\s*[:.;]\s*([0-5]\d))?\s*(น\.|น|am|pm)?',
      caseSensitive: false,
    );
    final fuzzyMatch = fuzzyThaiYearRegex.firstMatch(fullText);
    if (fuzzyMatch != null) {
      final d = int.tryParse(fuzzyMatch.group(1)!);
      final rawYear = int.tryParse(fuzzyMatch.group(2)!);
      final y = rawYear != null ? rawYear - 543 : DateTime.now().year;

      // พยายามค้นหาเดือนจากรหัสอ้างอิง เช่น 202609... หรือ 014256709...
      int mo = DateTime.now().month;
      final refMonthMatch = RegExp(r'(?:202\d|25[6-7]\d)(0[1-9]|1[0-2])').firstMatch(fullText);
      if (refMonthMatch != null) {
        mo = int.tryParse(refMonthMatch.group(1)!) ?? mo;
      }

      final t = parseTimeParts(
        fuzzyMatch.group(3)!,
        fuzzyMatch.group(5)!,
        fuzzyMatch.group(6),
        period: fuzzyMatch.group(7),
        isDot: fuzzyMatch.group(4) == '.',
        hasTimeWordOrUnit: true,
      );

      if (d != null && t != null) {
        return _ExtractedDateTime(
          DateTime(y, mo, d, t.hour, t.minute, t.second),
          hasTime: true,
        );
      }
    }

    // 4. กรณีวันที่และเวลาอยู่คนละบรรทัดกัน (Multi-line Contextual Parsing)
    // 4.1 ค้นหาบรรทัดวันที่
    int? dateLineIndex;
    final thaiDateOnlyRegex = RegExp(
      r'(?:(?:วันที่(?:ทำรายการ)?|เมื่อวันที่|Date)\s*[:：]?\s*)?([0-2]?\d|3[01])\s*(' +
          thaiMonthPattern +
          r')\s*(25\d{2}|20\d{2}|[5-9]\d|[2-3]\d)?',
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
        r'(?:Date\s*[:：]?\s*)?([0-2]?\d|3[01])\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*(20\d{2}|25\d{2}|\d{2})?',
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
      final numDateOnlyRegex = RegExp(
        r'(?:(?:วันที่|Date)\s*[:：]?\s*)?(?:([0-2]?\d|3[01])[/.-](0?[1-9]|1[0-2])[/.-](20\d{2}|25\d{2}|\d{2})|(20\d{2}|25\d{2})[/.-](0?[1-9]|1[0-2])[/.-]([0-2]?\d|3[01]))',
        caseSensitive: false,
      );
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineLower = line.toLowerCase();
        // ข้ามบรรทัดที่เป็นเบอร์พร้อมเพย์ บัญชี หรือเลขประจำตัวประชาชน
        if (lineLower.contains('พร้อมเพย์') ||
            lineLower.contains('promptpay') ||
            RegExp(r'^(?:0[689]\d[\s\-]?\d{3}[\s\-]?\d{4}|[0-9]\s*[-–—]\s*[0-9]{4}\s*[-–—])').hasMatch(line)) {
          continue;
        }
        final m = numDateOnlyRegex.firstMatch(line);
        if (m != null) {
          if (m.group(1) != null) {
            day = int.tryParse(m.group(1)!);
            month = int.tryParse(m.group(2)!);
            final rawYear = int.tryParse(m.group(3)!);
            if (rawYear != null) year = parseYear(rawYear);
          } else if (m.group(4) != null) {
            final rawYear = int.tryParse(m.group(4)!);
            if (rawYear != null) year = parseYear(rawYear);
            month = int.tryParse(m.group(5)!);
            day = int.tryParse(m.group(6)!);
          }
          dateLineIndex = i;
          break;
        }
      }
    }

    // 4.1.1 ค้นหาวันที่และเวลาจากรหัสอ้างอิง (Fallback เมื่อไม่พบบรรทัดวันที่ เช่น K PLUS 01425670912143500B1234 หรือ 20260912143522...)
    if (day == null || month == null || year == null) {
      // 1) รูปแบบ ค.ศ. (202x): YYYYMMDD ตามด้วย HHMMSS หรือรหัสอื่น
      final refCeMatch = RegExp(
        r'(?:[A-Za-z0-9]{0,6})?(202\d)(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])(?:([01]\d|2[0-3])([0-5]\d)([0-5]\d)?)?',
      ).firstMatch(fullText);

      if (refCeMatch != null) {
        year = int.tryParse(refCeMatch.group(1)!);
        month = int.tryParse(refCeMatch.group(2)!);
        day = int.tryParse(refCeMatch.group(3)!);
        if (refCeMatch.group(4) != null && refCeMatch.group(5) != null) {
          hour = int.tryParse(refCeMatch.group(4)!);
          minute = int.tryParse(refCeMatch.group(5)!);
          if (refCeMatch.group(6) != null) {
            second = int.tryParse(refCeMatch.group(6)!);
          }
          hasExplicitTime = true;
        }
      }

      // 2) รูปแบบ พ.ศ. (256x หรือ 257x): เช่น K PLUS 01425670912143500... หรือ 25690912143522...
      if (day == null || month == null || year == null) {
        final refBeMatch = RegExp(
          r'(?:[A-Za-z0-9]{0,6})?(25[6-7]\d)(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])(?:([01]\d|2[0-3])([0-5]\d)([0-5]\d)?)?',
        ).firstMatch(fullText);

        if (refBeMatch != null) {
          final rawY = int.tryParse(refBeMatch.group(1)!);
          if (rawY != null) year = rawY - 543;
          month = int.tryParse(refBeMatch.group(2)!);
          day = int.tryParse(refBeMatch.group(3)!);
          if (refBeMatch.group(4) != null && refBeMatch.group(5) != null) {
            hour = int.tryParse(refBeMatch.group(4)!);
            minute = int.tryParse(refBeMatch.group(5)!);
            if (refBeMatch.group(6) != null) {
              second = int.tryParse(refBeMatch.group(6)!);
            }
            hasExplicitTime = true;
          }
        }
      }
    }

    // 4.2 สกัดเวลาแบบ Multi-Tier Priority Scoring
    // ป้องกันการสับสนระหว่างเวลาจริง กับนาฬิกา Status Bar หรือยอดเงิน
    final explicitTimeRegex = RegExp(
      r'(?:(?:เวลา|Time|เมื่อเวลา)\s*[:：]?\s*)?([01]?\d|2[0-3])\s*([:.;])\s*([0-5]\d)(?:\s*[:.;]\s*([0-5]\d))?\s*(น\.|น|am|pm|a\.m\.|p\.m\.)?',
      caseSensitive: false,
    );

    int bestScore = -999;
    ({int hour, int minute, int second})? bestTime;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      // ข้ามบรรทัดที่มีข้อความเกี่ยวกับเงิน/ค่าธรรมเนียม ที่ไม่มีคำบอกเวลา
      final isMoneyLine = line.contains('บาท') ||
          line.contains('บ.') ||
          lineLower.contains('thb') ||
          line.contains('ค่าธรรมเนียม') ||
          lineLower.contains('fee') ||
          line.contains('ยอดเงิน') ||
          line.contains('จำนวนเงิน') ||
          lineLower.contains('amount');

      if (isMoneyLine) {
        final hasExplicitTimeWord = line.contains('เวลา') ||
            lineLower.contains('time') ||
            line.contains('น.') ||
            RegExp(r'\s+น\b').hasMatch(line);
        if (!hasExplicitTimeWord) {
          continue;
        }
      }

      final matches = explicitTimeRegex.allMatches(line);
      for (final m in matches) {
        final sep = m.group(2)!;
        final unit = m.group(5);
        final isDot = sep == '.';
        final hasTimeWord = line.contains('เวลา') || lineLower.contains('time');
        final isNearDate = !isMoneyLine && dateLineIndex != null && (i - dateLineIndex).abs() <= 1;
        // หากมีคำระบุเวลา หรือมีหน่วย น./am/pm หรือตัวเลขจุดอยู่ติดกับบรรทัดวันที่ ถือเป็นเวลาแน่นอน
        final hasTimeWordOrUnit = (unit != null && unit.isNotEmpty) || hasTimeWord || (isDot && isNearDate);

        final t = parseTimeParts(
          m.group(1)!,
          m.group(3)!,
          m.group(4),
          period: unit,
          isDot: isDot,
          hasTimeWordOrUnit: hasTimeWordOrUnit,
        );
        if (t == null) continue;

        int score = 0;
        if (hasTimeWord) score += 100;
        if (unit != null && unit.isNotEmpty) score += 80;

        // ให้คะแนนความใกล้ชิดกับบรรทัดวันที่
        if (dateLineIndex != null) {
          final diff = (i - dateLineIndex).abs();
          if (diff == 0) {
            score += 60;
          } else if (diff == 1) {
            score += 50;
          } else if (diff == 2) {
            score += 35;
          } else if (diff <= 4) {
            score += 20;
          }
        }

        // หักคะแนนกรณีอยู่บน 2 บรรทัดแรกของสลิป และไม่มีคำระบุเวลา (เลี่ยง Phone Status Bar)
        if (i <= 1 && !hasTimeWordOrUnit) {
          score -= 70;
        }

        if (score > bestScore) {
          bestScore = score;
          bestTime = t;
        }
      }
    }

    if (bestTime != null && bestScore > 0) {
      hour = bestTime.hour;
      minute = bestTime.minute;
      second = bestTime.second;
      hasExplicitTime = true;
    }

    final h = hour;
    final m = minute;

    if (day != null && month != null && year != null) {
      return _ExtractedDateTime(
        DateTime(
          year,
          month,
          day,
          h ?? 0,
          m ?? 0,
          second ?? 0,
        ),
        hasTime: hasExplicitTime,
      );
    } else if (h != null && m != null) {
      final now = DateTime.now();
      return _ExtractedDateTime(
        DateTime(
          now.year,
          now.month,
          now.day,
          h,
          m,
          second ?? 0,
        ),
        hasTime: true,
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

    // 4. ตรวจจับรหัสใบเสร็จ 7-Eleven / ร้านค้า (R#, INV#, ABB#, Bill#)
    final receiptNumMatch = RegExp(
      r'(?:R#|INV#|ABB#|Bill#|Tax\s*Inv(?:\(ABB\))?#?)\s*[:：\-]?\s*([0-9A-Za-z/_-]{4,24})',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (receiptNumMatch != null) {
      return receiptNumMatch.group(1)!.trim();
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

    // สกัดผู้โอนจากสลิปพร้อมเพย์ P2P ที่ไม่มีคำว่า "จาก" (เช่น K PLUS)
    int promptPayIdx = -1;
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      if (l.contains('พร้อมเพย์') || l.contains('promptpay')) {
        promptPayIdx = i;
        break;
      }
    }
    if (promptPayIdx > 0) {
      for (int prevIdx = 0; prevIdx < promptPayIdx; prevIdx++) {
        final candidate = lines[prevIdx].trim();
        if (_isBankOrChannelOrNoise(candidate)) continue;
        if (candidate.contains('โอนเงิน') ||
            candidate.contains('สำเร็จ') ||
            candidate.toLowerCase().contains('k plus') ||
            candidate.toLowerCase().contains('kbank') ||
            RegExp(r'(?:[0-2]?\d|3[01])\s*(?:ม\.ค|ก\.พ|มี\.ค|เม\.ย|พ\.ค|มิ\.ย|ก\.ค|ส\.ค|ก\.ย|ต\.ค|พ\.ย|ธ\.ค|\d{2})').hasMatch(candidate) ||
            RegExp(r'\d{1,2}[:.]\d{2}').hasMatch(candidate)) {
          continue;
        }
        final cleanedCandidate = _cleanName(candidate);
        if (cleanedCandidate.length >= 2 && !_isBankOrChannelOrNoise(cleanedCandidate)) {
          return cleanedCandidate;
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

  /// สกัดชื่อผู้รับเงิน (ไปยัง / To / ผู้รับ / เข้าบัญชี / ร้านค้า / 7-Eleven)
  static String? _extractReceiver(List<String> lines) {
    // 0. ตรวจสอบชื่อร้านและสาขาสำหรับใบเสร็จ 7-Eleven / CP ALL
    for (final line in lines) {
      final l = line.toLowerCase();
      if (l.contains('7-eleven') ||
          l.contains('7-11') ||
          l.contains('เซเว่น') ||
          l.contains('ซีพี ออลล์') ||
          l.contains('ซีพีออลล์') ||
          l.contains('cp all') ||
          l.contains('cpall')) {
        for (final branchLine in lines) {
          final branchMatch = RegExp(
            r'(?:สาขา|Store\s*#?)\s*([0-9]{3,6}\s*[^\n\r,]+|[^\n\r,]+)',
            caseSensitive: false,
          ).firstMatch(branchLine);
          if (branchMatch != null) {
            final cleanedBranch = _cleanReceiptBranch(branchMatch.group(0)!);
            if (cleanedBranch != null && cleanedBranch.length >= 3) {
              return '7-Eleven $cleanedBranch';
            }
          }
        }
        return '7-Eleven';
      }
    }

    final receiverKeywords = [
      'ไปยัง',
      'ผู้รับเงิน',
      'เข้าบัญชี',
      'โอนให้',
      'โอนไปยัง',
      'ผู้รับ',
      'ชำระเงินให้',
      'ชำระให้',
      'จ่ายให้',
      'payment to',
      'pay to',
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

      // ตรวจหารูปแบบชื่อร้านค้า เช่น "ร้าน ...", "บจก. ...", "บริษัท ...", "Payment to ..."
      final merchantMatch = RegExp(
        r'^(?:ร้าน|บจก\.|บริษัท|หจก\.|Payment\s+to\s+|Pay\s+to\s+)\s*[^\s]+.*$',
        caseSensitive: false,
      ).firstMatch(line.trim());
      if (merchantMatch != null) {
        final rawMerchant = merchantMatch.group(0)!
            .replaceFirst(RegExp(r'^(?:Payment\s+to\s+|Pay\s+to\s+)', caseSensitive: false), '')
            .trim();
        final name = _cleanName(rawMerchant);
        if (name.length >= 3 && !_isBankOrChannelOrNoise(name)) return name;
      }
    }

    // สกัดผู้รับเงินจากสลิปพร้อมเพย์ P2P ที่ไม่มีคำว่า "ไปยัง" (เช่น K PLUS / SCB)
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase().trim();
      if (lineLower == 'พร้อมเพย์' ||
          lineLower == 'promptpay' ||
          lineLower.startsWith('พร้อมเพย์ ') ||
          lineLower.startsWith('promptpay ') ||
          lineLower.startsWith('พร้อมเพย์:')) {
        for (int nextIdx = i + 1; nextIdx <= i + 3 && nextIdx < lines.length; nextIdx++) {
          final candidate = lines[nextIdx].trim();
          if (_isBankOrChannelOrNoise(candidate)) continue;
          final cleanedCandidate = _cleanName(candidate);
          if (cleanedCandidate.length >= 2 && !_isBankOrChannelOrNoise(cleanedCandidate)) {
            return cleanedCandidate;
          }
        }
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
          final stripped = l.replaceFirst(
            RegExp(r'^(?:ไปยัง|to|เข้าบัญชี|ผู้รับเงิน|พร้อมเพย์|promptpay)\s*[:：]?\s*', caseSensitive: false),
            '',
          ).trim();
          if (RegExp(r'^[xX0-9\s\-*]{8,24}$').hasMatch(stripped)) {
            return stripped;
          }
          final match = RegExp(r'[xX0-9*]{1,}[-xX*0-9\s]{7,}').firstMatch(stripped);
          if (match != null) {
            return match.group(0)!.trim();
          }
        }
      }
    }

    // สกัดเลขพร้อมเพย์ผู้รับจากสลิปที่ไม่มีคำว่า "ไปยัง" (เช่น K PLUS)
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase();
      if (lineLower.contains('พร้อมเพย์') || lineLower.contains('promptpay')) {
        for (int j = i; j <= i + 2 && j < lines.length; j++) {
          final l = lines[j].trim();
          if (l.contains('บาท') || l.toLowerCase().contains('thb') || l.contains('ค่าธรรมเนียม')) continue;
          final stripped = l.replaceFirst(
            RegExp(r'^(?:พร้อมเพย์|promptpay)\s*[:：]?\s*', caseSensitive: false),
            '',
          ).trim();
          if (RegExp(r'^[xX0-9\s\-*]{8,24}$').hasMatch(stripped)) {
            return stripped;
          }
          final match = RegExp(r'[xX0-9*]{1,}[-xX*0-9\s]{7,}').firstMatch(stripped);
          if (match != null) {
            return match.group(0)!.trim();
          }
        }
      }
    }

    return null;
  }

  /// สกัดบันทึกช่วยจำ (Memo / Note)
  static String? _extractMemo(List<String> lines, {List<_ReceiptParsedItem>? receiptItems}) {
    final memoKeywords = [
      'บันทึกช่วยจำ',
      'บันทึก:',
      'บันทึก',
      'ข้อความถึงผู้รับ:',
      'ข้อความ:',
      'ข้อความ',
      'หมายเหตุ:',
      'หมายเหตุ',
      'รายละเอียด:',
      'คำอธิบาย:',
      'memo:',
      'memo',
      'note:',
      'note',
      'message:',
      'description:',
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();
      for (final kw in memoKeywords) {
        if (lineLower.contains(kw)) {
          final inline = line.replaceFirst(
            RegExp('^(?:$kw)\\s*[:：]?\\s*', caseSensitive: false),
            '',
          ).trim();
          if (inline.isNotEmpty &&
              !inline.contains('QR') &&
              !inline.contains('สแกน') &&
              !inline.contains('สำเร็จ') &&
              !inline.contains('บาท')) {
            return inline;
          }
          if (i + 1 < lines.length) {
            final candidate = lines[i + 1].trim();
            if (candidate.isNotEmpty &&
                !candidate.contains('QR') &&
                !candidate.contains('สแกน') &&
                !candidate.contains('สำเร็จ') &&
                !candidate.contains('บาท')) {
              return candidate;
            }
          }
        }
      }
    }

    // สำหรับใบเสร็จ 7-Eleven หรือใบเสร็จร้านค้า
    final is7El = is7ElevenSlip(lines.join('\n'));

    if (is7El || isStoreReceipt(lines.join('\n'))) {
      final items = receiptItems ?? _extractReceiptItems(lines);
      if (items.isNotEmpty) {
        return items.map((it) {
          final priceStr = it.price == it.price.roundToDouble()
              ? '${it.price.toInt()}.-'
              : '${it.price.toStringAsFixed(2)}.-';
          return '${it.name} ($priceStr)';
        }).join(', ');
      }
      return is7El ? 'ซื้อของ 7-Eleven' : 'ซื้อของ/ใบเสร็จรับเงิน';
    }

    return null;
  }

  /// ทำความสะอาดชื่อสาขาจากใบเสร็จ 7-Eleven โดยตัดข้อความขยะที่พ่วงมาด้วย (เช่น TAX INV, เลขประจำตัว, POS, R#)
  static String? _cleanReceiptBranch(String rawBranch) {
    var b = rawBranch.trim();
    final cutOffPatterns = [
      RegExp(r'\s*(?:TAX|ABB|POS|R#|B#|REG|TAX\s*INV|ABB\s*NO)\b.*$', caseSensitive: false),
      RegExp(r'\s*(?:เลขประจำตัว|ผู้เสียภาษี|ใบเสร็จ|ใบกำกับ|โทร|Tel|เครื่อง|แคชเชียร์|ลำดับ).*$', caseSensitive: false),
      RegExp(r'\s*\d{2}[\/\-]\d{2}[\/\-]\d{2,4}.*$'),
    ];
    for (final p in cutOffPatterns) {
      b = b.replaceFirst(p, '').trim();
    }
    b = b.replaceAll(RegExp(r'[\s\-:：,.]+$'), '').trim();
    if (b.length > 30) {
      b = b.substring(0, 30).trim();
    }
    return b.isNotEmpty ? b : null;
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'ธ\.(?:กรุงไทย|กสิกรไทย|ไทยพาณิชย์|กรุงเทพ|กรุงศรีอยุธยา|กรุงศรี|ออมสิน|ก\.ส\.|ทหารไทยธนชาต|เกียรตินาคิน|ยูโอบี|ซีไอเอ็มบี|ทิสโก้|แลนด์ แอนด์ เฮ้าส์)', caseSensitive: false), '')
        .replaceAll(RegExp(r'ธนาคาร(?:กรุงไทย|กสิกรไทย|ไทยพาณิชย์|กรุงเทพ|กรุงศรีอยุธยา|กรุงศรี|ออมสิน|เพื่อการเกษตรและสหกรณ์การเกษตร|ทหารไทยธนชาต|เกียรตินาคินภัทร|เกียรตินาคิน|ยูโอบี|ซีไอเอ็มบีไทย|ซีไอเอ็มบี|ทิสโก้|แลนด์ แอนด์ เฮ้าส์)', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:PromptPay|พร้อมเพย์)', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:0[689]\d[-–—\s]?\d{3}[-–—\s]?\d{4})'), '')
        .replaceAll(RegExp(r'[xX*]{2,}[-xX*0-9\s]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{3}[-–—\s]?\d[-–—\s]?\d{5}[-–—\s]?\d\b'), '')
        .replaceAll(RegExp(r'^[–—\-•:：\s]+|[–—\-•:：\s]+$'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
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

/// ผลลัพธ์การสกัดวันและเวลาพร้อมสถานะความชัดเจนของเวลา
class _ExtractedDateTime {
  final DateTime dateTime;
  final bool hasTime;
  const _ExtractedDateTime(this.dateTime, {required this.hasTime});
}

/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100%
typedef KrungthaiSlipParser = BankSlipParser;

/// โมเดลข้อมูลรายการสินค้าที่แยกออกมาจากใบเสร็จ (Receipt Item)
class _ReceiptParsedItem {
  final String name;
  final double price;
  final int quantity;
  const _ReceiptParsedItem({required this.name, required this.price, this.quantity = 1});
}
