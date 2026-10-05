# Money Tracker

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![GetX](https://img.shields.io/badge/State-GetX_4.7.3-8A2BE2)](https://pub.dev/packages/get)
[![Design](https://img.shields.io/badge/Design-Nothing_OS_Industrial-111111)](https://nothing.tech)
[![Platform](https://img.shields.io/badge/Platform-iOS_|_Android_|_Windows_|_macOS_|_Web-lightgrey)](#dual-form-factor-architecture)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An intelligent, privacy-first personal finance management and cashflow engineering system built with **Flutter** and **GetX**. Designed with the **Nothing OS Industrial Design Language** (Squircle geometry, razor-sharp 0.8px hairline borders, dot-matrix surface grids, Share Tech Mono metrics, Space Grotesk typography, and Nothing Red LED status indicators).

Features a **100% on-device bank slip and receipt recognition engine** (EMVCo PromptPay QR decoder, dual-engine OCR, deep semantic parsing for 15+ Thai financial institutions, and 7-Eleven / CP ALL retail receipts), dynamic budgeting models (50/30/20, 60/20/20, 40/30/30), real-time daily spendable quota analytics, advance recurring payment management, biometric vault security, and seamless dual-form-factor adaptation across Mobile and Desktop Bento Grid environments.

---

## Architectural Highlights

### 1. Nothing OS Industrial Design System
- **Squircle Geometry & Precision Tolerances**:
  - Primary dashboard cards: `borderRadius: 28`
  - Dialog modals and diagnostic sheets: `borderRadius: 22` - `28`
  - Status chips, pills, and inputs: `borderRadius: 12` - `14`
  - Precision hairline borders: `width: 0.8` for an ultra-sharp, high-density industrial finish.
- **Monochrome & Nothing Red Palette**:
  - Matte dark surfaces (`#0D0D0E`, `#141416`, `#1B1B1E`) and crisp light surfaces (`#F5F5F7`, `#FFFFFF`).
  - Signature Nothing Red (`#D71921`) used strategically for active recording, alerts, and critical metric indicators.
  - Dot-matrix canvas backgrounds with dynamic procedural grid rendering (`_NothingDotGridPainter`).
- **Typography & Krungthai Smart Font Fallback**:
  - Numeric metrics, balances, dates, and times: `GoogleFonts.shareTechMono` (Nothing Dot / Monospace).
  - Labels, navigation headers, and action controls: `GoogleFonts.spaceGrotesk`.
  - **Modern Thai Banking Typography**: Modern loopless sans-serif styled after Krungthai Smart / NEXT, powered by Cadson Demak's `Prompt`. Configured with weight-matched fallback (`NothingTypography.thaiFallback`) and safe letter-spacing guards (`NothingTypography.safeSpacing`) to eliminate Thai diacritic/tone mark clipping.
- **Status LEDs & Segmented Progress**:
  - Live status feedback via `NothingLedIndicator` with optional pulsing animations (`isPulsing`) during critical budget alerts.
  - Multi-segment progress visualizers (`NothingSegmentedBar`) replacing traditional solid progress bars.
- **Zero-Emoji Policy**: Pure industrial design using Material Design glyph icons exclusively throughout UI components, translation bundles, and system models.

---

### 2. Dual-Form-Factor Architecture (Mobile & Desktop)

Money Tracker features dedicated, non-compromised layouts for both handheld and desktop workstations:

```
+------------------------------------------------------------------------------------+
|                                    VIEWPORT WIDTH                                  |
+--------------------------------------------------+---------------------------------+
|               Desktop (>= 800px)                 |         Mobile (< 800px)        |
+--------------------------------------------------+---------------------------------+
| - Bento Grid multi-column canvas                 | - Ergonomic single-column scroll|
| - Collapsible sidebar command rail               | - Floating Liquid Glass Nav Dock|
| - Comprehensive keyboard shortcut navigation     | - Swipe-to-dismiss Bottom Sheets|
| - Centered glass dialog modals (AppGlassDialog)  | - Pull-to-refresh & tactile haptic|
+--------------------------------------------------+---------------------------------+
```

#### Desktop Keyboard Navigation Matrix
When running on Desktop platforms (Windows, macOS, Web), operators can navigate the entire application without touching the mouse:

| Key Binding | Target Action | Description |
|---|---|---|
| `N` | Quick Add Transaction | Opens the transaction entry sheet with focused numpad |
| `H` | Navigate to Dashboard | Switches to overview dashboard canvas |
| `T` | Navigate to Transactions | Opens chronological transaction history and search |
| `S` | Navigate to Settings | Opens budget rules and preference configuration |
| `D` | Financial Health Diagnostic | Launches full-screen wallet diagnostic sheet |
| `M` | Cycle Filter / Month Picker | Opens the financial accounting period selector |
| `P` | Scheduled Payments | Opens recurring commitments and scheduled bills |
| `L` | Security Lock | Instantly engages master PIN / biometric lockscreen |
| `1` | Period: Monthly | Switches analytics view to current monthly cycle |
| `2` | Period: Yearly | Switches analytics view to annualized aggregation |
| `3` | Period: All-Time | Switches analytics view to cumulative historical data |
| `Esc` | Dismiss / Close | Dismisses active dialog, modal, or bottom sheet |

---

### 3. 100% On-Device Bank Slip & Receipt Engine

A zero-latency, privacy-first ingestion pipeline that extracts transaction metadata directly on the device with zero cloud API keys, zero external network requests, and zero data leakage.

```
[ Bank Slip Image / Camera / Gallery / Batch Drop ]
                        |
                        v
          +----------------------------+
          | Bank Slip Detection Filter |
          +----------------------------+
            |                        |
            v                        v
  +--------------------+   +-----------------------+
  |  ZXing2 QR Engine  |   | Dual-Engine OCR       |
  |  (EMVCo PromptPay) |   | (Google ML Kit + Tesseract) |
  +--------------------+   +-----------------------+
            |                        |
            +------------+-----------+
                         |
                         v
          +----------------------------+
          | BankSlipParser (2,500+ LOC)|
          | Multi-institution regex    |
          +----------------------------+
                         |
                         v
          +----------------------------+
          | SlipCategoryPredictor      |
          | Contextual title & nature  |
          +----------------------------+
                         |
            +------------+------------+
            |                         |
            v                         v
  [ Mode A: Review Sheet ]   [ Mode B: Instant Auto-Save ]
```

- **PromptPay EMVCo QR Code Engine (`zxing2`)**: Decodes standard Thai banking transfer QR codes, extracting exact transaction reference numbers, amounts, dates, and receiving account hashes.
- **Dual-Engine OCR Fallback**: Combines Google ML Kit on-device text recognition with Tesseract OCR fallback for unmatched character recognition accuracy across low-contrast and crumpled physical receipts.
- **Deep Semantic Parser (`BankSlipParser`)**: Supports over 15 major Thai financial institutions and retail slips:
  - Krungthai Bank (`Krungthai NEXT`, `Paotang`)
  - Kasikornbank (`K PLUS`)
  - Siam Commercial Bank (`SCB Easy`)
  - Bangkok Bank (`Bualuang mBanking`)
  - ttb (`ttb touch`)
  - Bank of Ayudhya (`Krungsri KMA`)
  - Government Savings Bank (`MyMo GSB`)
  - Bank for Agriculture and Agricultural Cooperatives (`BAAC`)
  - TrueMoney Wallet
  - Kiatnakin Phatra (`KKP Mobile` / `Dime!`)
  - UOB Thailand (`UOB TMRW`)
  - CIMB Thai
  - TISCO Bank
  - Land and Houses Bank (`LHB You`)
  - ShopeePay
  - 7-Eleven / CP ALL retail tax invoices and itemized receipts
- **Smart Category & Nature Predictor (`SlipCategoryPredictor`)**: Analyzes transaction descriptions, merchant tags, and transaction metadata to automatically classify transactions into standardized spending categories and tag their cost nature (Fixed vs. Variable).
- **Batch Processing & Duplicate Collision Prevention**: Ingest multiple slips simultaneously from photo albums. The engine validates incoming transfer references against local transaction logs to eliminate duplicate entries.
- **Dual Ingestion Pipelines**:
  - *Preview & Confirm Sheet*: Review inferred merchant, amount, category, and date with one-tap confirmation.
  - *Instant Auto-Save*: Direct ingestion with tactile confirmation snackbar and one-tap undo/edit controls.

---

### 4. Financial Intelligence & Budgeting Frameworks

- **Proven Allocation Frameworks**:
  - **50/30/20 Rule**: 50% Needs (Essential), 30% Wants (Discretionary), 20% Savings/Investments.
  - **60/20/20 Rule**: 60% Committed Expenses, 20% Discretionary, 20% Wealth Building.
  - **40/30/30 Rule**: 40% Living Costs, 30% Personal Lifestyle, 30% Accelerated Wealth.
  - **Custom Studio Allocation**: Fully configurable proportions tailored to personal cashflow strategies.
- **Cost Nature Segregation**: Explicit separation between **Fixed Costs** (rent, subscriptions, internet, debt obligations) and **Variable Costs** (dining, groceries, leisure, fuel) for accurate burn rate modeling.
- **Dynamic Daily Spendable Quota**:
  - Calculates remaining safe daily spending in real time:  
    $$\text{Daily Quota} = \frac{\text{Variable Budget} - \text{Current Variable Spend}}{\text{Days Remaining in Month}}$$
  - Prevents end-of-month cash shortages through visual status cards and real-time status indicators.
- **Wallet Health Diagnostic (`WalletHealthModel`)**:
  - Multi-dimensional financial health assessment calculating:
    - Net Savings Efficiency
    - Fixed Commitment Coverage
    - Emergency Reserve Runway (Months of survival fund)
    - Overall Financial Resilience Score (0–100%)
  - Integrated diagnostic recommendations sheet with prioritized financial advice.
- **Interactive Financial Visualizations**: Multi-curve cashflow trends, income versus outflow distributions, and categorized spending breakdowns powered by `fl_chart`.

---

### 5. Scheduled & Recurring Payments Engine

- **Flexible Cycle Frequencies**: Supports one-time advance payments, daily, weekly, monthly, and yearly recurring commitments.
- **Month-End Safe Clamping**: Automatically adjusts dates when handling 28th–31st day transitions, preventing skipped months or overflow in February and 30-day months.
- **Dual Execution Pipelines**:
  - *Auto-Record*: Automatically creates the transaction and advances the next cycle on the due date upon launching the application.
  - *Manual Confirm*: Displays upcoming alerts with 1-click **Pay Now** or **Skip** actions.
- **Upcoming Commitments Bento Card**: Real-time dashboard widget displaying imminent dues, overdue badges, and total commitment metrics.
- **Dedicated Management Sheet**: Filter by *All*, *Active*, *Paused*, or *Completed*; edit schedules, pause/resume, and inspect monthly recurring burn rates.

---

### 6. Security, Privacy & Data Vault

- **Zero-Knowledge Offline-First Storage**: Local JSON storage without remote tracking, telemetry, or third-party data collection.
- **Biometric & PIN Vault**:
  - 4-digit master PIN with maximum attempt limits and progressive lockout safeguards.
  - Fast unlock using device biometric hardware (`local_auth` supporting Touch ID, Face ID, Android Biometrics, and Windows Hello).
- **Data Portability**: Full JSON backup and restore, plus CSV export/import encoded with UTF-8 BOM for seamless compatibility with Microsoft Excel, Apple Numbers, and Google Sheets.

---

### 7. Cloud Synchronization Architecture (Supabase Blueprint)

The application architecture includes a structured blueprint for optional cloud database synchronization using **Supabase (PostgreSQL)**, ensuring ACID compliance, relational integrity, and cross-platform reliability.

```
                           +------------------------+
                           |  Local JSON Storage    |
                           |  (StorageService)      |
                           +------------------------+
                                       ^
                                       | (Two-Way Sync / LWW)
                                       v
                           +------------------------+
                           |  Supabase Repository   |
                           |  (Offline-First Sync)  |
                           +------------------------+
                                       |
                   +-------------------+-------------------+
                   |                   |                   |
                   v                   v                   v
            +--------------+   +------------------+   +---------------+
            |   profiles   |   |   budget_plans   |   |  transactions |
            | (auth.users) |   | (user_id = RLS)  |   | (user_id = RLS|
            +--------------+   +------------------+   +---------------+
```

#### Database Schema
- **`profiles`**: User account parameters and preferences (`id`, `email`, `currency_code`, timestamps).
- **`budget_plans`**: Monthly budgeting allocations (`id`, `user_id`, `target_daily_allowance`, `planned_income`, `target_monthly_savings`, `planned_fixed_costs`, `year_month`, timestamps).
- **`transactions`**: Granular financial transactions (`id`, `user_id`, `title`, `amount`, `type`, `cost_nature`, `category_name`, `date`, `note`, `is_synced`, `is_deleted`, timestamps).
- **Security & RLS**: 100% Row Level Security enforced on all tables, guaranteeing that authenticated users can only query and mutate records where `user_id = auth.uid()`.
- **Conflict Resolution**: Client-side offline resilience with Last-Write-Wins (LWW) timestamp reconciliation upon reconnection.

---

## Directory Structure

```
lib/
├── app.dart                                # Application widget configuration
├── main.dart                               # Bootstrap, security bindings & locale initialization
└── app/
    ├── data/
    │   ├── models/
    │   │   ├── bank_slip_model.dart        # Bank slip & QR parsing data models
    │   │   ├── budget_plan_model.dart      # Budget allocations & target allowances
    │   │   ├── scheduled_payment_model.dart# Recurring commitments & cycle settings
    │   │   ├── scheduled_payment_preset.dart# Quick payment templates & shortcuts
    │   │   ├── transaction_model.dart      # Core transaction entity & cost nature
    │   │   └── wallet_health_model.dart    # Diagnostic scoring & financial resilience
    │   └── services/
    │       ├── bank_ocr_service.dart       # ML Kit & Tesseract OCR dual-engine
    │       ├── bank_qr_decoder.dart        # ZXing2 EMVCo PromptPay QR decoder
    │       ├── bank_slip_parser.dart       # 2,500+ LOC Thai banking semantic parser
    │       ├── bank_slip_service.dart      # Batch slip processing & auto-save manager
    │       ├── csv_service.dart            # Excel UTF-8 BOM CSV import/export
    │       ├── security_service.dart       # Biometric hardware & 4-digit PIN vault
    │       ├── slip_category_predictor.dart# Multi-signal category inference engine
    │       └── storage_service.dart        # Encrypted on-device JSON persistence
    ├── modules/
    │   ├── budget/                         # Budget allocation settings & formula tuning
    │   ├── dashboard/                      # Overview dashboard, Bento Grid & diagnostics
    │   │   ├── controllers/                # DashboardController (Single Source of Truth)
    │   │   ├── views/                      # Adaptive, Desktop & Mobile views
    │   │   └── widgets/                    # BalanceCard, DailyAllowanceCard, Charts, etc.
    │   ├── data_management/                # Export, import, and database reset tools
    │   ├── security/                       # Lockscreen, PIN management & biometrics
    │   └── transactions/                   # Quick Add sheet, filters & slip confirm sheets
    ├── routes/
    │   ├── app_pages.dart                  # GetX page route definitions
    │   └── app_routes.dart                 # Route string constants
    ├── theme/
    │   ├── app_colors.dart                 # Nothing OS industrial monochrome palette
    │   ├── app_popup_decorations.dart      # Glass dialog & bottom sheet styling
    │   └── app_theme.dart                  # Material 3 typography with Prompt fallback
    ├── translations/
    │   └── app_translations.dart           # GetX bilingual translations (th_TH / en_US)
    └── widgets/
        ├── app_feedback.dart               # Tactile haptic & in-app snackbar manager
        ├── liquid_glass_nav_dock.dart      # Mobile floating navigation dock
        ├── modern_app_bar.dart             # Adaptive top navigation bar
        └── nothing_ui_components.dart      # Squircle cards, dot matrix grids & LED indicators
```

---

## Technology Stack

| Category | Component / Library | Specification / Usage |
|---|---|---|
| **Core Framework** | Flutter SDK | Version 3.x with Dart 3.12+ |
| **State Management** | GetX | Reactive state management, dependency injection & routing |
| **Design System** | Nothing OS Industrial | Squircle shapes, 0.8px hairline borders, LED glyphs |
| **Typography** | Google Fonts | Space Grotesk, Share Tech Mono & Prompt (Cadson Demak) |
| **Glassmorphism** | `liquid_glass_easy` | Real-time refraction, optical borders, and blur shaders |
| **Data Visualization**| `fl_chart` | Interactive multi-curve cashflow and category charts |
| **QR Code Engine** | `zxing2` | EMVCo PromptPay transfer QR code decoding |
| **OCR Engines** | `google_mlkit_text_recognition` & `flutter_tesseract_ocr` | Dual-engine on-device text extraction for receipts |
| **Biometrics** | `local_auth` | Touch ID, Face ID, Fingerprint, and Windows Hello |
| **Persistence** | `path_provider` & File I/O | Offline-first encrypted local JSON data store |
| **Internationalization**| GetX Translations | 100% string coverage for Thai (`th_TH`) and English (`en_US`) |

---

## Getting Started

### Prerequisites
- **Flutter SDK**: `>= 3.12.0` ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `>= 3.12.0`
- **IDE**: VS Code, Android Studio, or Antigravity IDE with Flutter extensions
- **Target Platform Tools**:
  - Android SDK for Android deployment
  - Xcode for iOS and macOS deployment
  - Visual Studio C++ build tools for Windows Desktop deployment

### Installation & Execution

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/money_tracker.git
   cd money_tracker
   ```

2. **Install project dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify static analysis and code health**:
   ```bash
   flutter analyze
   ```

4. **Launch on your target device**:
   ```bash
   # Run on connected mobile device or desktop workstation
   flutter run

   # Or target a specific platform directly:
   flutter run -d windows
   flutter run -d macos
   flutter run -d chrome
   ```

---

## Development Standards & Engineering Guidelines

All contributions to Money Tracker must strictly adhere to the project's engineering standards:

1. **Zero Hardcoded Strings**: All user-facing text, labels, units (`'days'`, `'THB'`, `'times'`), notices, and instructions must use GetX localization keys via `.tr` or `.trParams({...})` defined in `lib/app/translations/app_translations.dart`.
2. **Zero-Emoji Policy**: No emojis are permitted anywhere in code, models, widgets, or translation files. Use Material Design glyph icons exclusively to maintain clean industrial aesthetics.
3. **Typography Standards**: All numbers and monetary values must utilize `NothingTypography.mono` (`Share Tech Mono`). All labels must utilize `NothingTypography.grotesk` (`Space Grotesk`) with weight-matched `Prompt` fallback.
4. **Single Source of Truth**: All cashflow metrics and financial indicators must be derived from reactive getters in `DashboardController`.
5. **Responsive Safety**: All text in horizontal containers must be wrapped with `Expanded`, `Flexible`, or `FittedBox` to prevent overflow across display sizes from 320px mobile screens to wide desktop monitors.
6. **Clean Code Discipline**: Zero unused imports or variables permitted in production code.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for complete details.

### Acknowledgements
- Design language inspired by the industrial aesthetic of **Nothing Technology Limited**.
- Modern loopless Thai banking typography powered by **Prompt** created by **Cadson Demak**.
