import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/modern_app_bar.dart';
import '../controllers/security_controller.dart';

/// หน้าจอตั้งค่าความปลอดภัยและรหัส PIN ด้วย GetX
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
                      ? 'ตั้งรหัส PIN สำเร็จ!'
                      : (isConfirmStep ? 'ยืนยันรหัส PIN 4 หลัก' : 'ตั้งรหัส PIN 4 หลักใหม่'),
                  subtitle: isSuccess
                      ? 'บันทึกรหัส PIN ใหม่เรียบร้อยแล้ว'
                      : (dialogError ?? (isConfirmStep ? 'กรอกรหัสเดิมอีกครั้งเพื่อยืนยัน' : 'กรอกตัวเลข 4 หลักเพื่อตั้งรหัสผ่าน')),
                  icon: isSuccess
                      ? Icons.check_circle_rounded
                      : (isConfirmStep ? Icons.verified_user_rounded : Icons.lock_rounded),
                  iconColor: isSuccess
                      ? const Color(0xFF10B981)
                      : (dialogError != null ? AppColors.deficitText : AppColors.primary),
                  onClose: () => Get.back(),
                ),
                const SizedBox(height: 24),

                // 4 Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < currentPin.length;
                    final dotColor = isSuccess
                        ? const Color(0xFF10B981)
                        : (dialogError != null ? AppColors.deficitText : AppColors.primary);

                    Widget dot = Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: isSuccess ? 16 : 14,
                      height: isSuccess ? 16 : 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? dotColor : Colors.transparent,
                        border: Border.all(
                          color: isFilled ? dotColor : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: 2,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: dotColor.withValues(alpha: isSuccess ? 0.6 : 0.35),
                                  blurRadius: isSuccess ? 12 : 8,
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
                const SizedBox(height: 24),

                // Mini Numpad
                ..._buildMiniNumpad(
                  isDark: isDark,
                  onKey: (k) async {
                    if (isSuccess) return;
                    setDialogState(() {
                      dialogError = null;
                      if (k == '⌫') {
                        if (isConfirmStep) {
                          if (confirmPin.isNotEmpty) confirmPin = confirmPin.substring(0, confirmPin.length - 1);
                        } else {
                          if (firstPin.isNotEmpty) firstPin = firstPin.substring(0, firstPin.length - 1);
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
                            Future.delayed(const Duration(milliseconds: 400), () async {
                              await controller.setPin(firstPin);
                              if (Get.isDialogOpen ?? false) Get.back();
                              Get.snackbar(
                                'สำเร็จ',
                                'ตั้งค่ารหัส PIN เรียบร้อยแล้ว',
                                snackPosition: SnackPosition.TOP,
                              );
                            });
                          } else {
                            dialogError = 'รหัสไม่ตรงกัน โปรดลองใหม่อีกครั้ง';
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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

  List<Widget> _buildMiniNumpad({required bool isDark, required Function(String) onKey}) {
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
            if (key.isEmpty) return const SizedBox(width: 52, height: 44);

            return InkWell(
              onTap: () => onKey(key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 52,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: key == '⌫'
                    ? const Icon(Icons.backspace_outlined, size: 18)
                    : Text(key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'pin_security'.tr,
        subtitle: 'pin_subtitle'.tr,
        badgeWidget: Obx(() {
          final isEnabled = controller.isPinEnabled.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: (isEnabled ? AppColors.accent : AppColors.textSecondary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isEnabled ? AppColors.accent : AppColors.textSecondary).withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
            child: Text(
              isEnabled ? 'pin_status_enabled'.tr : 'pin_status_disabled'.tr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isEnabled ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          );
        }),
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
                  final enabled = controller.isPinEnabled.value;

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
                            color: enabled
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.textSecondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                            color: enabled ? AppColors.primary : AppColors.textSecondary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enabled ? 'PIN Security Active' : 'PIN Security Disabled',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                enabled
                                    ? 'แอปจะขอยืนยันรหัส PIN ทุกครั้งที่เปิดใช้งาน'
                                    : 'เข้าใช้งานได้โดยตรงโดยไม่ต้องกรอกรหัสผ่าน',
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

                // Settings Switch Card
                Material(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                    children: [
                      Obx(() {
                        return SwitchListTile(
                          title: const Text(
                            'ล็อกแอปด้วยรหัส PIN (PIN Lock)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'ต้องกรอกรหัส 4 หลักเพื่อเปิดแอป',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                        if (!controller.isPinEnabled.value) return const SizedBox();

                        return Column(
                          children: [
                            const Divider(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.password_rounded, color: AppColors.primary),
                              title: const Text(
                                'เปลี่ยนรหัสผ่าน PIN (Change PIN)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              onTap: () => _showSetPinDialog(context),
                            ),
                            const Divider(height: 16),
                            SwitchListTile(
                              title: const Text(
                                'ยืนยันตัวตนด้วย Biometrics (Face / Touch ID)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              subtitle: const Text(
                                'ปลดล็อกอย่างรวดเร็วด้วยการสแกนลายนิ้วมือหรือใบหน้า',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              value: controller.isBiometricsEnabled.value,
                              activeThumbColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => controller.setBiometricsEnabled(val),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
