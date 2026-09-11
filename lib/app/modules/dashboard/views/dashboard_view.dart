import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/liquid_glass_nav_dock.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../security/controllers/security_controller.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';
import 'desktop_dashboard_view.dart';
import 'mobile_dashboard_view.dart';

/// หน้าจอหลักแดชบอร์ดพร้อมระบบตรวจจับหน้าจออัตโนมัติ (Mobile & Desktop) สไตล์ FinTech 2026
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.keyN) {
        QuickAddBottomSheet.show(Get.context!);
      } else if (key == LogicalKeyboardKey.keyT) {
        Get.toNamed(Routes.TRANSACTIONS_LIST);
      } else if (key == LogicalKeyboardKey.keyS) {
        Get.toNamed(Routes.BUDGET_SETTINGS);
      } else if (key == LogicalKeyboardKey.keyD) {
        controller.toggleTheme();
      } else if (key == LogicalKeyboardKey.keyM) {
        Get.toNamed(Routes.DATA_MANAGEMENT);
      } else if (key == LogicalKeyboardKey.keyP) {
        Get.toNamed(Routes.PIN_SETTINGS);
      } else if (key == LogicalKeyboardKey.keyL) {
        if (Get.isRegistered<SecurityController>()) {
          Get.find<SecurityController>().lock();
        }
      } else if (key == LogicalKeyboardKey.digit1) {
        controller.setTimeFilter(TimeFilterPeriod.monthly);
      } else if (key == LogicalKeyboardKey.digit2) {
        controller.setTimeFilter(TimeFilterPeriod.yearly);
      } else if (key == LogicalKeyboardKey.digit3) {
        controller.setTimeFilter(TimeFilterPeriod.allTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: controller.keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        extendBody: true,
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        appBar: isDesktop ? null : _buildMobileAppBar(context),
        body: LiquidGlassNavDock.floatingOnScreen(
          context: context,
          currentRoute: Routes.DASHBOARD,
          body: Stack(
            children: [
              // Ambient Canvas Glow Lighting behind header
              if (!isDesktop)
                Positioned(
                  top: -60,
                  left: MediaQuery.of(context).size.width / 2 - 150,
                  child: IgnorePointer(
                    child: Container(
                      width: 300,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isDark
                                    ? AppColors.primary
                                    : const Color(0xFF6EE7B7))
                                .withValues(alpha: isDark ? 0.14 : 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.75],
                        ),
                      ),
                    ),
                  ),
                ),

              SafeArea(
                child: isDesktop
                    ? const DesktopDashboardView()
                    : const MobileDashboardView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernAppBar(
      showBackButton: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14, top: 11, bottom: 11, right: 2),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.32),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      title: 'Money Tracker',
      subtitle: 'Personal Finance',
      actions: [
        // 1. Live Security Pulse Badge
        ModernAppBar.securityBadge(context: context, isDark: isDark),

        // 2. One-Tap Quick Theme Morphing Squircle
        ModernAppBar.themeToggleButton(context: context, isDark: isDark),
      ],
    );
  }
}
