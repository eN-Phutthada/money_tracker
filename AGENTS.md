# AGENTS.md - Guidelines & Development Rules for Money Tracker

> **Project**: Money Tracker (FinTech 2026 Edition)  
> **Tech Stack**: Flutter (Dart), GetX State Management, Nothing OS Design System  
> **Target Platforms**: Mobile (iOS / Android) & Desktop (Windows / macOS / Web)

---

## 1. Core Architecture & Philosophy

- **Framework**: Flutter with **GetX** (`GetxController`, `GetView`, `Obx`, `AppRoutes`).
- **Design Language**: **Nothing OS Industrial Design System** (Squircle geometry, 0.8px hairline borders, Share Tech Mono numbers, Space Grotesk typography, Nothing LED indicators, and Nothing Red `#D71921` accents).
- **Dual Form Factor (Mobile & Desktop)**:
  - **Mobile (< 800px)**: Single-column scroll, floating liquid glass dock, bottom sheet modals (`Get.bottomSheet(..., isScrollControlled: true)`).
  - **Desktop (>= 800px)**: Bento Grid canvas, collapsible sidebar command rail, glass dialog modals (`AppGlassDialog`), and full keyboard navigation shortcuts (`N`, `H`, `T`, `S`, `D`, `M`, `P`, `L`, `1-3`).

---

## 2. 🚨 Critical Rules & Zero-Tolerance Constraints

### 2.1 ห้าม Hardcode ภาษาเด็ดขาด (No Hardcoded Strings)
- **ทุกข้อความที่เป็น User-Facing** (รวมถึงชื่อปุ่ม, ข้อความช่วยเหลือ, หน่วยนับ เช่น `'วัน'`, `'บาท'`, `'ครั้ง'`, สัญลักษณ์, และคำแนะนำ) **ต้องใช้ระบบภาษาผ่าน GetX Translation เสมอ**
- **ไฟล์เก็บคำแปล**: `lib/app/translations/app_translations.dart`
  - ต้องใส่คู่กันทั้งภาษาไทย (`th`) และภาษาอังกฤษ (`en`)
  - ใช้งานผ่าน `.tr` หรือ `.trParams({'key': value})` เสมอ
  - ❌ **ห้ามเด็ดขาด**: `Text('วัน')`, `Text('บันทึกสำเร็จ')`, `Text('Days left')`
  - ✅ **ถูกต้อง**: `Text('days_unit'.tr)`, `Text('save_success_title'.tr)`, `Text('days_left'.trParams({'days': '$days'}))`

### 2.2 Clean Code & Lint Cleanliness
- **ห้ามปล่อยให้มี Unused Import หรือ Unused Variable**:
  - เมื่อปรับโค้ดหรือลบฟังก์ชัน ต้องตรวจสอบและลบ `import` ที่ไม่ได้ใช้งานออกทันที (เช่น `flutter_animate`, `intl`)
  - ห้ามประกาศตัวแปรทิ้งไว้โดยไม่มีการเรียกใช้งาน (`The value of the local variable isn't used`)

### 2.3 การออกแบบสไตล์ Nothing OS
- **Typography**:
  - ตัวเลขสถิติ, ยอดเงิน, คะแนน: ใช้ `GoogleFonts.shareTechMono` หรือ `NothingTypography.mono`
  - ข้อความทั่วไป, หัวข้อ, บันทึก: ใช้ `GoogleFonts.spaceGrotesk` หรือ `NothingTypography.grotesk`
- **Border & Surfaces**:
  - เส้นขอบคมกริบแบบ Hairline: `width: 0.8` (ห้ามใช้เส้นขอบหนา 1.5 - 2.0 เว้นแต่เป็น Focus border ของ input field)
  - ความโค้ง Squircle:
    - การ์ดหลัก: `borderRadius: 28`
    - กล่องข้อความ / Pill สถานะ: `borderRadius: 12` - `14`
    - ป็อปอัป / ชีท: `borderRadius: 22` - `28`
- **LED & Segmented Indicators**:
  - แสดงสถานะด้วย `NothingLedIndicator` (มีเอฟเฟกต์กะพริบ `isPulsing` เมื่ออยู่ในสถานะวิกฤต)
  - มาตรวัดความคืบหน้าแบบแบ่งส่วน: ใช้ `NothingSegmentedBar` (ห้ามใช้แถบ LinearProgress ทึบธรรมดา)

### 2.4 งดใช้ Emoji ทั้งระบบเด็ดขาด (Zero Emoji Tolerance - Use Icons Only)
- **ห้ามใช้ Emoji ตัวอักษรภาพในทุกส่วนของระบบ**:
  - ครอบคลุมทั้งในไฟล์ UI, Widgets, Controller, Model, ข้อมูลจำลอง (Mock), และไฟล์คำแปลภาษา `app_translations.dart` (ทั้งภาษาไทยและอังกฤษ)
  - ❌ **ห้ามเด็ดขาด**: `Text('💰 รายรับ')`, `Text('⚠️ คำเตือน')`, `'category': '🍕 อาหาร'`
  - ✅ **ถูกต้อง**: ใช้ Material Glyph Icons คู่กับข้อความ เช่น `Icon(Icons.south_west_rounded)` คู่กับ `Text('total_inflow'.tr)`
