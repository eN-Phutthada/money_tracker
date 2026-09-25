import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../../data/services/security_service.dart';
import '../controllers/security_controller.dart';

enum _RecoveryMode { none, options, confirmReset }

/// หน้าจอล็อก PIN สไตล์ Nothing OS Design System
/// - สุนทรียภาพ Pitch Black Minimalist คมชัดระดับ Hi-Contrast
/// - แป้นพิมพ์ตัวเลข Industrial Numpad ทรงกลม/Squircle ขอบ Hairline 0.8px
/// - หลอดไฟ LED Pips 4 ดวงพร้อมระบบสั่นสะเทือนเตือนความผิดพลาด (Shake & Nothing Red)
/// - แอนิเมชันปลดล็อกสุดพรีเมียม (LED Wave Pulse, Halo Glow & Vault Spring Transition)
/// - ระบบกู้คืนรหัสผ่าน (Forgot PIN Recovery) พร้อมการนับถอยหลังเพื่อความปลอดภัย
/// - รองรับการปลดล็อกด้วยสแกนลายนิ้วมือ/ใบหน้า (Biometrics) และแป้นพิมพ์ฮาร์ดแวร์
class PinLockView extends StatefulWidget {
  final VoidCallback? onUnlocked;
  final bool canCancel;

  const PinLockView({super.key, this.onUnlocked, this.canCancel = false});

  @override
  State<PinLockView> createState() => _PinLockViewState();
}

class _PinLockViewState extends State<PinLockView> with TickerProviderStateMixin {
  final SecurityController controller = Get.find<SecurityController>();

  String _enteredPin = '';
  bool _isError = false;
  bool _isSuccess = false;
  bool _isExiting = false;
  int _failCount = 0;
  String _errorMessage = '';
  late AnimationController _shakeController;
  late AnimationController _unlockAnimationController;
  final FocusNode _keyboardFocusNode = FocusNode();

  // In-stack recovery and scanning overlay states
  _RecoveryMode _recoveryMode = _RecoveryMode.none;
  bool _isBiometricScanning = false;
  int _resetCountdown = 4;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _unlockAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
        Platform.environment.containsKey('FLUTTER_TEST');

