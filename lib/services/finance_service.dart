import 'package:flutter/foundation.dart';
import '../models/finance_models.dart';

/// Business Logic Engine และ State Controller สำหรับการจัดการข้อมูลการเงิน
class FinanceService extends ChangeNotifier {
  // แผนงบประมาณเริ่มต้น
  BudgetPlan _budgetPlan = const BudgetPlan(
    plannedIncome: 45000.0,
    targetDailyAllowance: 350.0,
    targetMonthlySavings: 10000.0,
    plannedFixedCosts: 12500.0,
  );

  // ตัวกรองช่วงเวลาปัจจุบัน
  TimeFilterPeriod _currentPeriod = TimeFilterPeriod.monthly;
  DateTime _selectedDate = DateTime.now();

  // รายการธุรกรรมทั้งหมด
  final List<TransactionItem> _transactions = [];

  FinanceService() {
    _seedInitialData();
  }

  // Getters
  BudgetPlan get budgetPlan => _budgetPlan;
  TimeFilterPeriod get currentPeriod => _currentPeriod;
  DateTime get selectedDate => _selectedDate;
  List<TransactionItem> get allTransactions => List.unmodifiable(_transactions);

  /// รายการธุรกรรมที่ถูกกรองตามช่วงเวลาปัจจุบัน
  List<TransactionItem> get filteredTransactions {
    final list = _transactions.where((item) {
      switch (_currentPeriod) {
        case TimeFilterPeriod.monthly:
          return item.date.year == _selectedDate.year &&
              item.date.month == _selectedDate.month;
        case TimeFilterPeriod.yearly:
          return item.date.year == _selectedDate.year;
        case TimeFilterPeriod.allTime:
          return true;
      }
    }).toList();

    // เรียงจากวันที่ล่าสุดไปเก่าสุด
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// คำนวณสรุปผลการเงินและสถานะ Surplus/Deficit แบบเรียลไทม์
  BudgetSummary get summary {
    final items = filteredTransactions;

    double income = 0;
    double fixedExpenses = 0;
    double variableExpenses = 0;
    double savings = 0;

    for (final item in items) {
      switch (item.type) {
        case TransactionType.income:
          income += item.amount;
          break;
        case TransactionType.expense:
          if (item.costNature == CostNature.fixed) {
            fixedExpenses += item.amount;
          } else {
            variableExpenses += item.amount;
          }
          break;
        case TransactionType.savingsInvestment:
          savings += item.amount;
          break;
      }
    }

    // คำนวณยอดเงินคงเหลือจริง ณ ปัจจุบัน
    final double actualNet = income - (fixedExpenses + variableExpenses) - savings;

    // คำนวณจำนวนวันในเดือน
    final int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final now = DateTime.now();
    final bool isCurrentMonth = _selectedDate.year == now.year && _selectedDate.month == now.month;
    final int currentDay = isCurrentMonth ? now.day : daysInMonth;
    final int remainingDays = (daysInMonth - currentDay + 1).clamp(1, daysInMonth);

    // การคำนวณตามแผน (Budgeting & Forecasting)
    double expectedNet;
    double remainingDaily;
    double burnRate = variableExpenses / (currentDay > 0 ? currentDay : 1);

    if (_currentPeriod == TimeFilterPeriod.monthly) {
      // ค่ากิน/ใช้จ่ายที่ควรใช้ไปแล้ว ณ วันที่ปัจจุบัน
      final double expectedVariableSpentToDate = _budgetPlan.targetDailyAllowance * currentDay;
      
      // ยอดเงินที่ควรเหลือตามแผน ณ วันปัจจุบัน
      expectedNet = _budgetPlan.plannedIncome -
          _budgetPlan.plannedFixedCosts -
          expectedVariableSpentToDate -
          _budgetPlan.targetMonthlySavings;

      // งบค่ากิน/จิปาถะทั้งเดือนตามแผน
      final double totalVariableBudget = _budgetPlan.plannedVariableBudget(daysInMonth);
      final double remainingVariableBudget = (totalVariableBudget - variableExpenses).clamp(0, double.infinity);
      remainingDaily = remainingVariableBudget / remainingDays;
    } else if (_currentPeriod == TimeFilterPeriod.yearly) {
      final double yearlyPlannedIncome = _budgetPlan.plannedIncome * 12;
      final double yearlyPlannedFixed = _budgetPlan.plannedFixedCosts * 12;
      final double yearlyPlannedVar = _budgetPlan.targetDailyAllowance * 365;
      final double yearlyPlannedSavings = _budgetPlan.targetMonthlySavings * 12;
      expectedNet = yearlyPlannedIncome - yearlyPlannedFixed - yearlyPlannedVar - yearlyPlannedSavings;
      remainingDaily = _budgetPlan.targetDailyAllowance;
    } else {
      expectedNet = 0.0;
      remainingDaily = _budgetPlan.targetDailyAllowance;
    }

    // คำนวณ Surplus (+) หรือ Deficit (-)
    final double diff = actualNet - expectedNet;

    return BudgetSummary(
      totalIncome: income,
      totalFixedExpenses: fixedExpenses,
      totalVariableExpenses: variableExpenses,
      totalSavings: savings,
      actualNetBalance: actualNet,
      expectedNetBalance: expectedNet,
      surplusOrDeficit: diff,
      remainingDailyAllowance: remainingDaily,
      remainingDaysInMonth: remainingDays,
      dailyBurnRate: burnRate,
    );
  }

  // Actions
  void addTransaction(TransactionItem item) {
    _transactions.add(item);
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void setTimeFilter(TimeFilterPeriod period) {
    _currentPeriod = period;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void previousPeriod() {
    if (_currentPeriod == TimeFilterPeriod.monthly) {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    } else if (_currentPeriod == TimeFilterPeriod.yearly) {
      _selectedDate = DateTime(_selectedDate.year - 1);
    }
    notifyListeners();
  }

  void nextPeriod() {
    if (_currentPeriod == TimeFilterPeriod.monthly) {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    } else if (_currentPeriod == TimeFilterPeriod.yearly) {
      _selectedDate = DateTime(_selectedDate.year + 1);
    }
    notifyListeners();
  }

  void updateBudgetPlan(BudgetPlan plan) {
    _budgetPlan = plan;
    notifyListeners();
  }

  /// ข้อมูลจำลองเริ่มต้นเพื่อให้เปิดแอปแล้วเห็นตัวเลขและการทำงานได้ทันที
  void _seedInitialData() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    _transactions.addAll([
      // รายรับ
      TransactionItem(
        id: '1',
        title: 'เงินเดือน (Salary)',
        amount: 45000.0,
        type: TransactionType.income,
        costNature: CostNature.notApplicable,
        categoryName: 'งานประจำ',
        date: DateTime(year, month, 1),
        note: 'เงินเดือนโอนเข้าบัญชีหลัก',
      ),
      TransactionItem(
        id: '2',
        title: 'งานฟรีแลนซ์ (Freelance Design)',
        amount: 5500.0,
        type: TransactionType.income,
        costNature: CostNature.notApplicable,
        categoryName: 'รายได้เสริม',
        date: DateTime(year, month, 5),
        note: 'ออกแบบ Banner เว็บไซต์',
      ),

      // ค่าใช้จ่ายคงที่ (Fixed Costs)
      TransactionItem(
        id: '3',
        title: 'ค่าเช่าคอนโด / หอพัก',
        amount: 8500.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'ที่อยู่อาศัย',
        date: DateTime(year, month, 2),
      ),
      TransactionItem(
        id: '4',
        title: 'ค่าน้ำ - ค่าไฟฟ้า',
        amount: 1450.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'สาธารณูปโภค',
        date: DateTime(year, month, 3),
      ),
      TransactionItem(
        id: '5',
        title: 'ค่าอินเทอร์เน็ต & ซิมรายเดือน',
        amount: 799.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'การสื่อสาร',
        date: DateTime(year, month, 4),
      ),
      TransactionItem(
        id: '6',
        title: 'เบี้ยประกันชีวิตและสุขภาพ',
        amount: 1800.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'ประกันสุขภาพ',
        date: DateTime(year, month, 5),
      ),

      // เงินออม / การลงทุน
      TransactionItem(
        id: '7',
        title: 'ออมกองทุนดัชนี S&P500 (DCA)',
        amount: 7000.0,
        type: TransactionType.savingsInvestment,
        costNature: CostNature.notApplicable,
        categoryName: 'กองทุนรวม',
        date: DateTime(year, month, 2),
        note: 'DCA อัตโนมัติต้นเดือน',
      ),
      TransactionItem(
        id: '8',
        title: 'บัญชีเงินฝากดอกเบี้ยสูง e-Savings',
        amount: 3000.0,
        type: TransactionType.savingsInvestment,
        costNature: CostNature.notApplicable,
        categoryName: 'เงินสำรองฉุกเฉิน',
        date: DateTime(year, month, 2),
      ),

      // ค่าใช้จ่ายจิปาถะ / ค่ากิน (Variable Costs)
      TransactionItem(
        id: '9',
        title: 'วัตถุดิบทำอาหาร & ตลาดสด',
        amount: 680.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'อาหาร/ของกิน',
        date: DateTime(year, month, 6),
      ),
      TransactionItem(
        id: '10',
        title: 'ทานข้าวนอกบ้าน & กาแฟ Speciality',
        amount: 290.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'อาหาร/ของกิน',
        date: DateTime(year, month, 7),
      ),
      TransactionItem(
        id: '11',
        title: 'ของใช้ในบ้าน / ซูเปอร์มาร์เก็ต',
        amount: 450.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'ของใช้ส่วนตัว',
        date: DateTime(year, month, 8),
      ),
    ]);
  }
}
