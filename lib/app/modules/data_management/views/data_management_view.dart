import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/csv_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// หน้าจอจัดการข้อมูล (Data Management) ด้วย GetX
class DataManagementView extends StatefulWidget {
  const DataManagementView({super.key});

  @override
  State<DataManagementView> createState() => _DataManagementViewState();
}

class _DataManagementViewState extends State<DataManagementView> {
  final DashboardController controller = Get.find<DashboardController>();
  final TextEditingController _importTextController = TextEditingController();
  List<TransactionItem>? _parsedPreviewItems;

  @override
  void dispose() {
    _importTextController.dispose();
    super.dispose();
  }

  void _exportCsv() {
    final transactions = controller.transactions;
    final csvContent = CsvService.exportToCsv(transactions);

    Get.dialog(
      _buildExportDialog(
        title: 'ส่งออกข้อมูล CSV (Excel Compatible)',
        description: 'ไฟล์ CSV มี UTF-8 BOM สำหรับเปิดอ่านภาษาไทยใน Microsoft Excel ได้อย่างถูกต้อง',
        content: csvContent,
        filename: 'money_tracker_export_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}.csv',
        itemCount: transactions.length,
      ),
    );
  }

  void _exportJsonBackup() async {
    final transactions = controller.transactions;
    final plan = controller.budgetPlan.value;
    final jsonContent = await StorageService().exportBackupJson(transactions, plan);

    Get.dialog(
      _buildExportDialog(
        title: 'สำรองข้อมูลทั้งหมด (JSON Backup)',
        description: 'ไฟล์ Backup สมบูรณ์แบบ ประกอบด้วยรายการธุรกรรมและแผนงบประมาณ',
        content: jsonContent,
        filename: 'money_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        itemCount: transactions.length,
      ),
    );
  }

