import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bank_slip_model.dart';
import '../models/transaction_model.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../widgets/app_feedback.dart';
import 'bank_ocr_service.dart';
import 'bank_qr_decoder.dart';
import 'bank_slip_parser.dart';
import 'config_service.dart';
import 'gemini_slip_service.dart';
import 'slip_category_predictor.dart';
import 'storage_service.dart';

/// ผลลัพธ์การประมวลผลสลิปแบบกลุ่ม (Batch Slip Result)
class BankBatchResult {
  final List<BankSlipData> validSlips;
  final List<Map<String, dynamic>> duplicateSlips;
  final int invalidCount;
  final int totalCount;

  const BankBatchResult({
    required this.validSlips,
    required this.duplicateSlips,
    required this.invalidCount,
    required this.totalCount,
  });

  int get validCount => validSlips.length;
  int get duplicateCount => duplicateSlips.length;
}

/// บริการสแกนและประมวลผลสลิปธนาคารกรุงไทย (Krungthai Slip Service)
/// รองรับทั้ง:
/// - โหมด A: ตรวจสอบและแก้ไขก่อนบันทึก (Preview & Confirm Sheet)
/// - โหมด B: บันทึกทันทีอัตโนมัติ (Instant Auto-Save) พร้อม In-App Notification และปุ่มแก้ไข
/// - ระบบสแกนแบบกลุ่ม (Batch Processing)
class BankSlipService {
  static final BankSlipService _instance =
      BankSlipService._internal();
  factory BankSlipService() => _instance;
  BankSlipService._internal();

  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  final RxBool isInstantAutoSave = false.obs;
  final RxBool isGeminiEnabled = false.obs;

  Future<void> init() async {
    await ConfigService().init();
    final pref = await _storageService.loadSlipAutoSavePref();
    isInstantAutoSave.value = pref;
    final geminiPref = await _storageService.loadGeminiEnabledPref();
    isGeminiEnabled.value = geminiPref;
  }

  Future<void> toggleAutoSave(bool value) async {
    isInstantAutoSave.value = value;
    await _storageService.saveSlipAutoSavePref(value);
  }

  Future<void> toggleGemini(bool value) async {
    isGeminiEnabled.value = value;
    await _storageService.saveGeminiEnabledPref(value);
  }

