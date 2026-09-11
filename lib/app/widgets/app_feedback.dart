import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../data/models/transaction_model.dart';
import '../theme/app_colors.dart';

/// ประเภทของการแจ้งเตือนแบบ In-App Feedback
enum FeedbackType { success, info, warning, error }

/// ระบบแสดงผล Feedback แจ้งเตือนสไตล์ Liquid Glass Dynamic Island FinTech 2026
/// สวยงามระดับพรีเมียม แสดงผลลอยด้านบนจอ พร้อม Countdown Bar, Haptic Feedback และ Drag-to-Dismiss
class AppFeedback {
  static OverlayEntry? _activeEntry;
  static _AppFeedbackHudState? _currentState;

  /// แสดงการแจ้งเตือนบันทึกสำเร็จ
  static void showSuccess({
    String? title,
    required String message,
    double? amount,
    TransactionType? transactionType,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(
      title: title ?? 'save_success_title'.tr,
      message: message,
      type: FeedbackType.success,
      amount: amount,
      transactionType: transactionType,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// แสดงการแจ้งเตือนข้อมูลทั่วไป
  static void showInfo({
    String? title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      title: title ?? 'แจ้งเตือน',
      message: message,
      type: FeedbackType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// แสดงการแจ้งเตือนเตือนระวัง
  static void showWarning({
    String? title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3400),
  }) {
    show(
      title: title ?? 'แจ้งเตือน',
      message: message,
      type: FeedbackType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// แสดงการแจ้งเตือนข้อผิดพลาด
  static void showError({
    String? title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3600),
  }) {
    show(
      title: title ?? 'เกิดข้อผิดพลาด',
      message: message,
      type: FeedbackType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// ซ่อนการแจ้งเตือนปัจจุบันทันที
  static void dismiss() {
    if (_currentState != null && _currentState!.mounted) {
      _currentState!.animateDismiss();
    } else {
      _cleanUpEntry();
    }
  }

  static void _cleanUpEntry() {
    _currentState = null;
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
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    // ปิด Toast ก่อนหน้าหากยังมีอยู่
    if (_activeEntry != null) {
      _cleanUpEntry();
    }

    // ตอบสนองด้วย Haptic Feedback ตามระดับความสำคัญ
    try {
      if (type == FeedbackType.success) {
        HapticFeedback.mediumImpact();
      } else if (type == FeedbackType.warning || type == FeedbackType.error) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}

    BuildContext? context = Get.overlayContext;
    if (context == null && Get.key.currentState != null) {
      context = Get.key.currentContext;
    }
    context ??= Get.context;
    if (context == null) return;

    OverlayState? overlay;
    try {
      if (Get.key.currentState != null && Get.key.currentState!.overlay != null) {
        overlay = Get.key.currentState!.overlay;
      }
    } catch (_) {}

    overlay ??= Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    try {
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) {
          return _AppFeedbackHud(
            key: GlobalKey<_AppFeedbackHudState>(),
            title: title,
            message: message,
            type: type,
            amount: amount,
            transactionType: transactionType,
            actionLabel: actionLabel,
            onAction: onAction,
            duration: duration,
            onDismissed: () {
              if (_activeEntry == entry) {
                _cleanUpEntry();
              }
            },
          );
        },
      );

      _activeEntry = entry;
      overlay.insert(entry);
    } catch (_) {}
  }
}

class _AppFeedbackHud extends StatefulWidget {
  final String title;
  final String message;
  final FeedbackType type;
  final double? amount;
  final TransactionType? transactionType;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppFeedbackHud({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.amount,
    this.transactionType,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppFeedbackHud> createState() => _AppFeedbackHudState();
}

class _AppFeedbackHudState extends State<_AppFeedbackHud> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  late AnimationController _progressController;
  late AnimationController _shimmerController;

  double _dragOffsetY = 0.0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    AppFeedback._currentState = this;

    // 1. Entrance & Exit Spring Physics
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _slideAnimation = Tween<double>(begin: -70.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    // 2. Countdown Progress Bar Animation
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animateDismiss();
      }
    });

    // 3. Subtle Liquid Edge Gleam Animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
        Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _shimmerController.repeat(reverse: true);
    }

    // Start entrance and progress
    _entryController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    if (AppFeedback._currentState == this) {
      AppFeedback._currentState = null;
    }
    _progressController.dispose();
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void animateDismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _progressController.stop();
    _entryController.reverse().then((_) {
      widget.onDismissed();
    });
  }

  void _pauseCountdown() {
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
  }

  void _resumeCountdown() {
    if (!_isDismissing && !_progressController.isAnimating && _progressController.value < 1.0) {
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    Color themeColor;
    IconData icon;
    String statusLabel;

    switch (widget.type) {
      case FeedbackType.success:
        themeColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        statusLabel = 'SUCCESS';
        break;
      case FeedbackType.info:
        themeColor = AppColors.primary;
        icon = Icons.info_rounded;
        statusLabel = 'INFO';
        break;
      case FeedbackType.warning:
        themeColor = const Color(0xFFF59E0B);
        icon = Icons.warning_amber_rounded;
        statusLabel = 'WARNING';
        break;
      case FeedbackType.error:
        themeColor = AppColors.deficitText;
        icon = Icons.error_outline_rounded;
        statusLabel = 'ALERT';
        break;
    }

    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);

    return Positioned(
      top: topPadding > 0 ? topPadding + 10 : 18,
      left: 14,
      right: 14,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entryController, _shimmerController]),
        builder: (context, child) {
          final totalTranslateY = _slideAnimation.value + _dragOffsetY;
          final totalOpacity = (_opacityAnimation.value * (1.0 - (-_dragOffsetY / 120.0).clamp(0.0, 1.0)))
              .clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(0, totalTranslateY),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: totalOpacity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: GestureDetector(
                      onTapDown: (_) => _pauseCountdown(),
                      onTapUp: (_) => _resumeCountdown(),
                      onTapCancel: () => _resumeCountdown(),
                      onVerticalDragDown: (_) => _pauseCountdown(),
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          if (details.primaryDelta != null) {
                            if (_dragOffsetY + details.primaryDelta! < 0) {
                              _dragOffsetY += details.primaryDelta!;
                            } else {
                              // Rubber-band resistance when pulling down
                              _dragOffsetY += details.primaryDelta! * 0.28;
                            }
                          }
                        });
                      },
                      onVerticalDragEnd: (details) {
                        if (_dragOffsetY < -25 || (details.primaryVelocity != null && details.primaryVelocity! < -250)) {
                          HapticFeedback.selectionClick();
                          animateDismiss();
                        } else {
                          setState(() {
                            _dragOffsetY = 0.0;
                          });
                          _resumeCountdown();
                        }
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              // Outer Dynamic Ambient Theme Glow
                              BoxShadow(
                                color: themeColor.withValues(alpha: isDark ? 0.32 : 0.22),
                                blurRadius: 28,
                                spreadRadius: -2,
                                offset: const Offset(0, 10),
                              ),
                              // Deep Surface Drop Shadow
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: LiquidGlassLens(
                            style: LiquidGlassStyle(
                              shape: const LiquidGlassShape.squircle(
                                cornerRadius: 24,
                                borderWidth: 1.2,
                                lightIntensity: 1.3,
                                lightDirection: 65,
                                borderType: OpticalBorder(
                                  borderSaturation: 1.35,
                                  ambientIntensity: 1.15,
                                  borderSolidity: 0.25,
                                ),
                              ),
                              appearance: LiquidGlassAppearance(
                                color: isDark
                                    ? const Color(0xFF111726).withValues(alpha: 0.65)
                                    : const Color(0xFFFFFFFF).withValues(alpha: 0.76),
                                blur: const LiquidGlassBlur(sigmaX: 16, sigmaY: 16),
                              ),
                              refraction: const LiquidGlassRefraction(
                                distortion: 0.08,
                                distortionWidth: 24,
                                chromaticAberration: 0.003,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          AppColors.darkSurface.withValues(alpha: 0.30),
                                          AppColors.darkSurfaceSecondary.withValues(alpha: 0.16),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: 0.38),
                                          Colors.white.withValues(alpha: 0.20),
                                        ],
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.16 + (_shimmerController.value * 0.08))
                                      : themeColor.withValues(alpha: 0.28 + (_shimmerController.value * 0.12)),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Main Content Area
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Glowing Squircle Icon Badge
                                          _buildIconBadge(themeColor, icon, isDark),
                                          const SizedBox(width: 12),

                                          // Notification Text & Amount Chip
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Header row with status pill and amount
                                                Row(
                                                  children: [
                                                    // Micro status indicator beacon
                                                    Container(
                                                      width: 5,
                                                      height: 5,
                                                      margin: const EdgeInsets.only(right: 5),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: themeColor,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: themeColor.withValues(alpha: 0.6),
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      statusLabel,
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: 0.6,
                                                        color: themeColor,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        widget.title,
                                                        style: TextStyle(
                                                          fontSize: 13.5,
                                                          fontWeight: FontWeight.w800,
                                                          letterSpacing: -0.2,
                                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                                          shadows: [
                                                            Shadow(
                                                              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.45),
                                                              blurRadius: 2,
                                                              offset: const Offset(0, 1),
                                                            ),
                                                          ],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (widget.amount != null) ...[
                                                      const SizedBox(width: 6),
                                                      _buildAmountBadge(currencyFmt),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  widget.message,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    height: 1.35,
                                                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                                    fontWeight: FontWeight.w500,
                                                    shadows: [
                                                      Shadow(
                                                        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.30),
                                                        blurRadius: 1.5,
                                                        offset: const Offset(0, 0.5),
                                                      ),
                                                    ],
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Optional Action Button (e.g. Undo / View)
                                          if (widget.actionLabel != null && widget.onAction != null) ...[
                                            const SizedBox(width: 8),
                                            _buildActionButton(themeColor, isDark),
                                          ],

                                          const SizedBox(width: 6),

                                          // Smooth Dismiss Button
                                          _buildCloseButton(isDark),
                                        ],
                                      ),
                                    ),

                                    // Liquid Progress Countdown Bar at the bottom rim
                                    _buildProgressBar(themeColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconBadge(Color themeColor, IconData icon, bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: themeColor.withValues(alpha: isDark ? 0.35 : 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: isDark ? 0.24 : 0.14),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: themeColor,
        size: 23,
      ),
    );
  }

  Widget _buildAmountBadge(NumberFormat currencyFmt) {
    if (widget.amount == null) return const SizedBox.shrink();

    Color pillColor;
    String prefix = '';
    final IconData trendIcon;

    if (widget.transactionType == TransactionType.income) {
      pillColor = AppColors.primary;
      prefix = '+';
      trendIcon = Icons.arrow_upward_rounded;
    } else if (widget.transactionType == TransactionType.savingsInvestment) {
      pillColor = AppColors.accent;
      prefix = '';
      trendIcon = Icons.savings_outlined;
    } else {
      pillColor = AppColors.deficitText;
      prefix = '-';
      trendIcon = Icons.arrow_downward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pillColor.withValues(alpha: 0.30),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 10.5, color: pillColor),
          const SizedBox(width: 2.5),
          Text(
            '$prefix${currencyFmt.format(widget.amount)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: pillColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Color themeColor, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onAction?.call();
          animateDismiss();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.32),
              width: 1,
            ),
          ),
          child: Text(
            widget.actionLabel!,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: themeColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(bool isDark) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        animateDismiss();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          size: 15,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color themeColor) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final progress = (1.0 - _progressController.value).clamp(0.0, 1.0);

        return Container(
          height: 2.5,
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.08),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withValues(alpha: 0.25),
                    themeColor,
                    Colors.white.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.85, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.45),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
