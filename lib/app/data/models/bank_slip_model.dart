import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import 'transaction_model.dart';

/// โมเดลข้อมูลสลิปโอนเงินธนาคารไทยทุกแห่ง (K PLUS, SCB EASY, Krungthai NEXT, เป๋าตัง, Bualuang, ttb, MyMo, BAAC ฯลฯ)
class BankSlipData {
  final double amount;
  final DateTime transactionDate;
  final String? senderName;
  final String? senderAccount;
  final String? receiverName;
  final String? receiverAccount;
  final String? referenceNo;
  final String? memo;
  final String bankName;
  final bool isKrungthai;
  final String suggestedCategory;
  final TransactionType suggestedType;
  final CostNature suggestedCostNature;
  final String rawText;
  final bool hasParsedDateTime;

  /// ระบุว่าพบเวลา (Hour:Minute) จากสลิปจริงหรือไม่ (ป้องกันสับสนกับค่าเริ่มต้น 00:00:00)
  final bool hasParsedTime;

  /// ความมั่นใจในการทำนายหมวดหมู่ 0.0–1.0 (จาก SlipCategoryPredictor)
  final double predictionConfidence;

  /// เหตุผลสั้นๆ ที่ระบบแนะนำหมวดหมู่นี้
  final String predictionReason;

  /// รายการสินค้าที่ตรวจพบจากใบเสร็จ (เช่น 7-Eleven, ซูเปอร์มาร์เก็ต)
  final List<String> receiptItems;

  const BankSlipData({
    required this.amount,
    required this.transactionDate,
    this.senderName,
    this.senderAccount,
    this.receiverName,
    this.receiverAccount,
    this.referenceNo,
    this.memo,
    required this.bankName,
    required this.isKrungthai,
    required this.suggestedCategory,
    required this.suggestedType,
    required this.suggestedCostNature,
    required this.rawText,
    required this.hasParsedDateTime,
    required this.hasParsedTime,
    required this.predictionConfidence,
    required this.predictionReason,
    this.receiptItems = const [],
  });

  /// สร้างสำเนาที่มีค่าบางฟิลด์ถูกแทนที่ (สำหรับ history-based enhancement)
  BankSlipData copyWith({
    double? amount,
    DateTime? transactionDate,
    String? senderName,
    String? senderAccount,
    String? receiverName,
    String? receiverAccount,
    String? referenceNo,
    String? memo,
    String? bankName,
    bool? isKrungthai,
    String? suggestedCategory,
    TransactionType? suggestedType,
    CostNature? suggestedCostNature,
    String? rawText,
    bool? hasParsedDateTime,
    bool? hasParsedTime,
    double? predictionConfidence,
    String? predictionReason,
    List<String>? receiptItems,
  }) {
    return BankSlipData(
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      senderName: senderName ?? this.senderName,
      senderAccount: senderAccount ?? this.senderAccount,
      receiverName: receiverName ?? this.receiverName,
      receiverAccount: receiverAccount ?? this.receiverAccount,
      referenceNo: referenceNo ?? this.referenceNo,
      memo: memo ?? this.memo,
      bankName: bankName ?? this.bankName,
      isKrungthai: isKrungthai ?? this.isKrungthai,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      suggestedType: suggestedType ?? this.suggestedType,
      suggestedCostNature: suggestedCostNature ?? this.suggestedCostNature,
      rawText: rawText ?? this.rawText,
      hasParsedDateTime: hasParsedDateTime ?? this.hasParsedDateTime,
      hasParsedTime: hasParsedTime ?? this.hasParsedTime,
      predictionConfidence: predictionConfidence ?? this.predictionConfidence,
      predictionReason: predictionReason ?? this.predictionReason,
      receiptItems: receiptItems ?? this.receiptItems,
    );
  }

  /// ตรวจสอบว่าเป็นใบเสร็จ 7-Eleven หรือไม่
  bool get is7Eleven {
    final lowerBank = bankName.toLowerCase();
    final lowerRaw = rawText.toLowerCase();
    final lowerReceiver = (receiverName ?? '').toLowerCase();
    return lowerBank.contains('7-eleven') ||
        lowerBank.contains('7-11') ||
        lowerBank.contains('เซเว่น') ||
        lowerBank.contains('ซีพี ออลล์') ||
        lowerBank.contains('ซีพีออลล์') ||
        lowerReceiver.contains('7-eleven') ||
        lowerReceiver.contains('ซีพี ออลล์') ||
        lowerRaw.contains('7-eleven') ||
        lowerRaw.contains('7-11') ||
        lowerRaw.contains('เซเว่น') ||
        lowerRaw.contains('ซีพี ออลล์') ||
        lowerRaw.contains('cp all') ||
        lowerRaw.contains('cpall');
  }

