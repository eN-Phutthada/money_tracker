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
    required String fullText,
    required double amount,
    required DateTime transactionDate,
    List<TransactionItem> history = const [],
  }) {
    final combined =
        '${memo ?? ''} ${receiverName ?? ''} $fullText'.toLowerCase();

    // Score map: category → accumulated score
    final scores = <String, int>{for (final d in _defs) d.category: 0};
    final hints = <String, String>{};

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

    // ── Find Winner ──────────────────────────────────────────────────
    String best = 'อื่นๆ';
    int bestScore = 0;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        best = entry.key;
      }
    }

    final def = _defs.firstWhere(
      (d) => d.category == best,
      orElse: () => _fallbackDef,
    );

    final confidence = _toConfidence(
      bestScore,
      isHistory: historyCategory == best,
      historyCount: historyCount,
    );

    final reason = hints[best] ??
        (amount > 0
            ? 'ประมาณจากยอดเงิน ฿${amount.toStringAsFixed(0)}'
            : 'ค่าเริ่มต้น');

    return SlipPrediction(
      category: best,
      type: def.type,
      costNature: def.costNature,
      confidence: confidence,
      reason: reason,
    );
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

  static const _defs = [
    _CatDef(
      category: 'อาหาร/ของกิน',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 30, amountMax: 1500,
      keywords: [
        'ข้าว', 'อาหาร', 'กิน', 'ก๋วยเตี๋ยว', 'ขนม', 'ชาบู',
        'ส้มตำ', 'lunch', 'dinner', 'food', 'meal', 'กะเพรา',
        'หมูกระทะ', 'เซเว่น', '7-eleven', '7-11', 'breakfast',
        'ร้านอาหาร', 'pizza', 'sushi', 'ข้าวมันไก่', 'ยำ',
        'ต้มยำ', 'ผัดไทย', 'ลาบ',
      ],
    ),
    _CatDef(
      category: 'กาแฟ/เครื่องดื่ม',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 30, amountMax: 350,
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
      amountMin: 20, amountMax: 1200,
      keywords: [
        'bts', 'mrt', 'grab', 'bolt', 'น้ำมัน', 'แท็กซี่',
        'ค่าทางด่วน', 'ตั๋ว', 'ปตท', 'บางจาก', 'shell',
        'caltex', 'วิน', 'รถไฟ', 'lyft', 'uber',
      ],
    ),
    _CatDef(
      category: 'ที่อยู่อาศัย',
      type: TransactionType.expense,
      costNature: CostNature.fixed,
      amountMin: 1500, amountMax: 30000,
      keywords: [
        'ค่าห้อง', 'ค่าเช่า', 'หอ', 'คอนโด', 'rent', 'นิติ',
        'อาคาร', 'หมู่บ้าน', 'apartment',
      ],
    ),
    _CatDef(
      category: 'สาธารณูปโภค',
      type: TransactionType.expense,
      costNature: CostNature.fixed,
      amountMin: 100, amountMax: 10000,
      keywords: [
        'ค่าน้ำ', 'ค่าไฟ', 'การไฟฟ้านครหลวง', 'การประปา',
        'pea', 'mea', 'เน็ต', 'internet', 'โทรศัพท์',
        'ais', 'true', 'dtac', 'nt broadband', 'tot',
        'wifi', 'broadband',
      ],
    ),
    _CatDef(
      category: 'สุขภาพ/ยา',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 100, amountMax: 20000,
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
      amountMin: 200, amountMax: 50000,
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
      amountMin: 500, amountMax: 500000,
      keywords: [
        'ออม', 'dca', 'กองทุน', 'หุ้น', 'savings', 'invest',
        'สลาก', 'ทอง', 'crypto', 'binance', 'innovestx',
        'dime', 'ลงทุน', 'พันธบัตร', 'ssf', 'rmf',
      ],
    ),
    _CatDef(
      category: 'ช้อปปิ้ง',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 100, amountMax: 15000,
      keywords: [
        'shopee', 'lazada', 'tiktok', 'เสื้อ', 'กางเกง',
        'รองเท้า', 'ของเล่น', 'uniqlo', 'zara', 'shop',
        'หูฟัง', 'samsung', 'apple', 'แว่น', 'กระเป๋า',
        'เครื่องสำอาง', 'ชุด',
      ],
    ),
    _CatDef(
      category: 'บันเทิง/พักผ่อน',
      type: TransactionType.expense,
      costNature: CostNature.variable,
      amountMin: 100, amountMax: 5000,
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
