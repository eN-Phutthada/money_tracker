import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/bank_slip_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/bank_slip_parser.dart';
import '../../../data/services/bank_slip_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import 'bank_batch_slip_sheet.dart';

/// หน้าต่างเลือกวิธีสแกนสลิปกรุงไทย (Scan Option Sheet)
class BankSlipScanModal extends StatelessWidget {
  const BankSlipScanModal({super.key});

  static void show(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      Get.dialog(
        const AppGlassDialog(
          maxWidth: 440,
          padding: EdgeInsets.all(22),
          child: BankSlipScanModal(),
        ),
      );
    } else {
      Get.bottomSheet(
        const BankSlipScanModal(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slipService = BankSlipService();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101010) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Container(
            width: 36,
            height: 3.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Nothing Industrial Squircle
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: isDark ? Colors.white : Colors.black,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'scan_bank_slip'.tr.toUpperCase(),
                      style: NothingTypography.grotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: NothingTypography.safeSpacing(
                          'scan_bank_slip'.tr,
                          1.2,
                        ),
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'slip_all_banks_supported'.tr,
                      style: NothingTypography.grotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFB0B0B0)
                            : const Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Get.back(),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF1C1C1C)
                      : const Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.nothingBorder
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option 1: Gallery (รองรับเลือก 1 รูป หรือหลายรูปพร้อมกัน)
          _buildOptionTile(
            context: context,
            icon: Icons.photo_library_outlined,
            title: 'choose_from_gallery'.tr,
            subtitle: 'choose_from_gallery_desc'.tr,
            isDark: isDark,
            onTap: () async {
              Get.back();
              final files = await slipService.pickMultiSlipImagesFromGallery();
              if (files.isEmpty) return;
              if (files.length == 1) {
                processSlipFile(files.first);
              } else {
                processBatchSlipFiles(files);
              }
            },
          ),
          const SizedBox(height: 10),

          // Option 2: Camera
          _buildOptionTile(
            context: context,
            icon: Icons.camera_alt_outlined,
            title: 'take_slip_photo'.tr,
            subtitle: 'take_slip_photo_desc'.tr,
            isDark: isDark,
            onTap: () async {
              Get.back();
              final file = await slipService.takeSlipPhotoWithCamera();
              if (file != null) {
                processSlipFile(file);
              }
            },
          ),
          const SizedBox(height: 16),

          // Instant Auto-Save Mode Switcher
          Obx(() {
            final isInstant = slipService.isInstantAutoSave.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  NothingLedIndicator(
                    size: 6,
                    color: isInstant
                        ? AppColors.nothingRed
                        : (isDark ? Colors.white38 : Colors.black38),
                    isPulsing: isInstant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (isInstant ? 'mode_b_instant'.tr : 'mode_a_preview'.tr).toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: NothingTypography.safeSpacing(
                              isInstant ? 'mode_b_instant'.tr : 'mode_a_preview'.tr,
                              0.8,
                            ),
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          isInstant ? 'mode_b_instant_desc'.tr : 'mode_a_preview_desc'.tr,
                          style: NothingTypography.grotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isInstant,
                    activeTrackColor: AppColors.nothingRed,
                    activeThumbColor: Colors.white,
                    inactiveTrackColor: isDark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFE0E0E0),
                    onChanged: (val) {
                      slipService.toggleAutoSave(val);
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppColors.nothingBorder
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF222222)
                    : const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isDark
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NothingTypography.grotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: NothingTypography.grotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: isDark
                  ? const Color(0xFF888888)
                  : const Color(0xFFAAAAAA),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> processSlipFile(XFile file) async {
    final slipService = BankSlipService();
    final activeContext = Get.context;
    final isDark = activeContext != null
        ? Theme.of(activeContext).brightness == Brightness.dark
        : Get.isDarkMode;

    // 1. แสดงหน้าต่างประมวลผล Nothing OS Telemetry Scanner ระหว่างสแกนภาพสลิปจริง
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.nothingBorder
                            : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NothingLedIndicator(
                        size: 5,
                        color: AppColors.nothingRed,
                        isPulsing: true,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'reading_slip_data'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: NothingTypography.safeSpacing('reading_slip_data'.tr, 1.2),
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'reading_slip_data_desc'.tr,
                    textAlign: TextAlign.center,
                    style: NothingTypography.grotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // 2. ประมวลผลภาพจริงด้วย QR Code Decoder และ OCR Engine
    final slipData = await slipService.processSlipImage(file);

    // ปิด Loading Dialog
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    final targetContext = Get.context;
    if (targetContext == null) return;

    // 3. ตรวจสอบผลลัพธ์
    if (slipData != null) {
      dispatchSlip(slipData);
    } else {
      showScanErrorDialog();
    }
  }

  /// ประมวลผลรูปภาพสลิปแบบกลุ่ม (Batch Processing)
  static Future<void> processBatchSlipFiles(List<XFile> files) async {
    final slipService = BankSlipService();
    final activeContext = Get.context;
    final isDark = activeContext != null
        ? Theme.of(activeContext).brightness == Brightness.dark
        : Get.isDarkMode;

    final progressRx = 0.obs;
    final totalCount = files.length;

    // แสดงหน้าต่างประมวลผล Nothing OS Batch Telemetry
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.nothingBorder
                            : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Obx(() => Text(
                        'processing_batch_count'.trParams({
                          'current': '${progressRx.value}',
                          'total': '$totalCount',
                        }).toUpperCase(),
                        style: NothingTypography.grotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'reading_slip_data_desc'.tr,
                    textAlign: TextAlign.center,
                    style: NothingTypography.grotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: totalCount > 0 ? progressRx.value / totalCount : 0.0,
                          minHeight: 4,
                          backgroundColor: isDark ? Colors.white12 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final batchResult = await slipService.processBatchImages(
      files,
      onProgress: (cur, tot) {
        progressRx.value = cur;
      },
    );

    if (Get.isDialogOpen ?? false) {
      Get.back(); // ปิด Loading Dialog
    }

    final targetContext = Get.context;
    if (targetContext == null) return;

    if (slipService.isInstantAutoSave.value) {
      // โหมด B: บันทึกทันทีเฉพาะสลิปที่ไม่ซ้ำ
      for (final slip in batchResult.validSlips) {
        slipService.saveSlipTransaction(slip, notify: false);
      }
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}

      final totalSaved = batchResult.validSlips.length;
      final duplicateCount = batchResult.duplicateSlips.length;
      final totalAmount = batchResult.validSlips.fold(0.0, (sum, s) => sum + s.amount);

      AppFeedback.showSuccess(
        title: 'batch_save_success_title'.tr,
        message: 'batch_save_success_msg'.trParams({
          'count': '$totalSaved',
          'amount': '฿${NumberFormat('#,##0.00').format(totalAmount)}',
        }) + (duplicateCount > 0 ? 'duplicate_found_msg'.trParams({'count': '$duplicateCount'}) : ''),
        amount: totalAmount,
      );

      // หากมีสลิปซ้ำ เปิด Sheet ให้ตรวจสอบรายการที่ซ้ำ
      if (duplicateCount > 0) {
        BankBatchSlipSheet.show(
          slips: const [],
          duplicates: batchResult.duplicateSlips,
        );
      }
    } else {
      // โหมด A: แสดงหน้าต่างตรวจสอบเป็นชุด
      if (batchResult.validSlips.isEmpty && batchResult.duplicateSlips.isEmpty) {
        showScanErrorDialog();
      } else {
        BankBatchSlipSheet.show(
          slips: batchResult.validSlips,
          duplicates: batchResult.duplicateSlips,
        );
      }
    }
  }

  static void showScanErrorDialog([BuildContext? context]) {
    final activeContext = (context != null && context.mounted ? context : Get.context);
    if (activeContext == null) return;
    final isDark = Theme.of(activeContext).brightness == Brightness.dark;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    Get.dialog(
      Center(
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A0C0E) : const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.nothingRed.withValues(alpha: 0.6)
                          : AppColors.nothingRed.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: isDark ? AppColors.nothingRedLight : AppColors.nothingRed,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'slip_not_found_title'.tr.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: NothingTypography.grotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: NothingTypography.safeSpacing('slip_not_found_title'.tr, 0.8),
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'slip_not_found_desc'.tr,
                  textAlign: TextAlign.center,
                  style: NothingTypography.grotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Get.back(),
                    child: Text(
                      'close'.tr.toUpperCase(),
                      style: NothingTypography.grotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  static void dispatchSlip(BankSlipData slip, [BuildContext? context]) {
    final activeContext = (context != null && context.mounted ? context : Get.context);
    if (activeContext == null) return;
    final slipService = BankSlipService();
    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;
    final isDuplicate = dashboardController != null &&
        BankSlipParser.isDuplicate(slip, dashboardController.transactions);

    if (isDuplicate) {
      // แม้จะเปิดโหมด Instant Auto-Save ไว้ หากตรวจพบว่าเป็นสลิปที่เคยใช้ไปแล้ว
      // ระบบจะสลับมาเปิด Confirmation Sheet พร้อมแถบเตือนสีแดงทันที เพื่อป้องกันการบันทึกยอดซ้ำซ้อน
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
      BankSlipSheet.show(activeContext, slip: slip);
      return;
    }

    // หากสกัดไม่พบยอดเงิน (amount <= 0) บังคับเปิด Confirmation Sheet ให้ผู้ใช้ตรวจสอบ/แก้ไขยอดเงินเสมอ ห้าม Auto-Save ยอด 0.00
    if (slip.amount <= 0) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
      BankSlipSheet.show(activeContext, slip: slip);
      return;
    }

    if (slipService.isInstantAutoSave.value) {
      // โหมด B: บันทึกทันทีอัตโนมัติ (เฉพาะเมื่อมียอดเงิน > 0 เท่านั้น)
      slipService.saveSlipTransaction(slip, notify: true);
    } else {
      // โหมด A: แสดงหน้าต่างตรวจสอบและแก้ไขก่อนบันทึก
      BankSlipSheet.show(activeContext, slip: slip);
    }
  }
}

/// หน้าต่างพรีวิวและยืนยันสลิปกรุงไทย (Krungthai Slip Confirmation Sheet)
class BankSlipSheet extends StatefulWidget {
  final BankSlipData slip;

  const BankSlipSheet({super.key, required this.slip});

  static void show(BuildContext context, {required BankSlipData slip}) {
    final activeContext = (context.mounted ? context : Get.context) ?? context;
    final isDesktop = MediaQuery.sizeOf(activeContext).width >= 800;

    if (isDesktop) {
      Get.dialog(
        AppGlassDialog(
          maxWidth: 480,
          padding: const EdgeInsets.all(22),
          child: BankSlipSheet(slip: slip),
        ),
      );
    } else {
      Get.bottomSheet(
        BankSlipSheet(slip: slip),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  State<BankSlipSheet> createState() => _BankSlipSheetState();
}

class _BankSlipSheetState extends State<BankSlipSheet> {
  final DashboardController controller = Get.find<DashboardController>();
  final BankSlipService slipService = BankSlipService();

  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late double _currentAmount;
  late String _selectedCategory;
  late CostNature _selectedCostNature;
  late TransactionType _selectedType;
  late DateTime _selectedDate;
  bool _isSaving = false;

  final currencyFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.slip.defaultTitle);
    _noteController = TextEditingController(text: widget.slip.memo ?? '');
    _currentAmount = widget.slip.amount;
    _selectedCategory = widget.slip.suggestedCategory;
    _selectedCostNature = widget.slip.suggestedCostNature;
    _selectedType = widget.slip.suggestedType;
    _selectedDate = widget.slip.transactionDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _getBankColor(String bankName) {
    if (bankName.contains('กสิกร')) return const Color(0xFF138F2D);
    if (bankName.contains('ไทยพาณิชย์')) return const Color(0xFF4E2A84);
    if (bankName.contains('กรุงเทพ')) return const Color(0xFF1E3F8A);
    if (bankName.contains('กรุงศรี')) return const Color(0xFFED9121);
    if (bankName.contains('ออมสิน')) return const Color(0xFFEB1985);
    if (bankName.contains('ธ.ก.ส.')) return const Color(0xFF006837);
    if (bankName.contains('ทหารไทย') || bankName.contains('ttb')) return const Color(0xFF002D63);
    if (bankName.contains('เกียรตินาคิน')) return const Color(0xFF195589);
    if (bankName.contains('ยูโอบี')) return const Color(0xFF003865);
    if (bankName.contains('TrueMoney')) return const Color(0xFFFF8200);
    return const Color(0xFF00A3E0); // Krungthai Cyan (Default)
  }

  List<String> get _categories => _currentCategories;

  List<String> get _currentCategories {
    switch (_selectedType) {
      case TransactionType.income:
        return [
          'เงินเดือน',
          'โบนัส',
          'ขายของ/รายได้เสริม',
          'เงินคืน/โอนคืน',
          'ดอกเบี้ย/ปันผล',
          'อื่นๆ',
        ];
      case TransactionType.savingsInvestment:
        return [
          'เงินออม/DCA',
          'กองทุนรวม',
          'หุ้น',
          'สลากออมทรัพย์',
          'คริปโต/สินทรัพย์ดิจิทัล',
          'ทองคำ',
          'สำรองฉุกเฉิน',
          'อื่นๆ',
        ];
      case TransactionType.expense:
        return [
          'อาหาร/ของกิน',
          'กาแฟ/เครื่องดื่ม',
          'การเดินทาง',
          'ช้อปปิ้ง',
          'ที่อยู่อาศัย',
          'สาธารณูปโภค',
          'สุขภาพ/ยา',
          'การศึกษา',
          'บันเทิง/พักผ่อน',
          'เงินออม/DCA',
          'อื่นๆ',
        ];
    }
  }

  void _onTypeChanged(TransactionType newType) {
    setState(() {
      final oldPredictedTitle = widget.slip.getPredictedTitle(type: _selectedType);
      final isTitleUntouched = _titleController.text.trim() == oldPredictedTitle ||
          _titleController.text.trim().isEmpty;
      _selectedType = newType;
      final cats = _currentCategories;
      if (!cats.contains(_selectedCategory)) {
        _selectedCategory = cats.first;
      }
      if (isTitleUntouched) {
        _titleController.text = widget.slip.getPredictedTitle(type: newType);
      }
    });
  }

  Widget _buildTypeOption({
    required String label,
    required IconData icon,
    required TransactionType type,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;
    final selectedBg = isDark ? Colors.white : Colors.black;
    final selectedFg = isDark ? Colors.black : Colors.white;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _onTypeChanged(type);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedBg
              : (isDark ? const Color(0xFF181818) : const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? selectedFg
                  : (isDark ? const Color(0xFF999999) : const Color(0xFF666666)),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: NothingTypography.grotesk(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: NothingTypography.safeSpacing(label, 0.4),
                  color: isSelected
                      ? selectedFg
                      : (isDark ? const Color(0xFF999999) : const Color(0xFF666666)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(bool isDark) {
    final conf = widget.slip.predictionConfidence;
    Color badgeColor;
    String label;
    if (conf >= 0.70) {
      badgeColor = isDark ? AppColors.nothingGreen : const Color(0xFF008736);
      label = 'confidence_high'.trParams({'percent': '${(conf * 100).round()}'});
    } else if (conf >= 0.40) {
      badgeColor = const Color(0xFFF59E0B);
      label = 'confidence_medium'.trParams({'percent': '${(conf * 100).round()}'});
    } else {
      badgeColor = isDark ? Colors.white : Colors.black;
      label = 'confidence_default'.tr;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NothingLedIndicator(size: 4.5, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: NothingTypography.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAmountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEditController = TextEditingController(
      text: _currentAmount > 0 ? _currentAmount.toStringAsFixed(2) : '',
    );

    Get.dialog(
      Center(
        child: Container(
          width: 350,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222222) : const Color(0xFFEAEAEA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '฿',
                          style: NothingTypography.mono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'enter_amount'.tr.toUpperCase(),
                      style: NothingTypography.grotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: NothingTypography.safeSpacing('enter_amount'.tr, 1.0),
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textEditController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: NothingTypography.mono(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    prefixText: '฿ ',
                    prefixStyle: NothingTypography.mono(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF888888) : const Color(0xFF555555),
                    ),
                    hintText: '0.00',
                    hintStyle: NothingTypography.mono(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white : Colors.black,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Quick preset chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [100, 300, 500, 1000].map((preset) {
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        textEditController.text = preset.toDouble().toStringAsFixed(2);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222222) : const Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '฿$preset',
                          style: NothingTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                        ),
                        child: Text(
                          'cancel'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final val = double.tryParse(textEditController.text.trim().replaceAll(',', ''));
                          if (val != null && val > 0) {
                            setState(() {
                              _currentAmount = val;
                            });
                            Get.back();
                          } else {
                            AppFeedback.showError(
                              title: 'invalid_amount'.tr,
                              message: 'invalid_amount_desc'.tr,
                            );
                          }
                        },
                        child: Text(
                          'confirm'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.selectionClick();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
    );
    if (!mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _selectedDate.hour,
        pickedTime?.minute ?? _selectedDate.minute,
      );
    });
  }

  void _submit() {
    if (_isSaving) return;

    if (_currentAmount <= 0) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
      AppFeedback.showError(
        title: 'amount_empty_title'.tr,
        message: 'amount_empty_desc'.tr,
      );
      _showEditAmountDialog();
      return;
    }

    setState(() => _isSaving = true);

    try {
      slipService.saveSlipTransaction(
        widget.slip,
        customAmount: _currentAmount,
        customTitle: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
        customCategory: _selectedCategory,
        customType: _selectedType,
        customCostNature: _selectedCostNature,
        customDate: _selectedDate,
        customNote: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        notify: true,
      );
      Get.back();
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duplicateItem = BankSlipParser.findDuplicateTransaction(widget.slip, controller.transactions);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101010) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Drag indicator
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 3.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank Branding Header
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NothingLedIndicator(
                                size: 5,
                                color: _getBankColor(widget.slip.bankName),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.slip.isKrungthai
                                      ? (widget.slip.bankName.contains('เป๋าตัง') ? 'เป๋าตัง VERIFIED' : 'KRUNGTHAI NEXT VERIFIED')
                                      : '${widget.slip.bankName.toUpperCase()} VERIFIED',
                                  style: NothingTypography.grotesk(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Get.back(),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Slip Amount Banner Card (Tap to edit)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showEditAmountDialog();
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF151515) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _currentAmount <= 0
                                ? (isDark ? AppColors.nothingRedLight : AppColors.nothingRed)
                                : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                            width: _currentAmount <= 0 ? 1.4 : 0.8,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'transfer_success_amount'.tr.toUpperCase(),
                                    style: NothingTypography.grotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: NothingTypography.safeSpacing('transfer_success_amount'.tr, 0.8),
                                      color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF222222) : const Color(0xFFEAEAEA),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 11,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'tap_to_edit'.tr.toUpperCase(),
                                        style: NothingTypography.grotesk(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _currentAmount > 0 ? '฿${currencyFormat.format(_currentAmount)}' : '฿0.00',
                                style: NothingTypography.mono(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: _currentAmount > 0
                                      ? (isDark ? Colors.white : Colors.black)
                                      : (isDark ? AppColors.nothingRedLight : AppColors.nothingRed),
                                ),
                              ),
                            ),
                            if (_currentAmount <= 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2A0C0E) : const Color(0xFFFDE8E8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.nothingRed.withValues(alpha: 0.6)
                                        : AppColors.nothingRed.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 13,
                                      color: isDark ? AppColors.nothingRedLight : AppColors.nothingRed,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'amount_not_detected_hint'.tr,
                                      style: NothingTypography.grotesk(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.nothingRedLight : AppColors.nothingRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickDateTime,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF202020) : const Color(0xFFE8E8E8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 13,
                                          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          DateFormat('dd MMM yyyy, HH:mm น.').format(_selectedDate),
                                          style: NothingTypography.mono(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF444444),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Icon(
                                          Icons.edit_calendar_rounded,
                                          size: 12,
                                          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Duplicate warning if detected
                  if (duplicateItem != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A0C0E) : const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.nothingRed.withValues(alpha: 0.6)
                              : AppColors.nothingRed.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              NothingLedIndicator(
                                size: 6,
                                color: AppColors.nothingRed,
                                isPulsing: true,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'duplicate_slip_warning'.tr.toUpperCase(),
                                  style: NothingTypography.grotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: isDark ? AppColors.nothingRedLight : AppColors.nothingRed,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.nothingRedLight : AppColors.nothingRed).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'duplicate_badge'.tr.toUpperCase(),
                                  style: NothingTypography.grotesk(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.nothingRedLight : AppColors.nothingRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Text(
                              'duplicate_detail_hint'.trParams({
                                'title': duplicateItem.title,
                                'date': DateFormat('d MMM, HH:mm น.').format(duplicateItem.date),
                                'amount': currencyFormat.format(duplicateItem.amount),
                              }),
                              style: NothingTypography.grotesk(
                                fontSize: 11,
                                height: 1.35,
                                color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF555555),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Slip Details Table
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('bank'.tr, widget.slip.bankName, isDark),
                        if (widget.slip.receiverName != null)
                          _buildDetailRow('receiver'.tr, widget.slip.receiverName!, isDark),
                        if (widget.slip.senderName != null)
                          _buildDetailRow('sender'.tr, widget.slip.senderName!, isDark),
                        if (widget.slip.memo != null)
                          _buildDetailRow('memo'.tr, widget.slip.memo!, isDark),
                        if (widget.slip.referenceNo != null)
                          _buildDetailRow('reference_no'.tr, widget.slip.referenceNo!, isDark, isMonospace: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transaction Type Selector
                  Text(
                    'transaction_type'.tr.toUpperCase(),
                    style: NothingTypography.grotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: NothingTypography.safeSpacing('transaction_type'.tr, 1.0),
                      color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeOption(
                          label: 'expense'.tr,
                          icon: Icons.arrow_upward_rounded,
                          type: TransactionType.expense,
                          activeColor: AppColors.nothingRed,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeOption(
                          label: 'income'.tr,
                          icon: Icons.arrow_downward_rounded,
                          type: TransactionType.income,
                          activeColor: isDark ? AppColors.nothingGreen : const Color(0xFF008736),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeOption(
                          label: 'savings_dca'.tr,
                          icon: Icons.savings_outlined,
                          type: TransactionType.savingsInvestment,
                          activeColor: isDark ? Colors.white : Colors.black,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Editable Title Field
                  Text(
                    'transaction_title_label'.tr.toUpperCase(),
                    style: NothingTypography.grotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: NothingTypography.safeSpacing('transaction_title_label'.tr, 1.0),
                      color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    style: NothingTypography.grotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : Colors.black,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Editable Note / Memo Field (แยกออกจาก Title)
                  Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'note'.tr.toUpperCase(),
                        style: NothingTypography.grotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: NothingTypography.safeSpacing('note'.tr, 1.0),
                          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    minLines: 1,
                    style: NothingTypography.grotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'note_hint'.tr,
                      hintStyle: NothingTypography.grotesk(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : Colors.black,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Selector Chips
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (_selectedType == TransactionType.income
                                  ? 'category_income'.tr
                                  : _selectedType == TransactionType.savingsInvestment
                                      ? 'category_savings'.tr
                                      : 'category_expense'.tr)
                              .toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildConfidenceBadge(isDark),
                    ],
                  ),
                  if (widget.slip.predictionReason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        NothingLedIndicator(
                          size: 4,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'recommended_from'.trParams({'reason': widget.slip.predictionReason}),
                            style: NothingTypography.grotesk(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat.tr),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        backgroundColor: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        labelStyle: NothingTypography.grotesk(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? const Color(0xFFD4D4D8) : const Color(0xFF444444)),
                        ),
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),

                  if (_selectedType == TransactionType.expense) ...[
                    const SizedBox(height: 14),

                    // Cost Nature (Fixed vs Variable)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${'cost_nature'.tr.toUpperCase()}: ',
                          style: NothingTypography.grotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                          ),
                        ),
                        ChoiceChip(
                          label: Text('variable_cost'.tr),
                          selected: _selectedCostNature == CostNature.variable,
                          selectedColor: isDark ? Colors.white : Colors.black,
                          backgroundColor: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _selectedCostNature == CostNature.variable
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                              width: 0.8,
                            ),
                          ),
                          labelStyle: NothingTypography.grotesk(
                            fontSize: 11,
                            fontWeight: _selectedCostNature == CostNature.variable ? FontWeight.w800 : FontWeight.w500,
                            color: _selectedCostNature == CostNature.variable
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? const Color(0xFFD4D4D8) : const Color(0xFF444444)),
                          ),
                          showCheckmark: false,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCostNature = CostNature.variable);
                          },
                        ),
                        ChoiceChip(
                          label: Text('fixed_cost'.tr),
                          selected: _selectedCostNature == CostNature.fixed,
                          selectedColor: isDark ? Colors.white : Colors.black,
                          backgroundColor: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _selectedCostNature == CostNature.fixed
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                              width: 0.8,
                            ),
                          ),
                          labelStyle: NothingTypography.grotesk(
                            fontSize: 11,
                            fontWeight: _selectedCostNature == CostNature.fixed ? FontWeight.w800 : FontWeight.w500,
                            color: _selectedCostNature == CostNature.fixed
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? const Color(0xFFD4D4D8) : const Color(0xFF444444)),
                          ),
                          showCheckmark: false,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCostNature = CostNature.fixed);
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nothingRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'save_slip_transaction'.tr.toUpperCase(),
                              style: NothingTypography.grotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: NothingTypography.safeSpacing('save_slip_transaction'.tr, 1.2),
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label.toUpperCase(),
              style: NothingTypography.grotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isMonospace
                  ? NothingTypography.mono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    )
                  : NothingTypography.grotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}




/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100%
typedef KrungthaiSlipSheet = BankSlipSheet;
typedef KrungthaiSlipScanModal = BankSlipScanModal;
