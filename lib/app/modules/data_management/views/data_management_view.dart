import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/csv_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../security/controllers/security_controller.dart';

/// หน้าจอจัดการข้อมูล (Data Management) สไตล์ Nothing OS Design System
/// ศูนย์กลางการสำรอง กู้คืน และส่งออกข้อมูลระดับสถาบันการเงิน:
/// 1. Hero Storage Telemetry Card แสดงสถานะความปลอดภัยและการจัดเก็บบนเครื่อง 100%
/// 2. Export Bento Deck สำหรับ CSV (Excel Compatible) และ JSON Full Backup
/// 3. Import & Recovery Studio พร้อมระบบตรวจสอบความถูกต้องแบบเรียลไทม์ (Live Validation)
/// 4. Danger Zone พร้อมการยืนยันความปลอดภัย 2 ชั้น สไตล์ Nothing Red
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
        icon: Icons.cloud_sync_rounded,
      ),
    );
  }

  // ==========================================
  // EXPORT MODAL DIALOG
  // ==========================================
  Widget _buildExportDialog({
    required String title,
    required String description,
    required String content,
    required String filename,
    required int itemCount,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 540),
        child: NothingCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const NothingLedIndicator(size: 6, color: AppColors.nothingRed),
                      const SizedBox(width: 8),
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.white : Colors.black,
                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      ),
                    ],
                  ),
                  NothingPill(
                    label: '$itemCount RECORDS',
                    isDotMatrix: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    fontSize: 10,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NothingPill(
                    label: 'copy_text'.tr,
                    prefixIcon: const Icon(Icons.copy_rounded, size: 14),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: content));
                      AppFeedback.showSuccess(
                        title: 'copied_title'.tr,
                        message: 'copied_to_clipboard'.tr,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  NothingPill(
                    label: 'save_file_btn'.tr,
                    isSelected: true,
                    selectedColor: isDark ? Colors.white : Colors.black,
                    textColor: isDark ? Colors.black : Colors.white,
                    prefixIcon: Icon(
                      Icons.save_alt_rounded,
                      size: 14,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      try {
                        final savedPath = await StorageService().saveExportFile(
                          filename,
                          content,
                        );
                        await Clipboard.setData(ClipboardData(text: savedPath));
                        Get.back();
                        AppFeedback.showSuccess(
                          title: 'save_file_success'.tr,
                          message: savedPath,
                        );
                      } catch (e) {
                        AppFeedback.showError(
                          title: 'error_title'.tr,
                          message: e.toString(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // IMPORT BOTTOM SHEET
  // ==========================================
  void _showImportBottomSheet() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101010) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'import_data_modal_title'.tr.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white : Colors.black,
                      ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _importTextController,
                  maxLines: 4,
                  style: GoogleFonts.shareTechMono(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'import_data_hint'.tr,
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                    ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF181818) : const Color(0xFFF4F4F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
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
                const SizedBox(height: 14),

                if (_parsedPreviewItems != null && _parsedPreviewItems!.isNotEmpty) ...[
                  Row(
                    children: [
                      const NothingLedIndicator(size: 6, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'found_valid_items'.trParams({
                          'count': _parsedPreviewItems!.length.toString(),
                        }),
                        style: GoogleFonts.shareTechMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                Row(
                  children: [
                    Expanded(
                      child: NothingPill(
                        label: 'paste_from_clipboard'.tr,
                        prefixIcon: const Icon(Icons.paste_rounded, size: 14),
                        onTap: () async {
                          HapticFeedback.lightImpact();
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
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NothingPill(
                        label: 'confirm_import'.tr,
                        isSelected: true,
                        selectedColor: AppColors.nothingRed,
                        onTap: (_importTextController.text.trim().isNotEmpty)
                            ? () async {
                                HapticFeedback.mediumImpact();
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
                                    AppFeedback.showSuccess(
                                      title: 'copied_title'.tr,
                                      message: 'restore_success_msg'.tr,
                                    );
                                  }
                                } else if (_parsedPreviewItems != null &&
                                    _parsedPreviewItems!.isNotEmpty) {
                                  await controller.importTransactions(_parsedPreviewItems!);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF7F7F7),
      appBar: ModernAppBar(
        title: 'data_management'.tr,
        badgeText: 'VAULT & BACKUP',
        subtitle: 'data_subtitle'.tr,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Storage Telemetry Card
                _buildStorageTelemetryCard(isDark),
                const SizedBox(height: 24),

                // 2. Section 1: Export Bento Deck
                NothingSectionHeader(
                  title: 'section_export'.tr,
                  showRedPip: true,
                ),
                const SizedBox(height: 10),
                _buildExportBentoDeck(isDark),
                const SizedBox(height: 24),

                // 3. Section 2: Import & Disaster Recovery
                NothingSectionHeader(
                  title: 'section_import'.tr,
                  showRedPip: false,
                ),
                const SizedBox(height: 10),
                _buildImportCard(isDark),
                const SizedBox(height: 24),

                // 4. Section 3: Danger Zone
                NothingSectionHeader(
                  title: 'section_danger'.tr,
                  showRedPip: true,
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

      return NothingCard(
        showDotGrid: true,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.storage_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'local_vault_title'.tr.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: isDark ? Colors.white : Colors.black,
                          ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const NothingLedIndicator(size: 6, color: Color(0xFF10B981)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'stored_records_offline'.trParams({'count': count.toString()}),
                    style: GoogleFonts.shareTechMono(
                      fontSize: 11.5,
                      color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ==========================================
  // EXPORT BENTO DECK
  // ==========================================
  Widget _buildExportBentoDeck(bool isDark) {
    return NothingCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.table_chart_rounded,
            title: 'export_csv_card_title'.tr,
            subtitle: 'export_csv_card_desc'.tr,
            tag: '.CSV',
            onTap: _exportCsv,
            isDark: isDark,
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
          ),
          _buildActionTile(
            icon: Icons.cloud_sync_rounded,
            title: 'backup_card_title'.tr,
            subtitle: 'backup_card_desc'.tr,
            tag: '.JSON',
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
    return NothingCard(
      padding: EdgeInsets.zero,
      child: _buildActionTile(
        icon: Icons.file_download_rounded,
        title: 'import_card_title'.tr,
        subtitle: 'import_card_desc'.tr,
        tag: 'LIVE PREVIEW',
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
        color: isDark ? const Color(0xFF140808) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.nothingRed.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 0.8,
        ),
      ),
      child: _buildActionTile(
        icon: Icons.delete_sweep_rounded,
        title: 'clear_transactions_title'.tr,
        subtitle: 'clear_transactions_desc'.tr,
        tag: 'DANGER',
        tagColor: AppColors.nothingRed,
        iconColor: AppColors.nothingRed,
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
    required String title,
    required String subtitle,
    required String tag,
    required VoidCallback onTap,
    required bool isDark,
    Color? tagColor,
    Color? iconColor,
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181818) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.06),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? (isDark ? Colors.white : Colors.black),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        NothingPill(
                          label: tag,
                          isDotMatrix: true,
                          color: tagColor ?? (isDark ? Colors.white12 : Colors.black12),
                          textColor: tagColor ?? (isDark ? Colors.white70 : Colors.black87),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          fontSize: 9,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                      ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isDark ? AppColors.nothingSubtext : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal ยืนยันการล้างข้อมูลธุรกรรม สไตล์ Nothing OS Danger Zone
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
      Get.back();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemCount = widget.controller.transactions.length;
    final targetKeyword = 'target_keyword_clear'.tr;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: NothingCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const NothingLedIndicator(size: 7, color: AppColors.nothingRed),
                  const SizedBox(width: 8),
                  Text(
                    'DANGER ZONE // PURGE'.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.nothingRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'will_delete_records'.trParams({'count': itemCount.toString()}),
                style: GoogleFonts.shareTechMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 14),

              // Keyword confirmation
              TextField(
                controller: _keywordController,
                enabled: !_isExecuting,
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'TYPE "$targetKeyword"',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: isDark ? AppColors.nothingSubtext : const Color(0xFF888888),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF3F3F3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.nothingBorder : Colors.black12,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),

              // PIN confirmation if enabled
              if (_isPinEnabled) ...[
                TextField(
                  controller: _pinController,
                  enabled: !_isExecuting,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: GoogleFonts.shareTechMono(fontSize: 16, letterSpacing: 6),
                  decoration: InputDecoration(
                    hintText: '••••',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF3F3F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.nothingBorder : Colors.black12,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() => _pinErrorMessage = null),
                ),
                if (_pinErrorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _pinErrorMessage!,
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.nothingRed),
                  ),
                ],
                const SizedBox(height: 10),
              ],

              // Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _understandRisk,
                    activeColor: AppColors.nothingRed,
                    onChanged: (v) => setState(() => _understandRisk = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'understand_delete_risk'.tr,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                      ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                    ),
                  ),
                ],
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
                  NothingPill(
                    label: 'DELETE ALL',
                    isSelected: true,
                    selectedColor: AppColors.nothingRed,
                    onTap: _canSubmit ? _executeClear : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
