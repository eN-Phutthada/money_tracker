import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bank_slip_model.dart';
import '../models/transaction_model.dart';
import 'config_service.dart';

/// บริการวิเคราะห์สลิปและใบเสร็จด้วย Google Gemini Multimodal Vision API
class GeminiSlipService {
  static final GeminiSlipService _instance = GeminiSlipService._internal();
  factory GeminiSlipService() => _instance;
  GeminiSlipService._internal();

  final ConfigService _config = ConfigService();

  /// ส่งรูปภาพสลิป/ใบเสร็จไปให้ Gemini Vision วิเคราะห์และแปลงเป็น BankSlipData
  Future<BankSlipData?> analyzeSlip({
    required XFile file,
    String? existingOcrText,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final apiKey = _config.geminiApiKey;
    if (apiKey.isEmpty) {
      debugPrint('[GeminiSlipService] GEMINI_API_KEY is missing in config.json');
      return null;
    }

    final model = _config.geminiModel;

    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(file.path);

      final prompt = '''
You are an expert financial receipt and bank transfer slip analyzer for a Thai personal finance app.
Analyze this slip or receipt image and extract structured transaction details.

Return a JSON object matching this schema:
{
  "amount": number (positive float, the NET total or final amount paid/transferred. For store receipts like 7-Eleven, use the net total/ยอดสุทธิ, NEVER an individual item price),
  "transaction_date": string in ISO8601 format "YYYY-MM-DDTHH:mm:ss" or null if unreadable,
  "bank_or_store": string (e.g. "7-Eleven สาขา 01234 อโศกมนตรี", "ธนาคารกรุงไทย", "ธนาคารกสิกรไทย", "Lotus's"),
  "sender_name": string or null,
  "receiver_name": string or null (store name or receiver person),
  "reference_no": string or null,
  "category": string (choose best fit: "อาหาร/ของกิน", "เดินทาง/ขนส่ง", "ช้อปปิ้ง", "บันเทิง/พักผ่อน", "สาธารณูปโภค", "ค่าที่พัก/หอพัก", "การศึกษา", "สุขภาพ/ยา", "โอนเงิน/ธุรกรรม", "อื่นๆ"),
  "type": string ("expense" or "income"),
  "items": array of strings (for retail receipts, list items with price, e.g. ["ข้าวกะเพราไก่ 47.-", "ชาเขียว 20.-"]),
  "memo": string (concise description for transaction note)
}
Rules:
- Net total is highest priority for "amount".
- If 7-Eleven or retail receipt, include purchased items in "items".
${existingOcrText != null && existingOcrText.isNotEmpty ? 'Extracted OCR hints: $existingOcrText' : ''}
''';

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        }
      };

      final client = HttpClient();
      client.connectionTimeout = timeout;

      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.set('Content-Type', 'application/json; charset=UTF-8');
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        debugPrint('[GeminiSlipService] API Error: ${response.statusCode} - $responseBody');
        return null;
      }

      final jsonResponse = jsonDecode(responseBody);
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final textResponse = parts[0]['text'] as String?;
      if (textResponse == null || textResponse.trim().isEmpty) return null;

      final cleanJsonText = _extractJsonBlock(textResponse);
      final parsedData = jsonDecode(cleanJsonText) as Map<String, dynamic>;

      return parseGeminiJson(
        parsedData,
        rawText: existingOcrText ?? textResponse,
        modelName: model,
      );
    } catch (e, stack) {
      debugPrint('[GeminiSlipService] Exception during Gemini analysis: $e\n$stack');
      return null;
    }
  }

  /// แปลง Map JSON ที่ส่งกลับมาจาก Gemini เป็น BankSlipData
  static BankSlipData parseGeminiJson(
    Map<String, dynamic> json, {
    String rawText = '',
    String modelName = 'gemini',
  }) {
    final double amount = () {
      final rawAmt = json['amount'];
      if (rawAmt is num) return rawAmt.toDouble();
      if (rawAmt is String) {
        final clean = rawAmt.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(clean) ?? 0.0;
      }
      return 0.0;
    }();

    DateTime? transactionDate;
    bool hasParsedTime = false;
    final dateStr = json['transaction_date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        transactionDate = parsed;
        hasParsedTime = parsed.hour != 0 || parsed.minute != 0;
      }
    }
    transactionDate ??= DateTime.now();

    final bankOrStore = json['bank_or_store']?.toString().trim() ?? 'ทั่วไป';
    final receiverName = json['receiver_name']?.toString().trim() ?? bankOrStore;
    final senderName = json['sender_name']?.toString().trim();
    final referenceNo = json['reference_no']?.toString().trim();
    final suggestedCategory = json['category']?.toString().trim() ?? 'อาหาร/ของกิน';
    final typeStr = json['type']?.toString().toLowerCase().trim();
    final suggestedType = typeStr == 'income' ? TransactionType.income : TransactionType.expense;

    final itemsRaw = json['items'];
    final List<String> receiptItems = [];
    if (itemsRaw is List) {
      for (final it in itemsRaw) {
        if (it != null && it.toString().trim().isNotEmpty) {
          receiptItems.add(it.toString().trim());
        }
      }
    }

    final memo = json['memo']?.toString().trim();

    final isKrungthai = bankOrStore.contains('กรุงไทย') ||
        bankOrStore.contains('Krungthai') ||
        bankOrStore.contains('NEXT');

    return BankSlipData(
      amount: amount,
      transactionDate: transactionDate,
      bankName: bankOrStore,
      receiverName: receiverName,
      senderName: senderName,
      referenceNo: referenceNo,
      isKrungthai: isKrungthai,
      suggestedCategory: suggestedCategory,
      suggestedType: suggestedType,
      suggestedCostNature: CostNature.variable,
      memo: memo,
      rawText: rawText,
      receiptItems: receiptItems,
      predictionConfidence: 0.98,
      predictionReason: 'Gemini AI ($modelName)',
      hasParsedDateTime: true,
      hasParsedTime: hasParsedTime,
    );
  }

  static String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  static String _extractJsonBlock(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('```json') && trimmed.endsWith('```')) {
      return trimmed.substring(7, trimmed.length - 3).trim();
    }
    if (trimmed.startsWith('```') && trimmed.endsWith('```')) {
      return trimmed.substring(3, trimmed.length - 3).trim();
    }
    return trimmed;
  }
}
