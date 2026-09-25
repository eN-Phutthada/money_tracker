import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/liquid_glass_nav_dock.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../security/controllers/security_controller.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/wallet_health_diagnostic_sheet.dart';
import '../../../theme/app_popup_decorations.dart';
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
      } else if (key == LogicalKeyboardKey.keyH) {
        WalletHealthDiagnosticSheet.show(Get.context!);
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
                bottom: false,
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
      toolbarHeight: 66.0,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 0),
        child: Center(
          child: NothingAppLogo(
            size: 42,
            borderRadius: 14,
          ),
        ),
      ),
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Money Tracker',
              style: NothingTypography.grotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final name = controller.userName.value.isNotEmpty
                ? controller.userName.value
                : 'user_default'.tr;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showEditUserNameDialog(context, isDark),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.35 : 0.20),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4.5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 85),
                        child: Text(
                          name,
                          style: NothingTypography.grotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      subtitleWidget: StreamBuilder<DateTime>(
        stream: Stream.periodic(
          const Duration(seconds: 1),
          (_) => DateTime.now(),
        ),
        builder: (context, snapshot) {
          final now = snapshot.data ?? DateTime.now();
          final hour = now.hour.toString().padLeft(2, '0');
          final minute = now.minute.toString().padLeft(2, '0');
          final timeStr = '$hour:$minute';
          final isEn = controller.isEnglish;
          final monthStr = isEn
              ? DashboardController.englishMonthShortNames[now.month]
              : DashboardController.thaiMonthShortNames[now.month];
          final dateStr = 'today_date_display'.trParams({
            'day': '${now.day}',
            'month': monthStr,
            'time': timeStr,
          });

          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'app_subtitle'.tr,
                  style: NothingTypography.grotesk(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: NothingTypography.mono(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        // 1. Quick 1-Tap Theme Toggle
        ModernAppBar.themeToggleButton(context: context, isDark: isDark),
        // 2. Live Security Pulse Badge
        ModernAppBar.securityBadge(context: context, isDark: isDark),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showEditUserNameDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final textController = TextEditingController(text: controller.userName.value);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AppGlassDialog(
          maxWidth: 380,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPopupHeader(
                  title: 'edit_user_name'.tr,
                  subtitle: 'enter_user_name'.tr,
                  icon: Icons.person_rounded,
                  onClose: () => Navigator.of(dialogCtx).pop(),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'user_default'.tr,
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white : Colors.black,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    controller.setUserName(val);
                    Navigator.of(dialogCtx).pop();
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: Text(
                        'cancel'.tr,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        controller.setUserName(textController.text);
                        Navigator.of(dialogCtx).pop();
                      },
                      child: Text(
                        'save'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
