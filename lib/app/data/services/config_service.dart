import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'secret_vault.dart';
import 'storage_service.dart';

/// บริการจัดการและอ่านค่าคอนฟิกูเรชันจากไฟล์ `config.json`, SecretVault, StorageService, และ Environment
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final Map<String, String> _config = {};
  bool _isInitialized = false;

  final RxString geminiApiKeyRx = ''.obs;
  final RxString geminiModelRx = 'gemini-3.6-flash'.obs;

  bool get isInitialized => _isInitialized;

  /// โหลดค่าคอนฟิกจากไฟล์ config.json, SecretVault, Storage, หรือ customContent
  Future<void> init({String? customContent}) async {
    if (customContent != null) {
      _parseContent(customContent);
      _syncObservables();
      _isInitialized = true;
      return;
    }

    try {
      // 1. ตรวจสอบจาก Local Persistent Storage (หากผู้ใช้เคยตั้งค่าหรือบันทึกผ่านแอป)
      try {
        final storedKey = await StorageService().loadGeminiApiKey();
        if (storedKey != null && storedKey.isNotEmpty) {
          _config['GEMINI_API_KEY'] = storedKey;
        }
        final storedModel = await StorageService().loadGeminiModel();
        if (storedModel != null && storedModel.isNotEmpty) {
          _config['GEMINI_MODEL'] = storedModel;
        }
      } catch (_) {}

      // 2. ตรวจสอบจาก Compile-time Environment Variables (--dart-define)
      const envKey = String.fromEnvironment('GEMINI_API_KEY');
      if (envKey.isNotEmpty && !_config.containsKey('GEMINI_API_KEY')) {
        _config['GEMINI_API_KEY'] = envKey;
      }
      const envModel = String.fromEnvironment('GEMINI_MODEL');
      if (envModel.isNotEmpty && !_config.containsKey('GEMINI_MODEL')) {
        _config['GEMINI_MODEL'] = envModel;
      }

      // 3. ตรวจสอบไฟล์ config.json ในไดเรกทอรีการทำงานปัจจุบัน (Root Directory สำหรับ Desktop/CLI)
      final jsonFile = File('config.json');
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        _parseContent(content);
      }

      // 4. ตรวจสอบไฟล์ config.json เคียงข้าง Executable (สำหรับ Desktop Release)
      try {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final exeJsonFile = File('$exeDir/config.json');
        if (await exeJsonFile.exists()) {
          final content = await exeJsonFile.readAsString();
          _parseContent(content);
        }
      } catch (_) {}

      // 5. Fallback: ตรวจสอบไฟล์ .env หากยังมีเหลืออยู่
      final envFile = File('.env');
      if (await envFile.exists()) {
        final content = await envFile.readAsString();
        _parseContent(content);
      }

      // 6. Built-in Fallback: ตรวจสอบจาก SecretVault (ระบบคีย์เข้ารหัสระดับ Binary ในตัว)
      if (!_config.containsKey('GEMINI_API_KEY') || _config['GEMINI_API_KEY']!.trim().isEmpty) {
        final vaultKey = SecretVault.defaultGeminiApiKey;
        if (vaultKey.isNotEmpty) {
          _config['GEMINI_API_KEY'] = vaultKey;
        }
      }
      if (!_config.containsKey('GEMINI_MODEL') || _config['GEMINI_MODEL']!.trim().isEmpty) {
        _config['GEMINI_MODEL'] = SecretVault.defaultGeminiModel;
      }
    } catch (_) {}

    _syncObservables();
    _isInitialized = true;
  }

  void _syncObservables() {
    final key = _config['GEMINI_API_KEY']?.trim() ?? '';
    geminiApiKeyRx.value = key;
    final model = _config['GEMINI_MODEL']?.trim();
    geminiModelRx.value = (model != null && model.isNotEmpty) ? model : 'gemini-3.6-flash';
  }

  void _parseContent(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final val = entry.value?.toString().trim() ?? '';
            if (val.isNotEmpty) {
              _config[entry.key] = val;
            }
          }
          return;
        }
      } catch (_) {}
    }

    // Fallback: parse as KEY=VALUE (.env format)
    final lines = content.split(RegExp(r'\r?\n'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final eqIdx = line.indexOf('=');
      if (eqIdx == -1) continue;

      final key = line.substring(0, eqIdx).trim();
      var value = line.substring(eqIdx + 1).trim();

      // ตัดเครื่องหมายคำพูด (Quotes)
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        if (value.length >= 2) {
          value = value.substring(1, value.length - 1);
        }
      }

      if (key.isNotEmpty && value.isNotEmpty) {
        _config[key] = value;
      }
    }
  }

  String? get(String key, {String? defaultValue}) {
    return _config[key] ?? defaultValue;
  }

  /// คีย์ Google Gemini API Key
  String get geminiApiKey => geminiApiKeyRx.value.isNotEmpty
      ? geminiApiKeyRx.value
      : (get('GEMINI_API_KEY')?.trim() ?? '');

  /// โมเดล Gemini ที่เลือกใช้งาน (ค่าเริ่มต้น: gemini-3.6-flash)
  String get geminiModel {
    if (geminiModelRx.value.isNotEmpty) return geminiModelRx.value;
    final configured = get('GEMINI_MODEL')?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return 'gemini-3.6-flash';
  }

  /// ตรวจสอบว่ามีการระบุ Gemini API Key แล้วหรือไม่
  bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// ตรวจสอบว่ากำลังใช้ระบบ AI อัจฉริยะในตัว (Built-in Vault) หรือไม่
  bool get isUsingBuiltInKey {
    final currentKey = geminiApiKey.trim();
    final vaultKey = SecretVault.defaultGeminiApiKey.trim();
    return vaultKey.isNotEmpty && currentKey == vaultKey;
  }

  /// บันทึก API Key และ Model ลง Persistent Storage ทันที
  Future<void> saveApiKey(String key, {String? model}) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      await resetToDefault();
      return;
    }
    _config['GEMINI_API_KEY'] = cleanKey;
    geminiApiKeyRx.value = cleanKey;
    await StorageService().saveGeminiApiKey(cleanKey);

    if (model != null && model.trim().isNotEmpty) {
      final cleanModel = model.trim();
      _config['GEMINI_MODEL'] = cleanModel;
      geminiModelRx.value = cleanModel;
      await StorageService().saveGeminiModel(cleanModel);
    }
  }

  /// ล้าง API Key ส่วนตัว และกลับไปใช้ระบบ AI อัจฉริยะในตัว
  Future<void> clearApiKey() async {
    await StorageService().saveGeminiApiKey('');
    _config.remove('GEMINI_API_KEY');
    final vaultKey = SecretVault.defaultGeminiApiKey;
    if (vaultKey.isNotEmpty) {
      _config['GEMINI_API_KEY'] = vaultKey;
    }
    _syncObservables();
  }

  /// ตั้งค่าโมเดล Gemini ที่ต้องการใช้งาน
  Future<void> setModel(String model) async {
    final cleanModel = model.trim();
    if (cleanModel.isNotEmpty) {
      _config['GEMINI_MODEL'] = cleanModel;
      geminiModelRx.value = cleanModel;
      await StorageService().saveGeminiModel(cleanModel);
    }
  }

  /// รีเซ็ตการตั้งค่ากลับสู่ระบบ AI ในตัว (Default Built-in Vault)
  Future<void> resetToDefault() async {
    await StorageService().saveGeminiApiKey('');
    await StorageService().saveGeminiModel(SecretVault.defaultGeminiModel);
    _config['GEMINI_API_KEY'] = SecretVault.defaultGeminiApiKey;
    _config['GEMINI_MODEL'] = SecretVault.defaultGeminiModel;
    _syncObservables();
  }

  /// ทดสอบการเชื่อมต่อไปยัง Google Gemini API แบบ Ping สั้นๆ
  Future<bool> testConnection({String? testKey, String? testModel}) async {
    final key = (testKey ?? geminiApiKey).trim();
    final model = (testModel ?? geminiModel).trim();
    if (key.isEmpty) return false;

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
      );
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      final payload = {
        'contents': [
          {
            'parts': [
              {'text': 'Reply OK'}
            ]
          }
        ]
      };
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ConfigService] Connection test failed: $e');
      return false;
    }
  }

  /// Helper สำหรับการจำลองค่าในการทดสอบ (Unit Tests)
  @visibleForTesting
  void setForTesting(String key, String value) {
    _config[key] = value;
    _syncObservables();
  }

  @visibleForTesting
  void clearForTesting() {
    _config.clear();
    geminiApiKeyRx.value = '';
    geminiModelRx.value = 'gemini-3.6-flash';
  }
}

/// Alias สำหรับความเข้ากันได้ย้อนหลัง
typedef EnvService = ConfigService;