- **เหตุผล**: เพื่อรักษาความคมชัด สะอาดตา และความงามเชิงอุตสาหกรรม (Industrial Aesthetics) ตามแนวทาง Nothing OS

### 2.5 ป้องกัน Text ล้นขอบและการตัดทอนจนอ่านไม่ครบ (Text Overflow & Layout Safety)
- **ห้ามปล่อยให้ Text ล้นขอบจอหรือตัดทอนจนอ่านไม่รู้เรื่อง**:
  - เมื่อมีข้อความภาษาไทยที่มีสระบน-ล่าง หรือข้อความยาว ต้องรองรับขนาดหน้าจอที่หลากหลาย (ตั้งแต่ Mobile หน้าจอแคบ 320px ไปจนถึง Desktop)
  - ใช้ `FittedBox(fit: BoxFit.scaleDown)` สำหรับตัวเลขสถิติ, ยอดเงินสำคัญ หรือ Label ขนาดสั้นในตารางคอลัมน์
  - ใช้ `Expanded` หรือ `Flexible` ครอบข้อความเสมอเมื่ออยู่ใน `Row`
  - ใช้ `NothingTypography.safeSpacing(text, baseSpacing)` ป้องกันไม่ให้ `letterSpacing` ทำให้ข้อความภาษาไทยสระซ้อนหรือล้นเกินกรอบ
  - ข้อความคำแนะนำ (Advice / Insight): อนุญาตให้ขึ้นบรรทัดใหม่ได้ (`maxLines: 2` หรือมากกว่า) ห้ามตัดทิ้งจนผู้ใช้ไม่สามารถเข้าใจเนื้อหา

---

## 3. Directory Structure & Key Files

```
lib/
├── app/
│   ├── data/
│   │   ├── models/           # TransactionItem, BudgetPlan, WalletHealthModel
│   │   └── services/         # StorageService (SharedPreferences), SecurityService
│   ├── modules/
│   │   ├── dashboard/        # DashboardView, DesktopDashboardView, MobileDashboardView
│   │   │   ├── controllers/  # DashboardController (Single Source of Truth)
│   │   │   └── widgets/      # BalanceCard, DailyAllowanceCard, FlFinanceChartCard,
│   │   │                     # RecentTransactionsCard, WalletHealthDiagnosticSheet
│   │   ├── budget/           # BudgetSettingsView, BudgetController
│   │   ├── transactions/     # TransactionsListView, QuickAddBottomSheet
│   │   ├── security/         # PinLockView, PinSettingsView, SecurityController
│   │   └── data_management/  # Backup, Restore, JSON/CSV Export
│   ├── routes/               # AppRoutes, AppPages
│   ├── theme/                # AppColors, AppTheme, AppPopupDecorations
│   ├── translations/         # AppTranslations (TH & EN)
│   └── widgets/              # NothingUiComponents, ModernAppBar, LiquidGlassNavDock
```

---

## 4. State Management & Mathematical Logic Rules

1. **DashboardController เป็นศูนย์กลาง (Single Source of Truth)**:
   - ยอดเงิน, กระแสเงินสด, และตัวชี้วัดสุขภาพการเงินทั้งหมดคำนวณผ่าน Reactive Getters ใน `DashboardController`
   - ห้ามเขียนสูตรคำนวณเงินสดหรือสุขภาพการเงินซ้ำซ้อนในระดับ Widget UI
2. **การป้องกันข้อผิดพลาดทางคณิตศาสตร์ (Edge Case Safety)**:
   - ป้องกัน Division by Zero: เสมอตรวจตัวหาร เช่น `(denominator > 0 ? denominator : 1.0)`
   - การจำกัดขอบเขตค่า: ใช้ `.clamp(0.0, 1.0)` หรือ `.clamp(0, 100)` เพื่อป้องกัน UI Overflow หรือค่าติดลบที่ไม่พึงประสงค์
   - การคำนวณวัน: ระวังเดือนที่มี 28, 29, 30, 31 วัน โดยอ้างอิงจาก `DateTime(year, month + 1, 0).day`
3. **การจัดรูปแบบตัวเลข (Formatting)**:
   - แสดงยอดเงิน: ใช้ `NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2 หรือ 0)`

---

## 5. Responsive & Dialog Conventions

เมื่อสร้างหน้าต่าง Modal, Sheet, หรือ Dialog ใหม่ ให้ทำตาม Pattern นี้เสมอ:

```dart
static void show(BuildContext context) {
  HapticFeedback.mediumImpact();
  final isDesktop = MediaQuery.sizeOf(context).width >= 800;

  if (isDesktop) {
    Get.dialog(
      AppGlassDialog(
        maxWidth: 580,
        padding: const EdgeInsets.all(24),
        child: const MyCustomDialog(),
      ),
    );
  } else {
    Get.bottomSheet(
      const MyCustomDialog(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
```

---

## 6. Cloud Database & Synchronization Architecture (ระบบฐานข้อมูลและคลาวด์ซิงค์: Supabase)

