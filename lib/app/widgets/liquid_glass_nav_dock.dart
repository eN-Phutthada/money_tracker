import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/security/controllers/security_controller.dart';
import '../modules/transactions/views/quick_add_bottom_sheet.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_popup_decorations.dart';
import 'shaders/shaders.dart';

/// แถบนำทางกระจกใสเหลวลอยตัวบนหน้าจอระดับอัลตร้าพรีเมียม (Ultra-Translucent Liquid Glass Navigation Dock)
/// สไตล์ FinTech 2026:
/// - ลอยอยู่บนหน้าจอ (Floating on Screen Overlay) ไม่ใส่ไว้ที่ bottom bar ของ Scaffold
/// - ทำงานแบบ Universal พร้อมแสดงบนทุกหน้าจอของแอปพลิเคชัน
/// - หักเหแสงด้วย ImageFilter.blur(sigma: 28)
/// - ขอบสะท้อนแสง Hairline Specular Highlight (1.2px)
/// - รวมศูนย์ควบคุม Hub & Vault Center Menu สำหรับสลับธีม ภาษา สำรองข้อมูล และความปลอดภัย
class LiquidGlassNavDock extends StatelessWidget {
  final String currentRoute;
  final GlobalKey? backgroundKey;

  static final LiquidGlassLensShader _lensShader =
      LiquidGlassLensShader()..initialize();

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

    return Stack(
      children: [
        RepaintBoundary(
          key: actualBgKey,
          child: body,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: LiquidGlassNavDock(
            currentRoute: currentRoute,
            backgroundKey: actualBgKey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardController = Get.find<DashboardController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: LiquidGlassBackgroundCapture(
              backgroundKey: backgroundKey,
              shader: _lensShader,
              borderRadius: BorderRadius.circular(28),
              effectSize: 5.0,
              blurIntensity: 0.6,
              dispersionStrength: 0.55,
              refractionStrength: 2.2,
              fallbackBuilder: (context, child) => ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: child,
                ),
              ),
              child: SizedBox(
                height: 66,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 1. Home / Overview
                      _buildDockItem(
                        icon: Icons.dashboard_rounded,
                        tooltip: 'dashboard_overview'.tr,
                        isActive: currentRoute == Routes.DASHBOARD,
                        isDark: isDark,
                        onTap: () {
                          if (currentRoute != Routes.DASHBOARD) {
                            Get.until((route) => route.isFirst || route.settings.name == Routes.DASHBOARD);
                          }
                        },
                      ),

                      // 2. Transactions History
                      _buildDockItem(
                        icon: Icons.receipt_long_rounded,
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

                      // 3. Center Liquid Neon Quick Add Button
                      _buildCenterAddButton(context),

                      // 4. Budget Settings
                      _buildDockItem(
                        icon: Icons.tune_rounded,
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

  /// รายการนำทางเดี่ยวบน Dock พร้อมสถานะ Active สไตล์ Apple iOS 26 Liquid Droplet Pill
  Widget _buildDockItem({
    required IconData icon,
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
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.20),
                            AppColors.primary.withValues(alpha: 0.22),
                            AppColors.primary.withValues(alpha: 0.08),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.75),
                            AppColors.primary.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.35),
                          ],
                    stops: const [0.0, 0.55, 1.0],
                  )
                : null,
            border: isActive
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.85),
                    width: 1.0,
                  )
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.60),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
              ),
              if (isActive) ...[
                const SizedBox(height: 3),
                Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary,
                        blurRadius: 6,
                        spreadRadius: 0.8,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// เมนูศูนย์ควบคุม Hub & Vault สไตล์ Liquid Glass (ย้ายมาจากแถบ AppBar ด้านบนขวา)
  Widget _buildDockVaultMenu(
    BuildContext context,
    bool isDark,
    DashboardController controller,
  ) {
    final isVaultActive = currentRoute == Routes.DATA_MANAGEMENT || currentRoute == Routes.PIN_SETTINGS;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: (isDark ? AppColors.darkSurface : AppColors.surface).withValues(alpha: 0.96),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.16) : AppColors.border.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          elevation: 14,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'data_management_short'.tr,
        offset: const Offset(0, -10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.16) : AppColors.border.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withValues(alpha: 0.96),
        elevation: 14,
        onSelected: (val) {
          HapticFeedback.selectionClick();
          if (val == 'theme') {
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
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HUB & VAULT CENTER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
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
                      color: (controller.themeMode.value == ThemeMode.dark
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      controller.themeMode.value == ThemeMode.system
                          ? Icons.brightness_auto_rounded
                          : (controller.themeMode.value == ThemeMode.dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded),
                      size: 17,
                      color: controller.themeMode.value == ThemeMode.dark
                          ? const Color(0xFF818CF8)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'theme_label'.trParams({'theme': controller.themeModeName}),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      controller.themeModeName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
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
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      size: 17,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'language_label'.trParams({'lang': controller.currentLanguageName}),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      controller.isEnglish ? 'EN' : 'TH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
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
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storage_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'data_management_short'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 17,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'security_pin_short'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Lock Screen Now (if PIN enabled)
            if (isPinOn)
              PopupMenuItem<String>(
                value: 'lock',
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.deficitText.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 17,
                        color: AppColors.deficitText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'lock_screen_now'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deficitText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ];
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isVaultActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.20),
                            AppColors.primary.withValues(alpha: 0.22),
                            AppColors.primary.withValues(alpha: 0.08),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.75),
                            AppColors.primary.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.35),
                          ],
                    stops: const [0.0, 0.55, 1.0],
                  )
                : null,
            border: isVaultActive
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.85),
                    width: 1.0,
                  )
                : null,
            boxShadow: isVaultActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.60),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ]
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
                    Icons.widgets_rounded,
                    size: 22,
                    color: isVaultActive
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                  ),
                  // Glowing status dot
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isVaultActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.6),
                        boxShadow: isVaultActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary,
                                  blurRadius: 6,
                                  spreadRadius: 0.8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (isVaultActive) ...[
                const SizedBox(height: 3),
                Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary,
                        blurRadius: 6,
                        spreadRadius: 0.8,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ปุ่มวงกลมมนนีออนตรงกลางสำหรับบันทึกรายการด่วน สไตล์ Apple iOS 26 Liquid Action Jewel
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
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF34D399), // Radiant Mint
                  Color(0xFF10B981), // Core Emerald
                  Color(0xFF047857), // Deep Forest Jewel
                ],
              ),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1.4,
              ),
              boxShadow: [
                // Radiant emerald halo
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.48),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
                // Specular razor glint
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.50),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Upper glass dome sheen overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17.5)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Center icon
                const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