  /// เลือกรูปสลิปหลายรูปพร้อมกันจากอัลบั้ม (Multi-Image Pick)
  Future<List<XFile>> pickMultiSlipImagesFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 95);
      return images;
    } catch (_) {
      return [];
    }
  }

  /// ประมวลผลรูปภาพสลิปแบบกลุ่ม (Batch Processing)
  Future<BankBatchResult> processBatchImages(
    List<XFile> files, {
    List<TransactionItem>? existingTransactions,
    void Function(int current, int total)? onProgress,
  }) async {
    final validSlips = <BankSlipData>[];
    final duplicateSlips = <Map<String, dynamic>>[];
    int invalidCount = 0;

    final transactions =
        existingTransactions ??
        (Get.isRegistered<DashboardController>()
            ? Get.find<DashboardController>().transactions
            : <TransactionItem>[]);

    for (int i = 0; i < files.length; i++) {
      onProgress?.call(i + 1, files.length);
      final file = files[i];
      final slip = await processSlipImage(file);
      if (slip == null) {
        invalidCount++;
      } else {
        final duplicate = BankSlipParser.findDuplicateTransaction(
          slip,
          transactions,
        );
        if (duplicate != null) {
          duplicateSlips.add({'slip': slip, 'existing': duplicate});
        } else {
          validSlips.add(slip);
        }
      }
    }

    return BankBatchResult(
      validSlips: validSlips,
      duplicateSlips: duplicateSlips,
      invalidCount: invalidCount,
      totalCount: files.length,
    );
  }



  /// เลือกรูปสลิปจากอัลบั้ม (Gallery)
  Future<XFile?> pickSlipImageFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      return image;
    } catch (_) {
      return null;
    }
  }

  /// ถ่ายภาพสลิปด้วยกล้อง (Camera)
  Future<XFile?> takeSlipPhotoWithCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      return image;
    } catch (_) {
      return null;
    }
  }

  /// ประมวลผลรูปภาพสลิปจริง (ถอดรหัส QR Code + OCR Text Recognition)
  Future<BankSlipData?> processSlipImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();

      DateTime? fileModTime;
      try {
        fileModTime = await file.lastModified();
      } catch (_) {}

      String? userProfileName;
      if (Get.isRegistered<DashboardController>()) {
        final u = Get.find<DashboardController>().userName.value;
        if (u.isNotEmpty) userProfileName = u;
      }

      // 1. ลองถอดรหัส QR Code บนสลิปด้วย Pure Dart Engine
      String? qrString;
      try {
        qrString = await BankQrDecoder.decodeQrFromImageBytes(bytes);
      } catch (_) {}

      BankSlipData? qrSlip;
      if (qrString != null) {
        qrSlip = BankQrDecoder.parsePromptPaySlipQr(qrString, userProfileName: userProfileName);
      }

      // Fast-path: หาก QR Code มีข้อมูลครบถ้วน (มียอดเงิน > 0, รหัสอ้างอิง, วันที่, และมีชื่อผู้รับ/ร้านค้า)
      // สามารถส่งต่อผลลัพธ์ได้ทันทีโดยไม่ต้องรัน OCR ให้เสียเวลาและเปลืองแบตเตอรี่
      if (qrSlip != null &&
          qrSlip.amount > 0 &&
          qrSlip.hasParsedDateTime &&
          qrSlip.referenceNo != null &&
          (qrSlip.receiverName?.isNotEmpty ?? false)) {
        final finalDate = resolveAccurateDateTime(
          qrSlip: qrSlip,
          fileModTime: fileModTime,
        );
        final completedSlip = qrSlip.copyWith(
          transactionDate: finalDate,
          hasParsedDateTime: true,
          hasParsedTime: qrSlip.hasParsedTime || finalDate.hour != 0 || finalDate.minute != 0,
        );
        return enrichWithHistory(completedSlip);
      }

      // 2. ลองอ่านข้อความผ่าน Mobile On-Device OCR
      String? ocrText;
      try {
        ocrText = await BankOcrService.recognizeTextFromImage(file.path);
      } catch (_) {}

      // 3. วิเคราะห์ด้วย Gemini AI (หากผู้ใช้เปิดใช้งานตัวเลือกนี้ไว้ และมี API Key ใน config.json)
      if (isGeminiEnabled.value && ConfigService().hasGeminiKey) {
        final geminiSlip = await GeminiSlipService().analyzeSlip(
          file: file,
          existingOcrText: ocrText,
        );
        if (geminiSlip != null && geminiSlip.amount > 0) {
          final finalRef = qrSlip?.referenceNo ?? geminiSlip.referenceNo;
          final finalDate = resolveAccurateDateTime(
            qrSlip: qrSlip,
            fileModTime: fileModTime,
          );
          final fusedSlip = geminiSlip.copyWith(
            referenceNo: finalRef,
            transactionDate: geminiSlip.hasParsedTime ? geminiSlip.transactionDate : finalDate,
            hasParsedDateTime: true,
          );
          return enrichWithHistory(fusedSlip);
        }
      }

      BankSlipData? ocrSlip;
      if (ocrText != null && ocrText.trim().isNotEmpty) {
        // หากไม่มี QR Code ต้องตรวจสอบก่อนว่าเป็นสลิปธนาคารจริงเพื่อข้ามรูปภาพทั่วไปได้อย่างรวดเร็ว
        if (qrSlip != null || BankSlipParser.isValidBankSlip(ocrText)) {
          ocrSlip = BankSlipParser.parse(ocrText, userProfileName: userProfileName);
        }
      }

      BankSlipData? result;
      // 3. ผสานข้อมูล (Data Fusion) เพื่อความแม่นยำสูงสุด
      if (qrSlip != null && ocrSlip != null) {
        final qr = qrSlip;
        final ocr = ocrSlip;

        // ให้ความสำคัญกับยอดเงินจาก OCR ก่อน เพราะพิมพ์ชัดเจนบนสลิปจริง (QR ของ BOT มักไม่มี Tag 54 ยอดเงิน)
        final finalAmount = (ocr.amount > 0)
            ? ocr.amount
            : (qr.amount > 0 ? qr.amount : 0.0);
        final finalRef = qr.referenceNo ?? ocr.referenceNo;
        final finalDate = resolveAccurateDateTime(
          qrSlip: qr,
          ocrSlip: ocr,
          fileModTime: fileModTime,
        );
        final hasDateTime = ocr.hasParsedDateTime ||
            qr.hasParsedDateTime ||
            fileModTime != null;

        result = BankSlipData(
          amount: finalAmount,
          transactionDate: finalDate,
          senderName: ocr.senderName ?? qr.senderName,
          senderAccount: ocr.senderAccount ?? qr.senderAccount,
          receiverName: ocr.receiverName ?? qr.receiverName,
          receiverAccount: ocr.receiverAccount ?? qr.receiverAccount,
          referenceNo: finalRef,
          memo: ocr.memo ?? qr.memo,
          bankName: (() {
            if (!qr.isKrungthai &&
                qr.bankName != 'ธนาคารกรุงไทย (Krungthai NEXT)') {
              return qr.bankName;
            }
            if (!ocr.isKrungthai &&
                ocr.bankName != 'ธนาคารกรุงไทย (Krungthai NEXT)') {
              return ocr.bankName;
            }
            if (qr.bankName.contains('NEXT') ||
                qr.bankName.contains('เป๋าตัง')) {
              return qr.bankName;
            }
            return ocr.bankName;
          })(),
          isKrungthai: (qr.isKrungthai || ocr.isKrungthai) &&
              !ocr.bankName.contains('กสิกร') &&
              !ocr.bankName.contains('ไทยพาณิชย์') &&
              !ocr.bankName.contains('กรุงเทพ') &&
              !ocr.bankName.contains('กรุงศรี') &&
              !ocr.bankName.contains('ทหารไทย') &&
              !ocr.bankName.contains('ออมสิน') &&
              !ocr.bankName.contains('ธ.ก.ส.') &&
              !ocr.bankName.contains('เกียรตินาคิน') &&
              !ocr.bankName.contains('ยูโอบี') &&
              !ocr.bankName.contains('ทิสโก้') &&
              !ocr.bankName.contains('ซีไอเอ็มบี') &&
              !ocr.bankName.contains('TrueMoney') &&
              !qr.bankName.contains('กสิกร') &&
              !qr.bankName.contains('ไทยพาณิชย์') &&
              !qr.bankName.contains('กรุงเทพ') &&
              !qr.bankName.contains('กรุงศรี'),
          suggestedCategory: ocr.suggestedCategory,
          suggestedType: ocr.suggestedType,
          suggestedCostNature: ocr.suggestedCostNature,
          rawText:
              '${qr.rawText}\n\n-- OCR Extracted Text --\n${ocr.rawText}',
          hasParsedDateTime: hasDateTime,
          hasParsedTime: ocr.hasParsedTime ||
              qr.hasParsedTime ||
              finalDate.hour != 0 ||
              finalDate.minute != 0,
          predictionConfidence: ocr.predictionConfidence,
          predictionReason: ocr.predictionReason,
        );
      } else if (qrSlip != null) {
        // หากพบเฉพาะ QR Code
        final finalDate = resolveAccurateDateTime(
          qrSlip: qrSlip,
          fileModTime: fileModTime,
        );
        result = qrSlip.copyWith(
          transactionDate: finalDate,
          hasParsedDateTime: qrSlip.hasParsedDateTime || fileModTime != null,
          hasParsedTime: qrSlip.hasParsedTime ||
              finalDate.hour != 0 ||
              finalDate.minute != 0,
        );
      } else if (ocrSlip != null &&
          (ocrSlip.isKrungthai || ocrSlip.amount > 0)) {
        // หากพบเฉพาะ OCR Text และมีข้อมูลที่เชื่อถือได้
        final finalDate = resolveAccurateDateTime(
          ocrSlip: ocrSlip,
          fileModTime: fileModTime,
        );
        result = ocrSlip.copyWith(
          transactionDate: finalDate,
          hasParsedDateTime: ocrSlip.hasParsedDateTime || fileModTime != null,
          hasParsedTime: ocrSlip.hasParsedTime ||
              finalDate.hour != 0 ||
              finalDate.minute != 0,
        );
      }

      if (result != null) {
        return enrichWithHistory(result);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// ผสานวันและเวลาจาก QR, OCR และเวลาไฟล์ภาพอย่างแม่นยำ (Time & Date Fusion Engine)
  /// ป้องกันปัญหาเวลาอัปโหลดภาพ (Image Picker temp cache) มาทับเวลาจริงบนสลิป
  static DateTime resolveAccurateDateTime({
    BankSlipData? qrSlip,
    BankSlipData? ocrSlip,
    DateTime? fileModTime,
  }) {
    // 1. ตรวจสอบว่าแต่ละแหล่งข้อมูลมีเวลาที่เจาะจง (ผ่าน hasParsedTime หรือไม่ใช่ 00:00:00) หรือไม่
    final ocrHasTime = ocrSlip != null &&
        ocrSlip.hasParsedDateTime &&
        (ocrSlip.hasParsedTime ||
            ocrSlip.transactionDate.hour != 0 ||
            ocrSlip.transactionDate.minute != 0 ||
            ocrSlip.transactionDate.second != 0);

    final qrHasTime = qrSlip != null &&
        qrSlip.hasParsedDateTime &&
        (qrSlip.hasParsedTime ||
            qrSlip.transactionDate.hour != 0 ||
            qrSlip.transactionDate.minute != 0 ||
            qrSlip.transactionDate.second != 0);

    // ตรวจสอบว่า fileModTime เป็นเวลาแคชเพิ่งสร้างขึ้นชั่วคราวจากการอัปโหลดหรือไม่ (เช่น image_picker แคชรูปภาพ ณ เวลาปัจจุบัน)
    // หากห่างจากเวลาปัจจุบันไม่เกิน 15 นาที และเรามีวันเวลาจาก OCR หรือ QR อยู่แล้ว ห้ามนำเวลาไฟล์มาทับ
    final now = DateTime.now();
    final isTempCacheTime = fileModTime != null &&
        now.difference(fileModTime).abs().inMinutes < 15;

    // 2. เลือกวันที่ (ปี, เดือน, วัน) โดยให้ความสำคัญกับสลิปจริงก่อนเสมอ
    int year;
    int month;
    int day;

    if (ocrSlip != null && ocrSlip.hasParsedDateTime) {
      year = ocrSlip.transactionDate.year;
      month = ocrSlip.transactionDate.month;
      day = ocrSlip.transactionDate.day;
    } else if (qrSlip != null && qrSlip.hasParsedDateTime) {
      year = qrSlip.transactionDate.year;
      month = qrSlip.transactionDate.month;
      day = qrSlip.transactionDate.day;
    } else if (fileModTime != null && !isTempCacheTime) {
      year = fileModTime.year;
      month = fileModTime.month;
      day = fileModTime.day;
    } else {
      year = now.year;
      month = now.month;
      day = now.day;
    }

    // 3. เลือกเวลา (ชั่วโมง, นาที, วินาที) โดยให้ความสำคัญกับสลิปจริงก่อนเสมอ
    int hour = 0;
    int minute = 0;
    int second = 0;

    if (ocrSlip != null && ocrHasTime) {
      hour = ocrSlip.transactionDate.hour;
      minute = ocrSlip.transactionDate.minute;
      second = ocrSlip.transactionDate.second;
    } else if (qrSlip != null && qrHasTime) {
      hour = qrSlip.transactionDate.hour;
      minute = qrSlip.transactionDate.minute;
      second = qrSlip.transactionDate.second;
    }

    // 4. หากยังไม่มีเวลา ให้ลองสกัดเวลาจากรหัสอ้างอิงของสลิป (Reference Number Embedded Time)
    if (hour == 0 && minute == 0 && second == 0) {
      final refToTry = qrSlip?.referenceNo ?? ocrSlip?.referenceNo;
      if (refToTry != null && refToTry.isNotEmpty) {
        // รูปแบบ ค.ศ. หรือ พ.ศ. ตามด้วย HHMMSS เช่น ...20260912143522... หรือ ...25690912143500...
        final timeFromRef = RegExp(
          r'(?:202\d|25[6-7]\d)(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])([01]\d|2[0-3])([0-5]\d)([0-5]\d)?',
        ).firstMatch(refToTry);
        if (timeFromRef != null) {
          hour = int.tryParse(timeFromRef.group(1)!) ?? 0;
          minute = int.tryParse(timeFromRef.group(2)!) ?? 0;
          if (timeFromRef.group(3) != null) {
            second = int.tryParse(timeFromRef.group(3)!) ?? 0;
          }
        }
      }
    }

    // 5. หากสลิปและรหัสอ้างอิงไม่มีเวลาจริง ให้ใช้เวลาของไฟล์ภาพ (ป้องกันการตกเป็น 00:00:00 เที่ยงคืน)
    if (!ocrHasTime && !qrHasTime && hour == 0 && minute == 0 && second == 0 && fileModTime != null && !isTempCacheTime) {
      hour = fileModTime.hour;
      minute = fileModTime.minute;
      second = fileModTime.second;
    }

    return DateTime(year, month, day, hour, minute, second);
  }

  /// นำประวัติรายการธุรกรรมในระบบมาช่วยเพิ่มความแม่นยำในการทำนายหมวดหมู่และชื่อรายการ (History-Based Learning)
  BankSlipData enrichWithHistory(BankSlipData slip) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        final controller = Get.find<DashboardController>();
        final history = controller.transactions;
        final userProfileName = controller.userName.value.isNotEmpty ? controller.userName.value : null;
        if (history.isNotEmpty) {
          final prediction = SlipCategoryPredictor.predict(
            memo: slip.memo,
            receiverName: slip.receiverName,
            senderName: slip.senderName,
            userProfileName: userProfileName,
            fullText: slip.rawText,
            amount: slip.amount,
            transactionDate: slip.transactionDate,
            history: history,
          );

          // ตรวจสอบประวัติเพื่อค้นหาบันทึกช่วยจำ/ชื่อรายการที่เคยใช้กับผู้รับนี้ (หาก slip.memo ว่างอยู่)
          String? learnedMemo = slip.memo;
          if ((learnedMemo == null || learnedMemo.trim().isEmpty) &&
              slip.receiverName != null &&
              slip.receiverName!.trim().isNotEmpty) {
            final cleanRecv = slip.receiverName!.trim().toLowerCase();
            for (final tx in history) {
              final title = tx.title.toLowerCase();
              final note = (tx.note ?? '').toLowerCase();
              if (title.contains(cleanRecv) ||
                  (cleanRecv.length > 4 && cleanRecv.contains(title)) ||
                  note.contains(cleanRecv)) {
                if (tx.note != null && tx.note!.trim().isNotEmpty) {
                  learnedMemo = tx.note!.trim();
                  break;
                }
              }
            }
          }

          if (prediction.confidence >= slip.predictionConfidence) {
            return slip.copyWith(
              memo: learnedMemo,
              suggestedCategory: prediction.category,
              suggestedType: prediction.type,
              suggestedCostNature: prediction.costNature,
              predictionConfidence: prediction.confidence,
              predictionReason: prediction.reason,
            );
          } else if (learnedMemo != slip.memo) {
            return slip.copyWith(memo: learnedMemo);
          }
        }
      }
    } catch (_) {}
    return slip;
  }

  /// แปลงข้อความสลิปเป็น `BankSlipData`
  BankSlipData parseSlipText(String text) {
    String? userProfileName;
    if (Get.isRegistered<DashboardController>()) {
      final u = Get.find<DashboardController>().userName.value;
      if (u.isNotEmpty) userProfileName = u;
    }
    final parsed = BankSlipParser.parse(text, userProfileName: userProfileName);
    return enrichWithHistory(parsed);
  }

  /// บันทึกรายการสลิปลงระบบ (รองรับทั้งโหมดทันทีและแก้ไขก่อน)
  TransactionItem saveSlipTransaction(
    BankSlipData slip, {
    double? customAmount,
    String? customTitle,
    String? customCategory,
    TransactionType? customType,
    CostNature? customCostNature,
    DateTime? customDate,
    DateTime? customTime,
    TimeOfDay? customTimeOfDay,
    bool notify = true,
  }) {
    final controller = Get.find<DashboardController>();
    final transactionItem = slip.toTransactionItem(
      customAmount: customAmount,
      customTitle: customTitle,
      customCategory: customCategory,
      customType: customType,
      customCostNature: customCostNature,
      customDate: customDate,
      customTime: customTime,
      customTimeOfDay: customTimeOfDay,
    );

    controller.addTransaction(transactionItem, notify: false);

    if (notify && Get.context != null) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}

      AppFeedback.showSuccess(
        title: 'slip_saved_success'.tr,
        message: '${transactionItem.title} (${transactionItem.categoryName.tr})',
        amount: transactionItem.amount,
        transactionType: transactionItem.type,
      );
    }

    return transactionItem;
  }

  /// รายการสลิปตัวอย่างของธนาคารกรุงไทยสำหรับทดสอบและสาธิตระบบ
  List<Map<String, dynamic>> getSampleKrungthaiSlips() {
    return [
      {
        'title': 'โอนค่าบริการสตรีมมิ่งรายเดือน (Krungthai NEXT)',
        'description': '139.00 บาท | บจก. เอ็นเอฟ สตรีมมิ่ง',
        'rawText': '''
Krungthai
กรุงไทย
โอนเงินสำเร็จ
รหัสอ้างอิง A308e920c27594e4c

จาก
นายพุทธดา ห * * *
กรุงไทย
XXX-X-XX167-8

ไปยัง
บจก. เอ็นเอฟ สตรีมมิ่ง
พร้อมเพย์
X XXXX XXXX6 48 2

จำนวนเงิน 139.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 02 ส.ค. 2569 - 22:02
''',
      },
      {
        'title': 'โอนจ่ายค่าอาหารกลางวัน (Krungthai NEXT)',
        'description': '350.00 บาท | ร้านก๋วยเตี๋ยวเรือป้าเล็ก',
        'rawText': '''
ธนาคารกรุงไทย
Krungthai NEXT
โอนเงินสำเร็จ
11 ก.ย. 2569 12:35:10 น.
รหัสอ้างอิง: 202609110006992211

จาก: นาย ธนากร มั่งคั่ง
ธ.กรุงไทย xxx-x-xx123-x

ไปยัง: ร้านก๋วยเตี๋ยวเรือป้าเล็ก
พร้อมเพย์ 089-xxx-4567

จำนวนเงิน: 350.00 บาท
ค่าธรรมเนียม: 0.00 บาท

บันทึกช่วยจำ: ค่าอาหารกลางวันทีม
''',
      },
      {
        'title': 'โอนค่าเช่าหอพักประจำเดือน (เป๋าตัง / KTB)',
        'description': '4,500.00 บาท | นิติบุคคล อาคารชุดสุขสบาย',
        'rawText': '''
ธนาคารกรุงไทย
เป๋าตัง Pay
โอนเงินสำเร็จ
01 ก.ย. 2569 09:15:00 น.
เลขที่รายการ 202609010006778899

จาก
นาย ธนากร มั่งคั่ง
ธ.กรุงไทย xxx-x-xx123-x

ไปยัง
นิติบุคคล อาคารชุดสุขสบาย
ธ.กรุงไทย xxx-x-xx888-x

จำนวนเงิน
4,500.00 บาท
ค่าธรรมเนียม 0.00 บาท

บันทึกช่วยจำ
ค่าห้อง 502 เดือนกันยายน
''',
      },
      {
        'title': 'โอนช้อปปิ้งออนไลน์ (Krungthai NEXT)',
        'description': '1,290.00 บาท | ShopeePay Thailand',
        'rawText': '''
Krungthai NEXT
Transfer Successful
10 Sep 2026 18:42
Transaction ID: 202609100006334455

From: Mr. Thanakorn M.
To: ShopeePay Thailand
Amount: 1,290.00 THB
Fee: 0.00 THB
Memo: หูฟังบลูทูธไร้สาย
''',
      },
      {
        'title': 'ใบเสร็จ 7-Eleven (ซีพี ออลล์)',
        'description': '99.00 บาท | 7-Eleven สาขา 01234 อโศกมนตรี',
        'rawText': '''
7-ELEVEN
บมจ. ซีพี ออลล์
สาขา 01234 อโศกมนตรี
ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ
วันที่ 13/09/2569 12:45:30
R# 12345/6789 T#02

1 ข้าวกะเพราไก่ไข่ดาว 47.00
1 ชาเขียวโออิชิ 20.00
1 แซนวิชอบร้อน 32.00

รวมเงิน 99.00 บาท
เงินสด 100.00
เงินทอน 1.00

7-Eleven ขอบคุณที่ใช้บริการ
''',
      },
    ];
  }
}


/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100%
typedef KrungthaiSlipService = BankSlipService;
typedef KrungthaiBatchResult = BankBatchResult;
