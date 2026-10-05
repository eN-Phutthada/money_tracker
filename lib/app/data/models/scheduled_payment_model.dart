import 'transaction_model.dart';

/// ความถี่ของรอบการจ่ายเงินล่วงหน้า / จ่ายประจำ
enum ScheduleFrequency {
  oneTime, // ครั้งเดียวตามวันเวลาล่วงหน้าที่กำหนด
  daily, // ทุกวัน
  weekly, // ทุกสัปดาห์
  monthly, // ทุกเดือน (เช่น ทุกวันที่ 1, 25 หรือสิ้นเดือน)
  yearly, // ทุกปี
}

extension ScheduleFrequencyX on ScheduleFrequency {
  String get labelKey {
    switch (this) {
      case ScheduleFrequency.oneTime:
        return 'frequency_one_time';
      case ScheduleFrequency.daily:
        return 'frequency_daily';
      case ScheduleFrequency.weekly:
        return 'frequency_weekly';
      case ScheduleFrequency.monthly:
        return 'frequency_monthly';
      case ScheduleFrequency.yearly:
        return 'frequency_yearly';
    }
  }
}

/// สถานะของรายการตั้งเวลา
enum ScheduledPaymentStatus {
  active, // กำลังทำงาน / รอถึงกำหนด
  paused, // พักการใช้งานชั่วคราว
  completed, // จ่ายเสร็จสิ้นแล้ว (สำหรับ oneTime)
}

/// โมเดลรายการตั้งเวลาการจ่ายเงินล่วงหน้า (Advance & Recurring Scheduled Payment)
class ScheduledPaymentItem {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final CostNature costNature;
  final String categoryName;
  final ScheduleFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? endDate;
  final bool autoRecord; // true: บันทึกเข้าธุรกรรมอัตโนมัติเมื่อถึงกำหนด, false: เตือนให้ผู้ใช้กดยืนยันจ่าย
  final ScheduledPaymentStatus status;
  final String? note;
  final DateTime? lastExecutedDate;
  final DateTime? previousDueDate;
  final int reminderDaysBefore; // เตือนล่วงหน้ากี่วัน (ค่าเริ่มต้น 1 วัน)

  const ScheduledPaymentItem({
    required this.id,
    required this.title,
    required this.amount,
    this.type = TransactionType.expense,
    this.costNature = CostNature.fixed,
    required this.categoryName,
    this.frequency = ScheduleFrequency.monthly,
    required this.startDate,
    required this.nextDueDate,
    this.endDate,
    this.autoRecord = false,
    this.status = ScheduledPaymentStatus.active,
    this.note,
    this.lastExecutedDate,
    this.previousDueDate,
    this.reminderDaysBefore = 1,
  });

  bool get isActive => status == ScheduledPaymentStatus.active;
  bool get isPaused => status == ScheduledPaymentStatus.paused;
  bool get isCompleted => status == ScheduledPaymentStatus.completed;

  /// เป็นค่าใช้จ่ายประเภทคงที่และกำลังเปิดใช้งานอยู่หรือไม่
  bool get isFixedExpense =>
      isActive &&
      type == TransactionType.expense &&
      costNature == CostNature.fixed;

  /// คำนวณค่ายอดเฉลี่ยต่อเดือนของรายการนี้ (Normalized Monthly Amount)
  double get monthlyEquivalentAmount {
    switch (frequency) {
      case ScheduleFrequency.monthly:
        return amount;
      case ScheduleFrequency.yearly:
        return amount / 12.0;
      case ScheduleFrequency.weekly:
        return (amount * 52.0) / 12.0;
      case ScheduleFrequency.daily:
        return amount * 30.0;
      case ScheduleFrequency.oneTime:
        final now = DateTime.now();
        if (nextDueDate.year == now.year && nextDueDate.month == now.month) {
          return amount;
        }
        return 0.0;
    }
  }