  /// ตรวจสอบว่าเป็นใบเสร็จรับเงินทั่วไปหรือไม่
  bool get isReceipt {
    final lowerBank = bankName.toLowerCase();
    final lowerRaw = rawText.toLowerCase();
    return is7Eleven ||
        lowerBank.contains('ใบเสร็จ') ||
        lowerBank.contains('receipt') ||
        lowerRaw.contains('ใบเสร็จรับเงิน') ||
        lowerRaw.contains('ใบกำกับภาษีอย่างย่อ') ||
        receiptItems.isNotEmpty;
  }

  /// ดึงรหัสภาษาปัจจุบันของแอปพลิเคชันอย่างแม่นยำ (th หรือ en)
  static String get _currentAppLanguage {
    try {
      if (Get.isRegistered<DashboardController>()) {
        final ctrl = Get.find<DashboardController>();
        final lang = ctrl.currentLanguage.value.trim().toLowerCase();
        if (lang == 'en' || lang == 'th') return lang;
      }
    } catch (_) {}
    try {
      final loc = Get.locale?.languageCode.trim().toLowerCase();
      if (loc == 'en' || loc == 'th') return loc!;
    } catch (_) {}
    try {
      final sysLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      if (sysLang == 'en' || sysLang == 'th') return sysLang;
    } catch (_) {}
    return 'th';
  }

  /// ชื่อรายการเริ่มต้นที่กระชับและเข้าใจง่าย (รองรับทั้งภาษาไทยและอังกฤษตามภาษาปัจจุบันของแอป)
  String get defaultTitle => getPredictedTitle();

