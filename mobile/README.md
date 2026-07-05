# MekanikHub (Mobile & Desktop POS)

MekanikHub is a robust and user-friendly Point of Sale (POS) and Inventory Management solution built with Flutter. It is designed to streamline operations for MekanikHub, supporting spare parts retail and mechanic services.

The application leverages a responsive design that adapts seamlessly across **Android Mobile** (optimized for touch), **Tablets** (expanded grid/dashboard), and **Windows Desktop** (optimized for keyboard/mouse + thermal printing).

## ✨ Key Features

### 🛒 Point of Sale (POS)
- **Fast Checkout**: Barcode scanning, quick search, and intuitive cart management.
- **Dynamic Pricing**: Support for Retail (Ecer) and Mechanic (Mechanic Price) pricing tiers.
- **Hold/Resume**: Save draft transactions and resume them later.
- **Discount Management**: Apply discounts per item or per transaction.
- **Customer Management**: Link sales to specific customers (Mechanic/Workshop).

### 📦 Inventory Management
- **Stock Tracking**: Real-time tracking of Display Stock (Toko) vs. Warehouse Stock (Gudang).
- **Low Stock Alerts**: Automatic notifications when stock falls below defined thresholds.
- **Bulk Operations**: Import/Export items via CSV/Excel.
- **Stock Transfers**: Workflow for staff to request stock transfers from Warehouse to Display.
- **Stock Opname**: Audit tools to reconcile physical stock with system records.

### 📊 Business Intelligence
- **Dashboard**: Real-time sales summary, top-selling items, and low stock warnings.
- **Reports**: Daily/Weekly/Monthly revenue charts.
- **Transaction History**: Searchable history with reprint capabilities.

### 👥 User Roles & Security
- **Admin**: Full access to all modules, including Buy Price (Modal) and Profit Reports.
- **Staff**: Restricted access focused on POS and basic inventory management.

### 🖨️ Hardware Integration
- **Thermal Printers**: Support for Bluetooth (Mobile) and USB/Network (Windows) thermal printers (58mm/80mm).
- **Barcode Scanners**: Optimized for usb/bluetooth barcode scanners.

## 📱 Platform Specifics

### Mobile (Android)
- **Livin-Style UI**: Modern, clean, and touch-friendly interface.
- **Bottom Navigation**: Easy access to core modules.
- **Bluetooth Printing**: Direct connection to mobile thermal printers.

### Tablet
- **Responsive Layout**: Expanded grid layouts for menus (8 columns).
- **Enhanced Dashboard**: 3-Card summary view (Sales, Items, Low Stock) + Revenue Chart.

### Desktop (Windows)
- **Window Management**: Custom window controls (Minimize/Maximize/Close).
- **Keyboard Shortcuts**: Optimized for rapid data entry.
- **Sidebar Navigation**: Persistent navigation for quick switching between modules.
- **Native Printing**: Direct printing via system drivers.

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth, Storage)
- **State Management**: Provider
- **UI Components**: Custom widgets, Lucide Icons, Google Fonts (Inter)
- **Printing**: `flutter_pos_printer_platform`
- **Charts**: `fl_chart`

## 🚀 Getting Started

1.  **Clone the repository**
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the application**:
    - **Mobile**: Connect device or emulator.
    - **Desktop**: Select Windows as target.
    ```bash
    flutter run
    ```

## 📝 Configuration

- **Firebase**: Ensure `google-services.json` (Android) and Firebase Options (Dart) are configured.
- **Printers**: Pair Bluetooth printers via system settings before connecting in-app.

---
**Developed for MekanikHub** | *Empowering Workshop Efficiency*
