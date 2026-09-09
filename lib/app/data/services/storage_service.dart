import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/budget_plan_model.dart';
import '../models/transaction_model.dart';

/// Storage Service สำหรับจัดเก็บข้อมูลธุรกรรมและงบประมาณลงเครื่อง
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Directory? _storageDir;

  Future<Directory> getStorageDirectory() async {
    if (_storageDir != null) return _storageDir!;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docDir.path}/MoneyTracker');
      if (!await dir.exists()) await dir.create(recursive: true);
      _storageDir = dir;
      return dir;
    } catch (_) {
      // Fallback
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final dir = Directory('$appData/MoneyTracker');
          if (!await dir.exists()) await dir.create(recursive: true);
          _storageDir = dir;
          return dir;
        }
      }
      _storageDir = Directory.systemTemp;
      return _storageDir!;
    }
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================
  Future<File> _getTransactionsFile() async {
    final dir = await getStorageDirectory();
    return File('${dir.path}/transactions.json');
  }

  Future<List<TransactionItem>?> loadTransactions() async {
    try {
      final file = await _getTransactionsFile();
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) return null;

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveTransactions(List<TransactionItem> transactions) async {
    try {
      final file = await _getTransactionsFile();
      final jsonList = transactions.map((t) => t.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // BUDGET PLAN
  // ==========================================
  Future<File> _getBudgetPlanFile() async {
    final dir = await getStorageDirectory();
    return File('${dir.path}/budget_plan.json');
  }

  Future<BudgetPlan?> loadBudgetPlan() async {
    try {
      final file = await _getBudgetPlanFile();
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) return null;

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return BudgetPlan.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveBudgetPlan(BudgetPlan plan) async {
    try {
      final file = await _getBudgetPlanFile();
      final jsonString = const JsonEncoder.withIndent('  ').convert(plan.toJson());
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // BACKUP / RESTORE / RESET
  // ==========================================
  Future<String> exportBackupJson(List<TransactionItem> transactions, BudgetPlan plan) async {
    final backupData = {
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'budgetPlan': plan.toJson(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  Future<Map<String, dynamic>?> restoreBackupJson(String jsonString) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return null;

      BudgetPlan? plan;
      if (decoded['budgetPlan'] != null) {
        plan = BudgetPlan.fromJson(decoded['budgetPlan'] as Map<String, dynamic>);
      }

      List<TransactionItem>? transactions;
      if (decoded['transactions'] is List) {
        transactions = (decoded['transactions'] as List)
            .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (plan != null) await saveBudgetPlan(plan);
      if (transactions != null) await saveTransactions(transactions);

      return {
        'budgetPlan': plan,
        'transactions': transactions,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAllData() async {
    try {
      final tFile = await _getTransactionsFile();
      if (await tFile.exists()) await tFile.delete();

      final bFile = await _getBudgetPlanFile();
      if (await bFile.exists()) await bFile.delete();
    } catch (_) {}
  }
}
