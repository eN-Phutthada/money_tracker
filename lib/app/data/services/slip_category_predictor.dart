import '../models/transaction_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SlipPrediction — ผลลัพธ์การทำนายหมวดหมู่จากสลิป
// ─────────────────────────────────────────────────────────────────────────────

/// ผลลัพธ์ที่ได้จาก [SlipCategoryPredictor.predict]
class SlipPrediction {
  /// หมวดหมู่ที่ทำนาย เช่น 'อาหาร/ของกิน', 'ช้อปปิ้ง'
  final String category;

  /// ประเภทธุรกรรมที่ทำนาย
  final TransactionType type;

  /// ลักษณะค่าใช้จ่าย (fixed/variable/notApplicable)
  final CostNature costNature;

  /// ความมั่นใจ 0.0–1.0
  final double confidence;

  /// เหตุผลสั้นๆ สำหรับแสดงใน UI
  final String reason;

  const SlipPrediction({
    required this.category,
    required this.type,
    required this.costNature,
    required this.confidence,
    required this.reason,
  });

  bool get isHighConfidence => confidence >= 0.70;
  bool get isMediumConfidence => confidence >= 0.40 && confidence < 0.70;
  bool get isLowConfidence => confidence < 0.40;

  String get confidenceLabel {
    if (isHighConfidence) return 'แม่นสูง';
    if (isMediumConfidence) return 'ปานกลาง';
    return 'ค่าเริ่มต้น';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SlipCategoryPredictor — Multi-Signal Scoring Engine
// ─────────────────────────────────────────────────────────────────────────────

/// ระบบทำนายหมวดหมู่อัตโนมัติจากข้อมูลสลิป
///
/// ใช้สัญญาณ 4 แหล่งผสมกัน:
/// 1. **Keyword Scoring** — ตรวจ memo / receiverName / rawText
/// 2. **Amount Heuristic** — ประมาณจากยอดเงิน
/// 3. **Time-of-Day Signal** — ช่วงเวลาทำรายการ
/// 4. **History Learning** — เรียนรู้จากธุรกรรมที่บันทึกไว้ก่อนหน้า
class SlipCategoryPredictor {
  /// ทำนายหมวดหมู่ธุรกรรม คืน [SlipPrediction] พร้อม confidence และ reason
  static SlipPrediction predict({
    String? memo,
    String? receiverName,
    String? senderName,
    String? userProfileName,
    required String fullText,
    required double amount,
    required DateTime transactionDate,
    List<TransactionItem> history = const [],
  }) {
    final lowerFull = fullText.toLowerCase();

    // 1. ตรวจสอบสัญญาณรายการเงินเข้าที่ชัดเจน (Explicit Income Signals)
    // ระมัดระวังไม่ให้คำว่า "โอนเงินเข้าบัญชี..." ของสลิปโอนออกถูกเข้าใจผิดว่าเป็นเงินเข้า
    final isExplicitIncomeHeader = lowerFull.contains('เงินเข้าสำเร็จ') ||
        lowerFull.contains('เงินโอนเข้าสำเร็จ') ||
        lowerFull.contains('แจ้งเตือนเงินเข้า') ||
        lowerFull.contains('มีเงินโอนเข้า') ||
        lowerFull.contains('รับเงินสำเร็จ') ||
        lowerFull.contains('รับโอนเงินสำเร็จ') ||
        lowerFull.contains('ได้รับเงินแล้ว') ||
        lowerFull.contains('คุณได้รับเงิน') ||
        lowerFull.contains('ท่านได้รับเงิน') ||
        lowerFull.contains('โอนเข้าบัญชีคุณ') ||
        lowerFull.contains('โอนเข้าบัญชีท่าน') ||
        lowerFull.contains('incoming transfer') ||
        lowerFull.contains('money received') ||
        lowerFull.contains('payment received from') ||
        RegExp(r'(^|\n)\s*เงินเข้า\s*($|\n|:)').hasMatch(lowerFull);

    // 2. วิเคราะห์ประเภทธุรกรรม (รายจ่าย vs รายรับ) โดยพิจารณาจากผู้ส่งและผู้รับ
    final resolvedType = _resolveTransactionType(
      senderName: senderName,
      receiverName: receiverName,
      userProfileName: userProfileName,
      memo: memo,
      fullText: fullText,
      hasExplicitIncomeSignal: isExplicitIncomeHeader,
    );

    final combined =
        '${memo ?? ''} ${receiverName ?? ''} $fullText'.toLowerCase();

    // Score map: category → accumulated score
    final scores = <String, int>{for (final d in _defs) d.category: 0};
    final hints = <String, String>{};

    if (resolvedType == TransactionType.income) {
      scores['ขายของ/รายได้เสริม'] = (scores['ขายของ/รายได้เสริม'] ?? 0) + 12;
      scores['เงินเดือน'] = (scores['เงินเดือน'] ?? 0) + 8;
      scores['เงินคืน/โอนคืน'] = (scores['เงินคืน/โอนคืน'] ?? 0) + 8;
    }

    // ── 1. Keyword Scoring ───────────────────────────────────────────
    for (final def in _defs) {
      final hits = <String>[];
      for (final kw in def.keywords) {
        if (_matchKeyword(combined, kw)) hits.add(kw);
      }
      if (hits.isNotEmpty) {
        scores[def.category] = (scores[def.category] ?? 0) + hits.length * 10;
        if (!hints.containsKey(def.category)) {
          hints[def.category] = 'คีย์เวิร์ด: ${hits.take(2).join(', ')}';
        }
      }
    }

    // ── 2. Amount Heuristic ──────────────────────────────────────────
    for (final def in _defs) {
      if (def.amountMin != null &&
          def.amountMax != null &&
          amount >= def.amountMin! &&
          amount <= def.amountMax!) {
        scores[def.category] = (scores[def.category] ?? 0) + 5;
      }
    }

    // ── 3. Time-of-Day Signal ────────────────────────────────────────
    _timeBoosts(transactionDate.hour).forEach((cat, pts) {
      scores[cat] = (scores[cat] ?? 0) + pts;
    });

    // ── 4. History Learning ──────────────────────────────────────────
    String? historyCategory;
    int historyCount = 0;
    if (history.isNotEmpty) {
      final match = _matchHistory(receiverName, memo, history);
      if (match != null) {
        historyCategory = match.$1;
        historyCount = match.$2;
        final bonus = historyCount >= 3 ? 50 : 30;
        scores[historyCategory] = (scores[historyCategory] ?? 0) + bonus;
        hints[historyCategory] = 'ประวัติ $historyCount รายการก่อนหน้า';
      }
    }

    // ── Find Winner (กรองประเภทหมวดหมู่ให้สอดคล้องกับ resolvedType) ───
    String best = 'อื่นๆ';
    int bestScore = -1;
    for (final entry in scores.entries) {
      final catDef = _defs.firstWhere(
        (d) => d.category == entry.key,
        orElse: () => _fallbackDef,
      );

      // กรองไม่ให้หมวดหมู่รายรับชนะในสลิปรายจ่าย และไม่ให้หมวดหมู่รายจ่ายชนะในสลิปรายรับ
      if (resolvedType == TransactionType.income && catDef.type == TransactionType.expense) {
        continue;
      }
      if (resolvedType == TransactionType.expense && catDef.type == TransactionType.income) {
        continue;
      }

      if (entry.value > bestScore) {
        bestScore = entry.value;
        best = entry.key;
      }
    }

    final fallback = resolvedType == TransactionType.income ? _fallbackIncomeDef : _fallbackDef;

    final def = _defs.firstWhere(
      (d) => d.category == best,
      orElse: () => fallback,
    );

    final finalType = (resolvedType == TransactionType.income)
        ? TransactionType.income
        : (def.type == TransactionType.savingsInvestment
            ? TransactionType.savingsInvestment
            : TransactionType.expense);

    final confidence = _toConfidence(
      bestScore > 0 ? bestScore : 0,
      isHistory: historyCategory == best,
      historyCount: historyCount,
    );

    String defaultReason;
    if (finalType == TransactionType.income) {
      defaultReason = 'ตรวจพบสัญญาณเงินโอนเข้า';
    } else if (receiverName != null && _isMerchantOrBusiness(receiverName)) {
      defaultReason = 'ชำระเงินให้ร้านค้า/บริการ';
    } else if (amount > 0) {
      defaultReason = 'ประมาณจากยอดเงิน ฿${amount.toStringAsFixed(0)}';
    } else {
      defaultReason = 'ค่าเริ่มต้น';
    }

    final reason = hints[best] ?? defaultReason;

    return SlipPrediction(
      category: best,
      type: finalType,
      costNature: finalType == TransactionType.income
          ? CostNature.notApplicable
          : def.costNature,
      confidence: confidence,
      reason: reason,
    );
  }

  /// ตรวจสอบและระบุประเภทธุรกรรม (รายจ่าย vs รายรับ) โดยพิจารณาจากผู้ส่ง ผู้รับ และชื่อผู้ใช้
  static TransactionType _resolveTransactionType({
    String? senderName,
    String? receiverName,
    String? userProfileName,
    String? memo,
    required String fullText,
    required bool hasExplicitIncomeSignal,
  }) {
    final lowerFull = fullText.toLowerCase();
    final lowerMemo = (memo ?? '').toLowerCase();

    // 1. ตรวจสอบชื่อผู้ใช้กับผู้ส่งและผู้รับ (User Profile Name Matching)
    if (userProfileName != null && userProfileName.trim().isNotEmpty) {
      final userClean = _cleanPersonName(userProfileName);
      if (userClean.isNotEmpty) {
        final senderClean = senderName != null ? _cleanPersonName(senderName) : '';
        final receiverClean = receiverName != null ? _cleanPersonName(receiverName) : '';

        // ถ้าชื่อผู้ใช้ตรงกับผู้ส่ง -> ผู้ใช้เป็นคนโอนเงินออก -> รายจ่าย 100%
        if (senderClean.isNotEmpty && _nameMatches(senderClean, userClean)) {
          return TransactionType.expense;
        }

        // ถ้าชื่อผู้ใช้ตรงกับผู้รับ และไม่ตรงกับผู้ส่ง -> ผู้ใช้ได้รับเงิน -> รายรับ
        if (receiverClean.isNotEmpty &&
            _nameMatches(receiverClean, userClean) &&
            !_nameMatches(senderClean, userClean)) {
          return TransactionType.income;
        }
      }
    }

    // 2. ถ้าผู้รับเงินเป็นร้านค้า ธุรกิจ หรือนิติบุคคล -> โอนจ่ายร้านค้า -> รายจ่าย 100%
    if (receiverName != null && receiverName.trim().isNotEmpty) {
      if (_isMerchantOrBusiness(receiverName)) {
        return TransactionType.expense;
      }
    }

    // 3. ตรวจสอบกรณีผู้ส่งเป็นบริษัท/นายจ้าง และผู้รับเป็นบุคคลธรรมดา พร้อมมีสัญญาณเงินเดือน/ค่าจ้าง -> รายรับ
    if (senderName != null && senderName.trim().isNotEmpty) {
      final senderIsOrg = _isMerchantOrBusiness(senderName);
      final receiverIsPerson = receiverName == null || !_isMerchantOrBusiness(receiverName);
      final hasSalaryKeyword = lowerMemo.contains('เงินเดือน') ||
          lowerMemo.contains('salary') ||
          lowerMemo.contains('payroll') ||
          lowerMemo.contains('ค่าจ้าง') ||
          lowerMemo.contains('ค่าแรง') ||
          lowerMemo.contains('โบนัส') ||
          lowerMemo.contains('bonus') ||
          lowerMemo.contains('รายได้') ||
          lowerFull.contains('เงินเดือน') ||
          lowerFull.contains('payroll');

      if (senderIsOrg && receiverIsPerson && (hasSalaryKeyword || hasExplicitIncomeSignal)) {
        return TransactionType.income;
      }
    }

    // 4. สัญญาณเงินเข้าที่ระบุชัดเจน (เช่น หัวสลิประบุ เงินเข้าสำเร็จ, เงินโอนเข้าสำเร็จ)
    if (hasExplicitIncomeSignal) {
      return TransactionType.income;
    }

    // 5. สลิปการโอนเงินทั่วไปของธนาคารในโทรศัพท์ -> สันนิษฐานเป็น "รายจ่าย" (Expense) เป็นค่าเริ่มต้น
    return TransactionType.expense;
  }

  /// ทำความสะอาดชื่อบุคคลเพื่อเปรียบเทียบความตรงกัน
  static String _cleanPersonName(String name) {
    return name
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'(นาย|นาง|นางสาว|น\.ส\.|ด\.ช\.|ด\.ญ\.|mr\.?|ms\.?|mrs\.?|dr\.?)\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[\*\.\-_\s]'), '')
        .trim();
  }

