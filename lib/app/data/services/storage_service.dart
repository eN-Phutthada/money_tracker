import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
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

    if (WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
        Platform.environment.containsKey('FLUTTER_TEST')) {
      _storageDir = Directory.systemTemp;
      return _storageDir!;
    }

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
  // INITIALIZATION STATE
  // ==========================================
  Future<File> _getInitFlagFile() async {
    final dir = await getStorageDirectory();
    return File('${dir.path}/.initialized');
  }

  Future<bool> isInitialized() async {
    try {
      final file = await _getInitFlagFile();
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> setInitialized() async {
    try {
      final file = await _getInitFlagFile();
      await file.writeAsString(DateTime.now().toIso8601String(), flush: true);
    } catch (_) {}
  }

  // ==========================================
  // THEME MODE PREFERENCE
  // ==========================================
  Future<File> _getThemeFile() async {
    final dir = await getStorageDirectory();
    return File('${dir.path}/theme_mode.txt');
  }

  Future<String?> loadThemeMode() async {
    try {
      final file = await _getThemeFile();
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveThemeMode(String mode) async {
    try {
      final file = await _getThemeFile();
      await file.writeAsString(mode, flush: true);
    } catch (_) {}
  }

  // ==========================================
  // LANGUAGE PREFERENCE
  // ==========================================
  Future<File> _getLanguageFile() async {
    final dir = await getStorageDirectory();
    return File('${dir.path}/language.txt');
  }

  Future<String?> loadLanguage() async {
    try {
      final file = await _getLanguageFile();
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLanguage(String langCode) async {
    try {
      final file = await _getLanguageFile();
      await file.writeAsString(langCode, flush: true);
    } catch (_) {}
  }

  // ==========================================
  // USER NAME PREFERENCE
  // ==========================================
  Future<File> _getUserNameFile() async {
    final dir = await getStorageDirectory();
    return File('${dir.path}/user_name.txt');
  }

  Future<String?> loadUserName() async {
    try {
      final file = await _getUserNameFile();
      if (!await file.exists()) return null;
      final name = await file.readAsString();
      return name.trim().isEmpty ? null : name.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserName(String name) async {
    try {
      final file = await _getUserNameFile();
      await file.writeAsString(name.trim(), flush: true);
    } catch (_) {}
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
      if (jsonString.trim().isEmpty) return <TransactionItem>[];

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return <TransactionItem>[];
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
      await setInitialized();
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
      await setInitialized();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // BACKUP / RESTORE / RESET & EXPORT FILES
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

  Future<String> saveExportFile(String filename, String content) async {
    Directory exportDir;
    try {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          final downloadsDir = Directory('$userProfile/Downloads');
          if (await downloadsDir.exists()) {
            exportDir = downloadsDir;
          } else {
            exportDir = await getStorageDirectory();
          }
        } else {
          exportDir = await getStorageDirectory();
        }
      } else {
        exportDir = await getStorageDirectory();
      }
    } catch (_) {
      exportDir = await getStorageDirectory();
    }

    final file = File('${exportDir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file.path;
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

  Future<void> clearAllData({bool keepInitialized = true}) async {
    try {
      final tFile = await _getTransactionsFile();
      if (await tFile.exists()) {
        if (keepInitialized) {
          await tFile.writeAsString('[]', flush: true);
        } else {
          await tFile.delete();
        }
      }

      final bFile = await _getBudgetPlanFile();
      if (await bFile.exists() && !keepInitialized) {
        await bFile.delete();
      }

      if (!keepInitialized) {
        final initFile = await _getInitFlagFile();
        if (await initFile.exists()) await initFile.delete();
      }
    } catch (_) {}
  }

  // ==========================================
  // SLIP SCANNER AUTO-SAVE PREFERENCE
  // ==========================================
  Future<File> _getSlipAutoSavePrefFile() async {
    final dir = await getStorageDirectory();
    return File('${dir.path}/slip_auto_save.pref');
  }

  Future<bool> loadSlipAutoSavePref() async {
    try {
      final file = await _getSlipAutoSavePrefFile();
      if (!await file.exists()) return false;
      final content = await file.readAsString();
      return content.trim() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveSlipAutoSavePref(bool enabled) async {
    try {
      final file = await _getSlipAutoSavePrefFile();
      await file.writeAsString(enabled ? 'true' : 'false', flush: true);
    } catch (_) {}
  }

  // ==========================================
  // GEMINI AI SLIP ANALYSIS PREFERENCES
  // ==========================================
  Future<File> _getGeminiEnabledPrefFile() async {
    final dir = await getStorageDirectory();
    return File('${dir.path}/gemini_slip_analysis.pref');
  }

  Future<bool> loadGeminiEnabledPref() async {
    try {
      final file = await _getGeminiEnabledPrefFile();
      if (!await file.exists()) return false;
      final content = await file.readAsString();
      return content.trim() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveGeminiEnabledPref(bool enabled) async {
    try {
      final file = await _getGeminiEnabledPrefFile();
      await file.writeAsString(enabled ? 'true' : 'false', flush: true);
    } catch (_) {}
  }
}


