import 'package:flutter/material.dart';
import 'scheduled_payment_model.dart';
import 'transaction_model.dart';

/// โมเดลสำหรับเทมเพลตรายการจ่ายล่วงหน้า/จ่ายประจำยอดนิยม (Scheduled Payment Preset)
class ScheduledPaymentPreset {
  final String id;
  final String titleKey;
  final double? suggestedAmount;
  final String categoryName;
  final CostNature costNature;
  final TransactionType type;
  final ScheduleFrequency frequency;
  final IconData icon;

  const ScheduledPaymentPreset({
    required this.id,
    required this.titleKey,
    this.suggestedAmount,
    required this.categoryName,
    required this.costNature,
    required this.type,
    required this.frequency,
    required this.icon,
  });

  /// รายการเทมเพลตบิลและภาระการเงินที่คนส่วนใหญ่จ่ายเป็นประจำ
  static const List<ScheduledPaymentPreset> curatedPresets = [
    // 1. สาธารณูปโภค (Utilities)
    ScheduledPaymentPreset(
      id: 'preset_electricity',
      titleKey: 'preset_electricity',
      suggestedAmount: 1200.0,
      categoryName: 'สาธารณูปโภค',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.bolt_rounded,
    ),
    ScheduledPaymentPreset(
      id: 'preset_water',
      titleKey: 'preset_water',
      suggestedAmount: 250.0,
      categoryName: 'สาธารณูปโภค',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.water_drop_rounded,
    ),

    // 2. การสื่อสาร & อินเทอร์เน็ต (Connectivity)
    ScheduledPaymentPreset(
      id: 'preset_internet',
      titleKey: 'preset_internet',
      suggestedAmount: 599.0,
      categoryName: 'การสื่อสาร',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.wifi_rounded,
    ),
    ScheduledPaymentPreset(
      id: 'preset_mobile',
      titleKey: 'preset_mobile',
      suggestedAmount: 499.0,
      categoryName: 'การสื่อสาร',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.phone_android_rounded,
    ),

    // 3. ที่อยู่อาศัย (Housing)
    ScheduledPaymentPreset(
      id: 'preset_rent',
      titleKey: 'preset_rent',
      suggestedAmount: 6500.0,
      categoryName: 'ที่อยู่อาศัย',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.home_work_rounded,
    ),
    ScheduledPaymentPreset(
      id: 'preset_condo_fee',
      titleKey: 'preset_condo_fee',
      suggestedAmount: 1500.0,
      categoryName: 'ที่อยู่อาศัย',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.apartment_rounded,
    ),

    // 4. สตรีมมิ่ง & บริการรายเดือน (Subscriptions)
    ScheduledPaymentPreset(
      id: 'preset_streaming',
      titleKey: 'preset_streaming',
      suggestedAmount: 419.0,
      categoryName: 'บันเทิง',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.movie_rounded,
    ),
    ScheduledPaymentPreset(
      id: 'preset_music',
      titleKey: 'preset_music',
      suggestedAmount: 179.0,
      categoryName: 'บันเทิง',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.headphones_rounded,
    ),
    ScheduledPaymentPreset(
      id: 'preset_cloud_storage',
      titleKey: 'preset_cloud_storage',
      suggestedAmount: 99.0,
      categoryName: 'บันเทิง',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.cloud_queue_rounded,
    ),

    // 5. ยานพาหนะ & หนี้สิน (Vehicle & Loans)
    ScheduledPaymentPreset(
      id: 'preset_car_loan',
      titleKey: 'preset_car_loan',
      suggestedAmount: 8500.0,
      categoryName: 'ยานพาหนะ/เดินทาง',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.directions_car_rounded,
    ),
    ScheduledPaymentPreset(
      id: 'preset_credit_card',
      titleKey: 'preset_credit_card',
      suggestedAmount: 3000.0,
      categoryName: 'หนี้สิน/บัตรเครดิต',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.credit_card_rounded,
    ),

    // 6. ความคุ้มครอง & การออมลงทุน (Insurance & DCA)
    ScheduledPaymentPreset(
      id: 'preset_insurance',
      titleKey: 'preset_insurance',
      suggestedAmount: 2500.0,
      categoryName: 'ประกัน',
      costNature: CostNature.fixed,
      type: TransactionType.expense,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.health_and_safety_rounded,
    ),
    ScheduledPaymentPreset(
      id: 'preset_auto_dca',
      titleKey: 'preset_auto_dca',
      suggestedAmount: 3000.0,
      categoryName: 'เงินออม/ลงทุน',
      costNature: CostNature.fixed,
      type: TransactionType.savingsInvestment,
      frequency: ScheduleFrequency.monthly,
      icon: Icons.trending_up_rounded,
    ),
  ];
}
