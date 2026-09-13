import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// บริการจัดการและอ่านค่าคอนฟิกูเรชันจากไฟล์ `config.json` (และ fallback `.env`)
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final Map<String, String> _config = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// โหลดค่าคอนฟิกจากไฟล์ config.json (หรือ customContent)
  Future<void> init({String? customContent}) async {
    if (customContent != null) {
      _parseContent(customContent);
      _isInitialized = true;
      return;
    }

    try {
      // 1. ตรวจสอบไฟล์ config.json ในไดเรกทอรีการทำงานปัจจุบัน (Root Directory)
      final jsonFile = File('config.json');
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        _parseContent(content);
        _isInitialized = true;
        return;
      }

      // 2. ตรวจสอบไฟล์ config.json เคียงข้าง Executable (สำหรับ Desktop Release)
      try {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final exeJsonFile = File('$exeDir/config.json');
        if (await exeJsonFile.exists()) {
          final content = await exeJsonFile.readAsString();
          _parseContent(content);
          _isInitialized = true;
          return;
        }
      } catch (_) {}

      // 3. Fallback: ตรวจสอบไฟล์ .env หากยังมีเหลืออยู่
      final envFile = File('.env');
      if (await envFile.exists()) {
        final content = await envFile.readAsString();
        _parseContent(content);
        _isInitialized = true;
        return;
      }

      // 4. ตรวจสอบจาก Assets ของแอป (กรณี Bundle)
      try {
        final assetJson = await rootBundle.loadString('config.json');
        _parseContent(assetJson);
        _isInitialized = true;
        return;
      } catch (_) {}

      try {
        final assetEnv = await rootBundle.loadString('.env');
        _parseContent(assetEnv);
        _isInitialized = true;
        return;
      } catch (_) {}
    } catch (_) {}

    _isInitialized = true;
  }

  void _parseContent(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            _config[entry.key] = entry.value?.toString() ?? '';
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

      if (key.isNotEmpty) {
        _config[key] = value;
      }
    }
  }

  String? get(String key, {String? defaultValue}) {
    return _config[key] ?? defaultValue;
  }

  /// คีย์ Google Gemini API Key ที่กำหนดใน config.json
  String get geminiApiKey => get('GEMINI_API_KEY')?.trim() ?? '';

  /// โมเดล Gemini ที่เลือกใช้งาน (ค่าเริ่มต้น: gemini-3.6-flash)
  String get geminiModel {
    final configured = get('GEMINI_MODEL')?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return 'gemini-3.6-flash';
  }

  /// ตรวจสอบว่ามีการระบุ Gemini API Key แล้วหรือไม่
  bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// Helper สำหรับการจำลองค่าในการทดสอบ (Unit Tests)
  @visibleForTesting
  void setForTesting(String key, String value) {
    _config[key] = value;
  }

  @visibleForTesting
  void clearForTesting() {
    _config.clear();
  }
}

/// Alias สำหรับความเข้ากันได้ย้อนหลัง
typedef EnvService = ConfigService;
