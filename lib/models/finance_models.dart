import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// 3 หมวดหมู่หลักของกระแสเงินสด
enum TransactionType {
  income,             // รายรับ
  expense,            // รายจ่าย
  savingsInvestment,  // เงินออม / การลงทุน
}

/// การจำแนกประเภทต้นทุนของรายจ่าย
enum CostNature {
  fixed,              // ค่าใช้จ่ายคงที่ (Fixed Costs: ค่าหอ, น้ำไฟ, เน็ต, ประกัน, subscription)
  variable,           // ค่าใช้จ่ายจิปาถะ (Variable / Misc Costs: ช้อปปิ้ง, ค่ากิน, สังสรรค์)
  notApplicable,      // สำหรับรายรับและเงินออม
}

/// ช่วงเวลาสำหรับตัวกรองข้อมูลบนแดชบอร์ด
enum TimeFilterPeriod {
  monthly,            // รายเดือน
  yearly,             // รายปี
  allTime,            // ทั้งหมด
}

extension TransactionTypeX on TransactionType {
  String get labelTh {
    switch (this) {
      case TransactionType.income:
        return 'รายรับ';
      case TransactionType.expense:
        return 'รายจ่าย';
      case TransactionType.savingsInvestment:
        return 'เงินออม / ลงทุน';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.savingsInvestment:
        return Icons.savings_outlined;
    }
  }

  Color get tagBgColor {
    switch (this) {
      case TransactionType.income:
        return AppColors.incomePastel;
      case TransactionType.expense:
        return AppColors.deficitBg;
      case TransactionType.savingsInvestment:
        return AppColors.savingsPastel;
    }
  }

  Color get tagTextColor {
    switch (this) {
      case TransactionType.income:
        return AppColors.incomeText;
      case TransactionType.expense:
        return AppColors.deficitText;
      case TransactionType.savingsInvestment:
        return AppColors.savingsText;
    }
  }
}

extension CostNatureX on CostNature {
  String get labelTh {
    switch (this) {
      case CostNature.fixed:
        return 'ค่าใช้จ่ายคงที่';
      case CostNature.variable:
        return 'ค่าใช้จ่ายจิปาถะ';
      case CostNature.notApplicable:
        return '-';
    }
  }

  Color get tagBgColor {
    switch (this) {
      case CostNature.fixed:
        return AppColors.fixedCostPastel;
      case CostNature.variable:
        return AppColors.variableCostPastel;
      case CostNature.notApplicable:
        return AppColors.surfaceSecondary;
    }
  }

  Color get tagTextColor {
    switch (this) {
      case CostNature.fixed:
        return AppColors.fixedCostText;
      case CostNature.variable:
        return AppColors.variableCostText;
      case CostNature.notApplicable:
        return AppColors.textTertiary;
    }
  }
}

/// โมเดลข้อมูลรายการธุรกรรมทางการเงิน
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
}

/// โมเดลแผนงบประมาณและการประมาณการ (Budget Plan)
class BudgetPlan {
  final double plannedIncome;          // รายรับตามเป้าหมายต่อเดือน
  final double targetDailyAllowance;    // ค่ากิน/ค่าใช้จ่ายต่อวัน (เป้าหมาย เช่น 300 บาท/วัน)
  final double targetMonthlySavings;   // เป้าหมายเงินออม/ลงทุนประจำเดือน
  final double plannedFixedCosts;      // งบค่าใช้จ่ายคงที่ประมาณการ (ค่าหอ, เน็ต, ฯลฯ)

  const BudgetPlan({
    required this.plannedIncome,
    required this.targetDailyAllowance,
    required this.targetMonthlySavings,
    required this.plannedFixedCosts,
  });

  /// งบประมาณรายจ่ายจิปาถะสำหรับทั้งเดือน (จำนวนวันในเดือน * เป้าหมายต่อวัน)
  double plannedVariableBudget(int daysInMonth) => targetDailyAllowance * daysInMonth;

  /// ยอดเงินคงเหลือที่ควรมีเมื่อสิ้นเดือนตามแผน
  double expectedEndingBalance(int daysInMonth) {
    return plannedIncome -
        plannedFixedCosts -
        plannedVariableBudget(daysInMonth) -
        targetMonthlySavings;
  }
}

/// สรุปผลการคำนวณและสถานะงบประมาณแบบเรียลไทม์
class BudgetSummary {
  final double totalIncome;
  final double totalFixedExpenses;
  final double totalVariableExpenses;
  final double totalSavings;
  final double actualNetBalance;        // ยอดคงเหลือจริง = รายรับจริง - รายจ่ายจริง - เงินออม
  final double expectedNetBalance;      // ยอดที่ควรเหลือตามแผน ณ วันปัจจุบัน
  final double surplusOrDeficit;        // ผลต่าง (เงินเกิน / เงินขาด)
  final double remainingDailyAllowance; // ค่ากิน/ใช้จ่ายเฉลี่ยที่เหลือใช้ได้ต่อวันจนสิ้นเดือน
  final int remainingDaysInMonth;       // จำนวนวันที่เหลือในเดือน
  final double dailyBurnRate;           // อัตราการใช้จ่ายต่อวันที่เกิดขึ้นจริง

  const BudgetSummary({
    required this.totalIncome,
    required this.totalFixedExpenses,
    required this.totalVariableExpenses,
    required this.totalSavings,
    required this.actualNetBalance,
    required this.expectedNetBalance,
    required this.surplusOrDeficit,
    required this.remainingDailyAllowance,
    required this.remainingDaysInMonth,
    required this.dailyBurnRate,
  });

  /// รวมรายจ่ายทั้งหมด (คงที่ + จิปาถะ)
  double get totalExpenses => totalFixedExpenses + totalVariableExpenses;

  /// สถานะว่าเป็นเงินเกิน (Surplus) หรือไม่
  bool get isSurplus => surplusOrDeficit >= 0;

  /// คำอธิบายสถานะ
  String get statusText => isSurplus ? 'เงินเกิน (Surplus)' : 'เงินขาด (Deficit)';
}
