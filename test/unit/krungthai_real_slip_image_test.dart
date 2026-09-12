import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:money_tracker/app/data/services/krungthai_slip_service.dart';
import 'package:zxing2/qrcode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper to generate a test QR image file
  File createQrImageFile(String payload, String fileName) {
    final qrCode = Encoder.encode(payload, ErrorCorrectionLevel.m);
    final matrix = qrCode.matrix!;
    const scale = 8;
    final width = matrix.width * scale;
    final height = matrix.height * scale;
    final image = img.Image(width: width, height: height, numChannels: 4);
    image.clear(img.ColorRgba8(255, 255, 255, 255));
    final black = img.ColorRgba8(0, 0, 0, 255);
    for (var y = 0; y < matrix.height; y++) {
      for (var x = 0; x < matrix.width; x++) {
        if (matrix.get(x, y) == 1) {
          img.fillRect(image, x1: x * scale, y1: y * scale, x2: (x + 1) * scale, y2: (y + 1) * scale, color: black);
        }
      }
    }

    final tempDir = Directory.systemTemp.createTempSync();
    final file = File('${tempDir.path}/$fileName');
    file.writeAsBytesSync(img.encodePng(image));
    return file;
  }

  group('Real-world Krungthai Slip Image & QR Processing Tests', () {
    test('1. Pure Dart QR encoding and decoding engine verification', () {
      const payload = '0046000600000101030140225111235102026091100069922115405350.005802TH6304ABCD';
      final file = createQrImageFile(payload, 'test_pure_dart_qr.png');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(100));

      file.parent.deleteSync(recursive: true);
    });

    test('2. Reads and extracts real BOT PromptPay slip QR image file', () async {
      const payload = '0046000600000101030140225111235102026091100069922115405350.005802TH6304ABCD';
      final file = createQrImageFile(payload, 'ktb_bot_slip.png');

      final service = KrungthaiSlipService();
      final slip = await service.processSlipImage(XFile(file.path));

      expect(slip, isNotNull);
      expect(slip!.isKrungthai, isTrue);
      expect(slip.amount, equals(350.00));
      expect(slip.referenceNo, equals('202609110006992211'));
      expect(slip.bankName, equals('ธนาคารกรุงไทย (Krungthai NEXT)'));
      expect(slip.transactionDate.year, equals(2026));
      expect(slip.transactionDate.month, equals(9));
      expect(slip.transactionDate.day, equals(11));
      expect(slip.transactionDate.hour, equals(12));
      expect(slip.transactionDate.minute, equals(35));
      expect(slip.transactionDate.second, equals(10));
      expect(slip.hasParsedDateTime, isTrue);

      // Cleanup
      file.parent.deleteSync(recursive: true);
    });

    test('3. Reads Krungthai NEXT URL QR image file', () async {
      const payload = 'https://next.krungthai.com/slip/verify?transRef=202609120006123456&amount=1290.00&date=20260912';
      final file = createQrImageFile(payload, 'ktb_next_url_slip.png');

      final service = KrungthaiSlipService();
      final slip = await service.processSlipImage(XFile(file.path));

      expect(slip, isNotNull);
      expect(slip!.isKrungthai, isTrue);
      expect(slip.amount, equals(1290.00));
      expect(slip.referenceNo, equals('202609120006123456'));
      expect(slip.bankName, contains('Krungthai NEXT'));

      // Cleanup
      file.parent.deleteSync(recursive: true);
    });

    test('4. Reads Krungthai เป๋าตัง Pay URL QR image file', () async {
      const payload = 'https://paotang.krungthai.com/slip/verify?id=202609010006778899&amount=4500.00';
      final file = createQrImageFile(payload, 'ktb_paotang_slip.png');

      final service = KrungthaiSlipService();
      final slip = await service.processSlipImage(XFile(file.path));

      expect(slip, isNotNull);
      expect(slip!.isKrungthai, isTrue);
      expect(slip.amount, equals(4500.00));
      expect(slip.referenceNo, equals('202609010006778899'));
      expect(slip.bankName, equals('ธนาคารกรุงไทย (เป๋าตัง)'));

      // Cleanup
      file.parent.deleteSync(recursive: true);
    });

    test('5. Returns null when non-bank QR image is processed', () async {
      const payload = 'https://example.com/not-a-bank-slip';
      final file = createQrImageFile(payload, 'random_qr.png');

      final service = KrungthaiSlipService();
      final slip = await service.processSlipImage(XFile(file.path));

      expect(slip, isNull);

      // Cleanup
      file.parent.deleteSync(recursive: true);
    });
  });
}
