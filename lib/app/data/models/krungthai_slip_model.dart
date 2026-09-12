import 'transaction_model.dart';

/// โมเดลข้อมูลสลิปโอนเงินธนาคารกรุงไทย (Krungthai NEXT / เป๋าตัง / KTB)
class KrungthaiSlipData {
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

  /// ความมั่นใจในการทำนายหมวดหมู่ 0.0–1.0 (จาก SlipCategoryPredictor)
  final double predictionConfidence;

  /// เหตุผลสั้นๆ ที่ระบบทำนายหมวดหมู่นี้ สำหรับแสดง UI
  final String predictionReason;

  const KrungthaiSlipData({
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
    this.suggestedCategory = 'อาหาร/ของกิน',
    this.suggestedType = TransactionType.expense,
    this.suggestedCostNature = CostNature.variable,
    this.rawText = '',
    this.hasParsedDateTime = false,
    this.predictionConfidence = 0.5,
    this.predictionReason = '',
  });

  /// สร้างสำเนาที่มีค่าบางฟิลด์ถูกแทนที่ (สำหรับ history-based enhancement)
  KrungthaiSlipData copyWith({
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
    double? predictionConfidence,
    String? predictionReason,
  }) {
    return KrungthaiSlipData(
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
      predictionConfidence: predictionConfidence ?? this.predictionConfidence,
      predictionReason: predictionReason ?? this.predictionReason,
    );
  }

  /// ชื่อรายการเริ่มต้นที่กระชับและเข้าใจง่าย
  String get defaultTitle {
    if (memo != null && memo!.trim().isNotEmpty) {
      return memo!.trim();
    }
    if (receiverName != null && receiverName!.trim().isNotEmpty) {
      return 'โอนให้ ${receiverName!.trim()}';
    }
    return 'โอนเงินกรุงไทย';
  }

  /// บันทึกประกอบรายการที่มีรหัสอ้างอิงธุรกรรมกำกับ
  String get formattedNote {
    final parts = <String>[];
    if (memo != null && memo!.trim().isNotEmpty) {
      parts.add('บันทึก: ${memo!.trim()}');
    }
    if (receiverName != null && receiverName!.trim().isNotEmpty) {
      parts.add('ผู้รับ: ${receiverName!.trim()}');
    }
    if (referenceNo != null && referenceNo!.trim().isNotEmpty) {
      parts.add('รหัสอ้างอิง: ${referenceNo!.trim()}');
    }
    parts.add('สลิป: ธนาคารกรุงไทย');
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

    return TransactionItem(
      id: referenceNo != null && referenceNo!.isNotEmpty
          ? 'ktb_${referenceNo!}'
          : 'ktb_${DateTime.now().millisecondsSinceEpoch}',
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
      'predictionConfidence': predictionConfidence,
      'predictionReason': predictionReason,
    };
  }

  factory KrungthaiSlipData.fromJson(Map<String, dynamic> json) {
    return KrungthaiSlipData(
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
      suggestedCategory: json['suggestedCategory'] as String? ?? 'อาหาร/ของกิน',
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
      predictionConfidence: (json['predictionConfidence'] as num?)?.toDouble() ?? 0.5,
      predictionReason: json['predictionReason'] as String? ?? '',
    );
  }
}