  /// ทำนายชื่อรายการโดยอ้างอิงภาษาปัจจุบันของแอปพลิเคชัน (th หรือ en) พร้อมแยกแยะประเภทบุคคล/ร้านค้าอย่างแม่นยำ
  String getPredictedTitle({String? langCode, TransactionType? type}) {
    final effectiveLang = (langCode != null && langCode.trim().isNotEmpty)
        ? langCode.trim().toLowerCase()
        : _currentAppLanguage;
    final isEnglish = effectiveLang == 'en';
    final activeType = type ?? suggestedType;

    // ── 0. กรณีใบเสร็จรับเงิน 7-Eleven หรือร้านค้าปลีก (Retail / 7-Eleven Receipts) ──
    // กำหนดชื่อรายการอย่างเป็นระบบ ไม่ให้ข้อความ memo หรือชื่อรายการชิ้นแรกที่สับสนมากลืนชื่อรายการทั้งหมด
    if (is7Eleven) {
      // ดึงข้อมูลสาขาที่สะอาด (ถ้ามี)
      String? cleanBranch;
      if (receiverName != null && receiverName!.isNotEmpty) {
        final rName = receiverName!;
        final bMatch = RegExp(r'(?:สาขา|Branch|Store\s*#?)\s*([0-9A-Za-zก-๙\s\.\-_]+)', caseSensitive: false).firstMatch(rName);
        if (bMatch != null) {
          final bText = bMatch.group(1)?.trim() ?? '';
          if (bText.isNotEmpty && !bText.contains('ซีพี') && !bText.contains('cp all')) {
            cleanBranch = isEnglish ? 'Branch $bText' : 'สาขา $bText';
          }
        }
      }

      final storeLabel = cleanBranch != null ? '7-Eleven $cleanBranch' : '7-Eleven';

      // กรณีมีสินค้าหลายรายการ (> 1)
      if (receiptItems.length > 1) {
        return isEnglish
            ? '$storeLabel (${receiptItems.length} items)'
            : 'slip_receipt_multiple_items'.trParams({
                'store': storeLabel,
                'count': '${receiptItems.length}',
              });
      }

      // กรณีมีสินค้าชิ้นเดียว (= 1)
      if (receiptItems.length == 1) {
        final item = receiptItems.first.trim();
        return '$storeLabel - $item';
      }

      // กรณีตรวจไม่พบรายการย่อย ให้ใช้ชื่อร้านพร้อมสาขา
      return storeLabel;
    }

    // กรณีใบเสร็จร้านค้าอื่นที่มีรายการสินค้า
    if (isReceipt && receiptItems.isNotEmpty) {
      final storeName = (receiverName != null && receiverName!.trim().isNotEmpty)
          ? receiverName!.trim()
          : bankName;
      if (receiptItems.length > 1) {
        return isEnglish
            ? '$storeName (${receiptItems.length} items)'
            : 'slip_receipt_multiple_items'.trParams({
                'store': storeName,
                'count': '${receiptItems.length}',
              });
      } else {
        return '$storeName - ${receiptItems.first.trim()}';
      }
    }

    // หากผู้ใช้มีบันทึกช่วยจำที่ไม่ใช่ข้อความทั่วไปของระบบ ให้ใช้ข้อความบันทึกเป็นชื่อรายการ
    final cleanMemo = memo?.trim();
    if (cleanMemo != null && cleanMemo.isNotEmpty) {
      final lowerMemo = cleanMemo.toLowerCase();
      final isGenericMemo = lowerMemo == 'โอนเงิน' ||
          lowerMemo == 'เงินโอน' ||
          lowerMemo == 'พร้อมเพย์' ||
          lowerMemo == 'promptpay' ||
          lowerMemo == 'transfer' ||
          lowerMemo == 'payment' ||
          lowerMemo == 'qr payment';
      if (!isGenericMemo) {
        return cleanMemo;
      }
    }

    // กรณีเงินเข้า (Income)
    if (activeType == TransactionType.income) {
      if (senderName != null && senderName!.trim().isNotEmpty) {
        final name = senderName!.trim();
        final isOrg = _isBusinessOrOrg(name);

        var cleanName = name;
        final prefixes = [
          'รับเงินจาก ',
          'รับจาก ',
          'รายได้จาก ',
          'received from ',
          'income from ',
          'from ',
        ];
        for (final p in prefixes) {
          if (cleanName.toLowerCase().startsWith(p)) {
            cleanName = cleanName.substring(p.length).trim();
            break;
          }
        }

        return isOrg
            ? 'slip_income_from'.trParams({'name': cleanName})
            : 'slip_receive_from'.trParams({'name': cleanName});
      }

      if (suggestedCategory.isNotEmpty &&
          suggestedCategory != 'อื่นๆ' &&
          suggestedCategory != 'Other' &&
          suggestedCategory != 'Others' &&
          suggestedCategory != 'โอนเงิน/ธุรกรรม' &&
          suggestedCategory != 'Transfers & Transactions') {
        final cat = isEnglish
            ? _translateCategory(suggestedCategory)
            : _translateCategoryToThai(suggestedCategory);
        return 'slip_income_category'.trParams({'category': cat});
      }

      return 'incoming_transfer'.tr;
    }

    // กรณีเงินออก (Expense & Savings / Transfer)
    if (receiverName != null && receiverName!.trim().isNotEmpty) {
      final name = receiverName!.trim();
      final isMerchant = _isBusinessOrMerchant(name);

      var cleanName = name;
      final prefixes = [
        'โอนให้ ',
        'โอนไปยัง ',
        'จ่าย ',
        'transfer to ',
        'pay ',
        'to ',
      ];
      for (final p in prefixes) {
        if (cleanName.toLowerCase().startsWith(p)) {
          cleanName = cleanName.substring(p.length).trim();
          break;
        }
      }

      return isMerchant
          ? 'slip_pay_to'.trParams({'name': cleanName})
          : 'slip_transfer_to'.trParams({'name': cleanName});
    }

    if (suggestedCategory.isNotEmpty &&
        suggestedCategory != 'อื่นๆ' &&
        suggestedCategory != 'Other' &&
        suggestedCategory != 'Others' &&
        suggestedCategory != 'โอนเงิน/ธุรกรรม' &&
        suggestedCategory != 'Transfers & Transactions') {
      final cat = isEnglish
          ? _translateCategory(suggestedCategory)
          : _translateCategoryToThai(suggestedCategory);
      return 'slip_expense_category'.trParams({'category': cat});
    }

    return 'money_transfer'.tr;
  }

