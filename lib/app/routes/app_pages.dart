// ignore_for_file: constant_identifier_names
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import '../modules/budget/controllers/budget_controller.dart';
import '../modules/budget/views/budget_settings_view.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/data_management/views/data_management_view.dart';
import '../modules/security/controllers/security_controller.dart';
import '../modules/security/views/pin_lock_view.dart';
import '../modules/security/views/pin_settings_view.dart';
import '../modules/transactions/views/transactions_list_view.dart';
import 'app_routes.dart';
import 'modern_page_transition.dart';

/// การกำหนดค่า Route และ Dependency Bindings สำหรับ GetX 4.7.3
class AppPages {
  static const INITIAL = Routes.DASHBOARD;

  static final routes = [
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      customTransition: ModernNothingTransition(),
      transitionDuration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: Routes.BUDGET_SETTINGS,
      page: () => const BudgetSettingsView(),
      binding: BudgetBinding(),
      customTransition: ModernNothingTransition(),
      transitionDuration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: Routes.TRANSACTIONS_LIST,
      page: () => const TransactionsListView(),
      customTransition: ModernNothingTransition(),
      transitionDuration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: Routes.DATA_MANAGEMENT,
      page: () => const DataManagementView(),
      customTransition: ModernNothingTransition(),
      transitionDuration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: Routes.PIN_SETTINGS,
      page: () => const PinSettingsView(),
      customTransition: ModernNothingTransition(),
      transitionDuration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: Routes.PIN_LOCK,
      page: () => const PinLockView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    ),
  ];
}

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<DashboardController>(DashboardController(), permanent: true);
    Get.put<SecurityController>(SecurityController(), permanent: true);
  }
}

class BudgetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BudgetController>(() => BudgetController());
  }
}
