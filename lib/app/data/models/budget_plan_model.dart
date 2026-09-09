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

  BudgetPlan copyWith({
    double? plannedIncome,
    double? targetDailyAllowance,
    double? targetMonthlySavings,
    double? plannedFixedCosts,
  }) {
    return BudgetPlan(
      plannedIncome: plannedIncome ?? this.plannedIncome,
      targetDailyAllowance: targetDailyAllowance ?? this.targetDailyAllowance,
      targetMonthlySavings: targetMonthlySavings ?? this.targetMonthlySavings,
      plannedFixedCosts: plannedFixedCosts ?? this.plannedFixedCosts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plannedIncome': plannedIncome,
      'targetDailyAllowance': targetDailyAllowance,
      'targetMonthlySavings': targetMonthlySavings,
      'plannedFixedCosts': plannedFixedCosts,
    };
  }

  factory BudgetPlan.fromJson(Map<String, dynamic> json) {
    return BudgetPlan(
      plannedIncome: (json['plannedIncome'] as num?)?.toDouble() ?? 45000.0,
      targetDailyAllowance: (json['targetDailyAllowance'] as num?)?.toDouble() ?? 300.0,
      targetMonthlySavings: (json['targetMonthlySavings'] as num?)?.toDouble() ?? 10000.0,
      plannedFixedCosts: (json['plannedFixedCosts'] as num?)?.toDouble() ?? 12500.0,
    );
  }
}
