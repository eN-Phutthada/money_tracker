import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// Quick Add & Edit BottomSheet พร้อม Ergonomic Numpad และระบบเลือกวันที่ (FinTech 2026 Edition)
class QuickAddBottomSheet extends StatefulWidget {
  final TransactionItem? existingItem;

  const QuickAddBottomSheet({super.key, this.existingItem});

  static void show(BuildContext context, {TransactionItem? existingItem}) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      Get.dialog(
        AppGlassDialog(
          maxWidth: 480,
          padding: const EdgeInsets.all(22),
          child: QuickAddBottomSheet(existingItem: existingItem),
        ),
      );
    } else {
      Get.bottomSheet(
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: QuickAddBottomSheet(existingItem: existingItem),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  State<QuickAddBottomSheet> createState() => _QuickAddBottomSheetState();
}

class _QuickAddBottomSheetState extends State<QuickAddBottomSheet> {
  final DashboardController controller = Get.find<DashboardController>();
  late final TextEditingController _titleController;
  final FocusNode _sheetFocusNode = FocusNode();

  late String _amountBuffer;
  late TransactionType _selectedType;
  late CostNature _selectedCostNature;
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;
  bool _isSuccess = false;

  bool get isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _amountBuffer = item.amount % 1 == 0 ? item.amount.toInt().toString() : item.amount.toStringAsFixed(2);
      _titleController = TextEditingController(text: item.title);
      _selectedType = item.type;
      _selectedCostNature = item.costNature;
      _selectedCategory = item.categoryName;
      _selectedDate = item.date;
    } else {
      _amountBuffer = '';
      _titleController = TextEditingController();
      _selectedType = TransactionType.expense;
      _selectedCostNature = CostNature.variable;
      _selectedCategory = 'อาหาร/ของกิน';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sheetFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getCategoriesForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return const [
          {'name': 'อาหาร/ของกิน', 'icon': Icons.fastfood_rounded},
          {'name': 'กาแฟ/เครื่องดื่ม', 'icon': Icons.local_cafe_rounded},
          {'name': 'การเดินทาง', 'icon': Icons.directions_subway_rounded},
          {'name': 'ช้อปปิ้ง', 'icon': Icons.shopping_bag_rounded},
          {'name': 'ของใช้ส่วนตัว', 'icon': Icons.inventory_2_rounded},
          {'name': 'ที่อยู่อาศัย', 'icon': Icons.home_rounded},
          {'name': 'สาธารณูปโภค', 'icon': Icons.flash_on_rounded},
          {'name': 'บันเทิง/พักผ่อน', 'icon': Icons.movie_rounded},
          {'name': 'สุขภาพ/ยา', 'icon': Icons.medical_services_rounded},
          {'name': 'การศึกษา', 'icon': Icons.school_rounded},
          {'name': 'อื่นๆ', 'icon': Icons.more_horiz_rounded},
        ];
      case TransactionType.income:
        return const [
          {'name': 'เงินเดือน', 'icon': Icons.account_balance_wallet_rounded},
          {'name': 'ฟรีแลนซ์/งานเสริม', 'icon': Icons.laptop_mac_rounded},
          {'name': 'โบนัส', 'icon': Icons.card_giftcard_rounded},
          {'name': 'เงินปันผล/ดอกเบี้ย', 'icon': Icons.trending_up_rounded},
          {'name': 'ขายของ', 'icon': Icons.storefront_rounded},
          {'name': 'รายรับอื่นๆ', 'icon': Icons.add_circle_outline_rounded},
        ];
      case TransactionType.savingsInvestment:
        return const [
          {'name': 'เงินออม/DCA', 'icon': Icons.savings_rounded},
          {'name': 'กองทุนรวม', 'icon': Icons.pie_chart_rounded},
          {'name': 'หุ้น/ตราสาร', 'icon': Icons.show_chart_rounded},
          {'name': 'เงินสำรองฉุกเฉิน', 'icon': Icons.security_rounded},
          {'name': 'สินทรัพย์อื่นๆ', 'icon': Icons.account_balance_rounded},
        ];
    }
  }

  List<String> _getCategorySuggestions(String category) {
    final isEn = controller.isEnglish;
    if (isEn) {
      switch (category) {
        case 'อาหาร/ของกิน':
          return const ['Breakfast', 'Lunch', 'Dinner', 'Snacks', '7-Eleven', 'Food Delivery'];
        case 'กาแฟ/เครื่องดื่ม':
          return const ['Americano', 'Latte', 'Matcha Green Tea', 'Thai Tea', 'Boba / Milk Tea', 'Water'];
        case 'การเดินทาง':
          return const ['BTS / MRT', 'Gas / Fuel', 'Grab / Taxi', 'Bus Fare', 'Expressway Toll', 'Motorbike'];
        case 'ช้อปปิ้ง':
          return const ['Clothing', 'Online Shopping', 'Home Decor', 'Gadgets & Tech'];
        case 'ของใช้ส่วนตัว':
          return const ['Toiletries', 'Laundry Detergent', 'Tissues', 'Haircut', 'Skincare'];
        case 'ที่อยู่อาศัย':
          return const ['Rent / Condo', 'Mortgage', 'Common Fee', 'Home Repairs'];
        case 'สาธารณูปโภค':
          return const ['Electricity', 'Water Bill', 'Home WiFi', 'Mobile Bill', 'Subscriptions'];
        case 'บันเทิง/พักผ่อน':
          return const ['Movie Tickets', 'Gaming', 'Concert', 'Travel / Hotel', 'Party & Drinks'];
        case 'สุขภาพ/ยา':
          return const ['Clinic / Doctor', 'Medicine & Vitamins', 'Dental', 'Health Checkup', 'Insurance'];
        case 'การศึกษา':
          return const ['Online Course', 'Books', 'Tuition Fee', 'Stationery'];
        case 'เงินเดือน':
          return const ['Monthly Salary', 'Performance Bonus', 'Back Pay', 'Overtime (OT)'];
        case 'ฟรีแลนซ์/งานเสริม':
          return const ['Freelance Gig', 'Side Project', 'Online Sales', 'Commission'];
        case 'โบนัส':
          return const ['Annual Bonus', 'Performance Bonus', 'Special Reward'];
        case 'เงินปันผล/ดอกเบี้ย':
          return const ['Stock Dividend', 'Bank Interest', 'Fund Dividend'];
        case 'ขายของ':
          return const ['Retail Sales', 'Online Store', 'Secondhand Goods'];
        case 'รายรับอื่นๆ':
          return const ['Cash Gift', 'Refund / Cashback', 'Lottery Prize', 'Other Income'];
        case 'เงินออม/DCA':
          return const ['Stock DCA', 'Fund DCA', 'Fixed Deposit', 'Gold Savings'];
        case 'กองทุนรวม':
          return const ['Index Fund', 'Tax Saving Fund', 'Retirement Fund'];
        case 'หุ้น/ตราสาร':
          return const ['Common Stock', 'Corporate Bonds', 'Treasury Bills'];
        case 'เงินสำรองฉุกเฉิน':
          return const ['Emergency Fund', 'High-Yield Savings'];
        case 'สินทรัพย์อื่นๆ':
          return const ['Real Estate', 'Crypto DCA', 'Precious Metals'];
        default:
          return const ['General Expense', 'Essential', 'Other'];
      }
    }

    switch (category) {
      case 'อาหาร/ของกิน':
        return const ['ข้าวแกง/ตามสั่ง', 'ก๋วยเตี๋ยว', 'เซเว่น 7-11', 'Grab/Lineman', 'มื้อเย็น/สังสรรค์', 'ขนม/ของว่าง'];
      case 'กาแฟ/เครื่องดื่ม':
        return const ['อเมริกาโน่', 'ลาเต้', 'ชาเขียวมัทฉะ', 'ชาไทย', 'ชานมไข่มุก', 'น้ำดื่ม'];
      case 'การเดินทาง':
        return const ['BTS / MRT', 'เติมน้ำมัน', 'Grab/แท็กซี่', 'รถเมล์/สองแถว', 'ทางด่วน', 'วินมอเตอร์ไซค์'];
      case 'ช้อปปิ้ง':
        return const ['ของใช้ส่วนตัว', 'เสื้อผ้า', 'Shopee/Lazada', 'ของแต่งบ้าน', 'เครื่องใช้ไฟฟ้า'];
      case 'ของใช้ส่วนตัว':
        return const ['สบู่/ยาสระผม', 'ผงซักฟอก', 'กระดาษทิชชู่', 'ตัดผม', 'เครื่องสำอาง'];
      case 'ที่อยู่อาศัย':
        return const ['ค่าเช่าห้อง/คอนโด', 'ค่างวดบ้าน', 'ค่าส่วนกลาง', 'ซ่อมแซมบ้าน'];
      case 'สาธารณูปโภค':
        return const ['ค่าไฟ', 'ค่าน้ำประปา', 'เน็ตบ้าน/WiFi', 'ค่าโทรศัพท์', 'Netflix/Spotify'];
      case 'บันเทิง/พักผ่อน':
        return const ['ตั๋วหนัง', 'เติมเกม', 'คอนเสิร์ต', 'ท่องเที่ยว/ที่พัก', 'สังสรรค์'];
      case 'สุขภาพ/ยา':
        return const ['หาหมอ/คลินิก', 'ค่ายา/วิตามิน', 'ทำฟัน', 'ตรวจสุขภาพ', 'ประกันสุขภาพ'];
      case 'การศึกษา':
        return const ['คอร์สเรียน', 'หนังสือ', 'ค่าเทอม', 'เครื่องเขียน'];
      case 'เงินเดือน':
        return const ['เงินเดือนประจำ', 'โบนัสพิเศษ', 'เงินตกเบิก', 'ค่าทำงานล่วงเวลา (OT)'];
      case 'ฟรีแลนซ์/งานเสริม':
        return const ['งานฟรีแลนซ์', 'รับจ้างทั่วไป', 'ขายของออนไลน์', 'ค่าคอมมิชชั่น'];
      case 'โบนัส':
        return const ['โบนัสประจำปี', 'โบนัสผลงาน', 'รางวัลพิเศษ'];
      case 'เงินปันผล/ดอกเบี้ย':
        return const ['เงินปันผลหุ้น', 'ดอกเบี้ยเงินฝาก', 'ปันผลกองทุน'];
      case 'ขายของ':
        return const ['ขายของหน้าร้าน', 'ขายของออนไลน์', 'ของมือสอง'];
      case 'เงินออม/DCA':
        return const ['DCA หุ้นประจำงวด', 'DCA กองทุนรวม', 'เงินฝากประจำ', 'ซื้อทองคำแท่ง'];
      case 'กองทุนรวม':
        return const ['SSF ลดหย่อนภาษี', 'RMF เพื่อการเกษียณ', 'กองทุนรวมดัชนี'];
      case 'หุ้น/ตราสาร':
        return const ['ซื้อหุ้นสามัญ', 'หุ้นกู้เอกชน', 'พันธบัตรรัฐบาล'];
      case 'เงินสำรองฉุกเฉิน':
        return const ['ฝากสำรองฉุกเฉิน', 'บัญชีดิจิทัลดอกเบี้ยสูง'];
      default:
        return const ['ค่าใช้จ่ายทั่วไป', 'จำเป็น', 'อื่นๆ'];
    }
  }

  void _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.backspace) {
        _onNumpadPress('⌫');
      } else if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) {
        _onNumpadPress('.');
      } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        _submit();
      } else if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
        _onNumpadPress('0');
      } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
        _onNumpadPress('1');
      } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
        _onNumpadPress('2');
      } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
        _onNumpadPress('3');
      } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
        _onNumpadPress('4');
      } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
        _onNumpadPress('5');
      } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
        _onNumpadPress('6');
      } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
        _onNumpadPress('7');
      } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
        _onNumpadPress('8');
      } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
        _onNumpadPress('9');
      }
    }
  }

  void _onNumpadPress(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == '⌫') {
        if (_amountBuffer.isNotEmpty) {
          _amountBuffer = _amountBuffer.substring(0, _amountBuffer.length - 1);
        }
      } else if (key == '.') {
        if (!_amountBuffer.contains('.')) {
          _amountBuffer = _amountBuffer.isEmpty ? '0.' : '$_amountBuffer.';
        }
      } else {
        if (_amountBuffer.contains('.')) {
          final parts = _amountBuffer.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        }
        if (_amountBuffer == '0') {
          _amountBuffer = key;
        } else if (_amountBuffer.length < 9) {
          _amountBuffer += key;
        }
      }
    });
  }

  void _addQuickAmount(double value) {
    HapticFeedback.lightImpact();
    final current = double.tryParse(_amountBuffer) ?? 0.0;
    final next = current + value;
    setState(() {
      _amountBuffer = next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(2);
    });
  }

  void _onTypeChange(TransactionType type) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedType = type;
      final cats = _getCategoriesForType(type);
      _selectedCategory = cats.first['name'] as String;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _submit() async {
    if (_isSaving || _isSuccess) return;

    final amount = double.tryParse(_amountBuffer);
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      AppFeedback.showWarning(
        title: 'warning'.tr,
        message: 'please_enter_valid_amount'.tr,
      );
      return;
    }

    final customTitle = _titleController.text.trim();
    final finalTitle = customTitle.isNotEmpty ? customTitle : _selectedCategory;

    setState(() {
      _isSaving = true;
      _isSuccess = true;
    });

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    if (isEditMode) {
      final updated = widget.existingItem!.copyWith(
        title: finalTitle,
        amount: amount,
        type: _selectedType,
        costNature: _selectedType == TransactionType.expense ? _selectedCostNature : CostNature.notApplicable,
        categoryName: _selectedCategory,
        date: _selectedDate,
        note: customTitle.isNotEmpty ? customTitle : null,
      );
      controller.updateTransaction(updated);
    } else {
      final item = TransactionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: finalTitle,
        amount: amount,
        type: _selectedType,
        costNature: _selectedType == TransactionType.expense ? _selectedCostNature : CostNature.notApplicable,
        categoryName: _selectedCategory,
        date: _selectedDate,
        note: customTitle.isNotEmpty ? customTitle : null,
      );
      controller.addTransaction(item);
    }

    // Brief delay to let the user see the emerald green success checkmark on the button
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    Get.back();

    // Show floating in-app notification banner
    AppFeedback.showSuccess(
      title: isEditMode ? 'update_success_title'.tr : 'save_success_title'.tr,
      message: isEditMode
          ? 'update_success_msg'.trParams({'title': finalTitle.tr})
          : 'save_success_msg'.trParams({'title': finalTitle.tr}),
      amount: amount,
      transactionType: _selectedType,
    );
  }

  void _delete() {
    if (widget.existingItem != null) {
      final title = widget.existingItem!.title;
      controller.deleteTransaction(widget.existingItem!.id);
      Get.back();
      AppFeedback.showInfo(
        title: 'delete_success_title'.tr,
        message: 'delete_success_msg'.trParams({'title': title.tr}),
      );
    }
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final isEn = controller.isEnglish;
    if (target == today) return isEn ? 'Today (${d.day}/${d.month})' : 'วันนี้ (${d.day}/${d.month})';
    if (target == today.subtract(const Duration(days: 1))) return isEn ? 'Yesterday (${d.day}/${d.month})' : 'เมื่อวาน (${d.day}/${d.month})';
    final yearSuffix = isEn ? '${d.year % 100}' : '${(d.year + 543) % 100}';
    return '${d.day}/${d.month}/$yearSuffix';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _getCategoriesForType(_selectedType);

    return KeyboardListener(
      focusNode: _sheetFocusNode,
      autofocus: true,
      onKeyEvent: _handleHardwareKey,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.8) : AppColors.border,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtle Drag Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.8)
                        : AppColors.border.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              AppPopupHeader(
                title: isEditMode ? 'edit_transaction_title'.tr : 'record_income_expense'.tr,
                subtitle: isEditMode ? 'edit_transaction_desc'.tr : 'record_transaction_desc'.tr,
                icon: _selectedType == TransactionType.expense
                    ? Icons.arrow_downward_rounded
                    : (_selectedType == TransactionType.income
                        ? Icons.arrow_upward_rounded
                        : Icons.savings_rounded),
                iconColor: _selectedType == TransactionType.expense
                    ? AppColors.deficitText
                    : (_selectedType == TransactionType.income ? AppColors.primary : AppColors.accent),
                trailing: isEditMode
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.deficitText, size: 20),
                        onPressed: _delete,
                        tooltip: 'delete_this_item'.tr,
                      )
                    : null,
              ),
              const SizedBox(height: 14),

              // Header Type Selector (Floating Pill Deck)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeSegment(
                        type: TransactionType.expense,
                        label: 'expense'.tr,
                        color: AppColors.deficitText,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTypeSegment(
                        type: TransactionType.income,
                        label: 'income'.tr,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTypeSegment(
                        type: TransactionType.savingsInvestment,
                        label: 'filter_savings'.tr,
                        color: AppColors.accent,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Fixed vs Variable (for expense)
              if (_selectedType == TransactionType.expense)
                Row(
                  children: [
                    _buildCostNaturePill(CostNature.variable, 'variable_cost'.tr, 'variable_cost_desc'.tr, isDark),
                    const SizedBox(width: 8),
                    _buildCostNaturePill(CostNature.fixed, 'fixed_cost'.tr, 'fixed_cost_desc'.tr, isDark),
                  ],
                ),
              if (_selectedType == TransactionType.expense) const SizedBox(height: 12),

              // Category Pills Carousel
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategory == cat['name'];

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat['name'] as String);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 15,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (cat['name'] as String).tr,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Smart Title Suggestions Row
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.accent),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'quick_suggestions_hint'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildSmartSuggestions(isDark),
              const SizedBox(height: 10),

              // Hero Amount Display Area (Guaranteed Zero RenderFlex Overflow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.darkBackground,
                            AppColors.darkSurfaceSecondary.withValues(alpha: 0.4),
                          ]
                        : [
                            AppColors.surfaceSecondary,
                            AppColors.surface,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_selectedType == TransactionType.expense
                                      ? AppColors.deficitText
                                      : (_selectedType == TransactionType.income
                                          ? AppColors.primary
                                          : AppColors.accent))
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedCategory.tr,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _selectedType == TransactionType.expense
                                    ? AppColors.deficitText
                                    : (_selectedType == TransactionType.income
                                        ? AppColors.primary
                                        : AppColors.accent),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_titleController.text.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _titleController.text,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _amountBuffer.isEmpty ? '0' : _amountBuffer,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '฿',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _selectedType == TransactionType.expense
                                    ? AppColors.deficitText
                                    : (_selectedType == TransactionType.income
                                        ? AppColors.primary
                                        : AppColors.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Quick Amount Add Pills & Clear Button
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildQuickPill('+20', 20, isDark),
                    const SizedBox(width: 6),
                    _buildQuickPill('+50', 50, isDark),
                    const SizedBox(width: 6),
                    _buildQuickPill('+100', 100, isDark),
                    const SizedBox(width: 6),
                    _buildQuickPill('+500', 500, isDark),
                    const SizedBox(width: 6),
                    _buildQuickPill('+1,000', 1000, isDark),
                    const SizedBox(width: 8),
                    if (_amountBuffer.isNotEmpty)
                      InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _amountBuffer = '');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.deficitBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.deficitText.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.clear_rounded, size: 12, color: AppColors.deficitText),
                              const SizedBox(width: 3),
                              Text(
                                'reset'.tr,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deficitText),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Built-in 4x3 Ergonomic Numpad
              _buildNumpadGrid(isDark),
              const SizedBox(height: 10),

              // Date Selection Row & Note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildDateChip('today'.tr, () {
                      setState(() => _selectedDate = DateTime.now());
                    }, isDark),
                    const SizedBox(width: 5),
                    _buildDateChip('yesterday'.tr, () {
                      final now = DateTime.now();
                      setState(() => _selectedDate = DateTime(now.year, now.month, now.day - 1, now.hour, now.minute));
                    }, isDark),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Custom Title/Note TextField
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'note_hint'.tr,
                  hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.textSecondary),
                  suffixIcon: _titleController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () => setState(() => _titleController.clear()),
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Glowing Submit Button with Animated State
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: _isSuccess
                        ? const [Color(0xFF10B981), Color(0xFF059669)]
                        : (_selectedType == TransactionType.expense
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : (_selectedType == TransactionType.income
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [AppColors.accent, const Color(0xFF7C3AED)])),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSuccess
                              ? const Color(0xFF10B981)
                              : (_selectedType == TransactionType.expense
                                  ? AppColors.deficitText
                                  : (_selectedType == TransactionType.income ? AppColors.primary : AppColors.accent)))
                          .withValues(alpha: _isSuccess ? 0.45 : 0.35),
                      blurRadius: _isSuccess ? 18 : 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isSuccess
                        ? Row(
                            key: const ValueKey('submit_success'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isEditMode ? 'update_success_title'.tr : 'save_success_title'.tr,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                            ],
                          )
                        : Text(
                            isEditMode ? 'save_changes'.tr : 'add_transaction'.tr,
                            key: const ValueKey('submit_idle'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartSuggestions(bool isDark) {
    final suggestions = _getCategorySuggestions(_selectedCategory);
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          final isSelected = _titleController.text == item;

          return InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isSelected) {
                  _titleController.clear();
                } else {
                  _titleController.text = item;
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : (isDark ? AppColors.darkBackground : AppColors.surfaceSecondary),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTypeSegment({
    required TransactionType type,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => _onTypeChange(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildCostNaturePill(CostNature nature, String label, String subtitle, bool isDark) {
    final isSelected = _selectedCostNature == nature;
    final color = nature == CostNature.fixed ? AppColors.fixedCostAccent : AppColors.variableCostAccent;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedCostNature = nature);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? color : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? color.withValues(alpha: 0.85) : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPill(String label, double value, bool isDark) {
    return InkWell(
      onTap: () => _addQuickAmount(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildNumpadGrid(bool isDark) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => _onNumpadPress(key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.75) : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.45) : AppColors.border.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: key == '⌫'
                          ? Icon(Icons.backspace_outlined, size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                          : Text(
                              key,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