  static String _translateCategory(String category) {
    const mapped = {
      'อาหารและเครื่องดื่ม': 'Food & Dining',
      'อาหาร/ของกิน': 'Food & Dining',
      'กาแฟ/เครื่องดื่ม': 'Coffee & Drinks',
      'ช้อปปิ้ง': 'Shopping',
      'ที่อยู่อาศัย': 'Housing & Rent',
      'ค่าที่พัก/หอพัก': 'Rent & Housing',
      'การเดินทาง': 'Transportation',
      'เดินทาง': 'Transportation',
      'เดินทาง/ขนส่ง': 'Transit & Transportation',
      'สุขภาพ/ยา': 'Health & Medical',
      'สุขภาพ': 'Health & Fitness',
      'การศึกษา': 'Education & Study',
      'ความบันเทิง': 'Entertainment',
      'บันเทิง': 'Entertainment',
      'บันเทิง/พักผ่อน': 'Entertainment & Leisure',
      'การลงทุน': 'Investments',
      'เงินเดือน': 'Salary',
      'ธุรกิจ/ขายของ': 'Business & Sales',
      'ขายของ': 'Commerce & Sales',
      'ขายของ/รายได้เสริม': 'Commerce & Side Hustle',
      'ฟรีแลนซ์/งานเสริม': 'Freelance & Gig',
      'ฟรีแลนซ์': 'Freelance',
      'โบนัส': 'Bonus',
      'โอนเงิน/ธุรกรรม': 'Transfers & Transactions',
      'บิล/สาธารณูปโภค': 'Bills & Utilities',
      'สาธารณูปโภค': 'Utilities & Bills',
      'ประกันภัย': 'Insurance',
      'ท่องเที่ยว': 'Travel & Vacation',
      'บริจาค/ทำบุญ': 'Donations & Charity',
      'ของใช้ส่วนตัว': 'Personal Care',
      'ของใช้': 'Daily Goods',
      'เงินคืน/โอนคืน': 'Refunds & Returns',
      'เงินออม/DCA': 'Savings / DCA',
      'กองทุนรวม': 'Mutual Funds',
      'หุ้น': 'Stocks',
      'หุ้น/ตราสาร': 'Stocks & Bonds',
      'หุ้น/คริปโต': 'Stocks / Crypto',
      'เงินสำรองฉุกเฉิน': 'Emergency Fund',
      'สำรองฉุกเฉิน': 'Emergency Fund',
      'สินทรัพย์อื่นๆ': 'Other Assets',
      'คริปโต/สินทรัพย์ดิจิทัล': 'Crypto & Digital Assets',
      'สลากออมทรัพย์': 'Savings Lottery',
      'ทองคำ': 'Gold Assets',
      'ดอกเบี้ย/ปันผล': 'Dividends/Interest',
      'เงินปันผล/ดอกเบี้ย': 'Dividends/Interest',
      'รายรับอื่นๆ': 'Other Income',
      'อื่นๆ': 'Other',
      'Other': 'Other',
      'Others': 'Other',
    };
    if (mapped.containsKey(category)) return mapped[category]!;
    try {
      final trVal = category.tr;
      if (trVal.isNotEmpty && trVal != category) return trVal;
    } catch (_) {}
    return category;
  }

