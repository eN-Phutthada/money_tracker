import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';
import '../models/krungthai_slip_model.dart';
import '../models/transaction_model.dart';

/// ตัวถอดรหัส QR Code บนสลิปธนาคารกรุงไทย (PromptPay / BOT Slip Verification Standard)
/// ทำงานด้วย Pure Dart 100% รองรับทุกแพลตฟอร์ม (Android, iOS, Windows, macOS, Web)
class KrungthaiQrDecoder {
  /// ถอดรหัส QR Code จากข้อมูลไบต์ของรูปภาพสลิป
  static Future<String?> decodeQrFromImageBytes(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 1. ลองอ่านจากภาพที่มีการปรับขนาดให้เหมาะสม (Downscaled) เพื่อความเร็วและประหยัด RAM บนมือถือ
      img.Image processed = image;
      const maxDimension = 1200;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width >= image.height) {
          processed = img.copyResize(image, width: maxDimension);
        } else {
          processed = img.copyResize(image, height: maxDimension);
        }
      }

      // แปลงเป็น ARGB Int32List สำหรับ LuminanceSource
      final decoded = _tryDecodeImage(processed);
      if (decoded != null) return decoded;

      // 2. หากยังไม่พบ และภาพเดิมถูกย่อ ให้ลองกับภาพขนาดเต็มต้นฉบับ
      if (processed != image) {
        final origDecoded = _tryDecodeImage(image);
        if (origDecoded != null) return origDecoded;
      }

      // 3. หากยังไม่พบ ให้ลองครอบส่วนบนขวา (ตำแหน่งยอดนิยมของ Krungthai NEXT และธนาคารพาณิชย์)
      final trX = (processed.width * 0.45).round();
      final trY = (processed.height * 0.05).round();
      final trW = processed.width - trX;
      final trH = (processed.height * 0.45).round();
      if (trW > 50 && trH > 50) {
        final trCropped = img.copyCrop(
          processed,
          x: trX,
          y: trY,
          width: trW,
          height: trH,
        );
        final trDecoded = _tryDecodeImage(trCropped);
        if (trDecoded != null) return trDecoded;
      }

      // 4. หากยังไม่พบ ให้ลองครอบเฉพาะครึ่งล่างของสลิป (ซึ่งเป็นตำแหน่งมาตรฐานของสลิปบางธนาคาร)
      final cropY = (processed.height * 0.35).round();
      final cropH = processed.height - cropY;
      if (cropH > 50 && processed.width > 50) {
        final cropped = img.copyCrop(
          processed,
          x: 0,
          y: cropY,
          width: processed.width,
          height: cropH,
        );
        final cropDecoded = _tryDecodeImage(cropped);
        if (cropDecoded != null) return cropDecoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _tryDecodeImage(img.Image image) {
    try {
      final int32List = Int32List(image.width * image.height);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final p = image.getPixel(x, y);
          int32List[y * image.width + x] =
              (p.a.toInt() << 24) | (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt();
        }
      }

      final source = RGBLuminanceSource(image.width, image.height, int32List);

      // ลองใช้ HybridBinarizer ก่อน (เหมาะสำหรับภาพถ่ายจริงที่มีเงาหรือแสงไม่สม่ำเสมอ)
      try {
        final hybridBitmap = BinaryBitmap(HybridBinarizer(source));
        final reader = QRCodeReader();
        final result = reader.decode(hybridBitmap);
        if (result.text.isNotEmpty) return result.text;
      } catch (_) {}

      // สำรองด้วย GlobalHistogramBinarizer (เหมาะสำหรับภาพสกรีนช็อตที่คอนทราสต์ชัด)
      try {
        final globalBitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
        final reader = QRCodeReader();
        final result = reader.decode(globalBitmap);
        if (result.text.isNotEmpty) return result.text;
      } catch (_) {}

      return null;
    } catch (_) {
      return null;
    }
  }

  /// วิเคราะห์ข้อมูลจากข้อความ QR Code สลิปธนาคารกรุงไทย (BOT / PromptPay Standard)
  static KrungthaiSlipData? parsePromptPaySlipQr(String qrText) {
    if (qrText.trim().isEmpty) return null;

    final trimmed = qrText.trim();
    final lower = trimmed.toLowerCase();

    // ตรวจสอบว่าเป็นสลิปหรือบริการของธนาคารกรุงไทยหรือไม่
    final isKrungthai = lower.contains('0006') ||
        lower.contains('006') ||
        lower.contains('krungthai') ||
        lower.contains('ktb') ||
        lower.contains('paotang') ||
        trimmed.startsWith('00460006') ||
        trimmed.startsWith('00380006') ||
        trimmed.contains('next.krungthai');

    if (!isKrungthai) {
      // หากเป็น PromptPay BScanC ทั่วไปแต่พบรหัสธนาคาร 006
      if (!trimmed.startsWith('0046') && !trimmed.startsWith('0038') && !trimmed.startsWith('000201')) {
        return null;
      }
    }

    // 1. วิเคราะห์กรณี QR เป็น URL (Krungthai NEXT หรือ เป๋าตัง Pay)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final transRef = uri.queryParameters['transRef'] ??
            uri.queryParameters['ref'] ??
            uri.queryParameters['id'] ??
            uri.queryParameters['txnId'];
        final amountStr = uri.queryParameters['amount'] ?? uri.queryParameters['amt'];
        final amount = amountStr != null ? double.tryParse(amountStr) ?? 0.0 : 0.0;

        DateTime date = DateTime.now();
        final dateStr = uri.queryParameters['date'] ?? uri.queryParameters['dateTime'];
        if (dateStr != null && dateStr.length >= 8) {
          final y = int.tryParse(dateStr.substring(0, 4)) ?? date.year;
          final m = int.tryParse(dateStr.substring(4, 6)) ?? date.month;
          final d = int.tryParse(dateStr.substring(6, 8)) ?? date.day;
          date = DateTime(y, m, d);
        }

        final bankVariant = lower.contains('paotang') ? 'ธนาคารกรุงไทย (เป๋าตัง)' : 'ธนาคารกรุงไทย (Krungthai NEXT)';

        return KrungthaiSlipData(
          amount: amount,
          transactionDate: date,
          referenceNo: transRef,
          bankName: bankVariant,
          isKrungthai: true,
          rawText: qrText,
        );
      }
    }

    // 2. วิเคราะห์กรณีเป็น PromptPay EMVCo / BOT Slip Verify TLV Standard
    final tlv = _parseTlv(trimmed);

    // สกัด Sub-TLV ภายใน Tag 00 (มาตรฐาน Bank of Thailand Cross-Bank Slip Verification)
    Map<String, String>? subTlv;
    if (tlv.containsKey('00')) {
      subTlv = _parseTlv(tlv['00']!);
    }

    // สกัดยอดเงิน (Tag 54)
    double amount = 0.0;
    if (tlv.containsKey('54')) {
      amount = double.tryParse(tlv['54']!) ?? 0.0;
    }

    // หากไม่พบใน Tag 54 ลองหาจากรูปแบบ regex ในข้อความ
    if (amount <= 0) {
      final amtMatch = RegExp(r'54\d{2}([0-9]+(?:\.[0-9]{2})?)').firstMatch(trimmed);
      if (amtMatch != null) {
        amount = double.tryParse(amtMatch.group(1)!) ?? 0.0;
      }
    }

    // สกัดรหัสอ้างอิงธุรกรรม (Transaction Reference)
    String? referenceNo;
    // 2.1 รูปแบบมาตรฐานสลิปกรุงไทย: ปี ค.ศ. (202x) + เดือน (2 หลัก) + วัน (2 หลัก) + รหัสธนาคาร 0006 + เลขธุรกรรม 6 หลัก
    final ktbExactRef = RegExp(r'(202\d(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])0006\d{6})').firstMatch(trimmed);
    if (ktbExactRef != null) {
      referenceNo = ktbExactRef.group(1);
    } else if (subTlv != null && subTlv.containsKey('02') && subTlv['02']!.isNotEmpty) {
      // 2.2 สกัดจาก Sub-Tag 02 ของ Tag 00 ในมาตรฐาน BOT Slip Verification (เช่น รหัส A308e920c27594e4c)
      referenceNo = subTlv['02'];
    } else {
      final ktbPrefix = RegExp(r'(KTB[0-9A-Z]{10,24})').firstMatch(trimmed);
      if (ktbPrefix != null) {
        referenceNo = ktbPrefix.group(1);
      } else {
        // รูปแบบขึ้นต้นด้วย 202x ที่หยุดก่อน Tag ถัดไป เช่น 54 (Amount) หรือ 58 (Country)
        final boundaryRef = RegExp(r'(202\d{13,17})(?=54\d{2}|58\d{2}|[A-Za-z]|$)').firstMatch(trimmed);
        if (boundaryRef != null) {
          referenceNo = boundaryRef.group(1);
        } else {
          final numMatch = RegExp(r'(202\d{14,17})').firstMatch(trimmed);
          if (numMatch != null) {
            referenceNo = numMatch.group(1);
          }
        }
      }
    }

    // สกัดวันที่ทำรายการ
    DateTime date = DateTime.now();
    if (referenceNo != null && referenceNo.length >= 8 && referenceNo.startsWith('202')) {
      final y = int.tryParse(referenceNo.substring(0, 4));
      final m = int.tryParse(referenceNo.substring(4, 6));
      final d = int.tryParse(referenceNo.substring(6, 8));
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        date = DateTime(y, m, d);
      }
    }

    final isPaotang = lower.contains('paotang') || lower.contains('เป๋าตัง');
    final bankName = isPaotang ? 'ธนาคารกรุงไทย (เป๋าตัง)' : 'ธนาคารกรุงไทย (Krungthai NEXT)';

    return KrungthaiSlipData(
      amount: amount,
      transactionDate: date,
      referenceNo: referenceNo,
      bankName: bankName,
      isKrungthai: true,
      suggestedCategory: 'อาหาร/ของกิน',
      suggestedCostNature: CostNature.variable,
      suggestedType: TransactionType.expense,
      rawText: qrText,
    );
  }

  /// แยกคู่ข้อมูล Tag-Length-Value (TLV) ตามมาตรฐาน EMVCo
  static Map<String, String> _parseTlv(String raw) {
    final result = <String, String>{};
    int idx = 0;
    while (idx + 4 <= raw.length) {
      final tag = raw.substring(idx, idx + 2);
      final lenStr = raw.substring(idx + 2, idx + 4);
      final len = int.tryParse(lenStr);
      if (len == null || idx + 4 + len > raw.length) break;
      final val = raw.substring(idx + 4, idx + 4 + len);
      result[tag] = val;
      idx += 4 + len;
    }
    return result;
  }
}
