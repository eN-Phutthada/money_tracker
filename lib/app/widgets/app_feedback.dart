import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../data/models/transaction_model.dart';
import '../theme/app_colors.dart';

/// ประเภทของการแจ้งเตือนแบบ In-App Feedback
enum FeedbackType { success, info, warning, error }

/// ระบบแสดงผล Feedback แจ้งเตือนความสำเร็จ (In-App Notification Banner & Toast)
/// สไตล์ Glassmorphism FinTech ระดับพรีเมียม แสดงผลลอยด้านบนจอพร้อม Haptic Feedback
class AppFeedback {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  /// แสดงการแจ้งเตือนบันทึกสำเร็จ
  static void showSuccess({
    String? title,
    required String message,
    double? amount,
    TransactionType? transactionType,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      title: title ?? 'save_success_title'.tr,
      message: message,
      type: FeedbackType.success,
      amount: amount,
      transactionType: transactionType,
      duration: duration,
    );
  }

  /// แสดงการแจ้งเตือนข้อมูลทั่วไป
  static void showInfo({
    String? title,
    required String message,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    show(
      title: title ?? 'แจ้งเตือน',
      message: message,
      type: FeedbackType.info,
      duration: duration,
    );
  }

  /// แสดงการแจ้งเตือนเตือนระวัง
  static void showWarning({
    String? title,
    required String message,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      title: title ?? 'แจ้งเตือน',
      message: message,
      type: FeedbackType.warning,
      duration: duration,
    );
  }

  /// ซ่อนการแจ้งเตือนปัจจุบันทันที
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_activeEntry != null) {
      try {
        _activeEntry?.remove();
      } catch (_) {}
      _activeEntry = null;
    }
  }

  /// แสดงแบนเนอร์แจ้งเตือนหลัก
  static void show({
    required String title,
    required String message,
    FeedbackType type = FeedbackType.success,
    double? amount,
    TransactionType? transactionType,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    // ปิด Toast ก่อนหน้าหากยังมีอยู่
    dismiss();

    // ตอบสนองด้วย Haptic Feedback ตามความสำคัญ
    try {
      if (type == FeedbackType.success) {
        HapticFeedback.mediumImpact();
      } else if (type == FeedbackType.warning || type == FeedbackType.error) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    try {
      final overlay = Overlay.of(context, rootOverlay: true);

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) {
          return _AppFeedbackBanner(
            title: title,
            message: message,
            type: type,
            amount: amount,
            transactionType: transactionType,
            onDismiss: () {
              if (_activeEntry == entry) {
                dismiss();
              }
            },
          );
        },
      );

      _activeEntry = entry;
      overlay.insert(entry);

      _dismissTimer = Timer(duration, () {
        if (_activeEntry == entry) {
          dismiss();
        }
      });
    } catch (_) {
      // Fallback ป้องกัน Error หาก Overlay ยังไม่พร้อมใช้งาน
      try {
        if (Get.context != null) {
          Get.snackbar(
            title,
            message,
            snackPosition: SnackPosition.TOP,
            duration: duration,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
          );
        }
      } catch (_) {}
    }
  }
}

class _AppFeedbackBanner extends StatelessWidget {
  final String title;
  final String message;
  final FeedbackType type;
  final double? amount;
  final TransactionType? transactionType;
  final VoidCallback onDismiss;

  const _AppFeedbackBanner({
    required this.title,
    required this.message,
    required this.type,
    this.amount,
    this.transactionType,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    Color themeColor;
    IconData icon;

    switch (type) {
      case FeedbackType.success:
        themeColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      case FeedbackType.info:
        themeColor = AppColors.primary;
        icon = Icons.info_rounded;
        break;
      case FeedbackType.warning:
        themeColor = const Color(0xFFF59E0B);
        icon = Icons.warning_amber_rounded;
        break;
      case FeedbackType.error:
        themeColor = AppColors.deficitText;
        icon = Icons.error_outline_rounded;
        break;
    }

    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);

    return Positioned(
      top: topPadding > 0 ? topPadding + 10 : 18,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GestureDetector(
            onTap: onDismiss,
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -4) {
                onDismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface.withValues(alpha: 0.94)
                          : Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: themeColor.withValues(alpha: isDark ? 0.35 : 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: isDark ? 0.25 : 0.16),
                          blurRadius: 24,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Glowing Icon Squircle
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.32),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(icon, color: themeColor, size: 22)
                              .animate(onPlay: (c) => c.forward())
                              .scale(
                                begin: const Offset(0.75, 0.75),
                                end: const Offset(1.15, 1.15),
                                duration: 240.ms,
                                curve: Curves.easeOutBack,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.15, 1.15),
                                end: const Offset(1.0, 1.0),
                                duration: 160.ms,
                              ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (amount != null) ...[
                                    const SizedBox(width: 6),
                                    _buildAmountBadge(currencyFmt),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Dismiss button
                        InkWell(
                          onTap: onDismiss,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .slideY(
                begin: -1.2,
                end: 0,
                duration: 320.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 220.ms),
        ),
      ),
    );
  }

  Widget _buildAmountBadge(NumberFormat currencyFmt) {
    if (amount == null) return const SizedBox.shrink();

    Color pillColor;
    String prefix = '';
    if (transactionType == TransactionType.income) {
      pillColor = AppColors.primary;
      prefix = '+';
    } else if (transactionType == TransactionType.savingsInvestment) {
      pillColor = AppColors.accent;
      prefix = '';
    } else {
      pillColor = AppColors.deficitText;
      prefix = '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: pillColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        '$prefix${currencyFmt.format(amount)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: pillColor,
        ),
      ),
    );
  }
}
