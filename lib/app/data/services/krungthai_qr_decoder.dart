import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';
import '../models/krungthai_slip_model.dart';
import 'slip_category_predictor.dart';

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

  /// ตารางรหัสธนาคารตามมาตรฐาน Bank of Thailand (BOT Slip Verification)
  static final Map<String, String> thaiBankCodes = {
    '002': 'ธนาคารกรุงเทพ (Bualuang mBanking)',
    '004': 'ธนาคารกสิกรไทย (K PLUS)',
    '006': 'ธนาคารกรุงไทย (Krungthai NEXT)',
    '011': 'ทีเอ็มบีธนชาต (ttb touch)',
    '014': 'ธนาคารไทยพาณิชย์ (SCB EASY)',
    '022': 'ธนาคารซีไอเอ็มบี ไทย',
    '024': 'ธนาคารยูโอบี (UOB TMRW)',
    '025': 'ธนาคารกรุงศรีอยุธยา (KMA)',
    '030': 'ธนาคารออมสิน (MyMo)',
    '034': 'ธ.ก.ส. (BAAC Mobile)',
    '067': 'ธนาคารทิสโก้',
    '069': 'ธนาคารเกียรตินาคินภัทร (KKP)',
    '070': 'ธนาคารไอซีบีซี (ไทย)',
    '073': 'ธนาคารแลนด์ แอนด์ เฮ้าส์',
  };

  /// ถอดรหัสข้อความ QR Code สลิปเป็นโมเดลข้อมูล KrungthaiSlipData (Alias สำหรับ parsePromptPaySlipQr)
  static KrungthaiSlipData? decodeSlipQr(String qrText) =>
      parsePromptPaySlipQr(qrText);

  /// วิเคราะห์ข้อมูลจากข้อความ QR Code สลิปธนาคาร (รองรับทุกธนาคารในไทย โดยมีกรุงไทยเป็นหลัก)
  static KrungthaiSlipData? parsePromptPaySlipQr(String qrText) {
    if (qrText.trim().isEmpty) return null;

    final trimmed = qrText.trim();
    final lower = trimmed.toLowerCase();

    final isUrl = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final isPromptPayTlv = RegExp(r'^00\d{2}').hasMatch(trimmed) || trimmed.startsWith('000201');

    if (!isUrl && !isPromptPayTlv) {
      return null;
    }

    // 1. วิเคราะห์กรณี QR เป็น URL (Krungthai NEXT, เป๋าตัง, K PLUS, SCB EASY, ฯลฯ)
    if (isUrl) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final transRef = uri.queryParameters['transRef'] ??
            uri.queryParameters['ref'] ??
            uri.queryParameters['id'] ??
            uri.queryParameters['txnId'];
        final amountStr = uri.queryParameters['amount'] ?? uri.queryParameters['amt'];

        // ตรวจสอบว่าเป็น URL สลิปธนาคารจริงหรือไม่
        if (transRef == null && amountStr == null) {
          return null;
        }

        final amount = amountStr != null ? double.tryParse(amountStr) ?? 0.0 : 0.0;

        DateTime date = DateTime.now();
        bool hasDate = false;
        final dateStr = uri.queryParameters['date'] ?? uri.queryParameters['dateTime'];
        final timeStr = uri.queryParameters['time'];
        if (dateStr != null) {
          final isoParsed = DateTime.tryParse(dateStr);
          if (isoParsed != null) {
            date = isoParsed;
            hasDate = true;
          } else if (dateStr.length >= 8) {
            final y = int.tryParse(dateStr.substring(0, 4)) ?? date.year;
            final m = int.tryParse(dateStr.substring(4, 6)) ?? date.month;
            final d = int.tryParse(dateStr.substring(6, 8)) ?? date.day;
            int h = 0;
            int min = 0;
            int s = 0;
            if (dateStr.length >= 14) {
              h = int.tryParse(dateStr.substring(8, 10)) ?? 0;
              min = int.tryParse(dateStr.substring(10, 12)) ?? 0;
              s = int.tryParse(dateStr.substring(12, 14)) ?? 0;
            } else if (dateStr.length >= 12) {
              h = int.tryParse(dateStr.substring(8, 10)) ?? 0;
              min = int.tryParse(dateStr.substring(10, 12)) ?? 0;
            } else if (timeStr != null) {
              final cleanTime = timeStr.replaceAll(':', '').replaceAll('.', '');
              if (cleanTime.length >= 6) {
                h = int.tryParse(cleanTime.substring(0, 2)) ?? 0;
                min = int.tryParse(cleanTime.substring(2, 4)) ?? 0;
                s = int.tryParse(cleanTime.substring(4, 6)) ?? 0;
              } else if (cleanTime.length >= 4) {
                h = int.tryParse(cleanTime.substring(0, 2)) ?? 0;
                min = int.tryParse(cleanTime.substring(2, 4)) ?? 0;
              }
            }
            date = DateTime(y, m, d, h, min, s);
            hasDate = true;
          }
        }

        String bankVariant = 'ธนาคารกรุงไทย (Krungthai NEXT)';
        if (lower.contains('paotang') || lower.contains('เป๋าตัง')) {
          bankVariant = 'ธนาคารกรุงไทย (เป๋าตัง)';
        } else if (lower.contains('kplus') || lower.contains('kasikorn')) {
          bankVariant = 'ธนาคารกสิกรไทย (K PLUS)';
        } else if (lower.contains('scbeasy') || lower.contains('scb')) {
          bankVariant = 'ธนาคารไทยพาณิชย์ (SCB EASY)';
        } else if (lower.contains('bangkokbank') || lower.contains('bbl')) {
          bankVariant = 'ธนาคารกรุงเทพ (Bualuang mBanking)';
        } else if (lower.contains('krungsri')) {
          bankVariant = 'ธนาคารกรุงศรีอยุธยา (KMA)';
        } else if (lower.contains('ttb')) {
          bankVariant = 'ทีเอ็มบีธนชาต (ttb touch)';
        } else if (lower.contains('gsb') || lower.contains('mymo')) {
          bankVariant = 'ธนาคารออมสิน (MyMo)';
        } else if (lower.contains('baac')) {
          bankVariant = 'ธ.ก.ส. (BAAC Mobile)';
        }

        final isKtb = bankVariant.contains('กรุงไทย') || bankVariant.contains('เป๋าตัง');

        return KrungthaiSlipData(
          amount: amount,
          transactionDate: date,
          referenceNo: transRef,
          bankName: bankVariant,
          isKrungthai: isKtb,
          rawText: qrText,
          hasParsedDateTime: hasDate,
        );
      }
    }

    // 2. วิเคราะห์กรณีเป็น PromptPay EMVCo / BOT Slip Verify TLV Standard
    final tlv = _parseTlv(trimmed);

    // สกัด Sub-TLV ภายใน Tag 00 (กรณีสลิปทั่วไป) หรือ Tag 29, 30, 31 (กรณี EMVCo PromptPay)
    Map<String, String>? subTlv;
    if (tlv.containsKey('00') && tlv['00']!.length > 10) {
      subTlv = _parseTlv(tlv['00']!);
    } else if (tlv.containsKey('29')) {
      subTlv = _parseTlv(tlv['29']!);
    } else if (tlv.containsKey('30')) {
      subTlv = _parseTlv(tlv['30']!);
    } else if (tlv.containsKey('31')) {
      subTlv = _parseTlv(tlv['31']!);
    } else if (tlv.containsKey('00')) {
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
      // 2.2 สกัดจาก Sub-Tag 02 ของ Tag 00 ในมาตรฐาน BOT Slip Verification
      final rawSub02 = subTlv['02']!;
      final subRefMatch = RegExp(r'(202\d(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\d{4}\d{6})').firstMatch(rawSub02);
      if (subRefMatch != null) {
        referenceNo = subRefMatch.group(1);
      } else {
        referenceNo = rawSub02;
      }
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

    // สกัดวันที่และเวลาทำรายการตามมาตรฐาน BOT Slip Verification (Tag 00, Sub-Tag 02)
    DateTime date = DateTime.now();
    bool hasDate = false;

    if (subTlv != null && subTlv.containsKey('02') && subTlv['02']!.isNotEmpty) {
      final sub02 = subTlv['02']!;
      // รูปแบบมาตรฐาน BOT PromptPay: DD HH MM SS YYYY MM DD ... เช่น 11123510202609110006992211
      final botPattern = RegExp(r'^(\d{2})(\d{2})(\d{2})(\d{2})(202\d)(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])');
      final botMatch = botPattern.firstMatch(sub02);
      if (botMatch != null) {
        final h = int.tryParse(botMatch.group(2)!);
        final min = int.tryParse(botMatch.group(3)!);
        final s = int.tryParse(botMatch.group(4)!);
        final y = int.tryParse(botMatch.group(5)!);
        final m = int.tryParse(botMatch.group(6)!);
        final d = int.tryParse(botMatch.group(7)!);
        if (y != null && m != null && d != null && h != null && min != null && s != null) {
          if (h >= 0 && h <= 23 && min >= 0 && min <= 59 && s >= 0 && s <= 59) {
            date = DateTime(y, m, d, h, min, s);
            hasDate = true;
          }
        }
      }

      // รูปแบบ YYYYMMDDHHMMSS เช่น 20260911123510...
      if (!hasDate) {
        final ymdHms = RegExp(r'^(202\d)(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])([01]\d|2[0-3])([0-5]\d)([0-5]\d)').firstMatch(sub02);
        if (ymdHms != null) {
          final y = int.tryParse(ymdHms.group(1)!);
          final m = int.tryParse(ymdHms.group(2)!);
          final d = int.tryParse(ymdHms.group(3)!);
          final h = int.tryParse(ymdHms.group(4)!);
          final min = int.tryParse(ymdHms.group(5)!);
          final s = int.tryParse(ymdHms.group(6)!);
          if (y != null && m != null && d != null && h != null && min != null && s != null) {
            date = DateTime(y, m, d, h, min, s);
            hasDate = true;
          }
        }
      }
    }

    // กรณีรหัสอ้างอิงเริ่มต้นด้วยปี ค.ศ. 202x (YYYYMMDD) แต่ไม่มีเวลา
    if (!hasDate && referenceNo != null && referenceNo.length >= 8 && referenceNo.startsWith('202')) {
      final y = int.tryParse(referenceNo.substring(0, 4));
      final m = int.tryParse(referenceNo.substring(4, 6));
      final d = int.tryParse(referenceNo.substring(6, 8));
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        date = DateTime(y, m, d);
        hasDate = true;
      }
    }

    // ตรวจจับชื่อธนาคารจาก Sub-Tag 01 (Sending Bank Code) หรือ Sub-Tag 02
    String bankName = 'ธนาคารกรุงไทย (Krungthai NEXT)';
    if (lower.contains('paotang') || lower.contains('เป๋าตัง')) {
      bankName = 'ธนาคารกรุงไทย (เป๋าตัง)';
    } else if (subTlv != null && subTlv['02'] != null && subTlv['02']!.contains('0006')) {
      bankName = 'ธนาคารกรุงไทย (Krungthai NEXT)';
    } else if (subTlv != null && subTlv['01'] != null) {
      final val01 = subTlv['01']!;
      if (thaiBankCodes.containsKey(val01)) {
        bankName = thaiBankCodes[val01]!;
      } else if (val01.length >= 3 && thaiBankCodes.containsKey(val01.substring(0, 3))) {
        bankName = thaiBankCodes[val01.substring(0, 3)]!;
      }
    } else if (subTlv != null && subTlv['02'] != null) {
      final s02 = subTlv['02']!;
      if (s02.contains('0004')) {
        bankName = 'ธนาคารกสิกรไทย (K PLUS)';
      } else if (s02.contains('0014')) {
        bankName = 'ธนาคารไทยพาณิชย์ (SCB EASY)';
      } else if (s02.contains('0002')) {
        bankName = 'ธนาคารกรุงเทพ (Bualuang mBanking)';
      } else if (s02.contains('0025')) {
        bankName = 'ธนาคารกรุงศรีอยุธยา (KMA)';
      } else if (s02.contains('0011')) {
        bankName = 'ทีเอ็มบีธนชาต (ttb touch)';
      } else if (s02.contains('0030')) {
        bankName = 'ธนาคารออมสิน (MyMo)';
      } else if (s02.contains('0034')) {
        bankName = 'ธ.ก.ส. (BAAC Mobile)';
      }
    }

    final isKtb = bankName.contains('กรุงไทย') || bankName.contains('เป๋าตัง');

    final prediction = SlipCategoryPredictor.predict(
      fullText: qrText,
      amount: amount,
      transactionDate: date,
    );

    return KrungthaiSlipData(
      amount: amount,
      transactionDate: date,
      referenceNo: referenceNo,
      bankName: bankName,
      isKrungthai: isKtb,
      suggestedCategory: prediction.category,
      suggestedCostNature: prediction.costNature,
      suggestedType: prediction.type,
      rawText: qrText,
      hasParsedDateTime: hasDate,
      predictionConfidence: prediction.confidence,
      predictionReason: prediction.reason.isNotEmpty ? prediction.reason : 'สแกน QR Code',
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