  static String _translateCategoryToThai(String category) {
    const mappedToThai = {
      'Food & Dining': 'อาหาร/ของกิน',
      'Coffee & Drinks': 'กาแฟ/เครื่องดื่ม',
      'Shopping': 'ช้อปปิ้ง',
      'Personal Care': 'ของใช้ส่วนตัว',
      'Daily Goods': 'ของใช้',
      'Housing & Rent': 'ที่อยู่อาศัย',
      'Rent & Housing': 'ค่าที่พัก/หอพัก',
      'Utilities & Bills': 'สาธารณูปโภค',
      'Bills & Utilities': 'บิล/สาธารณูปโภค',
      'Transportation': 'การเดินทาง',
      'Transit & Transportation': 'เดินทาง/ขนส่ง',
      'Health & Medical': 'สุขภาพ/ยา',
      'Health & Fitness': 'สุขภาพ',
      'Education & Study': 'การศึกษา',
      'Entertainment & Leisure': 'บันเทิง/พักผ่อน',
      'Entertainment': 'บันเทิง',
      'Investments': 'การลงทุน',
      'Savings / DCA': 'เงินออม/DCA',
      'Mutual Funds': 'กองทุนรวม',
      'Stocks': 'หุ้น',
      'Stocks & Bonds': 'หุ้น/ตราสาร',
      'Stocks / Crypto': 'หุ้น/คริปโต',
      'Savings Lottery': 'สลากออมทรัพย์',
      'Gold Assets': 'ทองคำ',
      'Emergency Fund': 'เงินสำรองฉุกเฉิน',
      'Other Assets': 'สินทรัพย์อื่นๆ',
      'Crypto & Digital Assets': 'คริปโต/สินทรัพย์ดิจิทัล',
      'Salary': 'เงินเดือน',
      'Business & Sales': 'ธุรกิจ/ขายของ',
      'Commerce & Sales': 'ขายของ',
      'Commerce & Side Hustle': 'ขายของ/รายได้เสริม',
      'Freelance & Gig': 'ฟรีแลนซ์/งานเสริม',
      'Freelance': 'ฟรีแลนซ์',
      'Bonus': 'โบนัส',
      'Dividends/Interest': 'เงินปันผล/ดอกเบี้ย',
      'Refunds & Returns': 'เงินคืน/โอนคืน',
      'Other Income': 'รายรับอื่นๆ',
      'Transfers & Transactions': 'โอนเงิน/ธุรกรรม',
      'Insurance': 'ประกันภัย',
      'Travel & Vacation': 'ท่องเที่ยว',
      'Donations & Charity': 'บริจาค/ทำบุญ',
      'Other': 'อื่นๆ',
      'Others': 'อื่นๆ',
    };
    if (mappedToThai.containsKey(category)) return mappedToThai[category]!;
    try {
      final trVal = category.tr;
      if (trVal.isNotEmpty && trVal != category) return trVal;
    } catch (_) {}
    return category;
  }

