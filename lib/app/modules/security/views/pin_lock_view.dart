import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
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
  bool _isSuccess = false;
  bool _isExiting = false;
  String _errorMessage = '';
  late AnimationController _shakeController;
  final FocusNode _keyboardFocusNode = FocusNode();

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
    _keyboardFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleHardwareKeyEvent(KeyEvent event) {
    if (_isSuccess || _isExiting) return;
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
        _onKeyPress('⌫');
      } else if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
        _onKeyPress('0');
      } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
        _onKeyPress('1');
      } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
        _onKeyPress('2');
      } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
        _onKeyPress('3');
      } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
        _onKeyPress('4');
      } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
        _onKeyPress('5');
      } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
        _onKeyPress('6');
      } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
        _onKeyPress('7');
      } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
        _onKeyPress('8');
      } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
        _onKeyPress('9');
      }
    }
  }

  void _onKeyPress(String key) {
    if (_isSuccess || _isExiting) return;
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

  void _verify() async {
    final isValid = controller.verifyPin(_enteredPin, autoUnlock: false);

    if (isValid) {
      setState(() {
        _isSuccess = true;
        _isError = false;
      });
      HapticFeedback.mediumImpact();

      // Show the animated success state (glowing open lock & bouncing green dots)
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      setState(() {
        _isExiting = true;
      });

      // Smooth exit transition into the dashboard
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      controller.unlock();
      widget.onUnlocked?.call();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _isError = true;
        _errorMessage = 'pin_incorrect'.tr;
        _enteredPin = '';
      });
    }
  }

  void _simulateBiometrics() {
    HapticFeedback.mediumImpact();
    Get.dialog(
      AppGlassDialog(
        maxWidth: 320,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.fingerprint_rounded, size: 48, color: AppColors.primary),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 20),
            Text(
              'scanning_biometrics'.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'biometric_verified'.tr,
              style: const TextStyle(fontSize: 12, color: AppColors.surplusText, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    Timer(const Duration(milliseconds: 900), () async {
      if (Get.isDialogOpen ?? false) Get.back();
      setState(() {
        _isSuccess = true;
        _enteredPin = '••••';
      });
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _isExiting = true;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      controller.unlock();
      widget.onUnlocked?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.canCancel,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleHardwareKeyEvent,
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          body: SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _isExiting ? 0.0 : 1.0,
              curve: Curves.easeInOut,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: _isExiting ? 1.05 : 1.0,
                curve: Curves.easeInOut,
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

                          // Shield / Unlocked Success Icon Badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutBack,
                            width: _isSuccess ? 72 : 64,
                            height: _isSuccess ? 72 : 64,
                            decoration: BoxDecoration(
                              color: _isSuccess
                                  ? const Color(0xFF10B981).withValues(alpha: 0.16)
                                  : AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isSuccess
                                    ? const Color(0xFF10B981).withValues(alpha: 0.45)
                                    : AppColors.primary.withValues(alpha: 0.25),
                                width: _isSuccess ? 2.5 : 1.5,
                              ),
                              boxShadow: _isSuccess
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                _isSuccess ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                key: ValueKey(_isSuccess),
                                color: _isSuccess ? const Color(0xFF10B981) : AppColors.primary,
                                size: _isSuccess ? 36 : 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _isSuccess
                                ? Column(
                                    key: const ValueKey('success_state'),
                                    children: [
                                      Text(
                                        'pin_success'.tr,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'pin_welcome'.tr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey('normal_state'),
                                    children: [
                                      const Text(
                                        'Money Tracker Security',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _isError ? _errorMessage : 'enter_pin'.tr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _isError ? FontWeight.w700 : FontWeight.w500,
                                          color: _isError ? AppColors.deficitText : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 28),

                          // 4 Dots with staggered scale bounce animation on success
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
                                    final color = _isSuccess
                                        ? const Color(0xFF10B981)
                                        : (_isError ? AppColors.deficitText : AppColors.primary);

                                    Widget dot = AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 10),
                                      width: _isSuccess ? 18 : 16,
                                      height: _isSuccess ? 18 : 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isFilled ? color : Colors.transparent,
                                        border: Border.all(
                                          color: isFilled
                                              ? color
                                              : (isDark ? AppColors.darkBorder : AppColors.border),
                                          width: 2,
                                        ),
                                        boxShadow: isFilled
                                            ? [
                                                BoxShadow(
                                                  color: color.withValues(alpha: _isSuccess ? 0.6 : 0.4),
                                                  blurRadius: _isSuccess ? 12 : 8,
                                                  spreadRadius: _isSuccess ? 3 : 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    );

                                    if (_isSuccess) {
                                      dot = dot
                                          .animate(delay: Duration(milliseconds: index * 60))
                                          .scale(
                                            begin: const Offset(0.8, 0.8),
                                            end: const Offset(1.25, 1.25),
                                            duration: const Duration(milliseconds: 220),
                                            curve: Curves.easeOutBack,
                                          )
                                          .then()
                                          .scale(
                                            begin: const Offset(1.25, 1.25),
                                            end: const Offset(1.0, 1.0),
                                            duration: const Duration(milliseconds: 180),
                                          );
                                    }
                                    return dot;
                                  }),
                                ),
                              );
                            },
                          ),
                          const Spacer(),

                          // Numpad
                          AnimatedOpacity(
                            opacity: _isSuccess ? 0.35 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            child: _buildNumpad(isDark),
                          ),
                          const SizedBox(height: 20),
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
