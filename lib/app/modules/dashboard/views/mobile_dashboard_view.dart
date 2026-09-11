import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/daily_allowance_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/fl_finance_chart_card.dart';
import '../widgets/recent_transactions_card.dart';

/// Single-Column Mobile Dashboard View
class MobileDashboardView extends GetView<DashboardController> {
  const MobileDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          DashboardHeader(),
          SizedBox(height: 14),
          BalanceCard(),
          SizedBox(height: 14),
          DailyAllowanceCard(),
          SizedBox(height: 14),
          FlFinanceChartCard(),
          SizedBox(height: 14),
          RecentTransactionsCard(),
          SizedBox(height: 96), // Bottom padding for Floating Navigation Dock
        ],
      ),
    );
  }
}
