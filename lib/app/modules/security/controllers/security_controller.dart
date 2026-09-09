import 'package:get/get.dart';
import '../../../data/services/security_service.dart';

/// GetX Controller สำหรับจัดการความปลอดภัย PIN และ Biometrics
class SecurityController extends GetxController {
  final SecurityService _service = SecurityService();

  final RxBool isPinEnabled = false.obs;
  final RxBool isBiometricsEnabled = false.obs;
  final RxBool isLocked = false.obs;

  @override
  void onInit() {
    super.onInit();
    _syncState();
  }

  void _syncState() {
    isPinEnabled.value = _service.isPinEnabled;
    isBiometricsEnabled.value = _service.isBiometricsEnabled;
    isLocked.value = _service.isLocked;
  }

  bool verifyPin(String pin) {
    final isValid = _service.verifyPin(pin);
    if (isValid) {
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

  Future<bool> setBiometricsEnabled(bool enabled) async {
    final success = await _service.setBiometricsEnabled(enabled);
    if (success) {
      _syncState();
    }
    return success;
  }
}
