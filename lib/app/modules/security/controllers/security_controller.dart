import 'package:get/get.dart';
import '../../../data/services/security_service.dart';

/// GetX Controller สำหรับจัดการความปลอดภัย PIN และ Biometrics
class SecurityController extends GetxController {
  final SecurityService _service = SecurityService();

  final RxBool isPinEnabled = false.obs;
  final RxBool isBiometricsEnabled = false.obs;
  final RxBool isLocked = false.obs;
  final Rx<BiometricAvailabilityResult?> biometricAvailability = Rx<BiometricAvailabilityResult?>(null);

  @override
  void onInit() {
    super.onInit();
    _syncState();
    checkBiometricAvailability();
  }

  void _syncState() {
    isPinEnabled.value = _service.isPinEnabled;
    isBiometricsEnabled.value = _service.isBiometricsEnabled;
    isLocked.value = _service.isLocked;
  }

  bool verifyPin(String pin, {bool autoUnlock = true}) {
    final isValid = _service.verifyPin(pin);
    if (isValid && autoUnlock) {
      isLocked.value = false;
    }
    return isValid;
  }

  void unlock() {
    _service.unlock();
    isLocked.value = false;
  }

  void lock() {
    if (isPinEnabled.value) {
      _service.lock();
      isLocked.value = true;
    }
  }

  Future<bool> setPin(String pin) async {
    final success = await _service.setPin(pin);
    if (success) {
      _syncState();
    }
    return success;
  }

  Future<bool> disablePin() async {
    final success = await _service.disablePin();
    if (success) {
      _syncState();
    }
    return success;
  }

  Future<BiometricAvailabilityResult> checkBiometricAvailability() async {
    final result = await _service.checkBiometricAvailability();
    biometricAvailability.value = result;
    return result;
  }

  Future<bool> canCheckBiometrics() async {
    final res = await checkBiometricAvailability();
    return res.isAvailable;
  }

  Future<BiometricAuthResult> authenticateWithBiometricsDetailed({String? localizedReason}) async {
    final result = await _service.authenticateWithBiometricsDetailed(
      localizedReason: localizedReason,
    );
    if (result.success) {
      isLocked.value = false;
    }
    return result;
  }

  Future<bool> authenticateWithBiometrics({String? localizedReason}) async {
    final result = await authenticateWithBiometricsDetailed(
      localizedReason: localizedReason,
    );
    return result.success;
  }

  Future<bool> setBiometricsEnabled(bool enabled) async {
    final success = await _service.setBiometricsEnabled(enabled);
    if (success) {
      _syncState();
    }
    return success;
  }

  String get biometricStatusSubtitle {
    final availability = biometricAvailability.value;
    if (availability == null) {
      return 'biometric_ready_desc'.tr;
    }
    switch (availability.status) {
      case BiometricAvailabilityStatus.notSupported:
        return 'biometric_not_supported'.tr;
      case BiometricAvailabilityStatus.notEnrolled:
        return 'biometric_not_enrolled'.tr;
      case BiometricAvailabilityStatus.available:
        return 'biometric_ready_desc'.tr;
    }
  }
}