**การเลือกโซลูชัน Cloud Database**: **Supabase (PostgreSQL)**  
เหตุผลที่เลือก: เหมาะสมที่สุดสำหรับแอปการเงิน (FinTech) เนื่องจากมีระบบความสมบูรณ์เชิงสัมพันธ์ (Relational Integrity), การันตีความถูกต้องของธุรกรรมตามมาตรฐาน ACID, ปลอดภัยด้วย Row Level Security (RLS) ที่ระดับฐานข้อมูล และรองรับ Cross-Platform ได้สมบูรณ์แบบทั้ง Mobile (iOS, Android) และ Desktop (Windows, macOS, Web) ผ่านไลบรารีทางการ `supabase_flutter`

### 6.1 โครงสร้างฐานข้อมูล (Database Schema Blueprint)
- **`profiles`**: เก็บข้อมูลบัญชีผู้ใช้งาน
  - `id` (uuid, primary key, references `auth.users(id)`)
  - `email` (text)
  - `currency_code` (text, default `'THB'`)
  - `created_at` / `updated_at` (timestamptz)
- **`budget_plans`**: แผนงบประมาณประจำเดือน
  - `id` (uuid, primary key)
  - `user_id` (uuid, references `profiles(id)`, indexed)
  - `target_daily_allowance` (numeric)
  - `planned_income` (numeric)
  - `target_monthly_savings` (numeric)
  - `planned_fixed_costs` (numeric)
  - `year_month` (text, e.g. `'2026-09'`)
  - `updated_at` (timestamptz)
- **`transactions`**: รายการธุรกรรมทางการเงิน
  - `id` (uuid, primary key)
  - `user_id` (uuid, references `profiles(id)`, indexed)
  - `title` (text)
  - `amount` (numeric)
  - `type` (text: `'income'`, `'expense'`, `'savingsInvestment'`)
  - `cost_nature` (text: `'fixed'`, `'variable'`, null)
  - `category_name` (text)
  - `date` (timestamptz)
  - `note` (text, nullable)
  - `is_synced` (boolean, default true)
  - `is_deleted` (boolean, default false - Soft Delete สำหรับซิงค์การลบข้ามอุปกรณ์)
  - `created_at` / `updated_at` (timestamptz)

### 6.2 ความปลอดภัยและการเข้าถึงข้อมูล (Security & RLS Policies)
- เปิดใช้งาน **Row Level Security (RLS)** ในทุกตาราง (100% Zero Data Leakage)
- บังคับนโยบาย: ผู้ใช้มีสิทธิ์อ่าน, เพิ่ม, แก้ไข, และลบได้เฉพาะแถวที่มี `user_id = auth.uid()` เท่านั้น

### 6.3 กลยุทธ์การเชื่อมต่อและการซิงค์ (Offline-First Synchronization)
1. **Local-First & Offline Resilience**:
   - แอปยังคงทำงานได้ฉับไวแม้ไม่มีอินเทอร์เน็ต เขียนและอ่านข้อมูลจาก Local Storage ก่อนเสมอ
   - เมื่อมีการเชื่อมต่ออินเทอร์เน็ต จะทำการ Sync ข้อมูลแบบสองทาง (Two-Way Background Sync)
2. **Conflict Resolution**:
   - ใช้หลักการ **Last-Write-Wins (LWW)** โดยตรวจสอบ `updated_at` timestamp ระหว่าง Client และ Remote DB
3. **Repository Pattern Abstraction**:
   - ออกแบบ `TransactionRepository` และ `BudgetRepository` เป็น Abstraction Interface
   - มี `LocalDataSource` และ `SupabaseDataSource` ทำงานร่วมกัน เพื่อให้ UI Controllers ไม่ต้องผูกติดกับเทคโนโลยีฐานข้อมูลโดยตรง

---

## 7. Checklist ก่อนส่งมอบงานทุกครั้ง (Pre-Delivery Checklist)

- [ ] **No Hardcoded Strings**: ไม่มีข้อความภาษาไทย/อังกฤษที่เขียนตรงในโค้ด UI (ต้องใช้ `.tr`)
- [ ] **No Emojis (Icons Only)**: ปราศจาก Emoji ในทุกส่วนของโค้ดและคำแปลภาษา ใช้ Material Icons เท่านั้น
- [ ] **No Text Overflow**: ไม่มีข้อความหรือตัวเลขที่ล้นขอบจอ หรือถูกตัดขาดจนอ่านไม่รู้เรื่อง
- [ ] **No Unused Imports / Variables**: ลบตัวแปรและ import ที่ไม่ได้ใช้งานทั้งหมด
- [ ] **Dual Theme Support**: ทดสอบทั้ง Light Mode และ Dark Mode (สีข้อความและพื้นหลังต้องอ่านออกชัดเจน ไม่กลืนกับพื้นหลัง)
- [ ] **Responsive Test**: ใช้งานได้สวยงามทั้ง Mobile View และ Desktop Bento Grid View
- [ ] **Keyboard Accessibility**: รองรับคีย์ลัดที่เกี่ยวข้อง และมี Haptic Feedback เมื่อกดปุ่มหลัก
