/// ประเภทหลักของกระแสเงินสด
enum TransactionType {
  income,            // รายรับ
  expense,           // รายจ่าย
  savingsInvestment, // เงินออมและการลงทุน
}

/// ลักษณะของค่าใช้จ่าย (เฉพาะ Expense)
enum CostNature {
  fixed,          // ค่าใช้จ่ายคงที่ (Fixed Costs) เช่น ค่าหอ, ค่าเน็ต, ประกัน
  variable,       // ค่าใช้จ่ายผันแปร / จิปาถะ (Variable Costs) เช่น ค่ากิน, ช้อปปิ้ง
  notApplicable,  // ไม่ระบุ (ใช้สำหรับ รายรับ หรือ เงินออม)
}

/// ตัวกรองช่วงเวลา
enum TimeFilterPeriod {
  monthly, // รายเดือน
  yearly,  // รายปี
  allTime, // ยอดสะสมทั้งหมด
}

/// โมเดลรายการธุรกรรมทางการเงิน
class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final CostNature costNature;
  final String categoryName;
  final DateTime date;
  final String? note;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.costNature = CostNature.variable,
    required this.categoryName,
    required this.date,
    this.note,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isSavings => type == TransactionType.savingsInvestment;
  bool get isFixedCost => isExpense && costNature == CostNature.fixed;
  bool get isVariableCost => isExpense && costNature == CostNature.variable;

  static const Set<String> savingsWithdrawalCategories = {
    'savings_withdrawal',
    'ถอนเงินออม',
    'ถอนสำรองฉุกเฉิน',
    'ถอนใช้จ่ายทั่วไป',
    'ถอนปิดหนี้',
    'ถอนการลงทุน/กำไร',
    'ถอนเงินออมอื่นๆ',
    'Savings Withdrawal',
  };

  /// ตรวจสอบว่าเป็นรายการถอนเงินออมกลับเข้ากระเป๋าหรือไม่
  bool get isSavingsWithdrawal =>
      isIncome &&
      (savingsWithdrawalCategories.contains(categoryName) ||
          categoryName.startsWith('savings_withdrawal') ||
          categoryName.startsWith('ถอนเงินออม'));

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    CostNature? costNature,
    String? categoryName,
    DateTime? date,
    String? note,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      costNature: costNature ?? this.costNature,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'costNature': costNature.name,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'ไม่มีชื่อรายการ',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      costNature: CostNature.values.firstWhere(
        (e) => e.name == json['costNature'],
        orElse: () => CostNature.variable,
      ),
      categoryName: json['categoryName'] as String? ?? 'ทั่วไป',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: json['note'] as String?,
    );
  }
}