  Widget _buildExportDialog({
    required String title,
    required String description,
    required String content,
    required String filename,
    required int itemCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppGlassDialog(
      maxWidth: 560,
      maxHeight: 540,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPopupHeader(
            title: title,
            subtitle: '$description (รวม $itemCount รายการ)',
            icon: Icons.file_download_outlined,
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  Get.snackbar(
                    'สำเร็จ',
                    'คัดลอกเนื้อหาลงคลิปบอร์ดแล้ว',
                    snackPosition: SnackPosition.TOP,
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('คัดลอกข้อความ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final savedPath = await StorageService().saveExportFile(filename, content);
                    await Clipboard.setData(ClipboardData(text: savedPath));
                    Get.back();
                    Get.dialog(
                      AppGlassDialog(
                        maxWidth: 440,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AppPopupHeader(
                              title: 'บันทึกไฟล์สำเร็จ!',
                              icon: Icons.check_circle_rounded,
                              iconColor: AppColors.surplusText,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'บันทึกไฟล์ $filename เรียบร้อยแล้วที่:',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                              ),
                              child: SelectableText(
                                savedPath,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '(คัดลอกตำแหน่งไฟล์ลงคลิปบอร์ดแล้ว สามารถเปิดใน File Explorer หรือ Excel ได้ทันที)',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => Get.back(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } catch (e) {
                    Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถบันทึกไฟล์ได้: $e', snackPosition: SnackPosition.TOP);
                  }
                },
                icon: const Icon(Icons.save_alt_rounded, size: 16),
                label: const Text('บันทึกลงไฟล์จริง'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportBottomSheet() {
    _importTextController.clear();
    setState(() => _parsedPreviewItems = null);

    Get.bottomSheet(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);

            return Material(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.96)
                  : AppColors.surface.withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppPopupHeader(
                        title: 'นำเข้าข้อมูลจาก CSV หรือ JSON',
                        subtitle: 'วางเนื้อหาไฟล์ CSV หรือ JSON จากการสำรองข้อมูลเพื่อตรวจสอบก่อนกู้คืน',
                        icon: Icons.cloud_download_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _importTextController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'วางเนื้อหา CSV หรือ JSON ที่นี่...',
                          hintStyle: const TextStyle(fontSize: 11),
                          filled: true,
                          fillColor: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                        ),
                        onChanged: (text) {
                          final items = text.trim().startsWith('{')
                              ? <TransactionItem>[]
                              : CsvService.importFromCsv(text);

                          setModalState(() {
                            _parsedPreviewItems = items;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_parsedPreviewItems != null && _parsedPreviewItems!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surplusBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surplusBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.surplusText),
                              const SizedBox(width: 8),
                              Text(
                                'ตรวจพบ ${_parsedPreviewItems!.length} รายการที่ถูกต้อง',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.surplusText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _parsedPreviewItems!.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _parsedPreviewItems![index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text('${item.categoryName} • ${item.date.day}/${item.date.month}/${item.date.year}', style: const TextStyle(fontSize: 11)),
                                trailing: Text(
                                  currencyFmt.format(item.amount),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: item.isIncome ? AppColors.primary : AppColors.deficitText,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else
                        const Spacer(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data != null && data.text != null) {
                                  _importTextController.text = data.text!;
                                  final items = data.text!.trim().startsWith('{')
                                      ? <TransactionItem>[]
                                      : CsvService.importFromCsv(data.text!);
                                  setModalState(() {
                                    _parsedPreviewItems = items;
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('วางจากคลิปบอร์ด'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_parsedPreviewItems != null && _parsedPreviewItems!.isNotEmpty) ||
                                      _importTextController.text.trim().startsWith('{')
                                  ? () async {
                                      final text = _importTextController.text.trim();
                                      if (text.startsWith('{')) {
                                        final result = await StorageService().restoreBackupJson(text);
                                        if (result != null) {
                                          if (result['transactions'] != null) {
                                            await controller.replaceAllTransactions(
                                              result['transactions'] as List<TransactionItem>,
                                            );
                                          }
                                          if (result['budgetPlan'] != null) {
                                            controller.updateBudgetPlan(result['budgetPlan']);
                                          }
                                          Get.back();
                                          Get.snackbar('สำเร็จ', 'กู้คืนข้อมูลสำรองเรียบร้อยแล้ว', snackPosition: SnackPosition.TOP);
                                        }
                                      } else if (_parsedPreviewItems != null && _parsedPreviewItems!.isNotEmpty) {
                                        await controller.importTransactions(_parsedPreviewItems!);
                                        Get.back();
                                        Get.snackbar(
                                          'สำเร็จ',
                                          'นำเข้าข้อมูลสำเร็จ ${_parsedPreviewItems!.length} รายการ!',
                                          snackPosition: SnackPosition.TOP,
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('ยืนยันนำเข้าข้อมูล', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmClearAll() {
    Get.dialog(
      AppConfirmDialog(
        title: 'ยืนยันล้างข้อมูลธุรกรรมทั้งหมด?',
        message: 'ระบบจะลบรายการธุรกรรมทั้งหมดออกจากเครื่องเพื่อเริ่มต้นใหม่ รายการที่ถูกลบจะไม่สามารถกู้คืนได้เว้นแต่คุณจะมีไฟล์สำรองข้อมูล',
        icon: Icons.delete_sweep_rounded,
        iconColor: AppColors.deficitText,
        confirmButtonColor: AppColors.deficitText,
        confirmText: 'ยืนยันล้างข้อมูลเป็น 0',
        onConfirm: () async {
          Get.back();
          await controller.clearAllToEmpty();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'data_management'.tr,
        badgeText: 'Backup & CSV',
        subtitle: 'data_subtitle'.tr,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Status Card
                Obx(() {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storage_rounded, color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Local Persistence Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(
                                'บันทึกข้อมูลถาวรในเครื่องแล้ว ${controller.transactions.length} รายการ',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Section 1: Export
                const Text('การส่งออกข้อมูล (Export)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        icon: Icons.table_chart_rounded,
                        color: const Color(0xFF10B981),
                        title: 'ส่งออกเป็นไฟล์ CSV (Excel Compatible)',
                        subtitle: 'มี UTF-8 BOM สำหรับเปิดอ่านบน Microsoft Excel หรือ Google Sheets',
                        onTap: _exportCsv,
                      ),
                      const Divider(height: 20),
                      _buildTile(
                        icon: Icons.backup_rounded,
                        color: const Color(0xFF8B5CF6),
                        title: 'สำรองข้อมูลทั้งหมด (JSON Full Backup)',
                        subtitle: 'สำรองรายการธุรกรรมและแผนงบประมาณสำหรับกู้คืนภายหลัง',
                        onTap: _exportJsonBackup,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 2: Import
                const Text('การนำเข้าข้อมูล (Import & Restore)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: _buildTile(
                    icon: Icons.file_download_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'นำเข้าข้อมูลจาก CSV หรือ JSON',
                    subtitle: 'วางข้อความหรือไฟล์สำรอง พร้อมระบบ Live Preview ตรวจสอบความถูกต้อง',
                    onTap: _showImportBottomSheet,
                  ),
                ),
                const SizedBox(height: 20),

                // Section 3: Manage Data State
                const Text('จัดการสถานะข้อมูล (Data State)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: _buildTile(
                    icon: Icons.delete_sweep_rounded,
                    color: AppColors.deficitText,
                    title: 'ล้างข้อมูลธุรกรรมทั้งหมด (Clear All)',
                    subtitle: 'ลบรายการธุรกรรมทั้งหมดออกจากเครื่องเพื่อเริ่มต้นใหม่',
                    onTap: _confirmClearAll,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
