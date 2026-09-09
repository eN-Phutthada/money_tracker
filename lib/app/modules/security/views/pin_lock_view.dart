import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/security_controller.dart';

/// หน้าจอล็อก PIN สำหรับ GetX Architecture
class PinLockView extends StatefulWidget {
  final VoidCallback? onUnlocked;
  final bool canCancel;

  const PinLockView({super.key, this.onUnlocked, this.canCancel = false});

  @override
  State<PinLockView> createState() => _PinLockViewState();
}

class _PinLockViewState extends State<PinLockView> with SingleTickerProviderStateMixin {
  final SecurityController controller = Get.find<SecurityController>();

  String _enteredPin = '';
  bool _isError = false;
  String _errorMessage = '';
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();

    if (key == '⌫') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _isError = false;
        });
      }
      return;
    }

    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += key;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verify();
      }
    }
  }

  void _verify() {
    final isValid = controller.verifyPin(_enteredPin);

    if (isValid) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked?.call();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _isError = true;
        _errorMessage = 'รหัส PIN ไม่ถูกต้อง โปรดลองใหม่';
        _enteredPin = '';
      });
    }
  }

  void _simulateBiometrics() {
    HapticFeedback.mediumImpact();
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.fingerprint_rounded, size: 56, color: AppColors.primary),
              SizedBox(height: 16),
              Text('กำลังสแกน Biometrics...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('ยืนยันตัวตนสำเร็จ', style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    Timer(const Duration(milliseconds: 800), () {
      if (Get.isDialogOpen ?? false) Get.back();
      controller.unlock();
      widget.onUnlocked?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.canCancel,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.canCancel)
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Get.back(),
                        ),
                      ),
                    const Spacer(),

                    // Shield Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Money Tracker Security',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isError ? _errorMessage : 'กรุณากรอกรหัส PIN 4 หลักเพื่อเข้าใช้งาน',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isError ? FontWeight.w700 : FontWeight.w500,
                        color: _isError ? AppColors.deficitText : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 4 Dots
                    AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final dx = _shakeController.value == 0
                            ? 0.0
                            : (1.0 - _shakeController.value) * 12.0 * (1.0 - (2.0 * ((_shakeController.value * 6) % 1)));
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFilled = index < _enteredPin.length;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled
                                      ? (_isError ? AppColors.deficitText : AppColors.primary)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isFilled
                                        ? (_isError ? AppColors.deficitText : AppColors.primary)
                                        : (isDark ? AppColors.darkBorder : AppColors.border),
                                    width: 2,
                                  ),
                                  boxShadow: isFilled
                                      ? [
                                          BoxShadow(
                                            color: (_isError ? AppColors.deficitText : AppColors.primary).withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    const Spacer(),

                    // Numpad
                    _buildNumpad(isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(bool isDark) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [
        controller.isBiometricsEnabled.value ? 'BIO' : '',
        '0',
        '⌫',
      ],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 68, height: 68);

              if (key == 'BIO') {
                return InkWell(
                  onTap: _simulateBiometrics,
                  borderRadius: BorderRadius.circular(34),
                  child: Container(
                    width: 68,
                    height: 68,
                    alignment: Alignment.center,
                    child: const Icon(Icons.fingerprint_rounded, size: 28, color: AppColors.primary),
                  ),
                );
              }

              return InkWell(
                onTap: () => _onKeyPress(key),
                borderRadius: BorderRadius.circular(34),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.7) : AppColors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: key == '⌫'
                      ? Icon(Icons.backspace_outlined, size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                      : Text(
                          key,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
