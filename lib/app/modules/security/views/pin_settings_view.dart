import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../data/services/security_service.dart';
import '../controllers/security_controller.dart';

/// หน้าจอตั้งค่าความปลอดภัยและรหัส PIN ด้วย GetX (FinTech 2026 Security Command Center)
class PinSettingsView extends GetView<SecurityController> {
  const PinSettingsView({super.key});

  void _showSetPinDialog(BuildContext context) {
    String firstPin = '';
    String confirmPin = '';
    bool isConfirmStep = false;
    bool isSuccess = false;
    String? dialogError;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final currentPin = isConfirmStep ? confirmPin : firstPin;

          return AppGlassDialog(
            maxWidth: 380,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppPopupHeader(
                  title: isSuccess
                      ? 'pin_set_success_dialog_title'.tr
                      : (isConfirmStep
                            ? 'confirm_pin_4_digits'.tr
                            : 'set_new_pin_4_digits'.tr),
                  subtitle: isSuccess
                      ? 'pin_set_success_dialog_subtitle'.tr
                      : (dialogError ??
                            (isConfirmStep
                                ? 'enter_same_pin_confirm'.tr
                                : 'enter_4_digits_to_set'.tr)),
                  icon: isSuccess
                      ? Icons.check_circle_rounded
                      : (isConfirmStep
                            ? Icons.verified_user_rounded
                            : Icons.lock_rounded),
                  iconColor: isSuccess
                      ? const Color(0xFF10B981)
                      : (dialogError != null
                            ? AppColors.deficitText
                            : AppColors.primary),
                  onClose: () => Get.back(),
                ),
                const SizedBox(height: 24),

                // Step Indicator Pills
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (!isConfirmStep
                                      ? AppColors.primary
                                      : AppColors.textSecondary)
                                  .withValues(alpha: !isConfirmStep ? 0.16 : 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                (!isConfirmStep
                                        ? AppColors.primary
                                        : AppColors.textSecondary)
                                    .withValues(alpha: !isConfirmStep ? 0.45 : 0.20),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              !isConfirmStep ? Icons.edit_rounded : Icons.check_circle_rounded,
                              size: 11,
                              color: !isConfirmStep ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'pin_step_1'.tr,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: !isConfirmStep
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isConfirmStep
                                      ? AppColors.primary
                                      : AppColors.textSecondary)
                                  .withValues(alpha: isConfirmStep ? 0.16 : 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                (isConfirmStep
                                        ? AppColors.primary
                                        : AppColors.textSecondary)
                                    .withValues(alpha: isConfirmStep ? 0.45 : 0.20),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isConfirmStep ? Icons.verified_user_rounded : Icons.lock_outline_rounded,
                              size: 11,
                              color: isConfirmStep ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'pin_step_2'.tr,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isConfirmStep
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4 Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < currentPin.length;
                    final dotColor = isSuccess
                        ? const Color(0xFF10B981)
                        : (dialogError != null
                              ? AppColors.deficitText
                              : AppColors.primary);

                    Widget dot = AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: isSuccess ? 18 : 16,
                      height: isSuccess ? 18 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? dotColor : Colors.transparent,
                        border: Border.all(
                          color: isFilled
                              ? dotColor
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          width: 2,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: dotColor.withValues(
                                    alpha: isSuccess ? 0.6 : 0.4,
                                  ),
                                  blurRadius: isSuccess ? 14 : 8,
                                  spreadRadius: isSuccess ? 2.5 : 1.5,
                                ),
                              ]
                            : null,
                      ),
                    );

