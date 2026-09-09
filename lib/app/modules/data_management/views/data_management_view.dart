import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/csv_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../theme/app_colors.dart';
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

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$description (รวม $itemCount รายการ)',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
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
                        'คัดลอกข้อมูลลงคลิปบอร์ดแล้ว',
                        snackPosition: SnackPosition.TOP,
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('คัดลอกข้อความ'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      Get.back();
                      Get.snackbar(
                        'สำเร็จ',
                        'เตรียมไฟล์ $filename เรียบร้อย (คัดลอกลงคลิปบอร์ดแล้ว)',
                        snackPosition: SnackPosition.TOP,
                      );
                    },
                    icon: const Icon(Icons.download_done_rounded, size: 16),
                    label: const Text('ตกลง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportBottomSheet() {
    _importTextController.clear();
    setState(() => _parsedPreviewItems = null);

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);

          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'นำเข้าข้อมูลจาก CSV หรือ JSON',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'วางเนื้อหาไฟล์ CSV หรือ JSON จากการสำรองข้อมูลเพื่อตรวจสอบก่อนกู้คืน',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surplusBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surplusBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.surplusText),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ยืนยันนำเข้าข้อมูล'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _confirmReset() {
    Get.dialog(
      AlertDialog(
        title: const Text('ยืนยันการรีเซ็ตข้อมูล?'),
        content: const Text('การดำเนินการนี้จะลบรายการที่บันทึกไว้ทั้งหมด และรีเซ็ตกลับเป็นข้อมูลตัวอย่างเริ่มต้น'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.resetToDefault();
              Get.snackbar('สำเร็จ', 'รีเซ็ตข้อมูลกลับสู่ค่าเริ่มต้นเรียบร้อยแล้ว', snackPosition: SnackPosition.TOP);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.deficitText, foregroundColor: Colors.white),
            child: const Text('รีเซ็ตข้อมูล'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการข้อมูล (Data Management)'),
        elevation: 0,
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

                // Section 3: Reset
                const Text('รีเซ็ตข้อมูล', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deficitText)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: _buildTile(
                    icon: Icons.restart_alt_rounded,
                    color: AppColors.deficitText,
                    title: 'รีเซ็ตข้อมูลกลับสู่ค่าเริ่มต้น',
                    subtitle: 'ลบรายการทั้งหมดและคืนค่าข้อมูลตัวอย่างตั้งต้น',
                    onTap: _confirmReset,
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
