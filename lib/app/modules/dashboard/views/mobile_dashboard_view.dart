import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        children: [
          const DashboardHeader()
              .animate()
              .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          const BalanceCard()
              .animate()
              .fadeIn(delay: 60.ms, duration: 350.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.08, end: 0, delay: 60.ms, duration: 350.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          const DailyAllowanceCard()
              .animate()
              .fadeIn(delay: 120.ms, duration: 350.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.08, end: 0, delay: 120.ms, duration: 350.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          const FlFinanceChartCard()
              .animate()
              .fadeIn(delay: 180.ms, duration: 350.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.08, end: 0, delay: 180.ms, duration: 350.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          const RecentTransactionsCard()
              .animate()
              .fadeIn(delay: 240.ms, duration: 350.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.08, end: 0, delay: 240.ms, duration: 350.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 84), // Bottom padding for Floating Navigation Dock
        ],
      ),
    );
  }
}
