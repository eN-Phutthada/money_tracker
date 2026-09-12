# Money Tracker - FinTech 2026 💎

> **English** | [ภาษาไทย](#ภาษาไทย-th)

An intelligent, privacy-first personal finance management application built with **Flutter** and **GetX**. Featuring advanced Thai bank slip scanning (OCR & QR decode), multi-signal AI category prediction, modern Liquid Glassmorphism UI, biometric security, and full bilingual localization (Thai 🇹🇭 / English 🇺🇸).

---

## 🌟 Highlights / จุดเด่น

- 📸 **Smart Bank Slip Scanner & OCR**: Instant transfer slip recognition supporting all major Thai banks (Krungthai, KBank, SCB, Bangkok Bank, ttb, Krungsri, MyMo, BAAC, ShopeePay, TrueMoney).
- 🏷️ **Contextual Bilingual Titles**: Auto-generates clear, intuitive transaction titles matching the app's current language (`Transfer to...` / `Pay...` / `โอนให้...` / `จ่าย...`).
- ⏱️ **Flexible Date & Time Controls**: Full control over recording date and time across Single slips, Batch slips, and Quick Add manual entries.
- 📊 **Smart Budget Rules**: Built-in 50/30/20, 60/20/20, and 40/30/30 budgeting frameworks with Fixed vs. Variable cost breakdown and Daily Studio Quotas.
- 🔒 **Biometric & PIN Vault**: Offline-first security with 4-digit PIN lock, auto-lock timeouts, and Fingerprint/Face ID authentication.
- 🎨 **Liquid Glassmorphism**: Responsive design for Mobile & Desktop with adaptive navigation, dynamic dark/light themes, and smooth micro-animations.

---

## 🇬🇧 English

### ✨ Key Features

#### 1. Smart Slip & OCR Engine
- **PromptPay QR Code Decoder**: Compliant with EMVCo QR specifications to extract exact transaction reference numbers, amounts, dates, and account endpoints.
- **Dual-Engine OCR**: Google ML Kit Text Recognition with Tesseract OCR fallback for high accuracy on receipts and notification screenshots.
- **AI Category & Type Predictor**: Multi-signal scoring engine combining merchant keywords, transfer history learning, and time-of-day heuristics.
- **Duplicate Slip Protection**: Automatically identifies duplicate slips by comparing timestamps, transaction amounts, and reference IDs.
- **Batch Processing**: Review, adjust categories, customize transaction times, and save multiple slips at once.
- **Folder Auto-Scan**: Detects newly saved slips in target image folders and prompts instant verification banners.

#### 2. Financial Intelligence & Budgeting
- **Budget Allocations**: Apply proven financial rules (50/30/20 Needs-Wants-Savings, 60/20/20, 40/30/30).
- **Cost Nature Segregation**: Separate Fixed Costs (rent, internet, insurance) from Variable Costs (dining, shopping).
- **Daily Studio Quota**: Live calculation of remaining daily spendable budget to prevent end-of-month deficits.
- **Interactive Analytics**: Visual cashflow graphs and category distributions powered by `fl_chart`.

#### 3. Ergonomic Quick Add
- **FinTech Numpad**: Single-handed numpad with tactile haptic feedback.
- **Hardware Keyboard Support**: Complete desktop support for numeric keypads, Enter, and Backspace.
- **Time Specification**: Dedicated interactive time picker (`HH:mm`) alongside rapid date chips (Today, Yesterday, Custom).

#### 4. Security & Privacy
- **Offline-First Storage**: Local JSON storage without remote tracking or third-party data sharing.
- **Security Lockscreen**: 4-digit master PIN with maximum attempt limits and lockout safeguards.
- **Biometric Integration**: Quick unlock using device biometric hardware (`local_auth`).
- **Data Portability**: Full JSON and CSV export/import for easy backups.

---

### 🛠️ Tech Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart 3.12+) |
| **State Management** | GetX 4.7.3 (Simplified Reactive Architecture) |
| **Styling & UI** | Liquid Glass Easy (`liquid_glass_easy`), Google Fonts |
| **Charts** | `fl_chart` |
| **OCR & QR** | `google_mlkit_text_recognition`, `flutter_tesseract_ocr`, `zxing2` |
| **Security** | `local_auth` (Biometrics) |
| **Internationalization** | GetX Translations (`AppTranslations` supporting `th_TH` & `en_US`) |

---

### 📂 Directory Structure

```
lib/
├── main.dart                          # App entry point, locale initialization & security bindings
├── app/
│   ├── data/
│   │   ├── models/                    # Data models (BankSlipData, TransactionItem, BudgetModel, etc.)
│   │   └── services/                  # Business logic (BankSlipService, BankSlipParser, SecurityService, etc.)
│   ├── modules/
│   │   ├── dashboard/                 # Overview dashboard, net cashflow, adaptive layouts
│   │   ├── transactions/              # Quick Add bottom sheet, Batch & Single slip confirmation sheets
│   │   ├── budget/                    # Budget formula settings & allocation rules
│   │   ├── security/                  # PIN lock screen, security vault, biometric settings
│   │   └── data_management/          # Data export, import, and reset utilities
│   ├── routes/                        # GetX routing configuration
│   ├── theme/                         # App colors, themes, glassmorphism decorations
│   ├── translations/                  # Bilingual translation keys (AppTranslations)
│   └── widgets/                       # Reusable UI components (LiquidGlassNavDock, AppFeedback, etc.)
```

---

### 🚀 Getting Started

#### Prerequisites
- Flutter SDK (>= 3.12.0)
- Android Studio / VS Code / Antigravity IDE
- Device or Emulator (Android, iOS, Windows, macOS, or Linux)

#### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/money_tracker.git
   cd money_tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run static analysis:
   ```bash
   flutter analyze
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

---
---

## 🇹🇭 ภาษาไทย (TH)

### ✨ ฟีเจอร์เด่นของแอปพลิเคชัน

#### 1. ระบบสแกนและถอดรหัสสลิปอัจฉริยะ (Bank Slip & OCR Engine)
- **ถอดรหัส QR Code พร้อมเพย์ (EMVCo)**: ดึงข้อมูลยอดเงิน วันที่ รหัสอ้างอิงธุรกรรม และบัญชีปลายทางได้อย่างแม่นยำ 100%
- **ระบบ OCR สองชั้น**: ใช้ Google ML Kit ร่วมกับ Tesseract OCR รองรับภาพถ่ายสลิปใบเสร็จจริง และภาพแคปหน้าจอจากแอปธนาคารทุกแห่งในไทย
- **ทำนายหมวดหมู่และประเภทธุรกรรมอัตโนมัติ**: คำนวณจากสัญญาณชื่อร้านค้า/คู่กรณี ประวัติการทำรายการในอดีต และช่วงเวลาของวัน
- **ตั้งชื่อรายการตามภาษาปัจจุบัน**: สร้างชื่อรายการธุรกรรมตามภาษาที่ใช้งานโดยอัตโนมัติ (เช่น ภาษาไทย: `โอนให้...` / `จ่าย...` / `รับเงินจาก...` / `รายได้จาก...` และภาษาอังกฤษ: `Transfer to...` / `Pay...`)
- **ระบบป้องกันสลิปซ้ำ**: ตรวจสอบยอดเงิน วันที่ และเลขอ้างอิงกับรายการในระบบเพื่อแจ้งเตือนก่อนบันทึกซ้ำ
- **ระบบตรวจสอบสลิปแบบกลุ่ม (Batch Scan)**: สแกน ตรวจสอบ ปรับเปลี่ยนหมวดหมู่ และกำหนดเวลาบันทึกรายการหลายใบได้พร้อมกัน
- **แบนเนอร์ตรวจจับสลิปใหม่ในเครื่อง**: แจ้งเตือนทันทีเมื่อมีภาพสลิปใหม่บันทึกลงในโฟลเดอร์รูปภาพของเครื่อง

#### 2. โครงสร้างการจัดการงบประมาณและการเงิน (Financial Architecture)
- **สูตรจัดสรรงบประมาณยอดนิยม**: ปรับใช้สูตรง่ายๆ ได้ในคลิกเดียว (50/30/20, 60/20/20, 40/30/30)
- **แยกประเภทค่าใช้จ่ายคงที่และผันแปร**: ติดตามภาระคงที่ (Fixed Costs) เช่น ค่าหอ ค่าเน็ต และค่าใช้จ่ายกินอยู่ผันแปร (Variable Costs)
- **สตูดิโอโควตากินอยู่รายวัน (Daily Studio Quota)**: คำนวณเงินที่ใช้ได้ต่อวันแบบเรียลไทม์เพื่อป้องกันปัญหาเงินหมดก่อนสิ้นเดือน
- **กราฟและสถิติเชิงลึก**: แสดงภาพรวมกระแสเงินสดสุทธิและสัดส่วนรายจ่ายด้วย `fl_chart`

#### 3. บันทึกรายการด่วนและกำหนดเวลา (Ergonomic Quick Add)
- **แป้นพิมพ์ตัวเลขใช้งานง่าย**: ออกแบบพิเศษให้กดบันทึกตัวเลขได้สะดวกด้วยมือเดียว พร้อมการตอบสนองแบบ Haptic Feedback
- **รองรับคีย์บอร์ดจริง (Hardware Keyboard)**: ใช้งานบนแท็บเล็ตหรือคอมพิวเตอร์ Desktop ได้เต็มรูปแบบ
- **กำหนดเวลาทำรายการเจาะจง**: มีปุ่มชิปเลือกเวลา (`HH:mm`) ข้างตัวเลือกวันที่ ทำให้บันทึกเวลาที่เกิดขึ้นจริงได้อย่างสมบูรณ์

#### 4. ความปลอดภัยและความเป็นส่วนตัว (Security & Privacy)
- **เก็บข้อมูลเฉพาะในเครื่อง (Offline-First)**: ข้อมูลการเงินทั้งหมดเก็บอยู่ในเครื่องของผู้ใช้ ไม่มีการส่งขึ้นเซิร์ฟเวอร์ภายนอก
- **ระบบล็อกรหัส PIN 4 หลัก**: ปกป้องความเป็นส่วนตัวพร้อมระบบนับจำนวนครั้งที่ใส่ผิดเพื่อป้องกันการสุ่มรหัส
- **ปลดล็อกด้วยชีวมิติ (Biometrics)**: รองรับการสแกนลายนิ้วมือและใบหน้า (Face ID / Touch ID)
- **นำเข้าและส่งออกข้อมูล (Data Backup)**: ส่งออกและกู้คืนข้อมูลในรูปแบบ JSON และ CSV ได้ตลอดเวลา

---

### ⚙️ การติดตั้งและเริ่มต้นใช้งาน

1. โคลนคลังโค้ดลงในเครื่อง:
   ```bash
   git clone https://github.com/your-username/money_tracker.git
   cd money_tracker
   ```

2. ดาวน์โหลดแพ็กเกจที่จำเป็น:
   ```bash
   flutter pub get
   ```

3. ตรวจสอบความถูกต้องของโค้ด:
   ```bash
   flutter analyze
   ```

4. สั่งรันแอปพลิเคชัน:
   ```bash
   flutter run
   ```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
