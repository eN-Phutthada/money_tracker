import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/security_controller.dart';

/// หน้าจอตั้งค่าความปลอดภัยและรหัส PIN ด้วย GetX
class PinSettingsView extends GetView<SecurityController> {
  const PinSettingsView({super.key});

  void _showSetPinDialog(BuildContext context) {
    String firstPin = '';
    String confirmPin = '';
    bool isConfirmStep = false;
    String? dialogError;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final currentPin = isConfirmStep ? confirmPin : firstPin;

          return Dialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isConfirmStep ? 'ยืนยันรหัส PIN 4 หลัก' : 'ตั้งรหัส PIN 4 หลักใหม่',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dialogError ?? (isConfirmStep ? 'กรอกรหัสเดิมอีกครั้งเพื่อยืนยัน' : 'กรอกตัวเลข 4 หลักเพื่อตั้งรหัสผ่าน'),
                    style: TextStyle(
                      fontSize: 12,
                      color: dialogError != null ? AppColors.deficitText : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4 Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < currentPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Mini Numpad
                  ..._buildMiniNumpad(
                    isDark: isDark,
                    onKey: (k) async {
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
                              controller.setPin(firstPin);
                              Get.back();
                              Get.snackbar(
                                'สำเร็จ',
                                'ตั้งค่ารหัส PIN เรียบร้อยแล้ว',
                                snackPosition: SnackPosition.TOP,
                              );
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
                    child: const Text('ยกเลิก'),
                  ),
                ],
              ),
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
      appBar: AppBar(
        title: const Text('ความปลอดภัยและรหัส PIN'),
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
