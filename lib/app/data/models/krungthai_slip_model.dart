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
  });

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
    );
  }
}
