import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../features/auth/auth_provider.dart';

// Screens
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/pos/pos_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/items/items_list_screen.dart';

import '../../features/categories/categories_list_screen.dart';
import '../../features/customers/customers_list_screen.dart';
import '../../features/suppliers/suppliers_list_screen.dart';
import '../../features/purchases/purchases_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/stock_opname/stock_opname_list_screen.dart';
import '../../features/reports/low_stock_report_screen.dart';
import '../../features/reports/daily_sales/daily_sales_screen.dart';
import '../../features/debts/debts_list_screen.dart';
import '../../features/auth/users_list_screen.dart';
import '../../features/stock_request/stock_request_screen.dart';
import '../../features/placeholder/placeholder_screen.dart';

class DesktopSidebar extends StatelessWidget {
  final String activeRoute; // e.g., '/dashboard', '/pos', '/items'

  const DesktopSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Area
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Image.asset('assets/icon/app_icon.png', width: 56, height: 56),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "MekanikHub",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Scrollable Menu
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavItem(
                    context,
                    "Dashboard",
                    LucideIcons.layoutDashboard,
                    const DashboardScreen(),
                    isActive: activeRoute == '/dashboard' || activeRoute == '/',
                  ),
                  _buildNavItem(
                    context,
                    "Kasir (POS)",
                    LucideIcons.shoppingCart,
                    const PosScreen(),
                    isActive: activeRoute == '/pos',
                  ),

                  const Divider(color: Colors.white10, height: 24),

                  // Master Data
                  _buildExpansionItem(
                    context,
                    title: "Master Data",
                    icon: LucideIcons.database,
                    children: [
                      _buildSubItem(
                        context,
                        "Barang",
                        const ItemsListScreen(),
                        isActive: activeRoute == '/items',
                      ),
                      _buildSubItem(
                        context,
                        "Kategori",
                        const CategoriesListScreen(),
                        isActive: activeRoute == '/categories',
                      ),
                      _buildSubItem(
                        context,
                        "Pelanggan",
                        const CustomersListScreen(),
                        isActive: activeRoute == '/customers',
                      ),
                      _buildSubItem(
                        context,
                        "Supplier",
                        const SuppliersListScreen(),
                        isActive: activeRoute == '/suppliers',
                      ),
                      _buildSubItem(
                        context,
                        "Hutang",
                        const DebtsListScreen(),
                        isActive: activeRoute == '/debts',
                      ),
                      _buildSubItem(
                        context,
                        "Stock Opname",
                        const StockOpnameListScreen(),
                        isActive: activeRoute == '/stock_opname',
                      ),
                      _buildSubItem(
                        context,
                        "Permintaan Stok",
                        const StockRequestScreen(),
                        isActive: activeRoute == '/stock_requests',
                      ),
                      if (isAdmin)
                        _buildSubItem(
                          context,
                          "Pembelian",
                          const PurchasesScreen(),
                          isActive: activeRoute == '/purchases',
                        ),
                    ],
                  ),

                  // Reports
                  _buildExpansionItem(
                    context,
                    title: "Laporan",
                    icon: LucideIcons.barChart3,
                    children: [
                      _buildSubItem(
                        context,
                        "Penjualan Harian",
                        DailySalesScreen(),
                        isActive: activeRoute == '/daily_sales',
                      ),
                      _buildSubItem(
                        context,
                        "Riwayat Transaksi",
                        const HistoryScreen(),
                        isActive: activeRoute == '/history',
                      ),
                      _buildSubItem(
                        context,
                        "Stok Menipis",
                        const LowStockReportScreen(),
                        isActive: activeRoute == '/low_stock',
                      ),
                      if (isAdmin)
                        _buildSubItem(
                          context,
                          "Keuntungan",
                          const PlaceholderScreen(title: "Keuntungan"),
                          isActive: activeRoute == '/profit',
                        ),
                    ],
                  ),

                  if (isAdmin) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _buildNavItem(
                      context,
                      "Kelola Pengguna",
                      LucideIcons.users,
                      const UsersListScreen(),
                      isActive: activeRoute == '/users',
                    ),
                  ],

                  const Divider(color: Colors.white10, height: 24),
                  _buildNavItem(
                    context,
                    "Pengaturan",
                    LucideIcons.settings,
                    const SettingsScreen(),
                    isActive: activeRoute == '/settings',
                  ),
                ],
              ),
            ),
          ),

          // Footer
          const Divider(color: Colors.white10),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen, {
    bool isActive = false,
    bool isScanner = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: isActive
          ? BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        selected: isActive,
        dense: true,
        horizontalTitleGap: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          if (!isActive) {
            if (isScanner) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            } else {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => screen,
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildExpansionItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // Check if any child is active to expand initially?
    // This is hard without explicit state management just for the UI.
    // Standard ExpansionTile works fine.
    // For styling, we need to customize Theme or parameters.
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(dividerColor: Colors.transparent), // Hide internal divider
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        childrenPadding: const EdgeInsets.only(left: 16), // Indent children
        children: children,
      ),
    );
  }

  // Need context in _buildExpansionItem, but it's not passed or method is not in build context.
  // I'll make it a full method passing context context, OR better, use a Builder or move it inside build if needed for Theme.
  // Actually, I can use context if I make it a method inside the class.
  // But `context` refers to `this.context` which doesn't exist in Stateless.
  // I must pass context.

  Widget _buildSubItem(
    BuildContext context,
    String title,
    Widget screen, {
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: isActive
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.only(
          left: 32,
          right: 8,
        ), // Indent Text
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => screen,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ListTile(
        leading: const Icon(
          LucideIcons.logOut,
          color: Colors.redAccent,
          size: 20,
        ),
        title: const Text(
          "Keluar",
          style: TextStyle(color: Colors.redAccent, fontSize: 14),
        ),
        dense: true,
        horizontalTitleGap: 0,
        onTap: () async {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          await auth.logout();
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
      ),
    );
  }
}
