import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// บริการสแกนและอ่านข้อความด้วยเทคโนโลยี Optical Character Recognition (OCR) บนมือถือ
/// ทำงานแบบ On-Device บนสมาร์ตโฟน Android และ iOS
class KrungthaiOcrService {
  /// สกัดข้อความจากไฟล์รูปภาพสลิป
  static Future<String?> recognizeTextFromImage(String filePath) async {
    // จำกัดการทำงานเฉพาะบนอุปกรณ์มือถือ (Android และ iOS)
    // เพื่อความปลอดภัยและหลีกเลี่ยงข้อผิดพลาด MissingPluginException บน Desktop / Web / Unit Tests
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return null;
    }

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      return recognizedText.text;
    } catch (_) {
      return null;
    }
  }
}