    // Auto-prompt real biometrics on launch after window gains focus
    if (!isTest && controller.isBiometricsEnabled.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted && !_isSuccess && !_isExiting) {
            _authenticateWithBiometrics();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _keyboardFocusNode.dispose();
    _shakeController.dispose();
    _unlockAnimationController.dispose();
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
      _failCount = 0;
      setState(() {
        _isSuccess = true;
        _isError = false;
      });
      HapticFeedback.mediumImpact();
      _unlockAnimationController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() {
        _isExiting = true;
      });
      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      controller.unlock();
      widget.onUnlocked?.call();
    } else {
      _failCount++;
      setState(() {
        _isError = true;
        _errorMessage = 'pin_wrong'.tr;
      });
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _enteredPin = '';
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isBiometricScanning || _isSuccess || _isExiting) return;
    setState(() {
      _isBiometricScanning = true;
    });

    try {
      final result = await controller.authenticateWithBiometricsDetailed(
        localizedReason: 'biometric_prompt_unlock'.tr,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _isSuccess = true;
          _isError = false;
          _errorMessage = '';
          _enteredPin = '••••';
        });
        HapticFeedback.mediumImpact();
        _unlockAnimationController.forward(from: 0.0);
        await Future.delayed(const Duration(milliseconds: 300));
        HapticFeedback.lightImpact();
        if (!mounted) return;
        setState(() {
          _isExiting = true;
        });
        await Future.delayed(const Duration(milliseconds: 220));
        if (!mounted) return;
        controller.unlock();
        widget.onUnlocked?.call();
      } else {
        if (result.failureReason != BiometricAuthFailureReason.canceled) {
          setState(() {
            _isError = true;
            _errorMessage = result.errorMessage ?? 'biometric_failed'.tr;
          });
          HapticFeedback.heavyImpact();
          _shakeController.forward(from: 0.0);
          if (result.failureReason != null) {
            AppFeedback.showWarning(
              title: 'biometric_auth_failed_title'.tr,
              message: result.errorMessage ?? 'biometric_failed'.tr,
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricScanning = false;
        });
      }
    }
  }

  void _showForgotPinDialog() {
    HapticFeedback.mediumImpact();
    setState(() {
      _recoveryMode = _RecoveryMode.options;
    });
  }

  void _startConfirmResetPin() {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    setState(() {
      _resetCountdown = 4;
      _recoveryMode = _RecoveryMode.confirmReset;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resetCountdown > 0) {
        setState(() {
          _resetCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _closeRecovery() {
    _countdownTimer?.cancel();
    setState(() {
      _recoveryMode = _RecoveryMode.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.canCancel && _recoveryMode == _RecoveryMode.none && !_isBiometricScanning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _recoveryMode != _RecoveryMode.none) {
          _closeRecovery();
        }
      },
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleHardwareKeyEvent,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF7F7F7),
          body: Stack(
            children: [
              SafeArea(
                child: AnimatedScale(
                  scale: _isExiting ? 0.93 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOutCubic,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isExiting ? 0.0 : 1.0,
                    curve: Curves.easeOut,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            final isCompact = availableHeight < 680;

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: availableHeight),
                                child: IntrinsicHeight(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: isCompact ? 12 : 20,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (widget.canCancel)
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.close_rounded,
                                                color: isDark ? Colors.white : Colors.black,
                                              ),
                                              onPressed: () => Get.back(),
                                            ),
                                          ),
                                        const Spacer(),

                                        // 1. Nothing OS Security Crest & Header
                                        _buildHeaderSection(isDark),
                                        SizedBox(height: isCompact ? 16 : 24),

                                        // 2. 4 Nothing OS LED Pip Indicators
                                        _buildLedPips(isDark),
                                        SizedBox(height: isCompact ? 20 : 32),

                                        // 3. Nothing Industrial 3x4 Numpad
                                        _buildNumpadGrid(isDark, isCompact),

                                        // 4. Forgot PIN Recovery Link
                                        const SizedBox(height: 16),
                                        _buildForgotPinButton(isDark),
                                        const Spacer(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Recovery Dialog Sheet Overlay
              if (_recoveryMode != _RecoveryMode.none)
                _buildRecoveryOverlay(isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// 4. Forgot PIN Button (Always accessible, highlighted when failed)
  Widget _buildForgotPinButton(bool isDark) {
    final bool hasFailed = _failCount >= 1;
    return TextButton.icon(
      onPressed: _showForgotPinDialog,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hasFailed
              ? BorderSide(color: AppColors.nothingRed.withValues(alpha: 0.35), width: 0.8)
              : BorderSide.none,
        ),
        backgroundColor: hasFailed
            ? AppColors.nothingRed.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      icon: Icon(
        Icons.help_outline_rounded,
        size: 14,
        color: hasFailed
            ? AppColors.nothingRed
            : (isDark ? AppColors.nothingSubtext : const Color(0xFF888888)),
      ),
      label: Text(
        'forgot_pin_title'.tr.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: hasFailed
              ? AppColors.nothingRed
              : (isDark ? AppColors.nothingSubtext : const Color(0xFF888888)),
        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
      ),
    );
  }

  /// 1. Header Section สไตล์ Nothing OS
  Widget _buildHeaderSection(bool isDark) {
    return Column(
      children: [
        // Squircle Icon Badge with LED Status Dot & Spring Animation
        AnimatedBuilder(
          animation: _unlockAnimationController,
          builder: (context, child) {
            final double scale = _isSuccess
                ? 1.0 + 0.16 * math.sin(_unlockAnimationController.value * math.pi)
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSuccess
                    ? const Color(0xFF10B981)
                    : (_isError
                        ? AppColors.nothingRed
                        : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.10))),
                width: 0.8,
              ),
              boxShadow: _isSuccess
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    _isSuccess
                        ? Icons.lock_open_rounded
                        : (_isError ? Icons.lock_rounded : Icons.shield_outlined),
                    key: ValueKey<String>(
                      _isSuccess ? 'success' : (_isError ? 'error' : 'shield'),
                    ),
                    size: 26,
                    color: _isSuccess
                        ? const Color(0xFF10B981)
                        : (_isError
                            ? AppColors.nothingRed
                            : (isDark ? Colors.white : Colors.black)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: NothingLedIndicator(
                    size: 5,
                    color: _isSuccess ? const Color(0xFF10B981) : AppColors.nothingRed,
                    isPulsing: _isSuccess || _isError,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // All-Caps Tracking Title
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            (_isSuccess
                    ? 'pin_access_granted'.tr
                    : (_isError ? _errorMessage : 'SECURITY // PIN REQUIRED'))
                .toUpperCase(),
            key: ValueKey<String>(
              _isSuccess
                  ? 'access_granted'
                  : (_isError ? 'error_$_errorMessage' : 'required'),
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: _isSuccess
                  ? const Color(0xFF10B981)
                  : (_isError ? AppColors.nothingRed : (isDark ? Colors.white : Colors.black)),
            ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'MONEY TRACKER VAULT',
          style: GoogleFonts.shareTechMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: isDark ? AppColors.nothingSubtext : const Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  /// 2. 4 Nothing OS LED Pip Indicators
  Widget _buildLedPips(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _unlockAnimationController]),
      builder: (context, child) {
        final dx = _shakeController.value == 0
            ? 0.0
            : (1.0 - _shakeController.value) *
                12.0 *
                (1.0 - (2.0 * ((_shakeController.value * 6) % 1)));

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isSuccess
                    ? const Color(0xFF10B981)
                    : (_isError
                        ? AppColors.nothingRed
                        : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08))),
                width: 0.8,
              ),
              boxShadow: _isSuccess
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                final Color pipColor = _isSuccess
                    ? const Color(0xFF10B981)
                    : (_isError
                        ? AppColors.nothingRed
                        : (isDark ? Colors.white : Colors.black));

                // Staggered wave scale on success
                double scale = 1.0;
                if (_isSuccess && _unlockAnimationController.isAnimating) {
                  final double progress = (_unlockAnimationController.value * 1.5 - index * 0.18).clamp(0.0, 1.0);
                  scale = 1.0 + 0.35 * math.sin(progress * math.pi);
                }

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? pipColor : Colors.transparent,
                      border: Border.all(
                        color: isFilled
                            ? pipColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.25)),
                        width: 1.2,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: pipColor.withValues(alpha: _isSuccess ? 0.65 : 0.45),
                                blurRadius: _isSuccess ? 8 : 6,
                                spreadRadius: _isSuccess ? 1.5 : 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  /// 3. Nothing Industrial 3x4 Numpad
  Widget _buildNumpadGrid(bool isDark, bool isCompact) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['bio', '0', '⌫'],
    ];

    final double keySize = isCompact ? 64 : 70;

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? 5 : 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildNumpadKey(key, keySize, isDark),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumpadKey(String key, double size, bool isDark) {
    if (key == 'bio') {
      return Obx(() {
        if (!controller.isBiometricsEnabled.value) {
          return SizedBox(width: size, height: size);
        }
        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _authenticateWithBiometrics();
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF141414) : const Color(0xFFEEEEEE),
                border: Border.all(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.fingerprint_rounded,
                size: 26,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      });
    }

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _onKeyPress(key),
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF141414) : const Color(0xFFEEEEEE),
            border: Border.all(
              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: key == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                )
              : Text(
                  key,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
        ),
      ),
    );
  }

  /// 4. Recovery Overlay Modal with Smooth Spring & Fade Animations
  Widget _buildRecoveryOverlay(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.72 * animValue),
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: 0.92 + (0.08 * animValue),
            child: Opacity(
              opacity: animValue.clamp(0.0, 1.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: NothingCard(
                  padding: const EdgeInsets.all(22),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _recoveryMode == _RecoveryMode.options
                        ? _buildRecoveryOptionsContent(isDark)
                        : _buildRecoveryConfirmResetContent(isDark),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecoveryOptionsContent(bool isDark) {
    return Column(
      key: const ValueKey('recovery_options'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  'forgot_pin_title'.tr.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white : Colors.black,
                  ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: _closeRecovery,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'forgot_pin_desc'.tr,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            height: 1.45,
            color: isDark ? AppColors.nothingSubtext : const Color(0xFF666666),
          ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
        ),
        const SizedBox(height: 22),
        if (controller.isBiometricsEnabled.value) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black,
                side: BorderSide(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.15),
                  width: 0.8,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.fingerprint_rounded, size: 20),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'recovery_biometric_title'.tr,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                ),
              ),
              onPressed: () {
                _closeRecovery();
                _authenticateWithBiometrics();
              },
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.nothingRed,
              side: BorderSide(
                color: AppColors.nothingRed.withValues(alpha: 0.35),
                width: 0.8,
              ),
              backgroundColor: AppColors.nothingRed.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 20, color: AppColors.nothingRed),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'recovery_reset_title'.tr,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nothingRed,
                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
              ),
            ),
            onPressed: _startConfirmResetPin,
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryConfirmResetContent(bool isDark) {
    return Column(
      key: const ValueKey('recovery_confirm_reset'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.nothingRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.nothingRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'recovery_confirm_reset'.tr.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.nothingRed,
                    ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'recovery_confirm_reset_subtitle'.tr,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                    ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161616) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Text(
            'recovery_warning'.tr,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.black87,
            ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _closeRecovery,
              child: Text(
                'cancel'.tr,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _resetCountdown > 0
                    ? (isDark ? const Color(0xFF262626) : const Color(0xFFDDDDDD))
                    : AppColors.nothingRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _resetCountdown > 0
                  ? null
                  : () async {
                      _countdownTimer?.cancel();
                      HapticFeedback.heavyImpact();
                      await controller.disablePin();
                      controller.unlock();
                      _closeRecovery();
                      AppFeedback.showSuccess(
                        title: 'recovery_reset_success_title'.tr,
                        message: 'recovery_reset_success'.tr,
                      );
                      widget.onUnlocked?.call();
                    },
              child: Text(
                _resetCountdown > 0
                    ? 'recovery_countdown_wait'.trParams({'seconds': '$_resetCountdown'})
                    : 'confirm'.tr,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _resetCountdown > 0
                      ? (isDark ? Colors.white38 : Colors.black38)
                      : Colors.white,
                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
