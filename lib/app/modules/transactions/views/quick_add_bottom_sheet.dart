import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/scheduled_payment_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import 'bank_slip_sheet.dart';

/// Quick Add & Edit BottomSheet พร้อม Ergonomic Numpad และระบบเลือกวันที่ (FinTech 2026 Edition)
class QuickAddBottomSheet extends StatefulWidget {
  final TransactionItem? existingItem;
  final ScheduledPaymentItem? existingScheduledItem;
  final bool initialIsScheduled;
  final double? initialAmount;
  final String? initialCategory;
  final CostNature? initialCostNature;

  const QuickAddBottomSheet({
    super.key,
    this.existingItem,
    this.existingScheduledItem,
    this.initialIsScheduled = false,
    this.initialAmount,
    this.initialCategory,
    this.initialCostNature,
  });

  static void show(
    BuildContext context, {
    TransactionItem? existingItem,
    ScheduledPaymentItem? existingScheduledItem,
    bool initialIsScheduled = false,
    double? initialAmount,
    String? initialCategory,
    CostNature? initialCostNature,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      Get.dialog(
        AppGlassDialog(
          maxWidth: 480,
          padding: const EdgeInsets.all(22),
          child: QuickAddBottomSheet(
            existingItem: existingItem,
            existingScheduledItem: existingScheduledItem,
            initialIsScheduled: initialIsScheduled,
            initialAmount: initialAmount,
            initialCategory: initialCategory,
            initialCostNature: initialCostNature,
          ),
        ),
      );
    } else {
      Get.bottomSheet(
        QuickAddBottomSheet(
          existingItem: existingItem,
          existingScheduledItem: existingScheduledItem,
          initialIsScheduled: initialIsScheduled,
          initialAmount: initialAmount,
          initialCategory: initialCategory,
          initialCostNature: initialCostNature,
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
  late bool _isScheduled;
  late ScheduleFrequency _scheduleFrequency;
  late bool _autoRecord;

  bool get isEditMode =>
      widget.existingItem != null || widget.existingScheduledItem != null;

  @override
  void initState() {
    super.initState();
    final scheduledItem = widget.existingScheduledItem;
    final item = widget.existingItem;

    if (scheduledItem != null) {
      _amountBuffer = scheduledItem.amount % 1 == 0
          ? scheduledItem.amount.toInt().toString()
          : scheduledItem.amount.toStringAsFixed(2);
      _titleController = TextEditingController(text: scheduledItem.title);
      _noteController = TextEditingController(text: scheduledItem.note ?? '');
      _isWithdrawal = false;
      _selectedType = scheduledItem.type;
      _selectedCostNature = scheduledItem.costNature;
      _selectedCategory = scheduledItem.categoryName;
      _selectedDate = scheduledItem.nextDueDate;
      _isScheduled = true;
      _scheduleFrequency = scheduledItem.frequency;
      _autoRecord = scheduledItem.autoRecord;
    } else if (item != null) {
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
      _isScheduled = false;
      _scheduleFrequency = ScheduleFrequency.monthly;
      _autoRecord = false;
    } else {
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountBuffer = widget.initialAmount! % 1 == 0
            ? widget.initialAmount!.toInt().toString()
            : widget.initialAmount!.toStringAsFixed(2);
      } else {
        _amountBuffer = '';
      }
      _titleController = TextEditingController();
      _noteController = TextEditingController();
      _isWithdrawal = false;
      _selectedType = TransactionType.expense;
      _selectedCostNature = widget.initialCostNature ??
          (widget.initialIsScheduled ? CostNature.fixed : CostNature.variable);
      _selectedCategory = widget.initialCategory ?? 'อาหาร/ของกิน';
      _selectedDate = DateTime.now();
      _isScheduled = widget.initialIsScheduled;
      _scheduleFrequency = ScheduleFrequency.monthly;
      _autoRecord = false;
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

  static const Map<String, List<String>> _withdrawalSuggestions = {
    'en': [
      'Emergency Fund',
      'Living Expenses',
      'Debt Payoff',
      'Medical Bills',
      'Travel / Leisure',
      'Major Purchase',
    ],
    'th': [
      'สำรองฉุกเฉิน',
      'ค่าใช้จ่ายจำเป็น',
      'ปิดหนี้สิน',
      'ค่ารักษาพยาบาล',
      'ท่องเที่ยวพักผ่อน',
      'ซื้อของชิ้นใหญ่',
    ],
  };

  static const Map<String, List<String>> _defaultSuggestions = {
    'en': ['General Expense', 'Essential', 'Other'],
    'th': ['ค่าใช้จ่ายทั่วไป', 'จำเป็น', 'อื่นๆ'],
  };

  static const Map<String, Map<String, List<String>>>
  _categorySuggestionsMap = {
    'อาหาร/ของกิน': {
      'en': [
        'Breakfast',
        'Lunch',
        'Dinner',
        'Snacks',
        '7-Eleven',
        'Food Delivery',
      ],
      'th': [
        'ข้าวแกง/ตามสั่ง',
        'ก๋วยเตี๋ยว',
        'เซเว่น 7-11',
        'Grab/Lineman',
        'มื้อเย็น/สังสรรค์',
        'ขนม/ของว่าง',
      ],
    },
    'กาแฟ/เครื่องดื่ม': {
      'en': [
        'Americano',
        'Latte',
        'Matcha Green Tea',
        'Thai Tea',
        'Boba / Milk Tea',
        'Water',
      ],
      'th': [
        'อเมริกาโน่',
        'ลาเต้',
        'ชาเขียวมัทฉะ',
        'ชาไทย',
        'ชานมไข่มุก',
        'น้ำดื่ม',
      ],
    },
    'การเดินทาง': {
      'en': [
        'BTS / MRT',
        'Gas / Fuel',
        'Grab / Taxi',
        'Bus Fare',
        'Expressway Toll',
        'Motorbike',
      ],
      'th': [
        'BTS / MRT',
        'เติมน้ำมัน',
        'Grab/แท็กซี่',
        'รถเมล์/สองแถว',
        'ทางด่วน',
        'วินมอเตอร์ไซค์',
      ],
    },
    'ช้อปปิ้ง': {
      'en': ['Clothing', 'Online Shopping', 'Home Decor', 'Gadgets & Tech'],
      'th': [
        'ของใช้ส่วนตัว',
        'เสื้อผ้า',
        'Shopee/Lazada',
        'ของแต่งบ้าน',
        'เครื่องใช้ไฟฟ้า',
      ],
    },
    'ของใช้ส่วนตัว': {
      'en': [
        'Toiletries',
        'Laundry Detergent',
        'Tissues',
        'Haircut',
        'Skincare',
      ],
      'th': [
        'สบู่/ยาสระผม',
        'ผงซักฟอก',
        'กระดาษทิชชู่',
        'ตัดผม',
        'เครื่องสำอาง',
      ],
    },
    'ที่อยู่อาศัย': {
      'en': ['Rent / Condo', 'Mortgage', 'Common Fee', 'Home Repairs'],
      'th': ['ค่าเช่าห้อง/คอนโด', 'ค่างวดบ้าน', 'ค่าส่วนกลาง', 'ซ่อมแซมบ้าน'],
    },
    'สาธารณูปโภค': {
      'en': [
        'Electricity',
        'Water Bill',
        'Home WiFi',
        'Mobile Bill',
        'Subscriptions',
      ],
      'th': [
        'ค่าไฟ',
        'ค่าน้ำประปา',
        'เน็ตบ้าน/WiFi',
        'ค่าโทรศัพท์',
        'Netflix/Spotify',
      ],
    },
    'บันเทิง/พักผ่อน': {
      'en': [
        'Movie Tickets',
        'Gaming',
        'Concert',
        'Travel / Hotel',
        'Party & Drinks',
      ],
      'th': [
        'ตั๋วหนัง',
        'เติมเกม',
        'คอนเสิร์ต',
        'ท่องเที่ยว/ที่พัก',
        'สังสรรค์',
      ],
    },
    'สุขภาพ/ยา': {
      'en': [
        'Clinic / Doctor',
        'Medicine & Vitamins',
        'Dental',
        'Health Checkup',
        'Insurance',
      ],
      'th': [
        'หาหมอ/คลินิก',
        'ค่ายา/วิตามิน',
        'ทำฟัน',
        'ตรวจสุขภาพ',
        'ประกันสุขภาพ',
      ],
    },
    'การศึกษา': {
      'en': ['Online Course', 'Books', 'Tuition Fee', 'Stationery'],
      'th': ['คอร์สเรียน', 'หนังสือ', 'ค่าเทอม', 'เครื่องเขียน'],
    },
    'เงินเดือน': {
      'en': [
        'Monthly Salary',
        'Performance Bonus',
        'Back Pay',
        'Overtime (OT)',
      ],
      'th': ['เงินเดือนประจำ', 'โบนัสพิเศษ', 'เงินตกเบิก', 'ค่าทำงานล่วงเวลา'],
    },
    'ฟรีแลนซ์/งานเสริม': {
      'en': ['Freelance Gig', 'Side Project', 'Online Sales', 'Commission'],
      'th': ['งานฟรีแลนซ์', 'รับจ้างทั่วไป', 'ขายของออนไลน์', 'ค่าคอมมิชชั่น'],
    },
    'โบนัส': {
      'en': ['Annual Bonus', 'Performance Bonus', 'Special Reward'],
      'th': ['โบนัสประจำปี', 'โบนัสผลงาน', 'รางวัลพิเศษ'],
    },
    'เงินปันผล/ดอกเบี้ย': {
      'en': ['Stock Dividend', 'Bank Interest', 'Fund Dividend'],
      'th': ['เงินปันผลหุ้น', 'ดอกเบี้ยเงินฝาก', 'ปันผลกองทุน'],
    },
    'ขายของ': {
      'en': ['Retail Sales', 'Online Store', 'Secondhand Goods'],
      'th': ['ขายของหน้าร้าน', 'ขายของออนไลน์', 'ของมือสอง'],
    },
    'รายรับอื่นๆ': {
      'en': ['Cash Gift', 'Refund / Cashback', 'Lottery Prize', 'Other Income'],
      'th': [
        'เงินให้เปล่า/ของขวัญ',
        'เงินคืน/Cashback',
        'ถูกรางวัลสลาก',
        'รายรับอื่นๆ',
      ],
    },
    'เงินออม/DCA': {
      'en': ['Stock DCA', 'Fund DCA', 'Fixed Deposit', 'Gold Savings'],
      'th': [
        'DCA หุ้นประจำงวด',
        'DCA กองทุนรวม',
        'เงินฝากประจำ',
        'ซื้อทองคำแท่ง',
      ],
    },
    'กองทุนรวม': {
      'en': ['Index Fund', 'Tax Saving Fund', 'Retirement Fund'],
      'th': ['SSF ลดหย่อนภาษี', 'RMF เพื่อการเกษียณ', 'กองทุนรวมดัชนี'],
    },
    'หุ้น/ตราสาร': {
      'en': ['Common Stock', 'Corporate Bonds', 'Treasury Bills'],
      'th': ['ซื้อหุ้นสามัญ', 'หุ้นกู้เอกชน', 'พันธบัตรรัฐบาล'],
    },
    'เงินสำรองฉุกเฉิน': {
      'en': ['Emergency Fund', 'High-Yield Savings'],
      'th': ['ฝากสำรองฉุกเฉิน', 'บัญชีดิจิทัลดอกเบี้ยสูง'],
    },
    'สินทรัพย์อื่นๆ': {
      'en': ['Real Estate', 'Crypto DCA', 'Precious Metals'],
      'th': ['อสังหาริมทรัพย์', 'Crypto DCA', 'ทองคำ/โลหะมีค่า'],
    },
  };

  List<String> _getCategorySuggestions(String category) {
    final langKey = controller.isEnglish ? 'en' : 'th';
    if (_isWithdrawal) {
      return _withdrawalSuggestions[langKey] ?? const [];
    }
    return _categorySuggestionsMap[category]?[langKey] ??
        _defaultSuggestions[langKey] ??
        const [];
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

    if (widget.existingScheduledItem != null) {
      final updated = widget.existingScheduledItem!.copyWith(
        title: finalTitle,
        amount: amount,
        type: _selectedType,
        costNature: _selectedType == TransactionType.expense
            ? _selectedCostNature
            : CostNature.notApplicable,
        categoryName: _selectedCategory,
        frequency: _scheduleFrequency,
        nextDueDate: _selectedDate,
        autoRecord: _autoRecord,
        note: customNote.isNotEmpty ? customNote : null,
      );
      controller.updateScheduledPayment(updated, notify: false);

      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;

      Get.back();

      AppFeedback.showSuccess(
        title: 'schedule_updated_title'.tr,
        message: 'schedule_updated_msg'.trParams({'title': finalTitle.tr}),
        amount: amount,
        transactionType: _selectedType,
      );
      return;
    }

    if (_isScheduled) {
      final scheduledItem = ScheduledPaymentItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: finalTitle,
        amount: amount,
        type: _selectedType,
        costNature: _selectedType == TransactionType.expense
            ? _selectedCostNature
            : CostNature.notApplicable,
        categoryName: _selectedCategory,
        frequency: _scheduleFrequency,
        startDate: _selectedDate,
        nextDueDate: _selectedDate,
        autoRecord: _autoRecord,
        status: ScheduledPaymentStatus.active,
        note: customNote.isNotEmpty ? customNote : null,
      );
      controller.addScheduledPayment(scheduledItem, notify: false);

      if (_autoRecord && scheduledItem.isDue) {
        controller.executeScheduledPayment(
          scheduledItem,
          executionDate: _selectedDate,
          notify: false,
        );
      }

      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;

      Get.back();

      AppFeedback.showSuccess(
        title: 'scheduled_success_title'.tr,
        message: 'scheduled_success_msg'.trParams({'title': finalTitle.tr}),
        amount: amount,
        transactionType: _selectedType,
      );
      return;
    }

    if (isEditMode && widget.existingItem != null) {
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
    if (widget.existingScheduledItem != null) {
      final title = widget.existingScheduledItem!.title;
      controller.deleteScheduledPayment(widget.existingScheduledItem!.id);
      Get.back();
      AppFeedback.showInfo(
        title: 'delete_success_title'.tr,
        message: 'delete_success_msg'.trParams({'title': title.tr}),
      );
      return;
    }
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
                                          style: NothingTypography.grotesk(
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
                              style: NothingTypography.grotesk(
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
                                      style: NothingTypography.grotesk(
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
                                      style: NothingTypography.grotesk(
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
                                style: NothingTypography.grotesk(
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
                        style: NothingTypography.grotesk(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'title_hint'.tr,
                          hintStyle: NothingTypography.grotesk(
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
                        style: NothingTypography.grotesk(
                          fontSize: 12.5,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'note_hint'.tr,
                          hintStyle: NothingTypography.grotesk(
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
                      const SizedBox(height: 10),

                      // ==========================================
                      // Schedule / Recurring Payment Toggle & Controls
                      // ==========================================
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141414)
                              : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isScheduled
                                ? AppColors.nothingRed.withValues(alpha: 0.6)
                                : (isDark
                                      ? AppColors.nothingBorder
                                      : Colors.black.withValues(alpha: 0.08)),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _isScheduled = !_isScheduled;
                                  if (_isScheduled &&
                                      _selectedType == TransactionType.expense &&
                                      _selectedCostNature == CostNature.variable) {
                                    _selectedCostNature = CostNature.fixed;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isScheduled
                                            ? AppColors.nothingRed.withValues(
                                                alpha: 0.15,
                                              )
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.06,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.05,
                                                    )),
                                      ),
                                      child: Icon(
                                        Icons.alarm_on_rounded,
                                        size: 16,
                                        color: _isScheduled
                                            ? AppColors.nothingRed
                                            : (isDark
                                                  ? AppColors.nothingMuted
                                                  : AppColors.textSecondary),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'schedule_mode_toggle'.tr,
                                            style: NothingTypography.grotesk(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            'schedule_payment_desc'.tr,
                                            style: NothingTypography.grotesk(
                                              fontSize: 10.5,
                                              color: isDark
                                                  ? AppColors.nothingSubtext
                                                  : AppColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _isScheduled,
                                      activeTrackColor: AppColors.nothingRed,
                                      activeThumbColor: Colors.white,
                                      onChanged: (val) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _isScheduled = val;
                                          if (_isScheduled &&
                                              _selectedType == TransactionType.expense &&
                                              _selectedCostNature == CostNature.variable) {
                                            _selectedCostNature = CostNature.fixed;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isScheduled) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Divider(
                                      height: 1,
                                      thickness: 0.8,
                                      color: isDark
                                          ? AppColors.nothingBorder
                                          : Colors.black.withValues(alpha: 0.08),
                                    ),
                                    const SizedBox(height: 10),

                                    // Popular Preset Suggestions Strip
                                    Text(
                                      'preset_bills_header'.tr.toUpperCase(),
                                      style: NothingTypography.grotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.nothingSubtext
                                            : AppColors.textSecondary,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        children: controller.popularScheduledPresets.map((preset) {
                                          final isSelected = _titleController.text == preset.titleKey.tr;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: InkWell(
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                setState(() {
                                                  _titleController.text = preset.titleKey.tr;
                                                  _selectedCategory = preset.categoryName;
                                                  _selectedCostNature = preset.costNature;
                                                  _selectedType = preset.type;
                                                  _scheduleFrequency = preset.frequency;
                                                  if (_amountBuffer.isEmpty && preset.suggestedAmount != null) {
                                                    final amt = preset.suggestedAmount!;
                                                    _amountBuffer = amt % 1 == 0
                                                        ? amt.toInt().toString()
                                                        : amt.toStringAsFixed(2);
                                                  }
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 9,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.nothingRed.withValues(alpha: 0.15)
                                                      : (isDark
                                                          ? const Color(0xFF1E1E1E)
                                                          : const Color(0xFFE8E8E8)),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppColors.nothingRed.withValues(alpha: 0.5)
                                                        : (isDark
                                                            ? AppColors.nothingBorder
                                                            : Colors.black.withValues(alpha: 0.08)),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      preset.icon,
                                                      size: 13,
                                                      color: isSelected
                                                          ? AppColors.nothingRed
                                                          : (isDark
                                                              ? Colors.white70
                                                              : Colors.black87),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      preset.titleKey.tr,
                                                      style: NothingTypography.grotesk(
                                                        fontSize: 10.5,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                        color: isSelected
                                                            ? AppColors.nothingRed
                                                            : (isDark
                                                                ? Colors.white
                                                                : Colors.black),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    Text(
                                      'schedule_frequency'.tr.toUpperCase(),
                                      style: NothingTypography.grotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.nothingSubtext
                                            : AppColors.textSecondary,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _buildFrequencyChip(
                                          ScheduleFrequency.oneTime,
                                          'frequency_one_time'.tr,
                                          isDark,
                                        ),
                                        _buildFrequencyChip(
                                          ScheduleFrequency.monthly,
                                          'frequency_monthly'.tr,
                                          isDark,
                                        ),
                                        _buildFrequencyChip(
                                          ScheduleFrequency.weekly,
                                          'frequency_weekly'.tr,
                                          isDark,
                                        ),
                                        _buildFrequencyChip(
                                          ScheduleFrequency.daily,
                                          'frequency_daily'.tr,
                                          isDark,
                                        ),
                                        _buildFrequencyChip(
                                          ScheduleFrequency.yearly,
                                          'frequency_yearly'.tr,
                                          isDark,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'execution_mode'.tr.toUpperCase(),
                                      style: NothingTypography.grotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.nothingSubtext
                                            : AppColors.textSecondary,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildExecutionModeTile(
                                            title: 'manual_confirm'.tr,
                                            subtitle: 'manual_confirm_desc'.tr,
                                            icon: Icons
                                                .notifications_active_outlined,
                                            isSelected: !_autoRecord,
                                            isDark: isDark,
                                            onTap: () => setState(
                                              () => _autoRecord = false,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildExecutionModeTile(
                                            title: 'auto_record'.tr,
                                            subtitle: 'auto_record_desc'.tr,
                                            icon: Icons.bolt_rounded,
                                            isSelected: _autoRecord,
                                            isDark: isDark,
                                            onTap: () => setState(
                                              () => _autoRecord = true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_scheduleFrequency ==
                                        ScheduleFrequency.monthly) ...[
                                      const SizedBox(height: 10),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            _buildQuickDuePreset(
                                              label:
                                                  'quick_due_end_of_month'.tr,
                                              onTap: () {
                                                final now = DateTime.now();
                                                final endDay = DateTime(
                                                  now.year,
                                                  now.month + 1,
                                                  0,
                                                ).day;
                                                setState(() {
                                                  _selectedDate = DateTime(
                                                    now.year,
                                                    now.month,
                                                    endDay,
                                                    _selectedDate.hour,
                                                    _selectedDate.minute,
                                                  );
                                                });
                                              },
                                              isDark: isDark,
                                            ),
                                            const SizedBox(width: 6),
                                            _buildQuickDuePreset(
                                              label:
                                                  'quick_due_next_month_1st'.tr,
                                              onTap: () {
                                                final now = DateTime.now();
                                                final nextMonth = now.month ==
                                                        12
                                                    ? 1
                                                    : now.month + 1;
                                                final nextYear = now.month == 12
                                                    ? now.year + 1
                                                    : now.year;
                                                setState(() {
                                                  _selectedDate = DateTime(
                                                    nextYear,
                                                    nextMonth,
                                                    1,
                                                    _selectedDate.hour,
                                                    _selectedDate.minute,
                                                  );
                                                });
                                              },
                                              isDark: isDark,
                                            ),
                                            const SizedBox(width: 6),
                                            _buildQuickDuePreset(
                                              label:
                                                  'quick_due_next_month_25th'.tr,
                                              onTap: () {
                                                final now = DateTime.now();
                                                final nextMonth = now.month ==
                                                        12
                                                    ? 1
                                                    : now.month + 1;
                                                final nextYear = now.month == 12
                                                    ? now.year + 1
                                                    : now.year;
                                                setState(() {
                                                  _selectedDate = DateTime(
                                                    nextYear,
                                                    nextMonth,
                                                    25,
                                                    _selectedDate.hour,
                                                    _selectedDate.minute,
                                                  );
                                                });
                                              },
                                              isDark: isDark,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_selectedType == TransactionType.expense &&
                                        _selectedCostNature == CostNature.fixed &&
                                        (double.tryParse(_amountBuffer) ?? 0.0) > 0) ...[
                                      const SizedBox(height: 10),
                                      Builder(
                                        builder: (context) {
                                          final amt = double.tryParse(_amountBuffer) ?? 0.0;
                                          double monthlyBurn = amt;
                                          switch (_scheduleFrequency) {
                                            case ScheduleFrequency.monthly:
                                              monthlyBurn = amt;
                                              break;
                                            case ScheduleFrequency.yearly:
                                              monthlyBurn = amt / 12.0;
                                              break;
                                            case ScheduleFrequency.weekly:
                                              monthlyBurn = (amt * 52.0) / 12.0;
                                              break;
                                            case ScheduleFrequency.daily:
                                              monthlyBurn = amt * 30.0;
                                              break;
                                            case ScheduleFrequency.oneTime:
                                              monthlyBurn = amt;
                                              break;
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.auto_graph_rounded,
                                                  size: 13,
                                                  color: Color(0xFF3B82F6),
                                                ),
                                                const SizedBox(width: 7),
                                                Expanded(
                                                  child: Text(
                                                    'fixed_budget_impact'.trParams({
                                                      'amount': NumberFormat('#,##0.##').format(monthlyBurn),
                                                    }),
                                                    style: NothingTypography.grotesk(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark
                                                          ? const Color(0xFF93C5FD)
                                                          : const Color(0xFF1D4ED8),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                                      style: NothingTypography.grotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  (_isScheduled
                                          ? 'schedule_payment'.tr
                                          : (isEditMode
                                                ? 'save_changes'.tr
                                                : 'add_transaction'.tr))
                                      .toUpperCase(),
                                  key: const ValueKey('submit_idle'),
                                  style: NothingTypography.grotesk(
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
          style: NothingTypography.grotesk(
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
          style: NothingTypography.grotesk(
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
                style: NothingTypography.grotesk(
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
                style: NothingTypography.grotesk(
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

  Widget _buildFrequencyChip(
    ScheduleFrequency frequency,
    String label,
    bool isDark,
  ) {
    final isSelected = _scheduleFrequency == frequency;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _scheduleFrequency = frequency);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.nothingRed
                : (isDark
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.08)),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: NothingTypography.grotesk(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildExecutionModeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? const Color(0xFF222222)
                    : Colors.black.withValues(alpha: 0.06))
              : (isDark ? const Color(0xFF161616) : const Color(0xFFEBEBEB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.nothingRed
                : (isDark
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.08)),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? AppColors.nothingRed
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: NothingTypography.grotesk(
                      fontSize: 11.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: NothingTypography.grotesk(
                fontSize: 9.5,
                color: isDark
                    ? AppColors.nothingSubtext
                    : AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDuePreset({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? AppColors.nothingBorder
                : Colors.black.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: NothingTypography.grotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
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
