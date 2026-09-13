# Money Tracker - FinTech 2026 💎

> **English** | [ภาษาไทย](#ภาษาไทย-th)

An intelligent, privacy-first personal finance management application built with **Flutter** and **GetX**. Featuring Google Gemini AI multimodal receipt & slip analysis, advanced Thai bank slip processing (PromptPay QR & OCR), multi-signal category prediction, modern Liquid Glassmorphism UI, biometric security, and full bilingual localization (Thai 🇹🇭 / English 🇺🇸).

---

## 🌟 Highlights / จุดเด่น

- 🤖 **Google Gemini Multimodal AI**: Next-generation slip & retail receipt recognition powered by `gemini-3.6-flash`. Extracts store names, item breakdowns, totals, and timestamps.
- 🛡️ **Zero-Friction & Anti-Leak Architecture**: Ready out-of-the-box without requiring users to configure API keys. Keys are binary-scrambled via XOR in native AOT code (`libapp.so`), 100% hidden from the UI, encrypted on disk, and excluded from Git.
- 📸 **Smart Bank Slip Scanner & PromptPay QR**: Instant transfer slip recognition supporting all major Thai banks (Krungthai NEXT, Paotang, K PLUS, SCB Easy, Bangkok Bank, ttb, Krungsri, MyMo, BAAC, ShopeePay, TrueMoney) and 7-Eleven receipts.
- 🏷️ **Contextual Bilingual Titles**: Auto-generates intuitive transaction titles matching the active language (`Transfer to...` / `Pay...` / `โอนให้...` / `จ่าย...`).
- ⏱️ **Flexible Date & Time Controls**: Full control over transaction date and time across Single slips, Batch slips, and Quick Add manual entries.
- 📊 **Smart Budgeting Frameworks**: Built-in 50/30/20, 60/20/20, and 40/30/30 budgeting rules with Fixed vs. Variable cost breakdown and Daily Studio Quotas.
- 🔒 **Biometric & PIN Vault**: Offline-first security with 4-digit PIN lock, auto-lock timeouts, and Fingerprint/Face ID authentication.
- 🎨 **Liquid Glassmorphism**: Responsive design for Mobile & Desktop with adaptive navigation, dynamic dark/light themes, and smooth micro-animations.

---

## 🇬🇧 English

### ✨ Key Features

#### 1. Gemini AI & Multi-Engine Slip Scanner
- **Multimodal AI Analysis (`gemini-3.6-flash`)**: Leverages Google Gemini AI to analyze complex slips, multi-item retail receipts (e.g., 7-Eleven / CP ALL), and crumpled or faded physical receipts.
- **Out-of-the-Box Readiness**: Users don't need to register on Google AI Studio or paste long keys. The app comes pre-configured with a secure native secret vault.
- **Enterprise-Grade Secret Protection**:
  - **Native Binary Obfuscation**: Secret keys are XOR-scrambled in native compiled ARM instructions (`SecretVault`). No plaintext strings exist in APK assets or binary strings.
  - **100% UI Concealment**: API keys are never rendered or previewed on screen. The UI displays status cards with verified security badges.
  - **On-Device Stream Cipher**: Any custom user keys are stored using multi-round XOR stream encryption (`.sec`).
  - **Strict Git Safety**: `.gitignore` strictly protects `config.json`, `secret_vault.dart`, and secret keys. Public repositories only track `.example` templates.
- **PromptPay EMVCo QR Code Decoder**: Extracts exact reference numbers, amounts, dates, and receiver account hashes.
- **Dual-Engine OCR**: Google ML Kit Text Recognition with Tesseract OCR fallback for high accuracy on receipts and notification screenshots.
- **Duplicate Slip Prevention**: Prevents accidental re-entries by checking reference IDs, timestamps, and amounts against the transaction database.
- **Batch Processing & Folder Monitoring**: Automatically monitors bank slip folders, previews detected slips in real time, and allows batch saving.

#### 2. Financial Intelligence & Budgeting
- **Budget Allocations**: Apply proven financial rules (50/30/20 Needs-Wants-Savings, 60/20/20, 40/30/30).
- **Cost Nature Segregation**: Separate Fixed Costs (rent, internet, insurance) from Variable Costs (dining, shopping).
- **Daily Studio Quota**: Real-time calculation of remaining daily spendable budget to prevent month-end deficits.
- **Interactive Analytics**: Visual cashflow graphs and category distribution charts powered by `fl_chart`.

#### 3. Ergonomic Quick Add
- **FinTech Numpad**: Single-handed numpad with tactile haptic feedback.
- **Hardware Keyboard Support**: Complete desktop support for numeric keypads, Enter, and Backspace.
- **Time Specification**: Dedicated interactive time picker (`HH:mm`) alongside rapid date chips (Today, Yesterday, Custom).

#### 4. Security & Privacy
- **Offline-First Storage**: Local JSON storage without remote tracking or third-party data sharing.
- **Security Lockscreen**: 4-digit master PIN with maximum attempt limits and lockout safeguards.
- **Biometric Integration**: Quick unlock using device biometric hardware (`local_auth`).
- **Data Portability**: Full JSON and CSV export/import with UTF-8 BOM for Microsoft Excel & Google Sheets.

---

### 🛠️ Tech Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart 3.12+) |
| **State Management** | GetX 4.7.3 (Simplified Reactive Architecture) |
| **AI Engine** | Google Gemini Multimodal API (`gemini-3.6-flash`, `gemini-3.5-flash`) |
| **Styling & UI** | Liquid Glass Easy (`liquid_glass_easy`), Google Fonts |
| **Charts** | `fl_chart` |
| **OCR & QR** | `google_mlkit_text_recognition`, `flutter_tesseract_ocr`, `zxing2` |
| **Security** | `local_auth` (Biometrics), XOR Stream Cipher Vault |
| **Internationalization** | GetX Translations (`AppTranslations` supporting `th_TH` & `en_US`) |

---

### 📂 Directory Structure

```
lib/
├── main.dart                          # App entry point, locale initialization & security bindings
├── app/
│   ├── data/
│   │   ├── models/                    # Data models (BankSlipData, TransactionItem, BudgetModel, etc.)
│   │   └── services/                  # Business logic:
│   │       ├── bank_slip_service.dart # Slip scanning, batch processing & auto-detect
│   │       ├── gemini_slip_service.dart# Google Gemini AI multimodal analysis
│   │       ├── config_service.dart    # Unified config manager (Storage, Env, Config, Vault)
│   │       ├── secret_vault.dart      # Binary-obfuscated Secret Vault (Git-ignored)
│   │       ├── storage_service.dart   # Encrypted on-device persistence
│   │       └── security_service.dart  # PIN lock and biometric manager
│   ├── modules/
│   │   ├── dashboard/                 # Overview dashboard, net cashflow, adaptive layouts
│   │   ├── transactions/              # Quick Add sheet, Batch & Single slip confirmation sheets
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

#### Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/money_tracker.git
   cd money_tracker
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API Secrets (Optional)**:
   The app works **out-of-the-box** using the built-in obfuscated vault. If you want to use your own custom Gemini API key during development:
   ```bash
   cp config.example.json config.json
   ```
   Edit `config.json` with your personal key:
   ```json
   {
     "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY",
     "GEMINI_MODEL": "gemini-3.6-flash"
   }
   ```
   *(Note: `config.json` and `secret_vault.dart` are automatically ignored by Git).*

4. **Verify Code Quality**:
   ```bash
   flutter analyze
   ```

5. **Launch the Application**:
   ```bash
   flutter run
   ```
   *(Or with custom config: `flutter run --dart-define-from-file=config.json`)*

---
---

## 🇹🇭 ภาษาไทย (TH)

### ✨ ฟีเจอร์เด่นของแอปพลิเคชัน

#### 1. ระบบวิเคราะห์สลิปและใบเสร็จด้วย Gemini AI (AI Multimodal Engine)
- **วิเคราะห์อัจฉริยะด้วย Gemini 3.6 Flash**: ใช้อัจฉริยภาพของ Google Gemini AI ถอดรหัสใบเสร็จรับเงิน รายการสินค้าหลายรายการ (เช่น ใบเสร็จ 7-Eleven / CP ALL, ซูเปอร์มาร์เก็ต) และสลิปที่มีความซับซ้อนได้อย่างแม่นยำ
- **พร้อมใช้งานทันที ไม่ลำบากผู้ใช้ (Zero-Friction)**: ผู้ใช้ทั่วไปไม่จำเป็นต้องไปสมัคร Google AI Studio หรือก๊อปปี้ API Key เอง ตัวแอปมีระบบคลังความลับในตัว (Secret Vault) เปิดแอปแล้วใช้งานได้ทันที 100%
- **มาตรฐานความปลอดภัยระดับสูงสุด (Anti-Leak & Reverse-Engineering Protection)**:
  - **ซ่อนคีย์ในระดับ Native Binary**: คีย์เริ่มต้นถูกแปลงเป็น Scrambled Byte Array ผ่านการ XOR หลากมิติในโค้ดภาษา Dart ซึ่งจะถูกคอมไพล์เป็น Machine Code (`libapp.so`) ทำให้แฮกเกอร์ไม่สามารถค้นหาคีย์ด้วยคำสั่ง strings หรือแตกไฟล์ APK ได้
  - **ไม่แสดง Key บนหน้าจอ 100%**: ปิดบังไม่ให้มีตัวอักษรของ API Key ปรากฏบนหน้าจอ เพื่อป้องกันการแอบดูหรือจับภาพหน้าจอ โดยแสดงเป็นสถานะความปลอดภัย **"เข้ารหัสและปลอดภัย (Protected & Encrypted)"**
  - **เข้ารหัสข้อมูลในเครื่อง**: คีย์ส่วนตัวที่บันทึกเพิ่มจะถูกเข้ารหัสด้วย Stream Cipher ในไฟล์ `.sec`
  - **ป้องกันการรั่วไหลบน Git**: `.gitignore` ถูกตั้งค่าอย่างรัดกุมไม่ให้ติดตาม `config.json` และ `secret_vault.dart` โดยมีไฟล์ `.example` สำหรับโอเพนซอร์ส
- **ถอดรหัส QR Code พร้อมเพย์ (EMVCo)**: ดึงยอดเงิน วันที่ รหัสอ้างอิง และบัญชีปลายทางได้อย่างแม่นยำ
- **ระบบ OCR สองชั้น (Dual-Engine)**: ใช้งานร่วมกันระหว่าง Google ML Kit และ Tesseract OCR รองรับภาพสลิปจากทุกธนาคารในไทย
- **ตรวจจับสลิปซ้ำอัตโนมัติ**: เทียบยอดเงิน วันที่ เวลา และเลขอ้างอิง เพื่อแจ้งเตือนก่อนบันทึกซ้ำ
- **ระบบสแกนแบบกลุ่ม (Batch Processing)**: ตรวจสอบ ปรับหมวดหมู่ และบันทึกสลิปหลายใบพร้อมกัน
- **ตรวจจับสลิปอัตโนมัติจากโฟลเดอร์**: แสดงแบนเนอร์แจ้งเตือนทันทีเมื่อมีสลิปใหม่ถูกบันทึกลงในเครื่อง

#### 2. โครงสร้างการจัดการงบประมาณและการเงิน (Financial Architecture)
- **สูตรจัดสรรงบประมาณยอดนิยม**: ปรับใช้สูตรการเงินระดับโลกได้ในคลิกเดียว (50/30/20, 60/20/20, 40/30/30)
- **แยกประเภทค่าใช้จ่ายคงที่และผันแปร**: ติดตามภาระคงที่ (Fixed Costs) เช่น ค่าหอ ค่าเน็ต และค่าใช้จ่ายกินอยู่ผันแปร (Variable Costs)
- **สตูดิโอโควตากินอยู่รายวัน (Daily Studio Quota)**: คำนวณเงินที่ใช้ได้ต่อวันแบบเรียลไทม์ ป้องกันปัญหาเงินตึงมือช่วงสิ้นเดือน
- **กราฟและสถิติเชิงลึก**: แสดงภาพรวมกระแสเงินสดสุทธิและสัดส่วนรายจ่ายด้วย `fl_chart`

#### 3. บันทึกรายการด่วนและกำหนดเวลา (Ergonomic Quick Add)
- **แป้นพิมพ์ตัวเลขใช้งานง่าย**: ออกแบบพิเศษให้กดบันทึกตัวเลขได้สะดวกด้วยมือเดียว พร้อมการตอบสนองแบบ Haptic Feedback
- **รองรับคีย์บอร์ดจริง (Hardware Keyboard)**: ใช้งานบนแท็บเล็ตหรือคอมพิวเตอร์ Desktop ได้เต็มรูปแบบ
- **กำหนดเวลาทำรายการเจาะจง**: มีปุ่มเลือกเวลา (`HH:mm`) ข้างตัวเลือกวันที่ บันทึกย้อนหลังได้แม่นยำ

#### 4. ความปลอดภัยและความเป็นส่วนตัว (Security & Privacy)
- **เก็บข้อมูลเฉพาะในเครื่อง (Offline-First)**: ข้อมูลการเงินทั้งหมดเก็บอยู่ในเครื่องของผู้ใช้ ไม่มีการส่งข้อมูลส่วนตัวออกนอกเครื่อง
- **ระบบล็อกรหัส PIN 4 หลัก**: ปกป้องความเป็นส่วนตัวพร้อมระบบนับจำนวนครั้งที่ใส่ผิดเพื่อป้องกันการสุ่มรหัส
- **ปลดล็อกด้วยชีวมิติ (Biometrics)**: รองรับการสแกนลายนิ้วมือและใบหน้า (Face ID / Touch ID)
- **นำเข้าและส่งออกข้อมูล (Data Backup)**: ส่งออกและกู้คืนข้อมูลในรูปแบบ JSON และ CSV (พร้อม UTF-8 BOM สำหรับ Microsoft Excel และ Google Sheets)

---

### ⚙️ การติดตั้งและเริ่มต้นใช้งาน

1. **โคลนคลังโค้ดลงในเครื่อง**:
   ```bash
   git clone https://github.com/your-username/money_tracker.git
   cd money_tracker
   ```

2. **ดาวน์โหลดแพ็กเกจที่จำเป็น**:
   ```bash
   flutter pub get
   ```

3. **การตั้งค่าคีย์ API (ไม่จำเป็นต้องทำ - ระบบมีคีย์ในตัวพร้อมใช้ทันที)**:
   หากนักพัฒนาต้องการใช้ API Key ส่วนตัวในการทดสอบ:
   ```bash
   cp config.example.json config.json
   ```
   ระบุคีย์ของคุณในไฟล์ `config.json`:
   ```json
   {
     "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY",
     "GEMINI_MODEL": "gemini-3.6-flash"
   }
   ```

4. **ตรวจสอบความถูกต้องของโค้ด**:
   ```bash
   flutter analyze
   ```

5. **สั่งรันแอปพลิเคชัน**:
   ```bash
   flutter run
   ```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