  /// ตรวจสอบว่าถึงกำหนดหรือเกินกำหนดชำระแล้วหรือไม่ (อ้างอิงระดับวัน)
  bool get isDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return dueDay.isBefore(today) || dueDay.isAtSameMomentAs(today);
  }

  /// จำนวนวันคงเหลือก่อนถึงกำหนด (ค่าติดลบแปลว่าเกินกำหนด)
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return dueDay.difference(today).inDays;
  }

  /// ตรวจสอบว่ากำลังจะถึงกำหนดในอีก [days] วันหรือไม่
  bool isDueSoon([int days = 7]) {
    final diff = daysUntilDue;
    return diff >= 0 && diff <= days;
  }

  /// คำนวณวันครบกำหนดรอบถัดไปอย่างแม่นยำ (รองรับเดือนที่มี 28/29/30/31 วัน)
  DateTime calculateNextDueDate([DateTime? fromDate]) {
    final base = fromDate ?? nextDueDate;

    switch (frequency) {
      case ScheduleFrequency.oneTime:
        return base;

      case ScheduleFrequency.daily:
        return DateTime(
          base.year,
          base.month,
          base.day + 1,
          base.hour,
          base.minute,
        );

      case ScheduleFrequency.weekly:
        return DateTime(
          base.year,
          base.month,
          base.day + 7,
          base.hour,
          base.minute,
        );

      case ScheduleFrequency.monthly:
        int targetYear = base.year;
        int targetMonth = base.month + 1;
        if (targetMonth > 12) {
          targetYear += 1;
          targetMonth = 1;
        }
        final maxDaysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final targetDay = startDate.day > maxDaysInTargetMonth
            ? maxDaysInTargetMonth
            : startDate.day;

        return DateTime(
          targetYear,
          targetMonth,
          targetDay,
          base.hour,
          base.minute,
        );

      case ScheduleFrequency.yearly:
        int targetYear = base.year + 1;
        int targetMonth = startDate.month;
        final maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
        final targetDay = startDate.day > maxDays ? maxDays : startDate.day;

        return DateTime(
          targetYear,
          targetMonth,
          targetDay,
          base.hour,
          base.minute,
        );
    }
  }

  /// คำนวณวันครบกำหนดรอบก่อนหน้า (ใช้สำหรับย้อนกลับเมื่อยกเลิกรายการจ่าย)
  DateTime calculatePreviousDueDate([DateTime? fromDate]) {
    final base = fromDate ?? nextDueDate;

    switch (frequency) {
      case ScheduleFrequency.oneTime:
        return startDate;

      case ScheduleFrequency.daily:
        return DateTime(
          base.year,
          base.month,
          base.day - 1,
          base.hour,
          base.minute,
        );

      case ScheduleFrequency.weekly:
        return DateTime(
          base.year,
          base.month,
          base.day - 7,
          base.hour,
          base.minute,
        );

      case ScheduleFrequency.monthly:
        int targetYear = base.year;
        int targetMonth = base.month - 1;
        if (targetMonth < 1) {
          targetYear -= 1;
          targetMonth = 12;
        }
        final maxDaysInTargetMonth =
            DateTime(targetYear, targetMonth + 1, 0).day;
        final targetDay = startDate.day > maxDaysInTargetMonth
            ? maxDaysInTargetMonth
            : startDate.day;

        return DateTime(
          targetYear,
          targetMonth,
          targetDay,
          base.hour,
          base.minute,
        );

      case ScheduleFrequency.yearly:
        int targetYear = base.year - 1;
        int targetMonth = startDate.month;
        final maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
        final targetDay = startDate.day > maxDays ? maxDays : startDate.day;

        return DateTime(
          targetYear,
          targetMonth,
          targetDay,
          base.hour,
          base.minute,
        );
    }
  }

  ScheduledPaymentItem copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    CostNature? costNature,
    String? categoryName,
    ScheduleFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
    bool? autoRecord,
    ScheduledPaymentStatus? status,
    String? note,
    DateTime? lastExecutedDate,
    DateTime? previousDueDate,
    int? reminderDaysBefore,
  }) {
    return ScheduledPaymentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      costNature: costNature ?? this.costNature,
      categoryName: categoryName ?? this.categoryName,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
      autoRecord: autoRecord ?? this.autoRecord,
      status: status ?? this.status,
      note: note ?? this.note,
      lastExecutedDate: lastExecutedDate ?? this.lastExecutedDate,
      previousDueDate: previousDueDate ?? this.previousDueDate,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
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
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'autoRecord': autoRecord,
      'status': status.name,
      'note': note,
      'lastExecutedDate': lastExecutedDate?.toIso8601String(),
      'previousDueDate': previousDueDate?.toIso8601String(),
      'reminderDaysBefore': reminderDaysBefore,
    };
  }

  factory ScheduledPaymentItem.fromJson(Map<String, dynamic> json) {
    return ScheduledPaymentItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'ไม่มีชื่อรายการ',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      costNature: CostNature.values.firstWhere(
        (e) => e.name == json['costNature'],
        orElse: () => CostNature.fixed,
      ),
      categoryName: json['categoryName'] as String? ?? 'ทั่วไป',
      frequency: ScheduleFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => ScheduleFrequency.monthly,
      ),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.tryParse(json['nextDueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      autoRecord: json['autoRecord'] as bool? ?? false,
      status: ScheduledPaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ScheduledPaymentStatus.active,
      ),
      note: json['note'] as String?,
      lastExecutedDate: json['lastExecutedDate'] != null
          ? DateTime.tryParse(json['lastExecutedDate'] as String)
          : null,
      previousDueDate: json['previousDueDate'] != null
          ? DateTime.tryParse(json['previousDueDate'] as String)
          : null,
      reminderDaysBefore: (json['reminderDaysBefore'] as num?)?.toInt() ?? 1,
    );
  }
}
