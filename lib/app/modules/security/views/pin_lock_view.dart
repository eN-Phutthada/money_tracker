import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../data/services/security_service.dart';
import '../controllers/security_controller.dart';

enum _RecoveryMode { none, options, confirmReset }

/// หน้าจอล็อก PIN สำหรับ GetX Architecture (FinTech 2026 Vault Edition)
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
  int _failCount = 0;
  String _errorMessage = '';
  late AnimationController _shakeController;
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

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
        Platform.environment.containsKey('FLUTTER_TEST');

    // Auto-prompt real biometrics on launch if enabled
    if (!isTest && controller.isBiometricsEnabled.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _authenticateWithBiometrics();
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
      _failCount = 0;
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
      _failCount++;
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _isError = true;
        _errorMessage = 'pin_incorrect'.tr;
        _enteredPin = '';
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isBiometricScanning || _isSuccess || _isExiting) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isBiometricScanning = true;
      _recoveryMode = _RecoveryMode.none;
    });

    final result = await controller.authenticateWithBiometricsDetailed(
      localizedReason: 'biometric_reason'.tr,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isBiometricScanning = false;
        _isSuccess = true;
        _isError = false;
        _errorMessage = '';
        _enteredPin = '••••';
      });
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        _isExiting = true;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      controller.unlock();
      widget.onUnlocked?.call();
    } else {
      setState(() {
        _isBiometricScanning = false;
        if (result.failureReason != BiometricAuthFailureReason.canceled) {
          _isError = true;
          _errorMessage = result.errorMessage ?? 'biometric_failed'.tr;
          HapticFeedback.heavyImpact();
          _shakeController.forward(from: 0.0);
        }
      });
      if (result.failureReason != BiometricAuthFailureReason.canceled &&
          result.failureReason != null) {
        AppFeedback.showWarning(
          title: 'ชีวมิติไม่สำเร็จ',
          message: result.errorMessage ?? 'biometric_failed'.tr,
        );
      }
    }
  }

  /// แสดงตัวเลือกกู้คืนการเข้าใช้งานเมื่อลืมรหัส PIN (แสดงทับบนหน้าจอล็อกโดยตรง)
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

  Widget _buildBiometricsOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.45),
        alignment: Alignment.center,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
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
                  blur: const LiquidGlassBlur(sigmaX: 18, sigmaY: 18),
                ),
                refraction: const LiquidGlassRefraction(
                  distortion: 0.08,
                  distortionWidth: 26,
                  chromaticAberration: 0.002,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                        ? Colors.white.withValues(alpha: 0.16)
                        : AppColors.border.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.fingerprint_rounded, size: 44, color: AppColors.primary),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.08, 1.08),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 20),
                    Text(
                      'scanning_biometrics'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        shadows: [
                          Shadow(
                            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.45),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'biometric_verified'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.surplusText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryModal(bool isDark) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Dim backdrop dismissible only in options mode
          Positioned.fill(
            child: GestureDetector(
              onTap: _recoveryMode == _RecoveryMode.options ? _closeRecovery : null,
              child: Container(
                color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.45),
              ),
            ),
          ),

          // Centered Glass Modal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                        blurRadius: 36,
                        spreadRadius: -4,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: LiquidGlassLens(
                    style: LiquidGlassStyle(
                      shape: const LiquidGlassShape.squircle(
                        cornerRadius: 26,
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
                        blur: const LiquidGlassBlur(sigmaX: 18, sigmaY: 18),
                      ),
                      refraction: const LiquidGlassRefraction(
                        distortion: 0.08,
                        distortionWidth: 28,
                        chromaticAberration: 0.002,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
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
                              ? Colors.white.withValues(alpha: 0.16)
                              : AppColors.border.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _recoveryMode == _RecoveryMode.options
                            ? _buildRecoveryOptionsCard(isDark)
                            : _buildRecoveryConfirmCard(isDark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 200));
  }

  Widget _buildRecoveryOptionsCard(bool isDark) {
    return Column(
      key: const ValueKey('recovery_options'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPopupHeader(
          title: 'forgot_pin_title'.tr,
          subtitle: 'forgot_pin_desc'.tr,
          icon: Icons.lock_reset_rounded,
          iconColor: AppColors.primary,
          onClose: _closeRecovery,
        ),
        const SizedBox(height: 20),

        // Recovery Option 1: Biometrics (if enabled)
        if (controller.isBiometricsEnabled.value) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _closeRecovery();
                _authenticateWithBiometrics();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'recovery_biometric_title'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'recovery_biometric_desc'.tr,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Recovery Option 2: Safety PIN Reset (Zero Data Loss)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _startConfirmResetPin,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6)
                    : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'recovery_reset_title'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'recovery_reset_desc'.tr,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryConfirmCard(bool isDark) {
    return Column(
      key: const ValueKey('recovery_confirm'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPopupHeader(
          title: 'recovery_confirm_reset'.tr,
          subtitle: 'ปลดล็อกและตั้งค่าความปลอดภัยใหม่',
          icon: Icons.lock_open_rounded,
          iconColor: const Color(0xFF10B981),
          onClose: _closeRecovery,
        ),
        const SizedBox(height: 18),

        // Safe Guarantee Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'recovery_warning'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _closeRecovery,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Text(
                  'cancel'.tr,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _resetCountdown > 0
                    ? null
                    : () async {
                        _countdownTimer?.cancel();
                        HapticFeedback.heavyImpact();
                        await controller.disablePin();
                        controller.unlock();
                        _closeRecovery();
                        widget.onUnlocked?.call();

                        AppFeedback.showSuccess(
                          title: 'recovery_reset_success_title'.tr,
                          message: 'recovery_reset_success'.tr,
                          duration: const Duration(seconds: 4),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.surfaceSecondary,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _resetCountdown > 0
                      ? 'recovery_countdown_wait'.trParams({'seconds': '$_resetCountdown'})
                      : 'recovery_confirm_reset'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          body: Stack(
            children: [
              // Ambient Vault Glow Orb behind the crest (expands and illuminates on success)
              Positioned(
                top: _isSuccess ? -80 : -60,
                left: MediaQuery.of(context).size.width / 2 - (_isSuccess ? 200 : 140),
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: _isSuccess ? 400 : 280,
                    height: _isSuccess ? 400 : 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (_isSuccess
                                  ? const Color(0xFF10B981)
                                  : (_isError ? AppColors.deficitText : AppColors.primary))
                              .withValues(alpha: _isSuccess ? (isDark ? 0.30 : 0.22) : (isDark ? 0.16 : 0.08)),
                          (_isSuccess
                                  ? const Color(0xFF059669).withValues(alpha: isDark ? 0.12 : 0.08)
                                  : Colors.transparent),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

                              // Shield / Unlocked Success Icon Crest Badge
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeOutBack,
                                width: _isSuccess ? 68 : 60,
                                height: _isSuccess ? 68 : 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _isSuccess
                                        ? [
                                            const Color(0xFF10B981),
                                            const Color(0xFF059669),
                                          ]
                                        : [
                                            AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.14),
                                            AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.06),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: _isSuccess
                                        ? Colors.white.withValues(alpha: 0.45)
                                        : AppColors.primary.withValues(alpha: 0.35),
                                    width: _isSuccess ? 2.2 : 1.5,
                                  ),
                                  boxShadow: [
                                    if (_isSuccess)
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                        blurRadius: 28,
                                        spreadRadius: 6,
                                      ),
                                    BoxShadow(
                                      color: (_isSuccess ? const Color(0xFF10B981) : AppColors.primary)
                                          .withValues(alpha: _isSuccess ? 0.50 : 0.18),
                                      blurRadius: _isSuccess ? 20 : 12,
                                      offset: _isSuccess ? const Offset(0, 3) : Offset.zero,
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  transitionBuilder: (child, anim) => ScaleTransition(
                                    scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                                    child: child,
                                  ),
                                  child: Icon(
                                    _isSuccess ? Icons.check_rounded : Icons.lock_outline_rounded,
                                    key: ValueKey(_isSuccess),
                                    color: _isSuccess ? Colors.white : AppColors.primary,
                                    size: _isSuccess ? 34 : 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Security Vault Tag Pill
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: EdgeInsets.symmetric(
                                  horizontal: _isSuccess ? 10 : 8,
                                  vertical: _isSuccess ? 3.5 : 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (_isSuccess ? const Color(0xFF10B981) : AppColors.primary)
                                      .withValues(alpha: _isSuccess ? 0.15 : 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (_isSuccess ? const Color(0xFF10B981) : AppColors.primary)
                                        .withValues(alpha: _isSuccess ? 0.45 : 0.25),
                                    width: _isSuccess ? 1.0 : 0.8,
                                  ),
                                  boxShadow: _isSuccess
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.22),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: _isSuccess ? 5 : 4,
                                      height: _isSuccess ? 5 : 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isSuccess ? const Color(0xFF10B981) : AppColors.primary,
                                        boxShadow: _isSuccess
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF10B981),
                                                  blurRadius: 6,
                                                  spreadRadius: 1.5,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: Text(
                                        _isSuccess ? 'pin_access_granted'.tr : 'pin_vault_active'.tr,
                                        key: ValueKey(_isSuccess),
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: _isSuccess ? const Color(0xFF10B981) : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) => FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.15),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                    child: child,
                                  ),
                                ),
                                child: _isSuccess
                                    ? Column(
                                        key: const ValueKey('success_state'),
                                        children: [
                                          Text(
                                            'pin_success'.tr,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3,
                                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'pin_welcome'.tr,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                                          const SizedBox(height: 4),
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
                              const SizedBox(height: 16),

                              // 4 Dots with staggered scale bounce & ripple wave animation on success
                              AnimatedBuilder(
                                animation: _shakeController,
                                builder: (context, child) {
                                  final dx = _shakeController.value == 0
                                      ? 0.0
                                      : (1.0 - _shakeController.value) *
                                          12.0 *
                                          (1.0 - (2.0 * ((_shakeController.value * 6) % 1)));
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
                                          duration: const Duration(milliseconds: 220),
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                          width: _isSuccess ? 16 : 14,
                                          height: _isSuccess ? 16 : 14,
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
                                                      color: color.withValues(alpha: _isSuccess ? 0.70 : 0.4),
                                                      blurRadius: _isSuccess ? 14 : 8,
                                                      spreadRadius: _isSuccess ? 2.5 : 1.5,
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
                                                end: const Offset(1.3, 1.3),
                                                duration: const Duration(milliseconds: 220),
                                                curve: Curves.easeOutBack,
                                              )
                                              .then()
                                              .scale(
                                                begin: const Offset(1.3, 1.3),
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

                              // Prompt if multiple failed attempts
                              if (_failCount >= 3 && !_isSuccess) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _showForgotPinDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.deficitText.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.deficitText.withValues(alpha: 0.30),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.deficitText),
                                        const SizedBox(width: 6),
                                        Text(
                                          'forgot_pin_hint'.tr,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.deficitText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),

                              // FinTech Numpad & Recovery (Smoothly slides down & fades out on success)
                              AnimatedSlide(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeInCubic,
                                offset: _isSuccess ? const Offset(0, 0.25) : Offset.zero,
                                child: AnimatedOpacity(
                                  opacity: _isSuccess ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  child: IgnorePointer(
                                    ignoring: _isSuccess,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildNumpad(isDark),
                                        const SizedBox(height: 10),

                                        // Forgot PIN Recovery Trigger Button
                                        TextButton.icon(
                                          onPressed: _showForgotPinDialog,
                                          icon: const Icon(Icons.help_outline_rounded, size: 15),
                                          label: Text(
                                            'forgot_pin'.tr,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Biometrics Scanning Overlay
              if (_isBiometricScanning) _buildBiometricsOverlay(isDark),

              // Forgot PIN / Recovery Modal Overlay
              if (_recoveryMode != _RecoveryMode.none) _buildRecoveryModal(isDark),
            ],
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
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 62, height: 62);

              if (key == 'BIO') {
                return InkWell(
                  onTap: _authenticateWithBiometrics,
                  borderRadius: BorderRadius.circular(31),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.fingerprint_rounded, size: 26, color: AppColors.primary),
                  ),
                );
              }

              return InkWell(
                onTap: () => _onKeyPress(key),
                borderRadius: BorderRadius.circular(31),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.85) : AppColors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder.withValues(alpha: 0.55) : AppColors.border.withValues(alpha: 0.65),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: key == '⌫'
                      ? Icon(
                          Icons.backspace_outlined,
                          size: 18,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        )
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