  /// เปรียบเทียบชื่อบุคคล 2 ชื่อ (รองรับกรณีมีตัวอักษร Masking เช่น พุทธดา ห * * *)
  static bool _nameMatches(String nameA, String nameB) {
    final a = _cleanPersonName(nameA);
    final b = _cleanPersonName(nameB);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.length >= 3 && b.length >= 3) {
      return a.contains(b) || b.contains(a);
    }
    return false;
  }

  /// ตรวจสอบว่าชื่อผู้รับ/ผู้ส่งเป็นนิติบุคคล ร้านค้า หรือบริการหรือไม่
  static bool _isMerchantOrBusiness(String name) {
    final lower = name.toLowerCase().trim();
    final prefixes = [
      'ร้าน', 'บจก.', 'บริษัท', 'หจก.', 'บมจ.', 'โรงพยาบาล', 'รพ.', 'คลินิก',
      'การไฟฟ้า', 'การประปา', 'เทศบาล', 'มหาวิทยาลัย', 'โรงเรียน', 'สำนักงาน',
      'สหกรณ์', 'ห้างหุ้นส่วน', 'ห้างสรรพสินค้า', 'ซุปเปอร์', 'มินิมาร์ท',
      'บลจ.', 'บมจ', 'บจ.',
    ];
    for (final p in prefixes) {
      if (name.startsWith(p) || lower.startsWith(p)) return true;
    }
    final keywords = [
      'co.,', 'ltd', 'limited', 'inc', 'corp', 'store', 'shop', 'market',
      'cafe', 'coffee', 'restaurant', 'express', 'shopee', 'lazada', 'grab',
      'lineman', 'foodpanda', 'netflix', 'spotify', 'apple', 'google',
      '7-eleven', 'เซเว่น', 'โลตัส', 'บิ๊กซี', 'ท็อปส์', 'amazon', 'station',
      'service', 'clinic', 'hospital', 'delivery', 'kfc', 'mcdonald',
      'starbucks', 'ptt', 'ปตท', 'bbl', 'ktb', 'scb', 'kbank', 'ktam',
      'dime', 'uob', 'ttb', 'cimb', 'tisco', 'shopeepay', 'truemoney',
    ];
    for (final kw in keywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// ตรวจ keyword หนึ่งตัวใน text (ASCII → word-boundary, Thai → contains)
  static bool _matchKeyword(String text, String keyword) {
    if (RegExp(r'^[a-zA-Z0-9\-\.]+$').hasMatch(keyword)) {
      return RegExp(
        r'\b' + RegExp.escape(keyword) + r'\b',
        caseSensitive: false,
      ).hasMatch(text);
    }
    return text.contains(keyword);
  }

  /// ค่าเสริมตามช่วงเวลา (time-of-day)
  static Map<String, int> _timeBoosts(int hour) {
    if (hour >= 6 && hour < 10) {
      return {'กาแฟ/เครื่องดื่ม': 3, 'อาหาร/ของกิน': 1, 'การเดินทาง': 1};
    } else if (hour >= 10 && hour < 14) {
      return {'อาหาร/ของกิน': 3, 'กาแฟ/เครื่องดื่ม': 1};
    } else if (hour >= 14 && hour < 18) {
      return {'ช้อปปิ้ง': 2, 'กาแฟ/เครื่องดื่ม': 1};
    } else if (hour >= 18 && hour < 22) {
      return {'อาหาร/ของกิน': 2, 'บันเทิง/พักผ่อน': 2, 'ช้อปปิ้ง': 1};
    } else {
      return {'บันเทิง/พักผ่อน': 2};
    }
  }

  /// เปรียบ receiverName/memo กับประวัติธุรกรรม คืน (category, count)
  static (String, int)? _matchHistory(
    String? receiverName,
    String? memo,
    List<TransactionItem> history,
  ) {
    if (receiverName == null && memo == null) return null;

    final normReceiver =
        receiverName != null ? _normalize(receiverName) : null;
    final normMemo = memo != null ? _normalize(memo) : null;

    final categoryCount = <String, int>{};

    for (final tx in history.take(120)) {
      // พยายามสกัด receiver จาก note format "ผู้รับ: X | ..."
      String? txReceiver;
      if (tx.note != null) {
        final m =
            RegExp(r'ผู้รับ:\s*(.+?)(?:\s*\||\s*$)').firstMatch(tx.note!);
        if (m != null) txReceiver = _normalize(m.group(1)!);
      }
      final txTitle = _normalize(tx.title);

      bool matched = false;
      if (normReceiver != null && normReceiver.length >= 3) {
        if (txReceiver != null &&
            (txReceiver.contains(normReceiver) ||
                normReceiver.contains(txReceiver))) {
          matched = true;
        } else if (txTitle.contains(normReceiver) ||
            normReceiver.contains(txTitle)) {
          matched = true;
        }
      }
      if (!matched && normMemo != null && normMemo.length >= 4) {
        if (txTitle.contains(normMemo) || normMemo.contains(txTitle)) {
          matched = true;
        }
      }

      if (matched) {
        categoryCount[tx.categoryName] =
            (categoryCount[tx.categoryName] ?? 0) + 1;
      }
    }

    if (categoryCount.isEmpty) return null;
    final best = categoryCount.entries
        .reduce((a, b) => a.value >= b.value ? a : b);
    return (best.key, best.value);
  }

  /// normalize ชื่อผู้โอน/ผู้รับ เพื่อเปรียบเทียบ
  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(
        RegExp(
          r'(นาย|นาง|นางสาว|บจก\.?|หจก\.?|บริษัท|ร้าน|mr\.?|ms\.?|mrs\.?|dr\.?)\s*',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// แปลง score → confidence 0.0–1.0
  static double _toConfidence(
    int score, {
    bool isHistory = false,
    int historyCount = 0,
  }) {
    if (isHistory && historyCount >= 3) return 0.93;
    if (isHistory && historyCount >= 1) return 0.86;
    if (score >= 30) return 0.78;
    if (score >= 20) return 0.67;
    if (score >= 10) return 0.55;
    if (score >= 5) return 0.38;
    return 0.25;
  }

  // ─── Category Definitions ─────────────────────────────────────────────────

  static const _fallbackDef = _CatDef(
    category: 'อื่นๆ',
    type: TransactionType.expense,
    costNature: CostNature.variable,
    keywords: [],
  );

  static const _fallbackIncomeDef = _CatDef(
    category: 'อื่นๆ',
    type: TransactionType.income,
    costNature: CostNature.notApplicable,
    keywords: [],
  );

  static const _defs = [
    // ── Income (รายรับ) ──────────────────────────────────────────
    _CatDef(
      category: 'เงินเดือน',
      type: TransactionType.income,
      costNature: CostNature.notApplicable,
      amountMin: 5000,
      amountMax: 1000000,
      keywords: [
        'เงินเดือน', 'payroll', 'salary', 'ค่าจ้าง', 'โบนัส', 'bonus',
        'สวัสดิการ', 'เบี้ยเลี้ยง', 'เงินปันผล', 'dividend', 'บำนาญ',
      ],
    ),
    _CatDef(
      category: 'ขายของ/รายได้เสริม',
      type: TransactionType.income,
      costNature: CostNature.notApplicable,
      amountMin: 50,
      amountMax: 500000,
      keywords: [
        'ขายของ', 'รายได้เสริม', 'ค่าสอน', 'คอมมิชชั่น', 'commission',
        'freelance', 'ฟรีแลนซ์', 'รับจ้าง', 'ค่าบริการ', 'ค่าแรง', 'ยอดขาย',
      ],
    ),
    _CatDef(
      category: 'เงินคืน/โอนคืน',
      type: TransactionType.income,
      costNature: CostNature.notApplicable,
      amountMin: 10,
      amountMax: 100000,
      keywords: [
        'คืนเงิน', 'โอนคืน', 'refund', 'เงินคืน', 'คืนค่า', 'cashback', 'แคชแบ็ค',
      ],
    ),

    // ── Expense (รายจ่าย) ──────────────────────────────────────────
    _CatDef(
      category: 'อาหาร/ของกิน',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 30,
      amountMax: 1500,
      keywords: [
        'ข้าว', 'อาหาร', 'กิน', 'ก๋วยเตี๋ยว', 'ขนม', 'ชาบู',
        'ส้มตำ', 'lunch', 'dinner', 'food', 'meal', 'กะเพรา',
        'หมูกระทะ', 'เซเว่น', '7-eleven', '7-11', 'breakfast',
        'ร้านอาหาร', 'pizza', 'sushi', 'ข้าวมันไก่', 'ยำ',
        'ต้มยำ', 'ผัดไทย', 'ลาบ', 'line man', 'lineman', 'grabfood',
        'grab food', 'foodpanda', 'robinhood', 'kfc', 'mcdonald',
        'chester', 'bar b q', 'mk', 'bonchon', 'yayoi', 'hachiban',
        'swensen', 'swensens', 'dairy queen', 'ชาบูชิ', 'บุฟเฟ่ต์',
        'เบเกอรี่', 'ขนมปัง', 'ไอศกรีม', 'ไอติม', 'delivery',
      ],
    ),
    _CatDef(
      category: 'กาแฟ/เครื่องดื่ม',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 30,
      amountMax: 350,
      keywords: [
        'กาแฟ', 'ชา', 'cafe', 'coffee', 'starbucks', 'amazon',
        'tea', 'ชานม', 'เต่าบิน', 'แบล็คแคนยอน', 'คาเฟ่',
        'bubble', 'doi chaang', 'inthanin',
      ],
    ),
    _CatDef(
      category: 'การเดินทาง',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 20,
      amountMax: 1200,
      keywords: [
        'bts', 'mrt', 'grab', 'bolt', 'น้ำมัน', 'แท็กซี่',
        'ค่าทางด่วน', 'ตั๋ว', 'ปตท', 'บางจาก', 'shell',
        'caltex', 'วิน', 'รถไฟ', 'lyft', 'uber', 'm-flow', 'mflow',
        'easypass', 'easy pass', 'ทางด่วน', 'bems', 'srtet',
        'airport rail link', 'ปั๊ม', 'esso', 'ptg', 'susco', 'เติมน้ำมัน',
      ],
    ),
    _CatDef(
      category: 'ที่อยู่อาศัย',
      type: TransactionType.expense,
      costNature: CostNature.fixed,
      amountMin: 1500,
      amountMax: 30000,
      keywords: [
        'ค่าห้อง', 'ค่าเช่า', 'หอ', 'คอนโด', 'rent', 'นิติ',
        'อาคาร', 'หมู่บ้าน', 'apartment',
      ],
    ),
    _CatDef(
      category: 'สาธารณูปโภค',
      type: TransactionType.expense,
      costNature: CostNature.fixed,
      amountMin: 100,
      amountMax: 10000,
      keywords: [
        'ค่าน้ำ', 'ค่าไฟ', 'การไฟฟ้านครหลวง', 'การประปา',
        'pea', 'mea', 'เน็ต', 'internet', 'โทรศัพท์',
        'ais', 'true', 'dtac', 'nt broadband', 'tot',
        'wifi', 'broadband', 'กฟน.', 'กฟภ.', 'กปน.', 'กปภ.',
        'ค่าโทร', 'ais fibre', 'true online', '3bb', 'nt',
      ],
    ),
    _CatDef(
      category: 'สุขภาพ/ยา',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 100,
      amountMax: 20000,
      keywords: [
        'ยา', 'หมอ', 'คลินิก', 'โรงพยาบาล', 'hospital',
        'pharmacy', 'ทันตกรรม', 'ฟัน', 'แพทย์', 'รักษา',
        'วัคซีน', 'clinic',
      ],
    ),
    _CatDef(
      category: 'การศึกษา',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 200,
      amountMax: 50000,
      keywords: [
        'เรียน', 'หนังสือ', 'คอร์ส', 'course', 'tuition',
        'ค่าเทอม', 'มหาลัย', 'university', 'school',
        'สถาบัน', 'อบรม', 'สอบ',
      ],
    ),
    _CatDef(
      category: 'เงินออม/DCA',
      type: TransactionType.savingsInvestment,
      costNature: CostNature.notApplicable,
      amountMin: 500,
      amountMax: 500000,
      keywords: [
        'ออม', 'dca', 'กองทุน', 'หุ้น', 'savings', 'invest',
        'สลาก', 'ทอง', 'crypto', 'binance', 'innovestx',
        'dime', 'ลงทุน', 'พันธบัตร', 'ssf', 'rmf',
        'ซื้อกองทุน', 'ซื้อหุ้น', 'เปิดพอร์ต', 'dime!',
        'krungthai xspring', 'k-cyber', 'scb easy invest',
      ],
    ),
    _CatDef(
      category: 'ช้อปปิ้ง',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 100,
      amountMax: 15000,
      keywords: [
        'shopee', 'lazada', 'tiktok', 'เสื้อ', 'กางเกง',
        'รองเท้า', 'ของเล่น', 'uniqlo', 'zara', 'shop',
        'หูฟัง', 'samsung', 'apple', 'แว่น', 'กระเป๋า',
        'เครื่องสำอาง', 'ชุด', 'tiktok shop', 'line man mart',
        'lotus', 'big c', 'cj express', 'makro', 'watson',
        'watsons', 'boots', 'ikea', 'homepro', 'mr.diy', 'diy',
        'decathlon', 'supermarket', 'ซูเปอร์มาร์เก็ต', 'ตลาด',
      ],
    ),
    _CatDef(
      category: 'บันเทิง/พักผ่อน',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 100,
      amountMax: 5000,
      keywords: [
        'netflix', 'spotify', 'youtube', 'สตรีมมิ่ง',
        'streaming', 'เอ็นเอฟ', 'nf', 'disney', 'prime',
        'hbo', 'apple tv', 'ตั๋วหนัง', 'major', 'sf',
        'เกม', 'steam', 'game', 'concert', 'ท่องเที่ยว',
      ],
    ),
    _CatDef(
      category: 'อื่นๆ',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      keywords: [],
    ),
  ];
}

// ─── Internal ─────────────────────────────────────────────────────────────────

class _CatDef {
  final String category;
  final TransactionType type;
  final CostNature costNature;
  final List<String> keywords;
  final double? amountMin;
  final double? amountMax;

  const _CatDef({
    required this.category,
    required this.type,
    required this.costNature,
    required this.keywords,
    this.amountMin,
    this.amountMax,
  });
}
