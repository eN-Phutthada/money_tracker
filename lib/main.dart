import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'screens/dashboard_screen.dart';
import 'services/finance_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoneyTrackerApp());
}

class MoneyTrackerApp extends StatefulWidget {
  const MoneyTrackerApp({super.key});

  @override
  State<MoneyTrackerApp> createState() => _MoneyTrackerAppState();
}

class _MoneyTrackerAppState extends State<MoneyTrackerApp> {
  late final FinanceService _financeService;

  @override
  void initState() {
    super.initState();
    _financeService = FinanceService();
  }

  @override
  void dispose() {
    _financeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Tracker - บันทึกการเงินส่วนบุคคล',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
      ),
      home: DashboardScreen(financeService: _financeService),
    );
  }
}
