import '../models/transaction_model.dart';

/// บริการแปลงข้อมูล Transactions ไป-กลับระหว่าง CSV (UTF-8 BOM สำหรับ Excel)
class CsvService {
  static String exportToCsv(List<TransactionItem> transactions) {
    final buffer = StringBuffer();
    // UTF-8 Byte Order Mark เพื่อให้ Excel อ่านภาษาไทยได้สมบูรณ์
    buffer.write('\uFEFF');
    buffer.writeln('รหัสรายการ,วันที่,ประเภท,ประเภทค่าใช้จ่าย,หมวดหมู่,ชื่อรายการ,จำนวนเงิน (บาท),บันทึกเพิ่มเติม');

    for (final item in transactions) {
      final id = _escapeCsv(item.id);
      final date = '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';

      String typeStr = 'รายจ่าย';
      if (item.type == TransactionType.income) {
        typeStr = 'รายรับ';
      } else if (item.type == TransactionType.savingsInvestment) {
        typeStr = 'เงินออม/ลงทุน';
      }

      String costNatureStr = '-';
      if (item.type == TransactionType.expense) {
        costNatureStr = item.costNature == CostNature.fixed ? 'คงที่' : 'จิปาถะ';
      }

      final category = _escapeCsv(item.categoryName);
      final title = _escapeCsv(item.title);
      final amount = item.amount.toStringAsFixed(2);
      final note = _escapeCsv(item.note ?? '');

      buffer.writeln('$id,$date,$typeStr,$costNatureStr,$category,$title,$amount,$note');
    }

    return buffer.toString();
  }

  static List<TransactionItem> importFromCsv(String csvContent) {
    final items = <TransactionItem>[];
    String cleanContent = csvContent;
    if (cleanContent.startsWith('\uFEFF')) {
      cleanContent = cleanContent.substring(1);
    }

    final lines = cleanContent.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return items;

    int startIndex = 0;
    if (lines.isNotEmpty &&
        (lines.first.contains('รหัสรายการ') ||
            lines.first.contains('วันที่') ||
            lines.first.contains('date'))) {
      startIndex = 1;
    }

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = _parseCsvLine(line);
      if (cols.length < 6) continue;

      try {
        final id = cols.isNotEmpty && cols[0].isNotEmpty
            ? cols[0]
            : 'import_${DateTime.now().millisecondsSinceEpoch}_$i';

        DateTime date = DateTime.now();
        if (cols.length > 1 && cols[1].isNotEmpty) {
          date = DateTime.tryParse(cols[1]) ?? DateTime.now();
        }

        TransactionType type = TransactionType.expense;
        if (cols.length > 2) {
          final typeVal = cols[2].toLowerCase();
          if (typeVal.contains('รับ') || typeVal.contains('income')) {
            type = TransactionType.income;
          } else if (typeVal.contains('ออม') || typeVal.contains('ลงทุน') || typeVal.contains('saving')) {
            type = TransactionType.savingsInvestment;
          }
        }

        CostNature costNature = CostNature.variable;
        if (cols.length > 3) {
          final costVal = cols[3].toLowerCase();
          if (costVal.contains('คงที่') || costVal.contains('fixed')) {
            costNature = CostNature.fixed;
          }
        }

        final category = cols.length > 4 && cols[4].isNotEmpty ? cols[4] : 'ทั่วไป';
        final title = cols.length > 5 && cols[5].isNotEmpty ? cols[5] : 'รายการนำเข้า';

        double amount = 0.0;
        if (cols.length > 6 && cols[6].isNotEmpty) {
          final cleanAmount = cols[6].replaceAll(',', '').replaceAll('฿', '').trim();
          amount = double.tryParse(cleanAmount) ?? 0.0;
        }

        final note = cols.length > 7 && cols[7].isNotEmpty ? cols[7] : null;

        if (amount > 0) {
          items.add(
            TransactionItem(
              id: id,
              title: title,
              amount: amount,
              type: type,
              costNature: costNature,
              categoryName: category,
              date: date,
              note: note,
            ),
          );
        }
      } catch (_) {}
    }

    return items;
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final current = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }
}
