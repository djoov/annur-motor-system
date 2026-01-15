import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/pos/pos_screen.dart';
import '../features/history/history_screen.dart';
import '../features/placeholder/placeholder_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/items/items_list_screen.dart';
import '../features/categories/categories_list_screen.dart';
import '../features/customers/customers_list_screen.dart';
import '../features/suppliers/suppliers_list_screen.dart';

import '../features/purchases/purchases_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stock_opname/stock_opname_list_screen.dart';
import '../features/reports/low_stock_report_screen.dart';
import '../features/reports/daily_sales/daily_sales_screen.dart';
import '../features/debts/debts_list_screen.dart';
import '../features/auth/users_list_screen.dart';
import '../features/stock_request/stock_request_screen.dart';

import '../features/auth/auth_provider.dart';
import '../core/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              authProvider.user?.displayName ?? "User",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(authProvider.user?.email ?? ""),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(LucideIcons.user, color: AppColors.primary),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  "Dashboard",
                  LucideIcons.layoutDashboard,
                  const DashboardScreen(),
                ),
                _buildNavItem(
                  context,
                  "Scan QR",
                  LucideIcons.scanLine,
                  const ScanScreen(),
                  isScanner: true,
                ),
                _buildNavItem(
                  context,
                  "Kasir (POS)",
                  LucideIcons.shoppingCart,
                  const PosScreen(),
                ),

                const Divider(),

                // Master Data Expansion
                ExpansionTile(
                  leading: const Icon(LucideIcons.database),
                  title: const Text("Master Data"),
                  children: [
                    _buildNavItem(
                      context,
                      "Kategori",
                      LucideIcons.package,
                      const CategoriesListScreen(),
                    ),
                    _buildNavItem(
                      context,
                      "Barang",
                      LucideIcons.shoppingCart,
                      const ItemsListScreen(),
                    ),
                    _buildNavItem(
                      context,
                      "Pelanggan",
                      LucideIcons.users,
                      const CustomersListScreen(),
                    ),
                    _buildNavItem(
                      context,
                      "Hutang / Piutang",
                      LucideIcons.wallet,
                      const DebtsListScreen(),
                    ),
                    _buildNavItem(
                      context,
                      "Supplier",
                      LucideIcons.truck,
                      const SuppliersListScreen(),
                    ),

                    _buildNavItem(
                      context,
                      "Stock Opname (Audit)",
                      LucideIcons.clipboardCheck,
                      const StockOpnameListScreen(),
                    ),
                    _buildNavItem(
                      context,
                      "Permintaan Stok",
                      LucideIcons.clipboardList,
                      const StockRequestScreen(),
                    ),
                    if (authProvider.isAdmin)
                      _buildNavItem(
                        context,
                        "Pembelian",
                        LucideIcons.archive,
                        const PurchasesScreen(),
                      ),
                  ],
                ),

                // Reports Expansion
                ExpansionTile(
                  leading: const Icon(LucideIcons.barChart3),
                  title: const Text("Laporan"),
                  children: [
                    _buildNavItem(
                      context,
                      "Penjualan Harian",
                      LucideIcons.fileText,
                      DailySalesScreen(),
                    ),
                    _buildNavItem(
                      context,
                      "Riwayat Transaksi",
                      LucideIcons.history,
                      const HistoryScreen(),
                    ),
                    _buildNavItem(
                      context,
                      "Stok Menipis",
                      LucideIcons.alertTriangle,
                      const LowStockReportScreen(),
                    ),
                    if (authProvider.isAdmin)
                      _buildNavItem(
                        context,
                        "Keuntungan",
                        LucideIcons.fileText,
                        const PlaceholderScreen(title: "Keuntungan"),
                      ),
                  ],
                ),

                if (authProvider.isAdmin) ...[
                  const Divider(),
                  _buildNavItem(
                    context,
                    "Kelola Pengguna",
                    LucideIcons.users,
                    const UsersListScreen(),
                  ),
                ],

                const Divider(),
                _buildNavItem(
                  context,
                  "Pengaturan",
                  LucideIcons.settings,
                  const SettingsScreen(),
                ),
              ],
            ),
          ),

          // Footer
          const Divider(),
          ListTile(
            leading: const Icon(
              LucideIcons.logOut,
              color: AppColors.destructive,
            ),
            title: const Text(
              "Keluar",
              style: TextStyle(color: AppColors.destructive),
            ),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen, {
    bool isScanner = false,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title),
      onTap: () async {
        Navigator.pop(context); // Close Drawer
        if (isScanner) {
          final code = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
          if (code != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemsListScreen(initialQuery: code),
              ),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        }
      },
    );
  }
}
