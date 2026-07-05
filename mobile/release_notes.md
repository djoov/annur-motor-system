# Release Notes v1.1.0 - Major UI/UX Overhaul & Desktop Optimization

We are excited to announce a major update for MekanikHub! This release focuses on modernizing the user interface, stabilizing platform compatibility, and significantly enhancing the Desktop/Tablet experience.

## 🌟 Key Highlights

### 🎨 Modern "Livin-Style" UI
-   **New Login & Register Screens**: Completely redesigned with a modern gradient aesthetic, split-view layout for desktop, and improved error handling.
-   **Dashboard Refinement**:
    -   **Mobile**: Cleaner layout with "Livin-style" header.
    -   **Tablet**: New 3-Card Summary row (Sales, Items, Low Stock) and optimized 8-column menu grid.
    -   **Desktop**: Persistent sidebar navigation and "Professional View" enforcement.

### 🖥️ Desktop & Windows Optimization
-   **Unified Sidebar**: Replaced the mobile drawer with a permanent, collapsible sidebar on Windows (>900px).
-   **Split Views**: Login screen now features a branding side-panel.
-   **Window Controls**: Enforced minimum window size (800x600) to prevent UI breakage.
-   **Pos Enhancement**: Persistent Cart Panel on the right side for faster checkout on large screens.

### 🖨️ Printing & Hardware
-   **Library Migration**: Migrated to `flutter_pos_printer_platform` to resolve Android Gradle Plugin (AGP) 8 build issues.
-   **Legacy Mode**: Added support for VSC/China printers via a "Legacy Mode" toggle in Settings.
-   **Custom Logos**: Fixed issue where transparent logos printed as black boxes.

### 🛠️ Features & Fixes
-   **Account Tab**: New settings tab for User Profile, Logout, and Data Reset.
-   **Stock Request**: Formal workflow for Staff to request stock from Warehouse.
-   **Stock Opname**: New module for physical stock auditing and reconciliation.
-   **Bug Fixes**:
    -   Fixed Logout navigation stack (now returns cleanly to login).
    -   Fixed "Simpan Pengaturan" button visibility on small screens.
    -   Resolved build issues on Windows regarding Firebase configuration.

## 📦 Technical Updates
-   **Codebase**: Refactored `HomeScreen` for responsive layout using `LayoutBuilder`.
-   **Assets**: Updated App Logo and Splash Screen.
-   **Documentation**: Completely rewritten `README.md` with detailed setup and feature guides.

## 🚀 How to Install
1.  Download the `.apk` file below.
2.  Install on your Android device.
3.  **Note**: For Bluetooth printing, ensure Location and Bluetooth permissions are granted.