  static bool _isBusinessOrMerchant(String name) {
    final lower = name.toLowerCase();
    final businessPrefixes = [
      'ร้าน', 'บจก.', 'บริษัท', 'หจก.', 'บมจ.', 'โรงพยาบาล', 'รพ.', 'คลินิก',
      'การไฟฟ้า', 'การประปา', 'เทศบาล', 'มหาวิทยาลัย', 'โรงเรียน', 'สำนักงาน',
    ];
    final businessKeywords = [
      'co.,', 'ltd', 'limited', 'inc', 'corp', 'store', 'shop', 'market',
      'cafe', 'coffee', 'restaurant', 'express', 'shopee', 'lazada', 'grab',
      'lineman', 'foodpanda', 'netflix', 'spotify', 'apple', 'google',
      '7-eleven', 'เซเว่น', 'โลตัส', 'บิ๊กซี', 'ท็อปส์', 'amazon',
    ];
    for (final prefix in businessPrefixes) {
      if (name.startsWith(prefix)) return true;
    }
    for (final kw in businessKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  static bool _isBusinessOrOrg(String name) {
    return _isBusinessOrMerchant(name) ||
        name.startsWith('กระทรวง') ||
        name.startsWith('กรม') ||
        name.startsWith('องค์การ');
  }

  /// บันทึกประกอบรายการที่มีรหัสอ้างอิงธุรกรรมกำกับ
  String get formattedNote => getFormattedNote();

  /// บันทึกประกอบรายการพร้อมระบุภาษา (th หรือ en)
  String getFormattedNote({String? langCode}) {
    final parts = <String>[];
    if (memo != null && memo!.trim().isNotEmpty) {
      parts.add('note_prefix'.trParams({'memo': memo!.trim()}));
    }
    if (suggestedType == TransactionType.income && senderName != null && senderName!.trim().isNotEmpty) {
      parts.add('sender_prefix'.trParams({'sender': senderName!.trim()}));
    }
    if (receiverName != null && receiverName!.trim().isNotEmpty) {
      parts.add('receiver_prefix'.trParams({'receiver': receiverName!.trim()}));
    }
    if (referenceNo != null && referenceNo!.trim().isNotEmpty) {
      parts.add('ref_prefix'.trParams({'ref': referenceNo!.trim()}));
    }
    parts.add('slip_prefix'.trParams({'slip': bankName}));
    return parts.join(' | ');
  }

  /// แปลงข้อมูลสลิปเป็น TransactionItem สำหรับบันทึกลงระบบ (รองรับการกำหนดวันและเวลาที่บันทึกรายการ)
  TransactionItem toTransactionItem({
    double? customAmount,
    String? customTitle,
    String? customCategory,
    TransactionType? customType,
    CostNature? customCostNature,
    DateTime? customDate,
    DateTime? customTime,
    TimeOfDay? customTimeOfDay,
    String? langCode,
  }) {
    final type = customType ?? suggestedType;
    final costNature = type == TransactionType.expense
        ? (customCostNature ?? suggestedCostNature)
        : CostNature.notApplicable;

    final idPrefix = isKrungthai ? 'ktb' : 'slip';

    DateTime resolvedDate = customDate ?? transactionDate;
    if (customTime != null) {
      resolvedDate = DateTime(
        resolvedDate.year,
        resolvedDate.month,
        resolvedDate.day,
        customTime.hour,
        customTime.minute,
        customTime.second,
      );
    } else if (customTimeOfDay != null) {
      resolvedDate = DateTime(
        resolvedDate.year,
        resolvedDate.month,
        resolvedDate.day,
        customTimeOfDay.hour,
        customTimeOfDay.minute,
      );
    }

    return TransactionItem(
      id: referenceNo != null && referenceNo!.isNotEmpty
          ? '${idPrefix}_${referenceNo!}'
          : '${idPrefix}_${DateTime.now().millisecondsSinceEpoch}',
      title: customTitle ?? getPredictedTitle(langCode: langCode, type: type),
      amount: customAmount ?? amount,
      type: type,
      costNature: costNature,
      categoryName: customCategory ?? suggestedCategory,
      date: resolvedDate,
      note: getFormattedNote(langCode: langCode),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'senderName': senderName,
      'senderAccount': senderAccount,
      'receiverName': receiverName,
      'receiverAccount': receiverAccount,
      'referenceNo': referenceNo,
      'memo': memo,
      'bankName': bankName,
      'isKrungthai': isKrungthai,
      'suggestedCategory': suggestedCategory,
      'suggestedType': suggestedType.name,
      'suggestedCostNature': suggestedCostNature.name,
      'rawText': rawText,
      'hasParsedDateTime': hasParsedDateTime,
      'hasParsedTime': hasParsedTime,
      'predictionConfidence': predictionConfidence,
      'predictionReason': predictionReason,
      'receiptItems': receiptItems,
    };
  }

  factory BankSlipData.fromJson(Map<String, dynamic> json) {
    return BankSlipData(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: json['transactionDate'] != null
          ? DateTime.tryParse(json['transactionDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      senderName: json['senderName'] as String?,
      senderAccount: json['senderAccount'] as String?,
      receiverName: json['receiverName'] as String?,
      receiverAccount: json['receiverAccount'] as String?,
      referenceNo: json['referenceNo'] as String?,
      memo: json['memo'] as String?,
      bankName: json['bankName'] as String? ?? 'ธนาคารกรุงไทย',
      isKrungthai: json['isKrungthai'] as bool? ?? true,
      suggestedCategory: json['suggestedCategory'] as String? ?? 'อื่นๆ',
      suggestedType: TransactionType.values.firstWhere(
        (e) => e.name == json['suggestedType'],
        orElse: () => TransactionType.expense,
      ),
      suggestedCostNature: CostNature.values.firstWhere(
        (e) => e.name == json['suggestedCostNature'],
        orElse: () => CostNature.variable,
      ),
      rawText: json['rawText'] as String? ?? '',
      hasParsedDateTime: json['hasParsedDateTime'] as bool? ?? false,
      hasParsedTime: json['hasParsedTime'] as bool? ?? false,
      predictionConfidence: (json['predictionConfidence'] as num?)?.toDouble() ?? 0.5,
      predictionReason: json['predictionReason'] as String? ?? '',
      receiptItems: (json['receiptItems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100% กับโค้ดเดิมที่เรียก KrungthaiSlipData
typedef KrungthaiSlipData = BankSlipData;
