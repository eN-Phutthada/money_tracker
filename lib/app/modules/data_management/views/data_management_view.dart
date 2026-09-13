import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/csv_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../security/controllers/security_controller.dart';

/// หน้าจอจัดการข้อมูล (Data Management) สไตล์ Modern FinTech 2026
/// ศูนย์กลางการสำรอง กู้คืน และส่งออกข้อมูลระดับสถาบันการเงิน:
/// 1. Hero Storage Telemetry Card แสดงสถานะความปลอดภัยและการจัดเก็บบนเครื่อง 100%
/// 2. Export Bento Deck สำหรับ CSV (Excel Compatible) และ JSON Full Backup
/// 3. Import & Recovery Studio พร้อมระบบตรวจสอบความถูกต้องแบบเรียลไทม์ (Live Validation)
/// 4. Data Danger Zone พร้อมการยืนยันความปลอดภัย 2 ชั้น
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

  // ==========================================
  // EXPORT CSV ACTION
  // ==========================================
  void _exportCsv() {
    HapticFeedback.selectionClick();
    final transactions = controller.transactions;
    final csvContent = CsvService.exportToCsv(transactions);

    Get.dialog(
      _buildExportDialog(
        title: 'export_csv_modal_title'.tr,
        description: 'export_csv_modal_desc'.tr,
        content: csvContent,
        filename:
            'money_tracker_export_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}.csv',
        itemCount: transactions.length,
        accentColor: AppColors.primary,
        icon: Icons.table_chart_rounded,
      ),
    );
  }

  // ==========================================
  // EXPORT JSON BACKUP ACTION
  // ==========================================
  void _exportJsonBackup() async {
    HapticFeedback.selectionClick();
    final transactions = controller.transactions;
    final plan = controller.budgetPlan.value;
    final jsonContent = await StorageService().exportBackupJson(
      transactions,
      plan,
    );

    Get.dialog(
      _buildExportDialog(
        title: 'backup_all_modal_title'.tr,
        description: 'backup_all_modal_desc'.tr,
        content: jsonContent,
        filename:
            'money_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        itemCount: transactions.length,
        accentColor: AppColors.accent,
        icon: Icons.cloud_sync_rounded,
      ),
    );
  }

  // ==========================================
  // EXPORT MODAL GLASS DIALOG
  // ==========================================
  Widget _buildExportDialog({
    required String title,
    required String description,
    required String content,
    required String filename,
    required int itemCount,
    required Color accentColor,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppGlassDialog(
      maxWidth: 560,
      maxHeight: 540,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPopupHeader(
            title: title,
            subtitle:
                '$description (${'total_records'.trParams({'count': itemCount.toString()})})',
            icon: icon,
            iconColor: accentColor,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: content));
                  AppFeedback.showSuccess(
                    title: 'copied_title'.tr,
                    message: 'copied_to_clipboard'.tr,
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(
                  'copy_text'.tr,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    final savedPath = await StorageService().saveExportFile(
                      filename,
                      content,
                    );
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
                            AppPopupHeader(
                              title: 'save_file_success'.tr,
                              icon: Icons.check_circle_rounded,
                              iconColor: AppColors.primary,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'save_file_path'.trParams({'filename': filename}),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                ),
                              ),
                              child: SelectableText(
                                savedPath,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: () => Get.back(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'close_window'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } catch (_) {}
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(
                  'save_to_file'.tr,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // IMPORT BOTTOM SHEET
  // ==========================================
  void _showImportBottomSheet() {
    HapticFeedback.selectionClick();
    _importTextController.clear();
    setState(() => _parsedPreviewItems = null);

    Get.bottomSheet(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final currencyFmt = NumberFormat.currency(
              locale: 'th_TH',
              symbol: '฿',
              decimalDigits: 2,
            );

            return Material(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.98)
                  : AppColors.surface.withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 22,
                    right: 22,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppPopupHeader(
                        title: 'import_data_modal_title'.tr,
                        subtitle: 'import_data_modal_desc'.tr,
                        icon: Icons.cloud_download_rounded,
                        iconColor: AppColors.fixedCostAccent,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _importTextController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'import_data_hint'.tr,
                          hintStyle: const TextStyle(fontSize: 11),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkBackground
                              : AppColors.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
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
                      if (_parsedPreviewItems != null &&
                          _parsedPreviewItems!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'found_valid_items'.trParams({
                                  'count': _parsedPreviewItems!.length.toString(),
                                }),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _parsedPreviewItems!.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _parsedPreviewItems![index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.categoryName} • ${item.date.day}/${item.date.month}/${item.date.year}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Text(
                                  currencyFmt.format(item.amount),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: item.isIncome
                                        ? AppColors.primary
                                        : AppColors.deficitText,
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
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final data = await Clipboard.getData(
                                  'text/plain',
                                );
                                if (data != null && data.text != null) {
                                  _importTextController.text = data.text!;
                                  final items =
                                      data.text!.trim().startsWith('{')
                                      ? <TransactionItem>[]
                                      : CsvService.importFromCsv(data.text!);
                                  setModalState(() {
                                    _parsedPreviewItems = items;
                                  });
                                }
                              },
                              icon: const Icon(Icons.paste_rounded, size: 16),
                              label: Text(
                                'paste_from_clipboard'.tr,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  (_parsedPreviewItems != null &&
                                          _parsedPreviewItems!.isNotEmpty) ||
                                      _importTextController.text
                                          .trim()
                                          .startsWith('{')
                                  ? () async {
                                      HapticFeedback.mediumImpact();
                                      final text = _importTextController.text
                                          .trim();
                                      if (text.startsWith('{')) {
                                        final result = await StorageService()
                                            .restoreBackupJson(text);
                                        if (result != null) {
                                          if (result['transactions'] != null) {
                                            await controller
                                                .replaceAllTransactions(
                                                  result['transactions']
                                                      as List<TransactionItem>,
                                                );
                                          }
                                          if (result['budgetPlan'] != null) {
                                            controller.updateBudgetPlan(
                                              result['budgetPlan'],
                                            );
                                          }
                                          Get.back();
                                          AppFeedback.showSuccess(
                                            title: 'copied_title'.tr,
                                            message: 'restore_success_msg'.tr,
                                          );
                                        }
                                      } else if (_parsedPreviewItems != null &&
                                          _parsedPreviewItems!.isNotEmpty) {
                                        await controller.importTransactions(
                                          _parsedPreviewItems!,
                                        );
                                        Get.back();
                                        AppFeedback.showSuccess(
                                          title: 'copied_title'.tr,
                                          message: 'import_success_msg'.trParams({
                                            'count': _parsedPreviewItems!.length.toString(),
                                          }),
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'confirm_import'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
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
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ==========================================
  // CONFIRM CLEAR ALL (SECURE ANTI-ACCIDENTAL CONFIRMATION)
  // ==========================================
  void _confirmClearAll() {
    HapticFeedback.heavyImpact();
    Get.dialog(
      SecureClearAllDialog(
        controller: controller,
        onConfirmed: () async {
          await controller.clearAllToEmpty();
        },
      ),
      barrierDismissible: false,
    );
  }

  // ==========================================
  // MAIN VIEW BUILD
  // ==========================================
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
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Storage Telemetry Card
                _buildStorageTelemetryCard(isDark),
                const SizedBox(height: 22),

                // 2. Section 1: Export Studio Bento Deck
                _buildSectionHeader(
                  icon: Icons.upload_file_rounded,
                  title: 'section_export'.tr,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildExportBentoDeck(isDark),
                const SizedBox(height: 22),

                // 3. Section 2: Import & Disaster Recovery
                _buildSectionHeader(
                  icon: Icons.download_for_offline_rounded,
                  title: 'section_import'.tr,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildImportCard(isDark),
                const SizedBox(height: 22),

                // 4. Section 3: Danger Zone
                _buildSectionHeader(
                  icon: Icons.security_update_warning_rounded,
                  title: 'section_danger'.tr,
                  isDark: isDark,
                  color: AppColors.deficitText,
                ),
                const SizedBox(height: 10),
                _buildDangerZoneCard(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HERO STORAGE TELEMETRY CARD
  // ==========================================
  Widget _buildStorageTelemetryCard(bool isDark) {
    return Obx(() {
          final count = controller.transactions.length;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.12 : 0.05,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.35 : 0.25,
                    ),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Squircle Storage Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storage_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Telemetry Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'local_vault_title'.tr,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'stored_records_offline'.trParams({
                              'count': count.toString(),
                            }),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        })
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: -0.04);
  }

  // ==========================================
  // EXPORT BENTO DECK
  // ==========================================
  Widget _buildExportBentoDeck(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.table_chart_rounded,
            color: AppColors.primary,
            title: 'export_csv_card_title'.tr,
            subtitle: 'export_csv_card_desc'.tr,
            tag: 'CSV / Excel',
            onTap: _exportCsv,
            isDark: isDark,
          ),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.darkBorder
                : AppColors.border.withValues(alpha: 0.7),
          ),
          _buildActionTile(
            icon: Icons.cloud_sync_rounded,
            color: AppColors.accent,
            title: 'backup_card_title'.tr,
            subtitle: 'backup_card_desc'.tr,
            tag: 'JSON Vault',
            onTap: _exportJsonBackup,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // IMPORT CARD
  // ==========================================
  Widget _buildImportCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _buildActionTile(
        icon: Icons.file_download_rounded,
        color: AppColors.fixedCostAccent,
        title: 'import_card_title'.tr,
        subtitle: 'import_card_desc'.tr,
        tag: 'live_preview'.tr,
        onTap: _showImportBottomSheet,
        isDark: isDark,
      ),
    );
  }

  // ==========================================
  // DANGER ZONE CARD
  // ==========================================
  Widget _buildDangerZoneCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.deficitText.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deficitText.withValues(
              alpha: isDark ? 0.12 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _buildActionTile(
        icon: Icons.delete_sweep_rounded,
        color: AppColors.deficitText,
        title: 'clear_transactions_title'.tr,
        subtitle: 'clear_transactions_desc'.tr,
        tag: 'reset_zero'.tr,
        onTap: _confirmClearAll,
        isDark: isDark,
      ),
    );
  }

  // ==========================================
  // ACTION TILE BUILDER
  // ==========================================
  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String tag,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Squircle Action Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // Title, Subtitle, & Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION HEADER
  // ==========================================
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.primary;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: effectiveColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: effectiveColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Modal ยืนยันการล้างข้อมูลธุรกรรมระดับความปลอดภัยสูงสุด (Anti-Accidental Clear Dialog)
/// ป้องกันการเผลอกดโดยไม่ได้ตั้งใจ 100%:
/// 1. สรุปผลกระทบและจำนวนรายการธุรกรรมที่จะถูกลบ
/// 2. บังคับพิมพ์ข้อความยืนยันความตั้งใจจริง ("ล้างข้อมูล" หรือ "CLEAR")
/// 3. มีกล่อง Checkbox รับทราบความเสี่ยงถาวร
/// 4. ตรวจสอบรหัส PIN 4 หลักของเครื่อง (กรณีผู้ใช้เปิดใช้งานระบบความปลอดภัย PIN)
/// 5. ปุ่มยืนยันจะถูกล็อกปิดการใช้งาน (Disabled) จนกว่าจะผ่านเงื่อนไขทั้งหมดครบถ้วน
class SecureClearAllDialog extends StatefulWidget {
  final DashboardController controller;
  final Future<void> Function() onConfirmed;

  const SecureClearAllDialog({
    super.key,
    required this.controller,
    required this.onConfirmed,
  });

  @override
  State<SecureClearAllDialog> createState() => _SecureClearAllDialogState();
}

class _SecureClearAllDialogState extends State<SecureClearAllDialog> {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _understandRisk = false;
  bool _isExecuting = false;
  String? _pinErrorMessage;

  bool get _isPinEnabled {
    if (Get.isRegistered<SecurityController>()) {
      return Get.find<SecurityController>().isPinEnabled.value;
    }
    return false;
  }

  bool get _isKeywordMatched {
    final text = _keywordController.text.trim().toLowerCase();
    final target = 'target_keyword_clear'.tr.toLowerCase();
    return text == target ||
        text == 'clear' ||
        text == 'delete' ||
        text == 'ล้างข้อมูล' ||
        text == 'ล้าง' ||
        text == 'ลบ';
  }

  bool get _isPinValid {
    if (!_isPinEnabled) return true;
    final pin = _pinController.text.trim();
    if (pin.length != 4) return false;
    return Get.find<SecurityController>().verifyPin(pin, autoUnlock: false);
  }

  bool get _canSubmit {
    return _isKeywordMatched && _understandRisk && _isPinValid && !_isExecuting;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _executeClear() async {
    if (!_canSubmit) return;

    // Double check PIN if enabled
    if (_isPinEnabled) {
      final pin = _pinController.text.trim();
      final sec = Get.find<SecurityController>();
      if (!sec.verifyPin(pin, autoUnlock: false)) {
        HapticFeedback.vibrate();
        setState(() {
          _pinErrorMessage = 'pin_incorrect'.tr;
        });
        return;
      }
    }

    setState(() {
      _isExecuting = true;
    });

    try {
      HapticFeedback.heavyImpact();
      Get.back(); // close dialog
      await widget.onConfirmed();
      AppFeedback.showSuccess(
        title: 'cleared_success_title'.tr,
        message: 'cleared_success_msg'.tr,
      );
    } catch (e) {
      setState(() {
        _isExecuting = false;
      });
      AppFeedback.showError(
        title: 'error_title'.tr,
        message: e.toString(),
      );
    }
  }

  Widget _buildWarningItem({
    required IconData icon,
    required String text,
    required bool isDark,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.deficitText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemCount = widget.controller.transactions.length;
    final screenHeight = MediaQuery.of(context).size.height;
    final targetKeyword = 'target_keyword_clear'.tr;

    return AppGlassDialog(
      maxWidth: 440,
      maxHeight: screenHeight * 0.88,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // 1. Header with Danger Shield Icon
          AppPopupHeader(
            title: 'clear_transactions_confirm_title'.tr,
            subtitle: 'clear_transactions_confirm_desc'.tr,
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.deficitText,
            onClose: _isExecuting ? null : () => Get.back(),
          ),
          const SizedBox(height: 16),

          // 2. Impact Warning Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.deficitText.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.deficitText.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.deficitText,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'danger_zone'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'will_delete_records'.trParams({
                          'count': itemCount.toString(),
                        }),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deficitText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildWarningItem(
                  icon: Icons.remove_circle_outline_rounded,
                  text: 'delete_history_warning'.tr,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildWarningItem(
                  icon: Icons.check_circle_outline_rounded,
                  text: 'budget_preserved_note'.tr,
                  isDark: isDark,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 6),
                _buildWarningItem(
                  icon: Icons.history_rounded,
                  text: 'cannot_undo_note'.tr,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Step 1: Type-to-Confirm Prompt
          Text.rich(
            TextSpan(
              text: 'step_type_confirm_prefix'.tr,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '"$targetKeyword"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.deficitText,
                  ),
                ),
                TextSpan(
                  text: 'step_type_confirm_suffix'.tr,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _keywordController,
            enabled: !_isExecuting,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'step_type_confirm_hint'.trParams({'keyword': targetKeyword}),
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                color: _isKeywordMatched
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                size: 20,
              ),
              suffixIcon: _isKeywordMatched
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _isKeywordMatched
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _isKeywordMatched
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _isKeywordMatched ? AppColors.primary : AppColors.deficitText,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // 4. Step 2 (Optional): PIN Verification if PIN is enabled
          if (_isPinEnabled) ...[
            Text(
              'step_pin_confirm'.tr,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              enabled: !_isExecuting,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 6,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: TextStyle(
                  letterSpacing: 6,
                  color: isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.shield_outlined,
                  color: _isPinValid
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  size: 20,
                ),
                suffixIcon: _isPinValid
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _isPinValid
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _isPinValid
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _isPinValid ? AppColors.primary : AppColors.deficitText,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (_) {
                setState(() {
                  _pinErrorMessage = null;
                });
              },
            ),
            if (_pinErrorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _pinErrorMessage!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.deficitText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // 5. Risk Acknowledgment Checkbox
          InkWell(
            onTap: _isExecuting
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _understandRisk = !_understandRisk;
                    });
                  },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _understandRisk,
                      activeColor: AppColors.deficitText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      onChanged: _isExecuting
                          ? null
                          : (val) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _understandRisk = val ?? false;
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'understand_delete_risk'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 6. Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isExecuting ? null : () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'cancel_keep_data'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _canSubmit
                        ? [
                            BoxShadow(
                              color: AppColors.deficitText.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _executeClear : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deficitText,
                      disabledBackgroundColor: isDark
                          ? AppColors.darkSurfaceSecondary
                          : Colors.black.withValues(alpha: 0.08),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: isDark
                          ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                      elevation: _canSubmit ? 2 : 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isExecuting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _canSubmit
                                    ? Icons.delete_forever_rounded
                                    : Icons.lock_outline_rounded,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _canSubmit
                                      ? 'clear_to_zero'.tr
                                      : 'locked_status'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
