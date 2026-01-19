import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../ui/app_drawer.dart';
import '../pos/pos_screen.dart';
import '../history/history_screen.dart';
import '../scan/scan_screen.dart';
import '../items/items_list_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_provider.dart';
import '../../features/stock_request/stock_request_provider.dart';
import '../../features/stock_request/stock_request_screen.dart';
import 'dashboard_provider.dart';
import 'package:intl/intl.dart';
import '../../features/auth/auth_provider.dart';
import 'widgets/weekly_revenue_chart.dart';
import 'widgets/top_items_widget.dart';
import 'widgets/low_stock_widget.dart';

class DashboardMobile extends StatelessWidget {
  const DashboardMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context); // Inject Auth
    final stockRequestProvider = Provider.of<StockRequestProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final pendingCount = stockRequestProvider.pendingCount;

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Annur Motor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Bell Icon with Badge (Admin only shows count)
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, color: Colors.white),
                onPressed: isAdmin
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StockRequestScreen(),
                        ),
                      )
                    : null,
              ),
              if (isAdmin && pendingCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        pendingCount > 9 ? '9+' : '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.userCircle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Section (Gradient + Welcome)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 110, 24, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // Slate 800
                    Color(0xFF0F172A), // Slate 900
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<SettingsProvider>(
                            builder: (context, settings, _) {
                              var hour = DateTime.now().hour;
                              String greeting;
                              if (hour < 11) {
                                greeting = "Selamat Pagi";
                              } else if (hour < 15) {
                                greeting = "Selamat Siang";
                              } else if (hour < 18) {
                                greeting = "Selamat Sore";
                              } else {
                                greeting = "Selamat Malam";
                              }

                              return Text(
                                "$greeting, ${settings.adminName}!",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Ringkasan Bisnis",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.refreshCw,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => dashboardProvider.fetchStats(),
                          tooltip: "Refresh Data",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Reduced from 24
                  // Summary Cards Row
                  SizedBox(
                    height: 130, // Slightly compact
                    child: dashboardProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            children: [
                              _buildSummaryCard(
                                "Penjualan Hari Ini",
                                currencyFormat.format(
                                  dashboardProvider.totalSales,
                                ),
                                LucideIcons.banknote,
                                const Color(0xFF3B82F6), // Blue
                              ),
                              const SizedBox(width: 16),
                              _buildSummaryCard(
                                "Transaksi",
                                "${dashboardProvider.transactionCount}",
                                LucideIcons.shoppingBag,
                                const Color(0xFF10B981), // Emerald
                              ),
                              const SizedBox(width: 16),
                              _buildSummaryCard(
                                "Total Pelanggan",
                                "${dashboardProvider.customerCount}",
                                LucideIcons.users,
                                const Color(0xFFF59E0B), // Amber
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            // 2. Content Section - Different order for phone vs tablet
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isTablet = screenWidth >= 600;

                // Build Quick Access widget
                Widget quickAccess = Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, isTablet ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Akses Cepat",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isTablet ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isTablet ? 1.2 : 1.0,
                        children: [
                          _buildMenuCard(
                            context,
                            "Kasir (POS)",
                            "Buat Transaksi",
                            LucideIcons.shoppingCart,
                            const Color(0xFF3B82F6),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PosScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            "Kelola Produk",
                            "Data Barang",
                            LucideIcons.package,
                            const Color(0xFFF97316),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ItemsListScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            "Cek Harga",
                            "Scan QR Code",
                            LucideIcons.scanLine,
                            const Color(0xFF8B5CF6),
                            () async {
                              final code = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanScreen(),
                                ),
                              );

                              if (code != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemsListScreen(initialQuery: code),
                                  ),
                                );
                              }
                            },
                          ),
                          _buildMenuCard(
                            context,
                            "Laporan",
                            "Riwayat & Omset",
                            LucideIcons.fileBarChart,
                            const Color(0xFF10B981),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                // Build BI Section widget
                Widget biSection = isTablet && isAdmin
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TopItemsWidget(
                                items: dashboardProvider.topItems,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LowStockWidget(
                                items: dashboardProvider.lowStockItems,
                              ),
                            ),
                          ],
                        ),
                      )
                    : (isAdmin
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Tren Pendapatan (7 Hari)",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    dashboardProvider.isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : WeeklyRevenueChart(
                                            weeklyData:
                                                dashboardProvider.weeklyRevenue,
                                          ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink());

                // Return different order based on device
                if (isTablet) {
                  // Tablet: Quick Access first, then BI
                  return Column(children: [quickAccess, biSection]);
                } else {
                  // Phone: BI first, then Quick Access
                  return Column(children: [biSection, quickAccess]);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 170, // Increased for better fit
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF334155), // DarkSlate
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
