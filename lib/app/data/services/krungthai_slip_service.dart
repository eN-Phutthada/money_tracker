import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/krungthai_slip_model.dart';
import '../models/transaction_model.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../widgets/app_feedback.dart';
import 'krungthai_ocr_service.dart';
import 'krungthai_qr_decoder.dart';
import 'krungthai_slip_parser.dart';
import 'slip_category_predictor.dart';
import 'storage_service.dart';

/// ผลลัพธ์การประมวลผลสลิปแบบกลุ่ม (Batch Slip Result)
class KrungthaiBatchResult {
  final List<KrungthaiSlipData> validSlips;
  final List<Map<String, dynamic>> duplicateSlips;
  final int invalidCount;
  final int totalCount;

  const KrungthaiBatchResult({
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
/// - ระบบตรวจจับสลิปใหม่อัตโนมัติจากโฟลเดอร์เป้าหมาย (Target Folder Auto-Scan)
class KrungthaiSlipService {
  static final KrungthaiSlipService _instance =
      KrungthaiSlipService._internal();
  factory KrungthaiSlipService() => _instance;
  KrungthaiSlipService._internal();

  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  final RxBool isInstantAutoSave = false.obs;

  // Folder Auto-Scan States
  final RxBool isFolderAutoScanEnabled = false.obs;
  final RxString targetFolderPath = ''.obs;
  final RxString targetFolderName = 'Krungthai NEXT'.obs;
  final Rx<DateTime?> lastScannedTime = Rx<DateTime?>(null);

  Future<void> init() async {
    final pref = await _storageService.loadSlipAutoSavePref();
    isInstantAutoSave.value = pref;

    final folderScanPref = await _storageService.loadSlipFolderAutoScanPref();
    isFolderAutoScanEnabled.value = folderScanPref;

    final targetFolder = await _storageService.loadSlipTargetFolder();
    if (targetFolder != null && (targetFolder['path']?.isNotEmpty ?? false)) {
      targetFolderPath.value = targetFolder['path']!;
      targetFolderName.value = targetFolder['name'] ?? 'โฟลเดอร์สลิป';
    } else {
      // ค่าแนะนำเริ่มต้น
      targetFolderName.value = 'Krungthai NEXT';
      if (Platform.isAndroid) {
        targetFolderPath.value = '/storage/emulated/0/Pictures/Krungthai';
      }
    }

    lastScannedTime.value = await _storageService.loadSlipLastScannedTime();
  }

  Future<void> toggleAutoSave(bool value) async {
    isInstantAutoSave.value = value;
    await _storageService.saveSlipAutoSavePref(value);
  }

  Future<void> toggleFolderAutoScan(bool value) async {
    isFolderAutoScanEnabled.value = value;
    await _storageService.saveSlipFolderAutoScanPref(value);
  }

  Future<void> setTargetFolder({
    required String path,
    required String name,
  }) async {
    targetFolderPath.value = path;
    targetFolderName.value = name;
    await _storageService.saveSlipTargetFolder(path, name);
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
  Future<KrungthaiBatchResult> processBatchImages(
    List<XFile> files, {
    List<TransactionItem>? existingTransactions,
    void Function(int current, int total)? onProgress,
  }) async {
    final validSlips = <KrungthaiSlipData>[];
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
        final duplicate = KrungthaiSlipParser.findDuplicateTransaction(
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

    return KrungthaiBatchResult(
      validSlips: validSlips,
      duplicateSlips: duplicateSlips,
      invalidCount: invalidCount,
      totalCount: files.length,
    );
  }

  /// ตรวจหาสลิปใหม่ในโฟลเดอร์เป้าหมาย
  Future<List<KrungthaiSlipData>> scanTargetFolderForNewSlips({
    List<TransactionItem>? existingTransactions,
  }) async {
    if (!isFolderAutoScanEnabled.value ||
        targetFolderPath.value.trim().isEmpty) {
      return [];
    }

    try {
      final dir = Directory(targetFolderPath.value.trim());
      if (!await dir.exists()) return [];

      final entities = await dir.list().toList();
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      final imageFiles = entities.whereType<File>().where((f) {
        final lower = f.path.toLowerCase();
        return imageExtensions.any((ext) => lower.endsWith(ext));
      }).toList();

      if (imageFiles.isEmpty) return [];

      // เรียงลำดับจากรูปที่แก้ไขล่าสุด
      imageFiles.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      // ตรวจสอบรูปภาพล่าสุดไม่เกิน 8 รูปล่าสุดเพื่อความรวดเร็ว
      final recentFiles = imageFiles.take(8).toList();
      final lastScan = lastScannedTime.value;

      final filesToProcess = recentFiles.where((f) {
        if (lastScan == null) return true;
        return f.lastModifiedSync().isAfter(lastScan);
      }).toList();

      if (filesToProcess.isEmpty) return [];

      final transactions =
          existingTransactions ??
          (Get.isRegistered<DashboardController>()
              ? Get.find<DashboardController>().transactions
              : <TransactionItem>[]);

      final newSlips = <KrungthaiSlipData>[];

      for (final f in filesToProcess) {
        final slip = await processSlipImage(XFile(f.path));
        if (slip != null) {
          final isDup = KrungthaiSlipParser.isDuplicate(slip, transactions);
          if (!isDup) {
            newSlips.add(slip);
          }
        }
      }

      // บันทึกเวลาที่สแกนล่าสุด
      final now = DateTime.now();
      lastScannedTime.value = now;
      await _storageService.saveSlipLastScannedTime(now);

      return newSlips;
    } catch (_) {
      return [];
    }
  }

  /// ตัวเลือกโฟลเดอร์สลิปแนะนำยอดนิยมสำหรับผู้ใช้ (เน้นกรุงไทยเป็นหลัก พร้อมรองรับธนาคารอื่น)
  static List<Map<String, String>> getRecommendedFolderPresets() {
    return [
      {
        'id': 'ktb_next',
        'name': 'Krungthai NEXT (หลัก)',
        'defaultPath': '/storage/emulated/0/Pictures/Krungthai NEXT',
        'subtitle': 'โฟลเดอร์สลิปอัตโนมัติจากแอป Krungthai NEXT (แนะนำ)',
      },
      {
        'id': 'paotang',
        'name': 'เป๋าตัง (Paotang Pay)',
        'defaultPath': '/storage/emulated/0/Pictures/เป๋าตัง',
        'subtitle': 'โฟลเดอร์สลิปอัตโนมัติจากแอปเป๋าตัง G-Wallet',
      },
      {
        'id': 'kplus',
        'name': 'K PLUS (กสิกรไทย)',
        'defaultPath': '/storage/emulated/0/Pictures/K PLUS',
        'subtitle': 'โฟลเดอร์สลิปอัตโนมัติจากแอป K PLUS',
      },
      {
        'id': 'scbeasy',
        'name': 'SCB EASY (ไทยพาณิชย์)',
        'defaultPath': '/storage/emulated/0/Pictures/SCB EASY',
        'subtitle': 'โฟลเดอร์สลิปอัตโนมัติจากแอป SCB EASY',
      },
      {
        'id': 'screenshots',
        'name': 'ภาพหน้าจอ (Screenshots)',
        'defaultPath': '/storage/emulated/0/DCIM/Screenshots',
        'subtitle': 'อัลบั้มภาพบันทึกหน้าจอสำหรับผู้ที่แคปภาพสลิปทุกธนาคาร',
      },
    ];
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
  Future<KrungthaiSlipData?> processSlipImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();

      DateTime? fileModTime;
      try {
        fileModTime = await file.lastModified();
      } catch (_) {}

      // 1. ลองถอดรหัส QR Code บนสลิปด้วย Pure Dart Engine
      String? qrString;
      try {
        qrString = await KrungthaiQrDecoder.decodeQrFromImageBytes(bytes);
      } catch (_) {}

      KrungthaiSlipData? qrSlip;
      if (qrString != null) {
        qrSlip = KrungthaiQrDecoder.parsePromptPaySlipQr(qrString);
      }

      // 2. ลองอ่านข้อความผ่าน Mobile On-Device OCR
      String? ocrText;
      try {
        ocrText = await KrungthaiOcrService.recognizeTextFromImage(file.path);
      } catch (_) {}

      KrungthaiSlipData? ocrSlip;
      if (ocrText != null && ocrText.trim().isNotEmpty) {
        ocrSlip = KrungthaiSlipParser.parse(ocrText);
      }

      KrungthaiSlipData? result;
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

        result = KrungthaiSlipData(
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
  static DateTime resolveAccurateDateTime({
    KrungthaiSlipData? qrSlip,
    KrungthaiSlipData? ocrSlip,
    DateTime? fileModTime,
  }) {
    // 1. ตรวจสอบว่าแต่ละแหล่งข้อมูลมีเวลาที่เจาะจง (ไม่ใช่ 00:00:00) หรือไม่
    final ocrHasTime = ocrSlip != null &&
        ocrSlip.hasParsedDateTime &&
        (ocrSlip.transactionDate.hour != 0 ||
            ocrSlip.transactionDate.minute != 0 ||
            ocrSlip.transactionDate.second != 0);

    final qrHasTime = qrSlip != null &&
        qrSlip.hasParsedDateTime &&
        (qrSlip.transactionDate.hour != 0 ||
            qrSlip.transactionDate.minute != 0 ||
            qrSlip.transactionDate.second != 0);

    // 2. เลือกวันที่ (ปี, เดือน, วัน)
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
    } else if (fileModTime != null) {
      year = fileModTime.year;
      month = fileModTime.month;
      day = fileModTime.day;
    } else {
      final now = DateTime.now();
      year = now.year;
      month = now.month;
      day = now.day;
    }

    // 3. เลือกเวลา (ชั่วโมง, นาที, วินาที)
    int hour = 0;
    int minute = 0;
    int second = 0;

    if (ocrHasTime) {
      hour = ocrSlip.transactionDate.hour;
      minute = ocrSlip.transactionDate.minute;
      second = ocrSlip.transactionDate.second;
    } else if (qrHasTime) {
      hour = qrSlip.transactionDate.hour;
      minute = qrSlip.transactionDate.minute;
      second = qrSlip.transactionDate.second;
    } else if (fileModTime != null) {
      // หาก OCR/QR ไม่มีเวลา แต่มีเวลาของไฟล์ภาพ ให้ใช้เวลาของไฟล์ภาพ
      hour = fileModTime.hour;
      minute = fileModTime.minute;
      second = fileModTime.second;
    }

    return DateTime(year, month, day, hour, minute, second);
  }

  /// นำประวัติรายการธุรกรรมในระบบมาช่วยเพิ่มความแม่นยำในการทำนายหมวดหมู่ (History-Based Learning)
  KrungthaiSlipData enrichWithHistory(KrungthaiSlipData slip) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        final controller = Get.find<DashboardController>();
        final history = controller.transactions;
        if (history.isNotEmpty) {
          final prediction = SlipCategoryPredictor.predict(
            memo: slip.memo,
            receiverName: slip.receiverName,
            fullText: slip.rawText,
            amount: slip.amount,
            transactionDate: slip.transactionDate,
            history: history,
          );
          if (prediction.confidence >= slip.predictionConfidence) {
            return slip.copyWith(
              suggestedCategory: prediction.category,
              suggestedType: prediction.type,
              suggestedCostNature: prediction.costNature,
              predictionConfidence: prediction.confidence,
              predictionReason: prediction.reason,
            );
          }
        }
      }
    } catch (_) {}
    return slip;
  }

  /// แปลงข้อความสลิปเป็น `KrungthaiSlipData`
  KrungthaiSlipData parseSlipText(String text) {
    final parsed = KrungthaiSlipParser.parse(text);
    return enrichWithHistory(parsed);
  }

  /// บันทึกรายการสลิปลงระบบ (รองรับทั้งโหมดทันทีและแก้ไขก่อน)
  TransactionItem saveSlipTransaction(
    KrungthaiSlipData slip, {
    double? customAmount,
    String? customTitle,
    String? customCategory,
    TransactionType? customType,
    CostNature? customCostNature,
    DateTime? customDate,
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
    ];
  }
}