                    if (isSuccess) {
                      dot = dot
                          .animate(delay: Duration(milliseconds: index * 60))
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(1.0, 1.0),
                            duration: const Duration(milliseconds: 150),
                          );
                    }
                    return dot;
                  }),
                ),
                const SizedBox(height: 22),

                // Mini Numpad
                ..._buildMiniNumpad(
                  isDark: isDark,
                  onKey: (k) async {
                    if (isSuccess) return;
                    setDialogState(() {
                      dialogError = null;
                      if (k == '⌫') {
                        if (isConfirmStep) {
                          if (confirmPin.isNotEmpty) {
                            confirmPin = confirmPin.substring(
                              0,
                              confirmPin.length - 1,
                            );
                          }
                        } else {
                          if (firstPin.isNotEmpty) {
                            firstPin = firstPin.substring(
                              0,
                              firstPin.length - 1,
                            );
                          }
                        }
                        return;
                      }

                      if (!isConfirmStep) {
                        if (firstPin.length < 4) firstPin += k;
                        if (firstPin.length == 4) {
                          isConfirmStep = true;
                        }
                      } else {
                        if (confirmPin.length < 4) confirmPin += k;
                        if (confirmPin.length == 4) {
                          if (confirmPin == firstPin) {
                            isSuccess = true;
                            HapticFeedback.mediumImpact();
                            Future.delayed(
                              const Duration(milliseconds: 400),
                              () async {
                                await controller.setPin(firstPin);
                                if (Get.isDialogOpen ?? false) Get.back();
                                AppFeedback.showSuccess(
                                  title: 'pin_set_success_title'.tr,
                                  message: 'pin_set_success_msg'.tr,
                                );
                              },
                            );
                          } else {
                            dialogError = 'pin_mismatch'.tr;
                            confirmPin = '';
                          }
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  static const Map<String, String> _miniNumpadSubtitles = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  List<Widget> _buildMiniNumpad({
    required bool isDark,
    required Function(String) onKey,
  }) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return rows.map((row) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 60, height: 50);

            if (key == '⌫') {
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onKey(key);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 60,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E283D).withValues(alpha: 0.55),
                              const Color(0xFF141C2B).withValues(alpha: 0.65),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.85),
                              const Color(0xFFE2E8F0).withValues(alpha: 0.70),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.60)
                          : AppColors.border.withValues(alpha: 0.70),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 19,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              );
            }

            final subtitle = _miniNumpadSubtitles[key] ?? '';
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onKey(key);
              },
              borderRadius: BorderRadius.circular(16),
              splashColor: AppColors.primary.withValues(alpha: 0.15),
              highlightColor: AppColors.primary.withValues(alpha: 0.08),
              child: Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF1E283D).withValues(alpha: 0.85),
                            const Color(0xFF121826).withValues(alpha: 0.90),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.95),
                            const Color(0xFFF1F5F9).withValues(alpha: 0.90),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E3D60).withValues(alpha: 0.65)
                        : const Color(0xFFCBD5E1).withValues(alpha: 0.80),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      key,
                      style: TextStyle(
                        fontSize: subtitle.isNotEmpty ? 17 : 19,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 1.5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          height: 1.0,
                          color: isDark
                              ? AppColors.darkTextSecondary.withValues(alpha: 0.75)
                              : AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Future<void> _handleToggleBiometrics(BuildContext context, bool enabled) async {
    HapticFeedback.selectionClick();
    if (enabled) {
      final availability = await controller.checkBiometricAvailability();
      if (!availability.isAvailable) {
        AppFeedback.showWarning(
          title: 'biometric_unavailable'.tr,
          message: availability.message ?? 'biometric_not_supported'.tr,
        );
        return;
      }

      final result = await controller.authenticateWithBiometricsDetailed(
        localizedReason: 'biometric_prompt_enable'.tr,
      );

      if (result.success) {
        await controller.setBiometricsEnabled(true);
        AppFeedback.showSuccess(
          title: 'biometric_verified'.tr,
          message: 'biometric_enabled_msg'.tr,
        );
      } else {
        if (result.failureReason != BiometricAuthFailureReason.canceled) {
          AppFeedback.showWarning(
            title: 'biometric_cannot_enable'.tr,
            message: result.errorMessage ?? 'biometric_failed'.tr,
          );
        }
      }
    } else {
      await controller.setBiometricsEnabled(false);
      AppFeedback.showInfo(
        title: 'biometric_disabled_title'.tr,
        message: 'biometric_disabled_msg'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: ModernAppBar(
        title: 'pin_security'.tr,
        subtitle: 'pin_subtitle'.tr,
        badgeWidget: Obx(() {
          final isEnabled = controller.isPinEnabled.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isEnabled ? AppColors.primary : AppColors.textSecondary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isEnabled ? AppColors.primary : AppColors.textSecondary)
                    .withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnabled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isEnabled
                      ? 'pin_status_enabled'.tr
                      : 'pin_status_disabled'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isEnabled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Master Security Hero Bento Card
                Obx(() {
                  final enabled = controller.isPinEnabled.value;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: enabled
                            ? [
                                AppColors.primary.withValues(
                                  alpha: isDark ? 0.20 : 0.12,
                                ),
                                AppColors.accent.withValues(
                                  alpha: isDark ? 0.12 : 0.05,
                                ),
                              ]
                            : [
                                (isDark
                                    ? AppColors.darkSurface
                                    : AppColors.surface),
                                (isDark
                                    ? AppColors.darkSurfaceSecondary
                                    : AppColors.surfaceSecondary),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: enabled
                            ? AppColors.primary.withValues(alpha: 0.35)
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (enabled ? AppColors.primary : Colors.black)
                              .withValues(
                                alpha: enabled ? 0.15 : (isDark ? 0.25 : 0.04),
                              ),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: enabled
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : AppColors.textSecondary.withValues(
                                    alpha: 0.12,
                                  ),
                            border: Border.all(
                              color: enabled
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.textSecondary.withValues(
                                      alpha: 0.25,
                                    ),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            enabled
                                ? Icons.verified_user_rounded
                                : Icons.lock_open_rounded,
                            color: enabled
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 30,
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
                                      enabled
                                          ? 'pin_security_active'.tr
                                          : 'pin_security_disabled'.tr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (enabled
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      enabled ? 'pin_badge_protected'.tr : 'pin_badge_open'.tr,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: enabled
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                enabled
                                    ? 'pin_active_desc'.tr
                                    : 'pin_disabled_desc'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Settings Switch Card (Bento Surface)
                Material(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  elevation: isDark ? 0 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Obx(() {
                          return SwitchListTile(
                            title: Text(
                              'lock_app_with_pin'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'lock_app_with_pin_desc'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            value: controller.isPinEnabled.value,
                            activeThumbColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              if (val) {
                                _showSetPinDialog(context);
                              } else {
                                controller.disablePin();
                              }
                            },
                          );
                        }),
                        Obx(() {
                          if (!controller.isPinEnabled.value) {
                            return const SizedBox();
                          }

                          return Column(
                            children: [
                              const Divider(height: 16),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.password_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'change_pin'.tr,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'change_pin_desc'.tr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceSecondary
                                        : AppColors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                  ),
                                ),
                                onTap: () => _showSetPinDialog(context),
                              ),
                              const Divider(height: 16),
                              Obx(() {
                                final availability = controller.biometricAvailability.value;
                                final isNotAvailable = availability != null && !availability.isAvailable;

                                return SwitchListTile(
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'biometric_unlock_title'.tr,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isNotAvailable) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.warning.withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            availability.status == BiometricAvailabilityStatus.notEnrolled
                                                ? 'biometric_not_enrolled_badge'.tr
                                                : 'biometric_not_supported_badge'.tr,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      controller.biometricStatusSubtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isNotAvailable ? AppColors.warning : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  value: controller.isBiometricsEnabled.value,
                                  activeThumbColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) =>
                                      _handleToggleBiometrics(context, val),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Vault Security Information Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.5)
                        : AppColors.surfaceSecondary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.6)
                          : AppColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'hardware_security_title'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'hardware_security_desc'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Forgot PIN FAQ & Assurance Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'forgot_pin_faq_title'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'forgot_pin_faq_desc'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
