import 'package:get/get.dart';
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

  /// เหตุผลสั้นๆ ที่ระบบทำนายหมวดหมู่นี้ สำหรับแสดง UI
  final String predictionReason;

  const BankSlipData({
    required this.amount,
    required this.transactionDate,
    this.senderName,
    this.senderAccount,
    this.receiverName,
    this.receiverAccount,
    this.referenceNo,
    this.memo,
    this.bankName = 'ธนาคารกรุงไทย',
    this.isKrungthai = true,
    this.suggestedCategory = 'อื่นๆ',
    this.suggestedType = TransactionType.expense,
    this.suggestedCostNature = CostNature.variable,
    this.rawText = '',
    this.hasParsedDateTime = false,
    this.hasParsedTime = false,
    this.predictionConfidence = 0.5,
    this.predictionReason = '',
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
    );
  }

  /// ชื่อรายการเริ่มต้นที่กระชับและเข้าใจง่าย (รองรับทั้งภาษาไทยและอังกฤษตามภาษาปัจจุบันของแอป)
  String get defaultTitle => getPredictedTitle();

  /// ทำนายชื่อรายการโดยอ้างอิงภาษาที่เลือก (th หรือ en) พร้อมแยกแยะประเภทบุคคล/ร้านค้าอย่างแม่นยำ
  String getPredictedTitle({String? langCode}) {
    // กำหนดภาษาโดยดูจาก langCode หรือตรวจจับจากภาษาของสลิป/ชื่อคู่กรณีเป็นหลัก
    final hasThaiChar = (receiverName?.contains(RegExp(r'[\u0E00-\u0E7F]')) ?? false) ||
        (senderName?.contains(RegExp(r'[\u0E00-\u0E7F]')) ?? false) ||
        rawText.contains(RegExp(r'[\u0E00-\u0E7F]')) ||
        bankName.contains(RegExp(r'[\u0E00-\u0E7F]'));

    final effectiveLang = langCode?.toLowerCase() ??
        (hasThaiChar ? 'th' : (Get.locale?.languageCode.toLowerCase() ?? 'th'));
    final isEnglish = effectiveLang == 'en';

    if (memo != null && memo!.trim().isNotEmpty) {
      return memo!.trim();
    }

    if (suggestedType == TransactionType.income) {
      if (senderName != null && senderName!.trim().isNotEmpty) {
        final name = senderName!.trim();
        if (isEnglish) {
          if (name.toLowerCase().startsWith('from ') ||
              name.toLowerCase().startsWith('received from ')) {
            return name;
          }
          final isOrg = _isBusinessOrOrg(name);
          return isOrg ? 'Income from $name' : 'Received from $name';
        } else {
          if (name.startsWith('รับจาก') || name.startsWith('รับเงินจาก')) {
            return name;
          }
          final isOrg = _isBusinessOrOrg(name);
          return isOrg ? 'รายได้จาก $name' : 'รับเงินจาก $name';
        }
      }
      if (suggestedCategory.isNotEmpty &&
          suggestedCategory != 'อื่นๆ' &&
          suggestedCategory != 'โอนเงิน/ธุรกรรม') {
        if (isEnglish) {
          final translatedCat = _translateCategory(suggestedCategory);
          return 'Income: $translatedCat';
        } else {
          return 'เงินได้ $suggestedCategory';
        }
      }
      return isEnglish ? 'Incoming Transfer' : 'เงินโอนเข้า';
    }

    // Expense & Savings / Transfer
    if (receiverName != null && receiverName!.trim().isNotEmpty) {
      final name = receiverName!.trim();
      final isMerchant = _isBusinessOrMerchant(name);

      if (isEnglish) {
        if (name.toLowerCase().startsWith('to ') ||
            name.toLowerCase().startsWith('transfer to ') ||
            name.toLowerCase().startsWith('pay ')) {
          return name;
        }
        return isMerchant ? 'Pay $name' : 'Transfer to $name';
      } else {
        if (name.startsWith('โอนให้') ||
            name.startsWith('โอนไปยัง') ||
            name.startsWith('จ่าย')) {
          return name;
        }
        // สอดคล้องกับพฤติกรรมภาษาไทยที่เป็นธรรมชาติ
        if (name.startsWith('ร้าน ')) {
          return 'จ่าย $name';
        }
        return 'โอนให้ $name';
      }
    }

    if (suggestedCategory.isNotEmpty &&
        suggestedCategory != 'อื่นๆ' &&
        suggestedCategory != 'โอนเงิน/ธุรกรรม') {
      if (isEnglish) {
        return _translateCategory(suggestedCategory);
      } else {
        return 'ค่า$suggestedCategory';
      }
    }

    return isEnglish ? 'Money Transfer' : 'รายการโอนเงิน';
  }

  static String _translateCategory(String category) {
    const mapped = {
      'อาหารและเครื่องดื่ม': 'Food & Dining',
      'ช้อปปิ้ง': 'Shopping',
      'ที่อยู่อาศัย': 'Housing',
      'การเดินทาง': 'Transportation',
      'สุขภาพ/ยา': 'Healthcare & Medical',
      'การศึกษา': 'Education',
      'ความบันเทิง': 'Entertainment',
      'การลงทุน': 'Investments',
      'เงินเดือน': 'Salary',
      'ธุรกิจ/ขายของ': 'Business & Sales',
      'โอนเงิน/ธุรกรรม': 'Transfers',
      'บิล/สาธารณูปโภค': 'Bills & Utilities',
      'ประกันภัย': 'Insurance',
      'ท่องเที่ยว': 'Travel & Vacation',
      'บริจาค/ทำบุญ': 'Donations & Charity',
      'ของใช้ส่วนตัว': 'Personal Care',
      'อื่นๆ': 'Others',
    };
    if (mapped.containsKey(category)) return mapped[category]!;
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
  String get formattedNote {
    final parts = <String>[];
    if (memo != null && memo!.trim().isNotEmpty) {
      parts.add('บันทึก: ${memo!.trim()}');
    }
    if (suggestedType == TransactionType.income && senderName != null && senderName!.trim().isNotEmpty) {
      parts.add('ผู้โอน: ${senderName!.trim()}');
    }
    if (receiverName != null && receiverName!.trim().isNotEmpty) {
      parts.add('ผู้รับ: ${receiverName!.trim()}');
    }
    if (referenceNo != null && referenceNo!.trim().isNotEmpty) {
      parts.add('รหัสอ้างอิง: ${referenceNo!.trim()}');
    }
    parts.add('สลิป: $bankName');
    return parts.join(' | ');
  }

  /// แปลงข้อมูลสลิปเป็น TransactionItem สำหรับบันทึกลงระบบ
  TransactionItem toTransactionItem({
    double? customAmount,
    String? customTitle,
    String? customCategory,
    TransactionType? customType,
    CostNature? customCostNature,
    DateTime? customDate,
  }) {
    final type = customType ?? suggestedType;
    final costNature = type == TransactionType.expense
        ? (customCostNature ?? suggestedCostNature)
        : CostNature.notApplicable;

    final idPrefix = isKrungthai ? 'ktb' : 'slip';

    return TransactionItem(
      id: referenceNo != null && referenceNo!.isNotEmpty
          ? '${idPrefix}_${referenceNo!}'
          : '${idPrefix}_${DateTime.now().millisecondsSinceEpoch}',
      title: customTitle ?? defaultTitle,
      amount: customAmount ?? amount,
      type: type,
      costNature: costNature,
      categoryName: customCategory ?? suggestedCategory,
      date: customDate ?? transactionDate,
      note: formattedNote,
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
    );
  }
}

/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100% กับโค้ดเดิมที่เรียก KrungthaiSlipData
typedef KrungthaiSlipData = BankSlipData;
