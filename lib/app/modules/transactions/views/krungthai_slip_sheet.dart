import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/krungthai_slip_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/krungthai_slip_parser.dart';
import '../../../data/services/krungthai_slip_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import 'krungthai_batch_slip_sheet.dart';

/// หน้าต่างเลือกวิธีสแกนสลิปกรุงไทย (Scan Option Sheet)
class KrungthaiSlipScanModal extends StatelessWidget {
  const KrungthaiSlipScanModal({super.key});

  static void show(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      Get.dialog(
        const AppGlassDialog(
          maxWidth: 440,
          padding: EdgeInsets.all(22),
          child: KrungthaiSlipScanModal(),
        ),
      );
    } else {
      Get.bottomSheet(
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: const KrungthaiSlipScanModal(),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slipService = KrungthaiSlipService();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 20,
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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Krungthai Cyan Accent
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A3E0), Color(0xFF0072CE)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A3E0).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'scan_krungthai_slip'.tr,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'รองรับสลิป Krungthai NEXT และเป๋าตัง',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option 1: Gallery (รองรับเลือก 1 รูป หรือหลายรูปพร้อมกัน)
          _buildOptionTile(
            context: context,
            icon: Icons.photo_library_rounded,
            title: 'choose_from_gallery'.tr,
            subtitle: 'เลือกรูปสลิป 1 รูป หรือเลือกหลายรูปพร้อมกัน',
            color: const Color(0xFF00A3E0),
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
            icon: Icons.camera_alt_rounded,
            title: 'take_slip_photo'.tr,
            subtitle: 'เปิดกล้องถ่ายภาพสลิปใบเสร็จจริง',
            color: const Color(0xFF10B981),
            isDark: isDark,
            onTap: () async {
              Get.back();
              final file = await slipService.takeSlipPhotoWithCamera();
              if (file != null) {
                processSlipFile(file);
              }
            },
          ),
          const SizedBox(height: 10),

          // Option 3: Paste Text
          _buildOptionTile(
            context: context,
            icon: Icons.content_paste_rounded,
            title: 'paste_slip_text'.tr,
            subtitle: 'วางข้อความสลิปหรือแจ้งเตือนจากธนาคาร',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
            onTap: () {
              Get.back();
              showPasteTextDialog(Get.context ?? context);
            },
          ),
          const SizedBox(height: 10),

          // Option 4: Folder Auto-Scan Settings
          Obx(() => _buildOptionTile(
            context: context,
            icon: Icons.folder_special_rounded,
            title: 'ตรวจจับสลิปอัตโนมัติจากโฟลเดอร์',
            subtitle: slipService.isFolderAutoScanEnabled.value
                ? 'เปิดใช้งาน: ${slipService.targetFolderName.value}'
                : 'ปิดอยู่ (แตะเพื่อเปิดและเลือกโฟลเดอร์เป้าหมาย)',
            color: const Color(0xFFEC4899),
            isDark: isDark,
            onTap: () {
              Get.back();
              showFolderSettingsModal(Get.context ?? context);
            },
          )),
          const SizedBox(height: 18),

