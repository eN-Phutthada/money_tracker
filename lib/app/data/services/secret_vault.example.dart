import 'dart:convert';

/// ตัวอย่างเทมเพลตสำหรับ SecretVault (สำหรับ Git Repository)
class SecretVault {
  static const List<int> _scrambled = [];
  static const List<int> _mask = [0x5A, 0x3C, 0x7E, 0x1F, 0x8D, 0x42];

  static String get defaultGeminiApiKey {
    if (_scrambled.isEmpty) return '';
    final bytes = List<int>.generate(
      _scrambled.length,
      (i) => _scrambled[i] ^ _mask[i % _mask.length],
    );
    return utf8.decode(bytes);
  }

  static const String defaultGeminiModel = 'gemini-3.6-flash';
}
