import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import 'bank_slip_sheet.dart';

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
        QuickAddBottomSheet(existingItem: existingItem),
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
  late final TextEditingController _noteController;
  final FocusNode _sheetFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late String _amountBuffer;
  late TransactionType _selectedType;
  late CostNature _selectedCostNature;
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isWithdrawal = false;
  bool _isSaving = false;
  bool _isSuccess = false;

  bool get isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _amountBuffer = item.amount % 1 == 0
          ? item.amount.toInt().toString()
          : item.amount.toStringAsFixed(2);
      _titleController = TextEditingController(text: item.title);
      _noteController = TextEditingController(text: item.note ?? '');
      _isWithdrawal = item.isSavingsWithdrawal;
      _selectedType = item.type;
      _selectedCostNature = item.costNature;
      _selectedCategory = item.categoryName;
      _selectedDate = item.date;
    } else {
      _amountBuffer = '';
      _titleController = TextEditingController();
      _noteController = TextEditingController();
      _isWithdrawal = false;
      _selectedType = TransactionType.expense;
      _selectedCostNature = CostNature.variable;
      _selectedCategory = 'อาหาร/ของกิน';
      _selectedDate = DateTime.now();
    }

    // เมื่อ keyboard เปิด ให้ scroll ลงมาล่างสุดเพื่อให้เห็น text fields
    _titleFocusNode.addListener(_onFieldFocused);
    _noteFocusNode.addListener(_onFieldFocused);
  }

  void _onFieldFocused() {
    if (!(_titleFocusNode.hasFocus || _noteFocusNode.hasFocus)) return;
    // ใช้ addPostFrameCallback เพื่อรอให้ layout อัปเดตก่อน
    // จากนั้น scroll เพื่อให้ text fields โผล่เหนือ keyboard พอดี
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      // scroll ไปใกล้ maxScrollExtent แต่เหลือช่องว่างเล็กน้อยไม่ให้ชิดเกินไป
      final target = (pos.maxScrollExtent - 8).clamp(0.0, pos.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _titleFocusNode.removeListener(_onFieldFocused);
    _noteFocusNode.removeListener(_onFieldFocused);
    _titleFocusNode.dispose();
    _noteFocusNode.dispose();
    _scrollController.dispose();
    _sheetFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getCategoriesForType(TransactionType type) {
    if (_isWithdrawal) {
      return const [
        {'name': 'ถอนเงินออม', 'icon': Icons.account_balance_wallet_rounded},
        {'name': 'ถอนสำรองฉุกเฉิน', 'icon': Icons.security_rounded},
        {'name': 'ถอนใช้จ่ายทั่วไป', 'icon': Icons.shopping_bag_rounded},
        {'name': 'ถอนปิดหนี้', 'icon': Icons.credit_card_rounded},
        {'name': 'ถอนการลงทุน/กำไร', 'icon': Icons.trending_up_rounded},
        {'name': 'ถอนเงินออมอื่นๆ', 'icon': Icons.more_horiz_rounded},
      ];
    }
    switch (type) {
      case TransactionType.expense:
        return const [
          {'name': 'อาหาร/ของกิน', 'icon': Icons.fastfood_outlined},
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
    if (_isWithdrawal) {
      if (isEn) {
        return const [
          'Emergency Fund',
          'Living Expenses',
          'Debt Payoff',
          'Medical Bills',
          'Travel / Leisure',
          'Major Purchase',
        ];
      }
      return const [
        'สำรองฉุกเฉิน',
        'ค่าใช้จ่ายจำเป็น',
        'ปิดหนี้สิน',
        'ค่ารักษาพยาบาล',
        'ท่องเที่ยวพักผ่อน',
        'ซื้อของชิ้นใหญ่',
      ];
    }
    if (isEn) {
      switch (category) {
        case 'อาหาร/ของกิน':
          return const [
            'Breakfast',
            'Lunch',
            'Dinner',
            'Snacks',
            '7-Eleven',
            'Food Delivery',
          ];
        case 'กาแฟ/เครื่องดื่ม':
          return const [
            'Americano',
            'Latte',
            'Matcha Green Tea',
            'Thai Tea',
            'Boba / Milk Tea',
            'Water',
          ];
        case 'การเดินทาง':
          return const [
            'BTS / MRT',
            'Gas / Fuel',
            'Grab / Taxi',
            'Bus Fare',
            'Expressway Toll',
            'Motorbike',
          ];
        case 'ช้อปปิ้ง':
          return const [
            'Clothing',
            'Online Shopping',
            'Home Decor',
            'Gadgets & Tech',
          ];
        case 'ของใช้ส่วนตัว':
          return const [
            'Toiletries',
            'Laundry Detergent',
            'Tissues',
            'Haircut',
            'Skincare',
          ];
        case 'ที่อยู่อาศัย':
          return const [
            'Rent / Condo',
            'Mortgage',
            'Common Fee',
            'Home Repairs',
          ];
        case 'สาธารณูปโภค':
          return const [
            'Electricity',
            'Water Bill',
            'Home WiFi',
            'Mobile Bill',
            'Subscriptions',
          ];
        case 'บันเทิง/พักผ่อน':
          return const [
            'Movie Tickets',
            'Gaming',
            'Concert',
            'Travel / Hotel',
            'Party & Drinks',
          ];
        case 'สุขภาพ/ยา':
          return const [
            'Clinic / Doctor',
            'Medicine & Vitamins',
            'Dental',
            'Health Checkup',
            'Insurance',
          ];
        case 'การศึกษา':
          return const ['Online Course', 'Books', 'Tuition Fee', 'Stationery'];
        case 'เงินเดือน':
          return const [
            'Monthly Salary',
            'Performance Bonus',
            'Back Pay',
            'Overtime (OT)',
          ];
        case 'ฟรีแลนซ์/งานเสริม':
          return const [
            'Freelance Gig',
            'Side Project',
            'Online Sales',
            'Commission',
          ];
        case 'โบนัส':
          return const ['Annual Bonus', 'Performance Bonus', 'Special Reward'];
        case 'เงินปันผล/ดอกเบี้ย':
          return const ['Stock Dividend', 'Bank Interest', 'Fund Dividend'];
        case 'ขายของ':
          return const ['Retail Sales', 'Online Store', 'Secondhand Goods'];
        case 'รายรับอื่นๆ':
          return const [
            'Cash Gift',
            'Refund / Cashback',
            'Lottery Prize',
            'Other Income',
          ];
        case 'เงินออม/DCA':
          return const [
            'Stock DCA',
            'Fund DCA',
            'Fixed Deposit',
            'Gold Savings',
          ];
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
        return const [
          'ข้าวแกง/ตามสั่ง',
          'ก๋วยเตี๋ยว',
          'เซเว่น 7-11',
          'Grab/Lineman',
          'มื้อเย็น/สังสรรค์',
          'ขนม/ของว่าง',
        ];
      case 'กาแฟ/เครื่องดื่ม':
        return const [
          'อเมริกาโน่',
          'ลาเต้',
          'ชาเขียวมัทฉะ',
          'ชาไทย',
          'ชานมไข่มุก',
          'น้ำดื่ม',
        ];
      case 'การเดินทาง':
        return const [
          'BTS / MRT',
          'เติมน้ำมัน',
          'Grab/แท็กซี่',
          'รถเมล์/สองแถว',
          'ทางด่วน',
          'วินมอเตอร์ไซค์',
        ];
      case 'ช้อปปิ้ง':
        return const [
          'ของใช้ส่วนตัว',
          'เสื้อผ้า',
          'Shopee/Lazada',
          'ของแต่งบ้าน',
          'เครื่องใช้ไฟฟ้า',
        ];
      case 'ของใช้ส่วนตัว':
        return const [
          'สบู่/ยาสระผม',
          'ผงซักฟอก',
          'กระดาษทิชชู่',
          'ตัดผม',
          'เครื่องสำอาง',
        ];
      case 'ที่อยู่อาศัย':
        return const [
          'ค่าเช่าห้อง/คอนโด',
          'ค่างวดบ้าน',
          'ค่าส่วนกลาง',
          'ซ่อมแซมบ้าน',
        ];
      case 'สาธารณูปโภค':
        return const [
          'ค่าไฟ',
          'ค่าน้ำประปา',
          'เน็ตบ้าน/WiFi',
          'ค่าโทรศัพท์',
          'Netflix/Spotify',
        ];
      case 'บันเทิง/พักผ่อน':
        return const [
          'ตั๋วหนัง',
          'เติมเกม',
          'คอนเสิร์ต',
          'ท่องเที่ยว/ที่พัก',
          'สังสรรค์',
        ];
      case 'สุขภาพ/ยา':
        return const [
          'หาหมอ/คลินิก',
          'ค่ายา/วิตามิน',
          'ทำฟัน',
          'ตรวจสุขภาพ',
          'ประกันสุขภาพ',
        ];
      case 'การศึกษา':
        return const ['คอร์สเรียน', 'หนังสือ', 'ค่าเทอม', 'เครื่องเขียน'];
      case 'เงินเดือน':
        return const [
          'เงินเดือนประจำ',
          'โบนัสพิเศษ',
          'เงินตกเบิก',
          'ค่าทำงานล่วงเวลา',
        ];
      case 'ฟรีแลนซ์/งานเสริม':
        return const [
          'งานฟรีแลนซ์',
          'รับจ้างทั่วไป',
          'ขายของออนไลน์',
          'ค่าคอมมิชชั่น',
        ];
      case 'โบนัส':
        return const ['โบนัสประจำปี', 'โบนัสผลงาน', 'รางวัลพิเศษ'];
      case 'เงินปันผล/ดอกเบี้ย':
        return const ['เงินปันผลหุ้น', 'ดอกเบี้ยเงินฝาก', 'ปันผลกองทุน'];
      case 'ขายของ':
        return const ['ขายของหน้าร้าน', 'ขายของออนไลน์', 'ของมือสอง'];
      case 'เงินออม/DCA':
        return const [
          'DCA หุ้นประจำงวด',
          'DCA กองทุนรวม',
          'เงินฝากประจำ',
          'ซื้อทองคำแท่ง',
        ];
      case 'กองทุนรวม':
        return const [
          'SSF ลดหย่อนภาษี',
          'RMF เพื่อการเกษียณ',
          'กองทุนรวมดัชนี',
        ];
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
      } else if (key == LogicalKeyboardKey.period ||
          key == LogicalKeyboardKey.numpadDecimal) {
        _onNumpadPress('.');
      } else if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        _submit();
      } else if (key == LogicalKeyboardKey.digit0 ||
          key == LogicalKeyboardKey.numpad0) {
        _onNumpadPress('0');
      } else if (key == LogicalKeyboardKey.digit1 ||
          key == LogicalKeyboardKey.numpad1) {
        _onNumpadPress('1');
      } else if (key == LogicalKeyboardKey.digit2 ||
          key == LogicalKeyboardKey.numpad2) {
        _onNumpadPress('2');
      } else if (key == LogicalKeyboardKey.digit3 ||
          key == LogicalKeyboardKey.numpad3) {
        _onNumpadPress('3');
      } else if (key == LogicalKeyboardKey.digit4 ||
          key == LogicalKeyboardKey.numpad4) {
        _onNumpadPress('4');
      } else if (key == LogicalKeyboardKey.digit5 ||
          key == LogicalKeyboardKey.numpad5) {
        _onNumpadPress('5');
      } else if (key == LogicalKeyboardKey.digit6 ||
          key == LogicalKeyboardKey.numpad6) {
        _onNumpadPress('6');
      } else if (key == LogicalKeyboardKey.digit7 ||
          key == LogicalKeyboardKey.numpad7) {
        _onNumpadPress('7');
      } else if (key == LogicalKeyboardKey.digit8 ||
          key == LogicalKeyboardKey.numpad8) {
        _onNumpadPress('8');
      } else if (key == LogicalKeyboardKey.digit9 ||
          key == LogicalKeyboardKey.numpad9) {
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
      _amountBuffer = next % 1 == 0
          ? next.toInt().toString()
          : next.toStringAsFixed(2);
    });
  }

  void _onTypeChange(TransactionType type, {bool isWithdrawal = false}) {
    HapticFeedback.selectionClick();
    setState(() {
      _isWithdrawal = isWithdrawal;
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

  Future<void> _pickTime() async {
    HapticFeedback.selectionClick();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _selectedDate.hour,
        minute: _selectedDate.minute,
      ),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
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
    final customNote = _noteController.text.trim();

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
        costNature: _selectedType == TransactionType.expense
            ? _selectedCostNature
            : CostNature.notApplicable,
        categoryName: _selectedCategory,
        date: _selectedDate,
        note: customNote.isNotEmpty ? customNote : null,
      );
      controller.updateTransaction(updated);
    } else {
      final item = TransactionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: finalTitle,
        amount: amount,
        type: _selectedType,
        costNature: _selectedType == TransactionType.expense
            ? _selectedCostNature
            : CostNature.notApplicable,
        categoryName: _selectedCategory,
        date: _selectedDate,
        note: customNote.isNotEmpty ? customNote : null,
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
      message: _isWithdrawal
          ? 'withdrawal_success_msg'.trParams({'title': finalTitle.tr})
          : (isEditMode
                ? 'update_success_msg'.trParams({'title': finalTitle.tr})
                : 'save_success_msg'.trParams({'title': finalTitle.tr})),
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
    if (target == today) return '${'today'.tr} (${d.day}/${d.month})';
    if (target == today.subtract(const Duration(days: 1))) {
      return '${'yesterday'.tr} (${d.day}/${d.month})';
    }
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
      child:
          Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.nothingBorder
                          : Colors.black.withValues(alpha: 0.1),
                      width: 0.8,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.6 : 0.15,
                      ),
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
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subtle Drag Handle Bar
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF333333)
                                : const Color(0xFFDDDDDD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header
                      AppPopupHeader(
                        title: isEditMode
                            ? (_isWithdrawal
                                  ? 'withdraw_from_savings'.tr
                                  : 'edit_transaction_title'.tr)
                            : (_isWithdrawal
                                  ? 'withdraw_from_savings'.tr
                                  : 'record_income_expense'.tr),
                        subtitle: isEditMode
                            ? 'edit_transaction_desc'.tr
                            : (_isWithdrawal
                                  ? 'savings_withdrawal'.tr
                                  : 'record_transaction_desc'.tr),
                        icon: _isWithdrawal
                            ? Icons.outbox_rounded
                            : (_selectedType == TransactionType.expense
                                  ? Icons.arrow_downward_rounded
                                  : (_selectedType == TransactionType.income
                                        ? Icons.arrow_upward_rounded
                                        : Icons.savings_outlined)),
                        iconColor: _isWithdrawal
                            ? const Color(0xFFF59E0B)
                            : (_selectedType == TransactionType.expense
                                  ? (isDark
                                        ? AppColors.nothingRedLight
                                        : AppColors.nothingRed)
                                  : (_selectedType == TransactionType.income
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF3B82F6))),
                        trailing: isEditMode
                            ? IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: isDark
                                      ? AppColors.nothingRedLight
                                      : AppColors.nothingRed,
                                  size: 20,
                                ),
                                onPressed: _delete,
                                tooltip: 'delete_this_item'.tr,
                              )
                            : Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Get.back();
                                    BankSlipScanModal.show(context);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1C1C1C)
                                          : const Color(0xFFF0F0F0),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.nothingBorder
                                            : Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.document_scanner_outlined,
                                          size: 14,
                                          color: AppColors.nothingRed,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'scan_bank_slip'.tr.toUpperCase(),
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),

                      // Header Type Selector (Nothing OS Segmented Pill Deck - 4 Tabs)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF000000)
                              : const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.nothingBorder
                                : Colors.black.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTypeSegment(
                                type: TransactionType.expense,
                                isWithdrawal: false,
                                label: 'expense'.tr.toUpperCase(),
                                color: AppColors.nothingRed,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: _buildTypeSegment(
                                type: TransactionType.income,
                                isWithdrawal: false,
                                label: 'income'.tr.toUpperCase(),
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: _buildTypeSegment(
                                type: TransactionType.savingsInvestment,
                                isWithdrawal: false,
                                label: 'filter_savings'.tr.toUpperCase(),
                                color: const Color(0xFF3B82F6),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: _buildTypeSegment(
                                type: TransactionType.income,
                                isWithdrawal: true,
                                label: 'withdrawal'.tr.toUpperCase(),
                                color: const Color(0xFFF59E0B),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Fixed vs Variable (for expense)
                      if (_selectedType == TransactionType.expense &&
                          !_isWithdrawal)
                        Row(
                          children: [
                            _buildCostNaturePill(
                              CostNature.variable,
                              'variable_cost'.tr,
                              'variable_cost_desc'.tr,
                              isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildCostNaturePill(
                              CostNature.fixed,
                              'fixed_cost'.tr,
                              'fixed_cost_desc'.tr,
                              isDark,
                            ),
                          ],
                        ),
                      if (_selectedType == TransactionType.expense &&
                          !_isWithdrawal)
                        const SizedBox(height: 12),

                      // Category Pills Carousel
                      SizedBox(
                        height: 38,
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
                                setState(
                                  () =>
                                      _selectedCategory = cat['name'] as String,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? Colors.white : Colors.black)
                                      : (isDark
                                            ? const Color(0xFF161616)
                                            : const Color(0xFFF3F3F3)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? Colors.white : Colors.black)
                                        : (isDark
                                              ? AppColors.nothingBorder
                                              : Colors.black.withValues(
                                                  alpha: 0.08,
                                                )),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat['icon'] as IconData,
                                      size: 14,
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.black
                                                : Colors.white)
                                          : (isDark
                                                ? AppColors.nothingSubtext
                                                : const Color(0xFF777777)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      (cat['name'] as String).tr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? (isDark
                                                  ? Colors.black
                                                  : Colors.white)
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.black),
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
                          const NothingLedIndicator(
                            color: AppColors.nothingRed,
                            size: 5,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'quick_suggestions_hint'.tr.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? AppColors.nothingSubtext
                                    : const Color(0xFF777777),
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

                      // Hero Amount Display Area (Nothing OS Dot-Matrix / Monospace readout)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF000000)
                              : const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.nothingBorder
                                : Colors.black.withValues(alpha: 0.1),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  NothingPill(
                                    label: _selectedCategory.tr,
                                    color:
                                        (_isWithdrawal
                                                ? const Color(0xFFF59E0B)
                                                : (_selectedType ==
                                                          TransactionType
                                                              .expense
                                                      ? AppColors.nothingRed
                                                      : (_selectedType ==
                                                                TransactionType
                                                                    .income
                                                            ? const Color(
                                                                0xFF10B981,
                                                              )
                                                            : const Color(
                                                                0xFF3B82F6,
                                                              ))))
                                            .withValues(alpha: 0.16),
                                    textColor: _isWithdrawal
                                        ? const Color(0xFFF59E0B)
                                        : (_selectedType ==
                                                  TransactionType.expense
                                              ? AppColors.nothingRed
                                              : (_selectedType ==
                                                        TransactionType.income
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFF3B82F6))),
                                    isDotMatrix: true,
                                    fontSize: 9.5,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                  ),
                                  if (_titleController.text.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _titleController.text,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (_noteController.text.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _noteController.text,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.nothingSubtext
                                            : const Color(0xFF777777),
                                        fontStyle: FontStyle.italic,
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
                                      _amountBuffer.isEmpty
                                          ? '0'
                                          : _amountBuffer,
                                      style: GoogleFonts.shareTechMono(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '฿',
                                      style: GoogleFonts.shareTechMono(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: _isWithdrawal
                                            ? const Color(0xFFF59E0B)
                                            : (_selectedType ==
                                                      TransactionType.expense
                                                  ? (isDark
                                                        ? AppColors
                                                              .nothingRedLight
                                                        : AppColors.nothingRed)
                                                  : (_selectedType ==
                                                            TransactionType
                                                                .income
                                                        ? const Color(
                                                            0xFF10B981,
                                                          )
                                                        : const Color(
                                                            0xFF3B82F6,
                                                          ))),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark
                                                ? AppColors.nothingRedLight
                                                : AppColors.nothingRed)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          (isDark
                                                  ? AppColors.nothingRedLight
                                                  : AppColors.nothingRed)
                                              .withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.clear_rounded,
                                        size: 12,
                                        color: isDark
                                            ? AppColors.nothingRedLight
                                            : AppColors.nothingRed,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'CLEAR',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: isDark
                                              ? AppColors.nothingRedLight
                                              : AppColors.nothingRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Built-in 4x3 Ergonomic Numpad in Nothing OS style
                      _buildNumpadGrid(isDark),
                      const SizedBox(height: 10),

                      // Date Selection Row & Note
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF000000)
                              : const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.nothingBorder
                                : Colors.black.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDate(_selectedDate),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildDateChip('today'.tr.toUpperCase(), () {
                              setState(() => _selectedDate = DateTime.now());
                            }, isDark),
                            const SizedBox(width: 5),
                            _buildDateChip('yesterday'.tr.toUpperCase(), () {
                              final now = DateTime.now();
                              setState(
                                () => _selectedDate = DateTime(
                                  now.year,
                                  now.month,
                                  now.day - 1,
                                  now.hour,
                                  now.minute,
                                ),
                              );
                            }, isDark),
                            const SizedBox(width: 5),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : const Color(0xFFE5E5E5),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Icon(
                                  Icons.edit_calendar_outlined,
                                  size: 13,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            InkWell(
                              onTap: _pickTime,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : const Color(0xFFE5E5E5),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_outlined,
                                      size: 12,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      DateFormat('HH:mm').format(_selectedDate),
                                      style: GoogleFonts.shareTechMono(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
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

                      // Title TextField
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(_noteFocusNode),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'title_hint'.tr,
                          hintStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 11.5,
                            color: AppColors.nothingSubtext,
                          ),
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          suffixIcon: _titleController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 15,
                                  ),
                                  onPressed: () =>
                                      setState(() => _titleController.clear()),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF000000)
                              : const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.nothingBorder
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.nothingBorder
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white : Colors.black,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Note TextField
                      TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'note_hint'.tr,
                          hintStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 11.5,
                            color: AppColors.nothingSubtext,
                          ),
                          prefixIcon: Icon(
                            Icons.notes_outlined,
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          suffixIcon: _noteController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 15,
                                  ),
                                  onPressed: () =>
                                      setState(() => _noteController.clear()),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF000000)
                              : const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.nothingBorder
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.nothingBorder
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white : Colors.black,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Submit Button in Nothing OS Signature Red
                      ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSuccess
                              ? const Color(0xFF10B981)
                              : (isDark
                                    ? AppColors.nothingRedLight
                                    : AppColors.nothingRed),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isSuccess
                              ? Row(
                                  key: const ValueKey('submit_success'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      (isEditMode
                                              ? 'update_success_title'.tr
                                              : 'save_success_title'.tr)
                                          .toUpperCase(),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  (isEditMode
                                          ? 'save_changes'.tr
                                          : 'add_transaction'.tr)
                                      .toUpperCase(),
                                  key: const ValueKey('submit_idle'),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: 0.05,
                end: 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
              )
              .scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
              ),
    );
  }

  Widget _buildSmartSuggestions(bool isDark) {
    final suggestions = _getCategorySuggestions(_selectedCategory);
    return SizedBox(
      height: 30,
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark
                          ? const Color(0xFF161616)
                          : const Color(0xFFF1F1F1)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark
                            ? AppColors.nothingBorder
                            : Colors.black.withValues(alpha: 0.08)),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white : Colors.black),
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
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isDark
                ? AppColors.nothingBorder
                : Colors.black.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required TransactionType type,
    required bool isWithdrawal,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type && _isWithdrawal == isWithdrawal;

    return GestureDetector(
      onTap: () => _onTypeChange(type, isWithdrawal: isWithdrawal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (type == TransactionType.expense
                    ? (isDark
                          ? AppColors.nothingRedLight
                          : AppColors.nothingRed)
                    : (isWithdrawal
                          ? const Color(0xFFF59E0B)
                          : (isDark ? Colors.white : Colors.black)))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.5,
            color: isSelected
                ? (type == TransactionType.expense || isWithdrawal
                      ? Colors.white
                      : (isDark ? Colors.black : Colors.white))
                : (isDark ? AppColors.nothingSubtext : const Color(0xFF777777)),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCostNaturePill(
    CostNature nature,
    String label,
    String subtitle,
    bool isDark,
  ) {
    final isSelected = _selectedCostNature == nature;

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
            color: isSelected
                ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDEDED))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08)),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.6,
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  color: isDark
                      ? AppColors.nothingSubtext
                      : const Color(0xFF888888),
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
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181818) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isDark
                ? AppColors.nothingBorder
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.shareTechMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _NumpadButton(
                    keyLabel: key,
                    onTap: () => _onNumpadPress(key),
                    isDark: isDark,
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

/// Numpad Key พร้อม Micro Press-Scale Animation สไตล์ Nothing OS
class _NumpadButton extends StatefulWidget {
  final String keyLabel;
  final VoidCallback onTap;
  final bool isDark;

  const _NumpadButton({
    required this.keyLabel,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_isPressed
                      ? const Color(0xFF242424)
                      : const Color(0xFF161616))
                : (_isPressed
                      ? const Color(0xFFE2E2E2)
                      : const Color(0xFFF4F4F4)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.nothingBorder
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: widget.keyLabel == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  size: 17,
                  color: widget.isDark ? Colors.white : Colors.black,
                )
              : Text(
                  widget.keyLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}
