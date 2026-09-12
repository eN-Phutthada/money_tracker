import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../transactions/views/krungthai_batch_slip_sheet.dart';
import '../controllers/dashboard_controller.dart';

/// แบนเนอร์อัจฉริยะแจ้งเตือนเมื่อตรวจพบสลิปใหม่ในโฟลเดอร์เป้าหมาย (Smart Auto-Scan Slips Banner)
class SmartAutoScanSlipsBanner extends GetView<DashboardController> {
  const SmartAutoScanSlipsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    return Obx(() {
      final slips = controller.detectedFolderSlips;
      if (slips.isEmpty) {
        return const SizedBox.shrink();
      }

      final count = slips.length;
      final totalAmount = slips.fold(0.0, (sum, s) => sum + s.amount);
      final firstTitle = slips.first.receiverName ?? slips.first.suggestedCategory;

      return AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF059669).withValues(alpha: 0.24),
                      const Color(0xFF00A3E0).withValues(alpha: 0.16),
                    ]
                  : [
                      const Color(0xFFECFDF5),
                      const Color(0xFFE0F2FE),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF10B981).withValues(alpha: 0.40)
                  : const Color(0xFF10B981).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Sparkling Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF00A3E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ตรวจพบสลิปใหม่',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count รายการ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$firstTitle ${count > 1 ? "และอื่นๆ " : ""}• รวม ฿${currencyFormat.format(totalAmount)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dismiss Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    onPressed: controller.dismissDetectedSlips,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Buttons Row
              Row(
                children: [
                  // Review Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                          width: 0.9,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        KrungthaiBatchSlipSheet.show(
                          context: context,
                          slips: slips.toList(),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('ตรวจสอบ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Save All Button
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: controller.saveAllDetectedSlips,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        'บันทึกทั้งหมด ($count)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
