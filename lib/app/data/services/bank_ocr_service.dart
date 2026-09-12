import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// บริการสแกนและอ่านข้อความด้วยเทคโนโลยี Optical Character Recognition (OCR)
/// ทำงานแบบ On-Device 100% ปลอดภัย ไม่ส่งข้อมูลออกนอกเครื่อง และฟรีตลอดชีพ
class BankOcrService {
  /// สกัดข้อความจากไฟล์รูปภาพสลิป
  static Future<String?> recognizeTextFromImage(String filePath) async {
    if (kIsWeb) return null;

    // 1. รองรับ Windows Desktop ผ่าน Windows.Media.Ocr.OcrEngine ในเครื่อง (รวดเร็วและรองรับภาษาไทย)
    if (Platform.isWindows) {
      return _recognizeTextOnWindows(filePath);
    }

    // จำกัดการทำงานบนมือถือ Android และ iOS
    if (!Platform.isAndroid && !Platform.isIOS) {
      return null;
    }

    // 2. ใช้งาน On-Device Thai Tesseract OCR (tha+eng) เป็นตัวเลือกหลัก
    try {
      final text = await FlutterTesseractOcr.extractText(
        filePath,
        language: 'tha+eng',
        args: {'preserve_interword_spaces': '1'},
      );
      if (text.trim().isNotEmpty) {
        return text;
      }
    } catch (e) {
      debugPrint('[BankOcrService] Tesseract OCR error, fallback to ML Kit: $e');
    }

    // 3. Fallback ไปยัง Google ML Kit กรณี Tesseract ขัดข้อง
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      return recognizedText.text;
    } catch (e) {
      debugPrint('[BankOcrService] ML Kit OCR error: $e');
      return null;
    }
  }

  /// สกัดข้อความด้วย Windows.Media.Ocr.OcrEngine บน Windows Desktop
  static Future<String?> _recognizeTextOnWindows(String filePath) async {
    try {
      final escapedPath = filePath.replaceAll("'", "''");
      final script = '''
Add-Type -AssemblyName System.Runtime.WindowsRuntime;
\$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | ? { \$_.Name -eq 'AsTask' -and \$_.GetParameters().Count -eq 1 -and \$_.ContainsGenericParameters } | Select -First 1;
function Aw(\$op, \$t) { \$m = \$asTask.MakeGenericMethod(\$t); \$task = \$m.Invoke(\$null, @(\$op)); \$task.Wait(-1) | Out-Null; return \$task.Result; };
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null;
[Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null;
[Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime] | Out-Null;
\$f = Aw ([Windows.Storage.StorageFile]::GetFileFromPathAsync('$escapedPath')) ([Windows.Storage.StorageFile]);
\$s = Aw (\$f.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream]);
\$d = Aw ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync(\$s)) ([Windows.Graphics.Imaging.BitmapDecoder]);
\$b = Aw (\$d.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap]);
\$e = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages();
\$r = Aw (\$e.RecognizeAsync(\$b)) ([Windows.Media.Ocr.OcrResult]);
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8;
\$lines = (\$r.Lines | ForEach-Object { \$_.Text }) -join [Environment]::NewLine;
Write-Output \$lines;
''';
      final res = await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', script]);
      if (res.exitCode == 0) {
        final out = res.stdout.toString().trim();
        if (out.isNotEmpty) return out;
      }
    } catch (_) {}
    return null;
  }
}

/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100%
typedef KrungthaiOcrService = BankOcrService;
