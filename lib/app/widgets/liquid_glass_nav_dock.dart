import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/security/controllers/security_controller.dart';
import '../modules/transactions/views/quick_add_bottom_sheet.dart';
import '../modules/transactions/views/bank_slip_sheet.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_popup_decorations.dart';
import 'nothing_ui_components.dart';

/// แถบนำทางกระจกใสเหลวลอยตัวสไตล์ Nothing OS Design
/// - สไตล์ Smoked Black / Minimal Monochrome Dock ลอยตัวเหนือพื้นหลัง
/// - เลนส์กระจก Squircle ขอบมน 28px พร้อม OpticalBorder บางเบา
/// - ปุ่มบันทึกด่วนสีแดงเอกลักษณ์ Nothing Red ตรงกลาง
/// - จุดสถานะ Active สไตล์ LED Dot Indicator สีแดง Nothing Red
/// - เมนูศูนย์ควบคุม Hub & Vault สไตล์ Nothing UI
class LiquidGlassNavDock extends StatelessWidget {
  final String currentRoute;
  final GlobalKey? backgroundKey;

  const LiquidGlassNavDock({
    super.key,
    required this.currentRoute,
    this.backgroundKey,
  });

  /// ตัวช่วยครอบหน้าจอให้ Floating Dock ลอยอยู่บนหน้าจออัตโนมัติ (ซ่อนบนจอ Desktop >= 900px)
  static Widget floatingOnScreen({
    required BuildContext context,
    required Widget body,
    required String currentRoute,
    GlobalKey? backgroundKey,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    if (isDesktop) return body;

    final actualBgKey = backgroundKey ?? GlobalKey();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');

    return LiquidGlassView(
      backgroundWidget: RepaintBoundary(
        key: actualBgKey,
        child: body,
      ),
      realTimeCapture: !isTest,
      regionCapture: true,
      refreshRate: LiquidGlassRefreshRate.medium,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: LiquidGlassNavDock(
              currentRoute: currentRoute,
              backgroundKey: actualBgKey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardController = Get.find<DashboardController>();

    final style = LiquidGlassStyle(
      shape: const LiquidGlassShape.squircle(
        cornerRadius: 28,
        borderWidth: 1.0,
        lightIntensity: 1.1,
        lightDirection: 75,
        borderType: OpticalBorder(
          borderSaturation: 1.1,
          ambientIntensity: 1.0,
          borderSolidity: 0.20,
        ),
      ),
      appearance: LiquidGlassAppearance(
        color: isDark
            ? const Color(0xFF000000).withValues(alpha: 0.76)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.85),
        blur: const LiquidGlassBlur(sigmaX: 14, sigmaY: 14),
      ),
      refraction: const LiquidGlassRefraction(
        distortion: 0.05,
        distortionWidth: 20,
        chromaticAberration: 0.001,
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: SizedBox(
              height: 66,
              child: LiquidGlassLens(
                style: style,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: isDark
                        ? const Color(0xFF0A0A0A).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.7),
                    border: Border.all(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 1. Home / Overview
                      _buildDockItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        tooltip: 'dashboard_overview'.tr,
                        isActive: currentRoute == Routes.DASHBOARD,
                        isDark: isDark,
                        onTap: () {
                          if (currentRoute != Routes.DASHBOARD) {
                            Get.until((route) =>
                                route.isFirst ||
                                route.settings.name == Routes.DASHBOARD);
                          }
                        },
                      ),

                      // 2. Transactions History
                      _buildDockItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        tooltip: 'all_transactions'.tr,
                        isActive: currentRoute == Routes.TRANSACTIONS_LIST,
                        isDark: isDark,
                        onTap: () {
                          if (currentRoute != Routes.TRANSACTIONS_LIST) {
                            if (currentRoute != Routes.DASHBOARD) {
                              Get.offNamed(Routes.TRANSACTIONS_LIST);
                            } else {
                              Get.toNamed(Routes.TRANSACTIONS_LIST);
                            }
                          }
                        },
                      ),

                      // 3. Center Nothing Red Quick Add Button
                      _buildCenterAddButton(context),

                      // 4. Budget Settings
                      _buildDockItem(
                        icon: Icons.tune_outlined,
                        activeIcon: Icons.tune_rounded,
                        tooltip: 'budget_settings'.tr,
                        isActive: currentRoute == Routes.BUDGET_SETTINGS,
                        isDark: isDark,
                        onTap: () {
                          if (currentRoute != Routes.BUDGET_SETTINGS) {
                            if (currentRoute != Routes.DASHBOARD) {
                              Get.offNamed(Routes.BUDGET_SETTINGS);
                            } else {
                              Get.toNamed(Routes.BUDGET_SETTINGS);
                            }
                          }
                        },
                      ),

                      // 5. Hub & Vault Control Center Menu
                      _buildDockVaultMenu(context, isDark, dashboardController),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// รายการนำทางเดี่ยวบน Dock พร้อมสถานะ Active สไตล์ Nothing OS
  Widget _buildDockItem({
    required IconData icon,
    IconData? activeIcon,
    required String tooltip,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive
                ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDEDED))
                : Colors.transparent,
            border: isActive
                ? Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                    width: 0.8,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                size: 21,
                color: isActive
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? const Color(0xFF888888) : const Color(0xFF777777)),
              ),
              if (isActive) ...[
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.nothingRed,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// เมนูศูนย์ควบคุม Hub & Vault สไตล์ Nothing OS
  Widget _buildDockVaultMenu(
    BuildContext context,
    bool isDark,
    DashboardController controller,
  ) {
    final isVaultActive = currentRoute == Routes.DATA_MANAGEMENT || currentRoute == Routes.PIN_SETTINGS;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: (isDark ? const Color(0xFF121212) : Colors.white).withValues(alpha: 0.98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          elevation: 16,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'data_management_short'.tr,
        offset: const Offset(0, -10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        color: (isDark ? const Color(0xFF121212) : Colors.white).withValues(alpha: 0.98),
        elevation: 16,
        onSelected: (val) {
          HapticFeedback.selectionClick();
          if (val == 'slip') {
            BankSlipScanModal.show(context);
          } else if (val == 'theme') {
            showThemePickerDialog(context);
          } else if (val == 'language') {
            showLanguagePickerDialog(context);
          } else if (val == 'data') {
            if (currentRoute != Routes.DATA_MANAGEMENT) {
              if (currentRoute != Routes.DASHBOARD) {
                Get.offNamed(Routes.DATA_MANAGEMENT);
              } else {
                Get.toNamed(Routes.DATA_MANAGEMENT);
              }
            }
          } else if (val == 'security') {
            if (currentRoute != Routes.PIN_SETTINGS) {
              if (currentRoute != Routes.DASHBOARD) {
                Get.offNamed(Routes.PIN_SETTINGS);
              } else {
                Get.toNamed(Routes.PIN_SETTINGS);
              }
            }
          } else if (val == 'lock') {
            if (Get.isRegistered<SecurityController>()) {
              Get.find<SecurityController>().lock();
            }
          }
        },
        itemBuilder: (ctx) {
          final isPinOn = Get.isRegistered<SecurityController>() &&
              Get.find<SecurityController>().isPinEnabled.value;

          return [
            // Header
            PopupMenuItem<String>(
              enabled: false,
              height: 32,
              child: Row(
                children: [
                  const NothingLedIndicator(color: AppColors.nothingRed, size: 5),
                  const SizedBox(width: 8),
                  NothingDotText(
                    'SYSTEM // VAULT',
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),

            // 1. Theme
            PopupMenuItem<String>(
              value: 'theme',
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      (controller.themeMode.value == ThemeMode.dark ||
                              (controller.themeMode.value == ThemeMode.system && isDark))
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      size: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'theme_settings'.tr,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  NothingPill(
                    label: controller.themeModeName.toUpperCase(),
                    color: isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE),
                    textColor: isDark ? Colors.white : Colors.black,
                    isDotMatrix: true,
                    fontSize: 9.5,
                  ),
                ],
              ),
            ),

            // 2. Language
            PopupMenuItem<String>(
              value: 'language',
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'language_settings'.tr,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  NothingPill(
                    label: controller.isEnglish ? 'EN' : 'TH',
                    color: isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE),
                    textColor: isDark ? Colors.white : Colors.black,
                    isDotMatrix: true,
                    fontSize: 9.5,
                  ),
                ],
              ),
            ),

            // 3. Data Management
            PopupMenuItem<String>(
              value: 'data',
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.storage_outlined,
                      size: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'data_management_short'.tr,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Security PIN Settings
            PopupMenuItem<String>(
              value: 'security',
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.security_outlined,
                      size: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'security_pin_short'.tr,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Scan Krungthai Slip
            PopupMenuItem<String>(
              value: 'slip',
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.document_scanner_outlined,
                      size: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'scan_bank_slip'.tr,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 6. Lock Screen Now (if PIN enabled)
            if (isPinOn)
              PopupMenuItem<String>(
                value: 'lock',
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.nothingRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppColors.nothingRed.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: AppColors.nothingRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'lock_screen_now'.tr,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.nothingRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ];
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isVaultActive
                ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDEDED))
                : Colors.transparent,
            border: isVaultActive
                ? Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                    width: 0.8,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.widgets_outlined,
                    size: 21,
                    color: isVaultActive
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xFF888888) : const Color(0xFF777777)),
                  ),
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.nothingRed,
                      ),
                    ),
                  ),
                ],
              ),
              if (isVaultActive) ...[
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.nothingRed,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ปุ่มวงกลมมนสีแดง Nothing Red ตรงกลางสำหรับบันทึกรายการด่วน
  Widget _buildCenterAddButton(BuildContext context) {
    return Tooltip(
      message: 'save'.tr,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            QuickAddBottomSheet.show(context);
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.nothingRed,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.nothingRed.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
