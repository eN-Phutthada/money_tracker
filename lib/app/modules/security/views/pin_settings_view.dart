import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../../data/services/security_service.dart';
import '../controllers/security_controller.dart';

/// หน้าจอตั้งค่าความปลอดภัยและรหัส PIN สไตล์ Nothing OS Design System
/// - ศูนย์ควบคุมความปลอดภัย Minimalist Monochrome
/// - การ์ดวิเคราะห์สถานะความปลอดภัย Hardware Encryption สไตล์ Nothing OS
/// - หน้าต่างตั้งรหัส PIN พร้อมหลอดไฟ LED Pips และแป้นพิมพ์ Industrial Numpad
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

          void onKey(String key) {
            if (isSuccess) return;
            HapticFeedback.lightImpact();

            setDialogState(() {
              dialogError = null;

              if (key == '⌫') {
                if (isConfirmStep) {
                  if (confirmPin.isNotEmpty) {
                    confirmPin = confirmPin.substring(0, confirmPin.length - 1);
                  }
                } else {
                  if (firstPin.isNotEmpty) {
                    firstPin = firstPin.substring(0, firstPin.length - 1);
                  }
                }
                return;
              }

              if (isConfirmStep) {
                if (confirmPin.length < 4) {
                  confirmPin += key;
                  if (confirmPin.length == 4) {
                    if (confirmPin == firstPin) {
                      isSuccess = true;
                      HapticFeedback.mediumImpact();
                      Future.delayed(const Duration(milliseconds: 300), () async {
                        await controller.setPin(firstPin);
                        Get.back();
                        AppFeedback.showSuccess(
                          title: 'pin_set_success_title'.tr,
                          message: 'pin_set_success_desc'.tr,
                        );
                      });
                    } else {
                      HapticFeedback.heavyImpact();
                      dialogError = 'pin_not_match'.tr;
                      confirmPin = '';
                    }
                  }
                }
              } else {
                if (firstPin.length < 4) {
                  firstPin += key;
                  if (firstPin.length == 4) {
                    HapticFeedback.mediumImpact();
                    Future.delayed(const Duration(milliseconds: 180), () {
                      setDialogState(() {
                        isConfirmStep = true;
                      });
                    });
                  }
                }
              }
            });
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: NothingCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            NothingLedIndicator(
                              size: 6,
                              color: isSuccess ? const Color(0xFF10B981) : AppColors.nothingRed,
                            ),
                            const SizedBox(width: 8),
                            NothingDotText(
                              isSuccess
                                  ? 'AUTHENTICATED'
                                  : (isConfirmStep ? 'CONFIRM // STEP 2' : 'NEW PIN // STEP 1'),
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      dialogError ??
                          (isConfirmStep
                              ? 'enter_same_pin_confirm'.tr
                              : 'enter_4_digits_to_set'.tr),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: dialogError != null
                            ? AppColors.nothingRed
                            : (isDark ? AppColors.nothingSubtext : const Color(0xFF777777)),
                        fontWeight: dialogError != null ? FontWeight.w700 : FontWeight.w500,
                      ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    // 4 LED Pips
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: dialogError != null
                              ? AppColors.nothingRed
                              : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (index) {
                          final isFilled = index < currentPin.length;
                          final Color pipColor = isSuccess
                              ? const Color(0xFF10B981)
                              : (dialogError != null
                                  ? AppColors.nothingRed
                                  : (isDark ? Colors.white : Colors.black));

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled ? pipColor : Colors.transparent,
                              border: Border.all(
                                color: isFilled
                                    ? pipColor
                                    : (isDark ? Colors.white38 : Colors.black26),
                                width: 1.0,
                              ),
                              boxShadow: isFilled
                                  ? [
                                      BoxShadow(
                                        color: pipColor.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mini Industrial Numpad
                    Column(
                      children: [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                        ['', '0', '⌫'],
                      ].map((row) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: row.map((key) {
                              if (key.isEmpty) {
                                return const SizedBox(width: 58, height: 46);
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Material(
                                  color: isDark ? const Color(0xFF141414) : const Color(0xFFF3F3F3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => onKey(key),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 58,
                                      height: 46,
                                      alignment: Alignment.center,
                                      child: key == '⌫'
                                          ? Icon(
                                              Icons.backspace_outlined,
                                              size: 18,
                                              color: isDark ? Colors.white : Colors.black,
                                            )
                                          : Text(
                                              key,
                                              style: GoogleFonts.shareTechMono(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : Colors.black,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF7F7F7),
      appBar: ModernAppBar(
        title: 'pin_security'.tr,
        subtitle: 'pin_subtitle'.tr,
        badgeWidget: Obx(() {
          final isEnabled = controller.isPinEnabled.value;
          return NothingPill(
            label: isEnabled ? 'SECURED' : 'OFF',
            isDotMatrix: true,
            showDot: true,
            dotColor: isEnabled ? const Color(0xFF10B981) : AppColors.nothingRed,
            color: isEnabled
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : AppColors.nothingRed.withValues(alpha: 0.12),
            textColor: isEnabled ? const Color(0xFF10B981) : AppColors.nothingRed,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            fontSize: 10,
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
                // 1. Master Security Hero NothingCard
                Obx(() {
                  final enabled = controller.isPinEnabled.value;

                  return NothingCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
                            border: Border.all(
                              color: enabled
                                  ? const Color(0xFF10B981)
                                  : (isDark ? AppColors.nothingBorder : Colors.black12),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            enabled ? Icons.verified_user_rounded : Icons.lock_open_rounded,
                            color: enabled
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white70 : Colors.black54),
                            size: 26,
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
                                      (enabled
                                              ? 'pin_security_active'.tr
                                              : 'pin_security_disabled'.tr)
                                          .toUpperCase(),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: isDark ? Colors.white : Colors.black,
                                      ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  NothingLedIndicator(
                                    size: 6,
                                    color: enabled ? const Color(0xFF10B981) : AppColors.nothingRed,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                enabled ? 'pin_active_desc'.tr : 'pin_disabled_desc'.tr,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11.5,
                                  color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // 2. Settings Group (NothingCard)
                NothingCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Obx(() {
                        return SwitchListTile(
                          title: Text(
                            'lock_app_with_pin'.tr,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                          ),
                          subtitle: Text(
                            'lock_app_with_pin_desc'.tr,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                            ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                          ),
                          value: controller.isPinEnabled.value,
                          activeThumbColor: AppColors.nothingRed,
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
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: [
                            Divider(
                              height: 16,
                              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? AppColors.nothingBorder : Colors.black12,
                                    width: 0.8,
                                  ),
                                ),
                                child: Icon(
                                  Icons.password_rounded,
                                  color: isDark ? Colors.white : Colors.black,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                'change_pin'.tr,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                              ),
                              subtitle: Text(
                                'change_pin_desc'.tr,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: isDark ? AppColors.nothingSubtext : Colors.black45,
                              ),
                              onTap: () => _showSetPinDialog(context),
                            ),
                            Divider(
                              height: 16,
                              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                            ),
                            Obx(() {
                              final availability = controller.biometricAvailability.value;
                              final isNotAvailable = availability != null && !availability.isAvailable;

                              return SwitchListTile(
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'biometric_unlock_title'.tr,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : Colors.black,
                                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isNotAvailable) ...[
                                      const SizedBox(width: 8),
                                      NothingPill(
                                        label: availability.status == BiometricAvailabilityStatus.notEnrolled
                                            ? 'biometric_not_enrolled_badge'.tr
                                            : 'biometric_not_supported_badge'.tr,
                                        color: AppColors.nothingRed,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        fontSize: 9,
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    controller.biometricStatusSubtitle,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      color: isNotAvailable ? AppColors.nothingRed : (isDark ? AppColors.nothingSubtext : const Color(0xFF777777)),
                                    ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                                  ),
                                ),
                                value: controller.isBiometricsEnabled.value,
                                activeThumbColor: AppColors.nothingRed,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => _handleToggleBiometrics(context, val),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Vault Security Information Card
                NothingCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'hardware_security_title'.tr.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark ? Colors.white : Colors.black,
                              ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'hardware_security_desc'.tr,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                                height: 1.4,
                              ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Forgot PIN FAQ & Assurance Card
                NothingCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const NothingLedIndicator(size: 6, color: AppColors.nothingRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'forgot_pin_faq_title'.tr.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark ? Colors.white : Colors.black,
                              ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'forgot_pin_faq_desc'.tr,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                                height: 1.4,
                              ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
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
