import 'package:flutter/material.dart';
import '../../core/theme.dart';

import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/weekly_revenue_chart.dart';
import '../../ui/desktop_scaffold.dart';
import 'widgets/top_items_widget.dart';
import 'widgets/low_stock_widget.dart';
import '../../features/settings/settings_provider.dart';
import '../../features/stock_request/stock_request_provider.dart';
import '../../features/stock_request/stock_request_screen.dart';

class DashboardDesktop extends StatelessWidget {
  const DashboardDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final stockRequestProvider = Provider.of<StockRequestProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final pendingCount = stockRequestProvider.pendingCount;

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Mobile uses MobileScaffold/Scaffold logic typically, but here we enforce DesktopScaffold
    // because this widget is specifically "DashboardDesktop".
    // If we want to support mobile dashboard, it should be in dashboard_mobile.dart
    // or handled by a responsive wrapper.
    // Assuming this widget IS standard for desktop:

    return DesktopScaffold(
      activeRoute: '/dashboard',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (Search, Profile)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              color: Colors.white,
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dashboard Utama",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        "Halo, ${settingsProvider.adminName}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Bell Icon with Badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.bell),
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
                          right: 4,
                          top: 4,
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
                  const SizedBox(width: 16),
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(LucideIcons.user, color: Colors.white),
                  ),
                ],
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    constraints.maxWidth > 800; // Threshold for 4-col stats

                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Stats Row
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "Total Penjualan",
                                currencyFormat.format(
                                  dashboardProvider.totalSales,
                                ),
                                LucideIcons.banknote,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStatCard(
                                "Transaksi",
                                "${dashboardProvider.transactionCount}",
                                LucideIcons.shoppingBag,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStatCard(
                                "Pelanggan",
                                "${dashboardProvider.customerCount}",
                                LucideIcons.users,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStatCard(
                                "Estimasi Profit",
                                isAdmin
                                    ? currencyFormat.format(
                                        dashboardProvider.totalSales * 0.2,
                                      )
                                    : "Rp *****",
                                LucideIcons.trendingUp,
                                Colors.purple,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Total Penjualan",
                                    currencyFormat.format(
                                      dashboardProvider.totalSales,
                                    ),
                                    LucideIcons.banknote,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildStatCard(
                                    "Transaksi",
                                    "${dashboardProvider.transactionCount}",
                                    LucideIcons.shoppingBag,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Pelanggan",
                                    "${dashboardProvider.customerCount}",
                                    LucideIcons.users,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildStatCard(
                                    "Estimasi Profit",
                                    isAdmin
                                        ? currencyFormat.format(
                                            dashboardProvider.totalSales * 0.2,
                                          )
                                        : "Rp *****",
                                    LucideIcons.trendingUp,
                                    Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: 32),

                      // Charts & Activity
                      if (isAdmin) ...[
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildChartContainer(
                                  dashboardProvider,
                                  isAdmin,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: _buildActivityContainer(
                                  dashboardProvider,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildChartContainer(dashboardProvider, isAdmin),
                              const SizedBox(height: 24),
                              _buildActivityContainer(dashboardProvider),
                            ],
                          ),
                      ] else ...[
                        // Staff View: Only Activity (No Charts)
                        _buildActivityContainer(dashboardProvider),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(DashboardProvider provider, bool isAdmin) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tren Pendapatan Mingguan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: isAdmin
                ? WeeklyRevenueChart(weeklyData: provider.weeklyRevenue)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.lock, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Akses Terbatas (Admin Only)",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityContainer(DashboardProvider provider) {
    return Column(
      children: [
        Expanded(child: TopItemsWidget(items: provider.topItems)),
        const SizedBox(height: 24),
        Expanded(child: LowStockWidget(items: provider.lowStockItems)),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
