import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../security/controllers/security_controller.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../../../widgets/modern_app_bar.dart';
import '../controllers/dashboard_controller.dart';
import 'desktop_dashboard_view.dart';
import 'mobile_dashboard_view.dart';

/// หน้าจอหลักแดชบอร์ดพร้อมระบบตรวจจับหน้าจออัตโนมัติ (Mobile & Desktop)
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

    return KeyboardListener(
      focusNode: controller.keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: isDesktop ? null : _buildMobileAppBar(context),
        floatingActionButton: isDesktop
            ? null
            : FloatingActionButton.extended(
                onPressed: () => QuickAddBottomSheet.show(context),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
        body: SafeArea(
          child: isDesktop ? const DesktopDashboardView() : const MobileDashboardView(),
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
                color: AppColors.primary.withValues(alpha: 0.28),
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
      badgeWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.28),
            width: 0.8,
          ),
        ),
        child: const Text(
          'Smart FinTech',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      actions: [
        ModernAppBar.squircleIconButton(
          onTap: () => Get.toNamed(Routes.TRANSACTIONS_LIST),
          icon: Icons.receipt_long_rounded,
          isDark: isDark,
          tooltip: 'all_transactions'.tr,
        ),
        ModernAppBar.squircleIconButton(
          onTap: () => Get.toNamed(Routes.BUDGET_SETTINGS),
          icon: Icons.tune_rounded,
          isDark: isDark,
          tooltip: 'budget_settings'.tr,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Material(
            color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val == 'theme') {
                  showThemePickerDialog(context);
                } else if (val == 'language') {
                  showLanguagePickerDialog(context);
                } else if (val == 'data') {
                  Get.toNamed(Routes.DATA_MANAGEMENT);
                } else if (val == 'security') {
                  Get.toNamed(Routes.PIN_SETTINGS);
                } else if (val == 'lock') {
                  if (Get.isRegistered<SecurityController>()) {
                    Get.find<SecurityController>().lock();
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(
                        controller.themeMode.value == ThemeMode.system
                            ? Icons.brightness_auto_rounded
                            : (controller.themeMode.value == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded),
                        size: 18,
                        color: controller.themeMode.value == ThemeMode.system ? AppColors.primary : null,
                      ),
                      const SizedBox(width: 10),
                      Text('theme_label'.trParams({'theme': controller.themeModeName}), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'language',
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, size: 18, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 10),
                      Text('language_label'.trParams({'lang': controller.currentLanguageName}), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'data',
                  child: Row(
                    children: [
                      const Icon(Icons.storage_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text('data_management_short'.tr, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'security',
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Text('security_pin_short'.tr, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                if (Get.isRegistered<SecurityController>() && Get.find<SecurityController>().isPinEnabled.value)
                  PopupMenuItem(
                    value: 'lock',
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.deficitText),
                        const SizedBox(width: 10),
                        Text('lock_screen_now'.tr, style: const TextStyle(fontSize: 13, color: AppColors.deficitText)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
