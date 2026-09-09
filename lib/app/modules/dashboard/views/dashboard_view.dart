import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../security/controllers/security_controller.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
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

  String _getPeriodTitle(DashboardController controller) {
    final date = controller.selectedDate.value;
    switch (controller.currentPeriod.value) {
      case TimeFilterPeriod.monthly:
        const months = ['', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
        return '${months[date.month]} ${date.year + 543}';
      case TimeFilterPeriod.yearly:
        return 'ปี พ.ศ. ${date.year + 543}';
      case TimeFilterPeriod.allTime:
        return 'ภาพรวมสะสมทั้งหมด';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: isDesktop ? null : _buildMobileAppBar(),
        floatingActionButton: isDesktop
            ? null
            : FloatingActionButton.extended(
                onPressed: () => QuickAddBottomSheet.show(context),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
        body: SafeArea(
          child: isDesktop ? const DesktopDashboardView() : const MobileDashboardView(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      titleSpacing: 18,
      title: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Finance',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              _getPeriodTitle(controller),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
          ],
        );
      }),
      actions: [
        Obx(() {
          if (controller.currentPeriod.value == TimeFilterPeriod.monthly) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: controller.previousPeriod,
                  tooltip: 'เดือนก่อนหน้า',
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: controller.nextPeriod,
                  tooltip: 'เดือนถัดไป',
                ),
              ],
            );
          }
          return const SizedBox();
        }),
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 20),
          onPressed: () => Get.toNamed(Routes.BUDGET_SETTINGS),
          tooltip: 'ตั้งค่าเป้าหมายงบประมาณ',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (val) {
            if (val == 'theme') {
              controller.toggleTheme();
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
                    controller.isDarkMode.value ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(controller.isDarkMode.value ? 'โหมดสว่าง' : 'โหมดมืด', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'data',
              child: Row(
                children: [
                  Icon(Icons.storage_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('จัดการข้อมูล (CSV)', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'security',
              child: Row(
                children: [
                  Icon(Icons.security_rounded, size: 18, color: AppColors.accent),
                  SizedBox(width: 10),
                  Text('ความปลอดภัย (PIN)', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (Get.isRegistered<SecurityController>() && Get.find<SecurityController>().isPinEnabled.value)
              const PopupMenuItem(
                value: 'lock',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.deficitText),
                    SizedBox(width: 10),
                    Text('ล็อกหน้าจอทันที', style: TextStyle(fontSize: 13, color: AppColors.deficitText)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