          // Instant Auto-Save Mode Switcher
          Obx(() {
            final isInstant = slipService.isInstantAutoSave.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6)
                    : AppColors.surfaceSecondary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isInstant ? Icons.flash_on_rounded : Icons.visibility_rounded,
                    size: 20,
                    color: isInstant ? const Color(0xFFF59E0B) : const Color(0xFF00A3E0),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isInstant ? 'โหมด B: บันทึกทันทีอัตโนมัติ' : 'โหมด A: ตรวจสอบก่อนบันทึก',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isInstant ? 'บันทึกรายการลงระบบทันทีโดยไม่ต้องกดยืนยัน' : 'เปิดหน้าต่างพรีวิวเพื่อตรวจเช็กและแก้ไขหมวดหมู่',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isInstant,
                    activeTrackColor: const Color(0xFFF59E0B),
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
    required Color color,
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
          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> processSlipFile(XFile file) async {
    final slipService = KrungthaiSlipService();
    final activeContext = Get.context;
    final isDark = activeContext != null
        ? Theme.of(activeContext).brightness == Brightness.dark
        : Get.isDarkMode;

    // 1. แสดงหน้าต่างประมวลผล Liquid Glass Loading ระหว่างสแกนภาพสลิปจริง
    Get.dialog(
      PopScope(
        canPop: false,
        child: AppGlassDialog(
          maxWidth: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A3E0), Color(0xFF0072CE)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A3E0).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'กำลังอ่านข้อมูลสลิป...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ถอดรหัส QR Code และข้อความสลิป',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
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
    final slipService = KrungthaiSlipService();
    final activeContext = Get.context;
    final isDark = activeContext != null
        ? Theme.of(activeContext).brightness == Brightness.dark
        : Get.isDarkMode;

    final progressRx = 0.obs;
    final totalCount = files.length;

    // แสดงหน้าต่างประมวลผล Liquid Glass Loading แบบกลุ่ม
    Get.dialog(
      PopScope(
        canPop: false,
        child: AppGlassDialog(
          maxWidth: 340,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A3E0), Color(0xFF6366F1)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A3E0).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Obx(() => Text(
                    'กำลังอ่านสลิป ${progressRx.value}/$totalCount รูป',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  )),
              const SizedBox(height: 6),
              Text(
                'ถอดรหัส QR Code และข้อความสลิป',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalCount > 0 ? progressRx.value / totalCount : 0.0,
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A3E0)),
                    ),
                  )),
            ],
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
        title: 'บันทึกสลิปเป็นชุดสำเร็จ',
        message: 'บันทึก $totalSaved รายการ (฿${NumberFormat('#,##0.00').format(totalAmount)})${duplicateCount > 0 ? ' • พบซ้ำ $duplicateCount รายการ' : ''}',
        amount: totalAmount,
      );

      // หากมีสลิปซ้ำ เปิด Sheet ให้ตรวจสอบรายการที่ซ้ำ
      if (duplicateCount > 0) {
        KrungthaiBatchSlipSheet.show(
          slips: const [],
          duplicates: batchResult.duplicateSlips,
        );
      }
    } else {
      // โหมด A: แสดงหน้าต่างตรวจสอบเป็นชุด
      if (batchResult.validSlips.isEmpty && batchResult.duplicateSlips.isEmpty) {
        showScanErrorDialog();
      } else {
        KrungthaiBatchSlipSheet.show(
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
      AppGlassDialog(
        maxWidth: 400,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFFF59E0B),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ไม่พบข้อมูลสลิปโอนเงิน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'รูปภาพที่เลือกไม่ใช่ภาพสลิป หรือไม่พบ QR Code / ข้อมูลธนาคารที่ชัดเจนในรูปนี้\n\nท่านสามารถถ่ายหรือเลือกรูปใหม่อีกครั้ง หรือใช้วิธีวางข้อความสลิปแทนได้ครับ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A3E0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      showPasteTextDialog(activeContext);
                    },
                    child: const Text('วางข้อความ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void showPasteTextDialog(BuildContext context) {
    final activeContext = (context.mounted ? context : Get.context) ?? context;
    final textController = TextEditingController();
    final isDark = Theme.of(activeContext).brightness == Brightness.dark;

    Get.dialog(
      AppGlassDialog(
        maxWidth: 460,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.paste_rounded, color: Color(0xFF00A3E0), size: 22),
                const SizedBox(width: 10),
                Text(
                  'วางข้อความสลิปกรุงไทย',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 8,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'วางข้อความสลิป เช่น:\nธนาคารกรุงไทย โอนเงินสำเร็จ\n11 ก.ย. 2569 12:35 น.\nจำนวนเงิน 350.00 บาท...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('cancel'.tr),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3E0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;
                    Get.back();
                    final slipData = KrungthaiSlipParser.parse(text);
                    dispatchSlip(slipData, activeContext);
                  },
                  child: const Text('อ่านข้อมูลสลิป'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// แสดงหน้าต่างตั้งค่าโฟลเดอร์สำหรับตรวจจับสลิปใหม่อัตโนมัติ
  static void showFolderSettingsModal([BuildContext? context]) {
    final activeContext = (context != null && context.mounted ? context : Get.context);
    if (activeContext == null) return;
    final isDark = Theme.of(activeContext).brightness == Brightness.dark;
    final slipService = KrungthaiSlipService();
    final presets = KrungthaiSlipService.getRecommendedFolderPresets();

    final customPathController = TextEditingController(text: slipService.targetFolderPath.value);

    Get.dialog(
      AppGlassDialog(
        maxWidth: 440,
        padding: const EdgeInsets.all(22),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.folder_special_rounded, color: Color(0xFFEC4899), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'โฟลเดอร์ตรวจจับสลิปอัตโนมัติ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ตรวจจับสลิปใหม่ทันทีเมื่อเปิดแอป',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Toggle Auto-Scan Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'เปิดตรวจจับสลิปอัตโนมัติเมื่อเปิดแอป',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Obx(() => Switch.adaptive(
                              value: slipService.isFolderAutoScanEnabled.value,
                              activeTrackColor: const Color(0xFF10B981),
                              onChanged: (val) {
                                slipService.toggleFolderAutoScan(val);
                              },
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'เลือกโฟลเดอร์หรืออัลบั้มสลิป:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Presets
                  ...presets.map((preset) {
                    final isSelected = slipService.targetFolderName.value == preset['name'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          slipService.setTargetFolder(
                            path: preset['defaultPath']!,
                            name: preset['name']!,
                          );
                          setState(() {
                            customPathController.text = preset['defaultPath']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00A3E0).withValues(alpha: 0.12)
                                : isDark
                                    ? AppColors.darkSurfaceSecondary
                                    : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00A3E0)
                                  : isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                              width: isSelected ? 1.4 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: isSelected ? const Color(0xFF00A3E0) : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      preset['name']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      preset['subtitle']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  // Custom path input
                  TextField(
                    controller: customPathController,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'ที่อยู่โฟลเดอร์ (Folder Path)',
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3E0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final path = customPathController.text.trim();
                        if (path.isNotEmpty) {
                          slipService.setTargetFolder(
                            path: path,
                            name: slipService.targetFolderName.value,
                          );
                        }
                        Get.back();
                        AppFeedback.showSuccess(
                          title: 'บันทึกการตั้งค่าโฟลเดอร์สำเร็จ',
                          message: 'ตั้งค่าโฟลเดอร์ "${slipService.targetFolderName.value}" เรียบร้อยแล้ว',
                        );
                      },
                      child: const Text('บันทึกการตั้งค่า'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static void dispatchSlip(KrungthaiSlipData slip, [BuildContext? context]) {
    final activeContext = (context != null && context.mounted ? context : Get.context);
    if (activeContext == null) return;
    final slipService = KrungthaiSlipService();
    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;
    final isDuplicate = dashboardController != null &&
        KrungthaiSlipParser.isDuplicate(slip, dashboardController.transactions);

    if (isDuplicate) {
      // แม้จะเปิดโหมด Instant Auto-Save ไว้ หากตรวจพบว่าเป็นสลิปที่เคยใช้ไปแล้ว
      // ระบบจะสลับมาเปิด Confirmation Sheet พร้อมแถบเตือนสีแดงทันที เพื่อป้องกันการบันทึกยอดซ้ำซ้อน
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
      KrungthaiSlipSheet.show(activeContext, slip: slip);
      return;
    }

    // หากสกัดไม่พบยอดเงิน (amount <= 0) บังคับเปิด Confirmation Sheet ให้ผู้ใช้ตรวจสอบ/แก้ไขยอดเงินเสมอ ห้าม Auto-Save ยอด 0.00
    if (slip.amount <= 0) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
      KrungthaiSlipSheet.show(activeContext, slip: slip);
      return;
    }

    if (slipService.isInstantAutoSave.value) {
      // โหมด B: บันทึกทันทีอัตโนมัติ (เฉพาะเมื่อมียอดเงิน > 0 เท่านั้น)
      slipService.saveSlipTransaction(slip, notify: true);
    } else {
      // โหมด A: แสดงหน้าต่างตรวจสอบและแก้ไขก่อนบันทึก
      KrungthaiSlipSheet.show(activeContext, slip: slip);
    }
  }
}

/// หน้าต่างพรีวิวและยืนยันสลิปกรุงไทย (Krungthai Slip Confirmation Sheet)
class KrungthaiSlipSheet extends StatefulWidget {
  final KrungthaiSlipData slip;

  const KrungthaiSlipSheet({super.key, required this.slip});

  static void show(BuildContext context, {required KrungthaiSlipData slip}) {
    final activeContext = (context.mounted ? context : Get.context) ?? context;
    final isDesktop = MediaQuery.sizeOf(activeContext).width >= 800;

    if (isDesktop) {
      Get.dialog(
        AppGlassDialog(
          maxWidth: 480,
          padding: const EdgeInsets.all(22),
          child: KrungthaiSlipSheet(slip: slip),
        ),
      );
    } else {
      Get.bottomSheet(
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: KrungthaiSlipSheet(slip: slip),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  State<KrungthaiSlipSheet> createState() => _KrungthaiSlipSheetState();
}

class _KrungthaiSlipSheetState extends State<KrungthaiSlipSheet> {
  final DashboardController controller = Get.find<DashboardController>();
  final KrungthaiSlipService slipService = KrungthaiSlipService();

  late TextEditingController _titleController;
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
    _currentAmount = widget.slip.amount;
    _selectedCategory = widget.slip.suggestedCategory;
    _selectedCostNature = widget.slip.suggestedCostNature;
    _selectedType = widget.slip.suggestedType;
    _selectedDate = widget.slip.transactionDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
      _selectedType = newType;
      final cats = _currentCategories;
      if (!cats.contains(_selectedCategory)) {
        _selectedCategory = cats.first;
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
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _onTypeChanged(type);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.16)
              : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? activeColor
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
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
      badgeColor = const Color(0xFF00C853);
      label = 'แม่นยำสูง ${(conf * 100).round()}%';
    } else if (conf >= 0.40) {
      badgeColor = const Color(0xFFFF9800);
      label = 'ปานกลาง ${(conf * 100).round()}%';
    } else {
      badgeColor = const Color(0xFF00A3E0);
      label = 'ค่าเริ่มต้น';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: badgeColor,
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
      AppGlassDialog(
        maxWidth: 360,
        padding: const EdgeInsets.all(22),
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
                    color: const Color(0xFF00A3E0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_money_rounded, color: Color(0xFF00A3E0), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'ระบุจำนวนเงิน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textEditController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '฿ ',
                prefixStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00A3E0),
                ),
                hintText: '0.00',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A3E0).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '฿$preset',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00A3E0),
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
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A3E0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                          title: 'ยอดเงินไม่ถูกต้อง',
                          message: 'กรุณากรอกจำนวนเงินที่มากกว่า 0 บาท',
                        );
                      }
                    },
                    child: const Text('ตกลง'),
                  ),
                ),
              ],
            ),
          ],
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
        title: 'ยังไม่ได้ระบุยอดเงิน',
        message: 'กรุณาแตะที่กล่องยอดเงินเพื่อระบุจำนวนเงินก่อนบันทึกครับ',
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
    final duplicateItem = KrungthaiSlipParser.findDuplicateTransaction(widget.slip, controller.transactions);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Drag indicator
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.15),
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
                  // Krungthai Branding Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A3E0).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00A3E0).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: Color(0xFF00A3E0)),
                            SizedBox(width: 5),
                            Text(
                              'Krungthai NEXT Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00A3E0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF00A3E0).withValues(alpha: 0.20),
                                    const Color(0xFF0072CE).withValues(alpha: 0.10),
                                  ]
                                : [
                                    const Color(0xFF00A3E0).withValues(alpha: 0.12),
                                    const Color(0xFF0072CE).withValues(alpha: 0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _currentAmount <= 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF00A3E0).withValues(alpha: 0.35),
                            width: _currentAmount <= 0 ? 1.8 : 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ยอดเงินโอนสำเร็จ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A3E0).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_rounded, size: 11, color: Color(0xFF00A3E0)),
                                      SizedBox(width: 3),
                                      Text(
                                        'แตะแก้ไข',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF00A3E0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentAmount > 0 ? '฿${currencyFormat.format(_currentAmount)}' : '฿0.00',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                color: _currentAmount > 0 ? const Color(0xFF00A3E0) : const Color(0xFFEF4444),
                              ),
                            ),
                            if (_currentAmount <= 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                                    SizedBox(width: 4),
                                    Text(
                                      'ไม่พบยอดเงินจากภาพ กรุณาแตะเพื่อระบุจำนวนเงิน',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickDateTime,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isDark ? const Color(0xFF00A3E0) : const Color(0xFF0284C7)).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: (isDark ? const Color(0xFF00A3E0) : const Color(0xFF0284C7)).withValues(alpha: 0.20),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm น.').format(_selectedDate),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit_calendar_rounded,
                                        size: 11,
                                        color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                                      ),
                                    ],
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
                        color: AppColors.deficitText.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.deficitText.withValues(alpha: 0.40),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.deficitText),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'สลิปนี้อาจเคยถูกบันทึกไปแล้ว',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deficitText,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.deficitText.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ตรวจพบซ้ำ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deficitText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 26),
                            child: Text(
                              'พบรายการ "${duplicateItem.title}" บันทึกเมื่อ ${DateFormat('d MMM, HH:mm น.').format(duplicateItem.date)} ยอด ฿${currencyFormat.format(duplicateItem.amount)}\n(หากต้องการบันทึกอีกครั้ง สามารถกดยืนยันด้านล่างได้)',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (widget.slip.receiverName != null)
                          _buildDetailRow('ผู้รับเงิน', widget.slip.receiverName!, isDark),
                        if (widget.slip.senderName != null)
                          _buildDetailRow('ผู้โอนเงิน', widget.slip.senderName!, isDark),
                        if (widget.slip.memo != null)
                          _buildDetailRow('บันทึกช่วยจำ', widget.slip.memo!, isDark),
                        if (widget.slip.referenceNo != null)
                          _buildDetailRow('รหัสอ้างอิง', widget.slip.referenceNo!, isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transaction Type Selector
                  Text(
                    'ประเภทธุรกรรม',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeOption(
                          label: 'รายจ่าย',
                          icon: Icons.arrow_upward_rounded,
                          type: TransactionType.expense,
                          activeColor: const Color(0xFFFF5252),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeOption(
                          label: 'รายรับ',
                          icon: Icons.arrow_downward_rounded,
                          type: TransactionType.income,
                          activeColor: const Color(0xFF00C853),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeOption(
                          label: 'เงินออม/DCA',
                          icon: Icons.savings_rounded,
                          type: TransactionType.savingsInvestment,
                          activeColor: const Color(0xFF00A3E0),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Editable Title Field
                  Text(
                    'ชื่อรายการธุรกรรม',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
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
                          _selectedType == TransactionType.income
                              ? 'หมวดหมู่รายรับ'
                              : _selectedType == TransactionType.savingsInvestment
                                  ? 'หมวดหมู่เงินออม/ลงทุน'
                                  : 'หมวดหมู่ค่าใช้จ่าย',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: const Color(0xFF00A3E0).withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'แนะนำจาก: ${widget.slip.predictionReason}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00A3E0).withValues(alpha: 0.18),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF00A3E0)
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: isSelected ? 1.4 : 0.8,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF00A3E0)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
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
                          'ลักษณะค่าใช้จ่าย: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('ค่าใช้จ่ายผันแปร'),
                          selected: _selectedCostNature == CostNature.variable,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCostNature = CostNature.variable);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('ค่าใช้จ่ายคงที่'),
                          selected: _selectedCostNature == CostNature.fixed,
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
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3E0),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'บันทึกรายการโอนเงิน',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
