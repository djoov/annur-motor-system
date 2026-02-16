import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../items/items_provider.dart';
import '../history/history_provider.dart';
import '../dashboard/dashboard_provider.dart';

// Screens
import '../pos/pos_screen.dart';
import '../items/items_list_screen.dart';
import '../categories/categories_list_screen.dart';
import '../customers/customers_list_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../history/history_screen.dart';
import '../debts/debts_list_screen.dart';
import '../purchases/purchases_screen.dart';
import '../settings/settings_screen.dart';
import '../stock_opname/stock_opname_list_screen.dart';
import '../reports/low_stock_report_screen.dart';
import '../reports/daily_sales/daily_sales_screen.dart';
import '../auth/users_list_screen.dart';
import '../stock_request/stock_request_screen.dart';
import '../scan/scan_screen.dart';
import '../profile/profile_screen.dart';
import '../dashboard/widgets/weekly_revenue_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Mandiri-like Color Palette
  static const Color mandiriBlueDark = Color(0xFF003D79);
  static const Color mandiriBlueLight = Color(0xFF005C9F);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemsProvider>(context, listen: false).fetchItems();
      Provider.of<HistoryProvider>(context, listen: false).fetchTransactions();
      Provider.of<DashboardProvider>(context, listen: false).fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      extendBody: true,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const ItemsListScreen(showBackButton: false);
      case 2:
        return const PosScreen();
      case 3:
        return const HistoryScreen();
      case 4:
        return const SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemsProvider = Provider.of<ItemsProvider>(context);
    final historyProvider = Provider.of<HistoryProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Calculate today's sales
    final today = DateTime.now();
    final todaySales = historyProvider.transactions
        .where(
          (t) =>
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .toList();
    final todayTotal = todaySales.fold<int>(0, (sum, t) => sum + t.totalAmount);
    final todayCount = todaySales.length;

    return CustomScrollView(
      slivers: [
        // Merged Header & Summary Card Section
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return _buildTabletHeader(
                  authProvider,
                  currencyFormat,
                  todayTotal,
                  todayCount,
                  itemsProvider,
                );
              }
              return _buildHeaderAndSummarySection(
                authProvider,
                currencyFormat,
                todayTotal,
                todayCount,
                itemsProvider,
              );
            },
          ),
        ),

        // Menu Grid
        SliverToBoxAdapter(child: _buildMenuSection(authProvider)),

        // Weekly Revenue Chart (New)
        SliverToBoxAdapter(child: _buildChartSection(dashboardProvider)),

        // Low Stock Alert
        if (itemsProvider.lowStockDisplayItems.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildAlertCard(itemsProvider.lowStockDisplayItems.length),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildChartSection(DashboardProvider dashboard) {
    // Only show on Tablet/Desktop
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.of(context).size.width < 600) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tren Penjualan (7 Hari)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: mandiriBlueDark,
                      ),
                    ),
                    Icon(
                      LucideIcons.barChart2,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                dashboard.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : WeeklyRevenueChart(weeklyData: dashboard.weeklyRevenue),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAndSummarySection(
    AuthProvider auth,
    NumberFormat currency,
    int todayTotal,
    int todayCount,
    ItemsProvider itemsProvider,
  ) {
    return Stack(
      children: [
        // 1. Blue Header Background (Underneath)
        Container(
          height: 250, // Fixed height for background
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [mandiriBlueDark, mandiriBlueLight],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              // Decorative Circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Foreground Content (User Info + Card)
        Column(
          children: [
            // User Info Section
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                (auth.userModel?.name ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: mandiriBlueDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Selamat Pagi,",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                auth.userModel?.name ?? 'User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Actions
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => _navigateTo(const ScanScreen()),
                            icon: const Icon(
                              LucideIcons.scan,
                              color: Colors.white,
                            ),
                            tooltip: "Scan Barcode",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                _navigateTo(const SettingsScreen()),
                            icon: const Icon(
                              LucideIcons.settings,
                              color: Colors.white,
                            ),
                            tooltip: "Pengaturan",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10), // Spacing between Header and Card
            // Floating Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: mandiriBlueDark.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Section: Sales
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: mandiriBlueLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.wallet,
                              color: mandiriBlueDark,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Penjualan Hari Ini',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currency.format(todayTotal),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: mandiriBlueDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade100,
                                  ),
                                ),
                                child: Text(
                                  "$todayCount Trx",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Bottom Section: Quick Stats
                    SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _navigateTo(const ItemsListScreen()),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.package,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${itemsProvider.items.length} Barang",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, color: Colors.grey.shade200),
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  _navigateTo(const LowStockReportScreen()),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.alertTriangle,
                                    size: 16,
                                    color:
                                        itemsProvider
                                            .lowStockDisplayItems
                                            .isNotEmpty
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${itemsProvider.lowStockDisplayItems.length} Menipis",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          itemsProvider
                                              .lowStockDisplayItems
                                              .isNotEmpty
                                          ? Colors.orange
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletHeader(
    AuthProvider auth,
    NumberFormat currency,
    int todayTotal,
    int todayCount,
    ItemsProvider itemsProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mandiriBlueDark, mandiriBlueLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (User & Settings)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Text(
                      (auth.userModel?.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: mandiriBlueDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Selamat Pagi,",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        auth.userModel?.name ?? "Admin User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _navigateTo(const ScanScreen()),
                    icon: const Icon(LucideIcons.scan, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => _navigateTo(const SettingsScreen()),
                    icon: const Icon(LucideIcons.settings, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Dashboard Summary Cards (Row of 3)
          Row(
            children: [
              // 1. Sales Card
              Expanded(
                child: _buildSummaryCard(
                  title: "Penjualan Hari Ini",
                  value: currency.format(todayTotal),
                  icon: LucideIcons.wallet,
                  color: Colors.green,
                  badge: "$todayCount Trx",
                ),
              ),
              const SizedBox(width: 16),
              // 2. Items Card
              Expanded(
                child: _buildSummaryCard(
                  title: "Total Barang",
                  value: "${itemsProvider.items.length}",
                  icon: LucideIcons.package,
                  color: Colors.blue,
                  onTap: () => _navigateTo(const ItemsListScreen()),
                ),
              ),
              const SizedBox(width: 16),
              // 3. Low Stock Card
              Expanded(
                child: _buildSummaryCard(
                  title: "Stok Menipis",
                  value: "${itemsProvider.lowStockDisplayItems.length}",
                  icon: LucideIcons.alertTriangle,
                  color: Colors.orange,
                  onTap: () => _navigateTo(const LowStockReportScreen()),
                  isDestructive: itemsProvider.lowStockDisplayItems.isNotEmpty,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? badge,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isDestructive
                ? Border.all(color: Colors.red.shade200)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDestructive ? Colors.red : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu Utama',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mandiriBlueDark,
                    ),
                  ),
                  // Optional: Add settings button like Livin
                  // Icon(LucideIcons.settings2, color: mandiriBlueDark, size: 20),
                ],
              ),
            ),
            // Menu Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: _buildMenuGrid(auth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(AuthProvider auth) {
    final menus = _getMenuItems(auth);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive columns: Livin style
        int crossAxisCount = 5; // Default phone
        if (constraints.maxWidth >= 600)
          crossAxisCount = 8; // Tablet (Smaller cards)
        if (constraints.maxWidth >= 900)
          crossAxisCount = 9; // Large tablet/Desktop
        if (constraints.maxWidth < 400) crossAxisCount = 4; // Small phone
        if (constraints.maxWidth < 320) crossAxisCount = 3; // Very small

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing: 16,
          ),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final menu = menus[index];
            return _buildMenuItem(
              icon: menu['icon'] as IconData,
              label: menu['label'] as String,
              color: menu['color'] as Color,
              onTap: () => _navigateTo(menu['screen'] as Widget),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMenuItems(AuthProvider auth) {
    // Distinct colors for visual separation
    final items = <Map<String, dynamic>>[
      {
        'icon': LucideIcons.shoppingCart,
        'label': 'Kasir',
        'color': const Color(0xFF00C853), // Vivid Green
        'screen': const PosScreen(),
      },
      {
        'icon': LucideIcons.package,
        'label': 'Barang',
        'color': const Color(0xFF2962FF), // Vivid Blue
        'screen': const ItemsListScreen(),
      },
      {
        'icon': LucideIcons.users,
        'label': 'Pelanggan',
        'color': const Color(0xFFFF6D00), // Vivid Orange
        'screen': const CustomersListScreen(),
      },
      {
        'icon': LucideIcons.history,
        'label': 'Riwayat',
        'color': const Color(0xFF5D4037), // Brown
        'screen': const HistoryScreen(),
      },
      {
        'icon': LucideIcons.wallet,
        'label': 'Hutang',
        'color': const Color(0xFFD50000), // Red
        'screen': const DebtsListScreen(),
      },
      {
        'icon': LucideIcons.layoutGrid,
        'label': 'Kategori',
        'color': const Color(0xFF00B8D4), // Cyan
        'screen': const CategoriesListScreen(),
      },
      {
        'icon': LucideIcons.clipboardList,
        'label': 'Permintaan',
        'color': const Color(0xFF455A64), // Blue Grey
        'screen': const StockRequestScreen(),
      },
      {
        'icon': LucideIcons.clipboardCheck,
        'label': 'Opname',
        'color': const Color(0xFF304FFE), // Indigo
        'screen': const StockOpnameListScreen(),
      },
      {
        'icon': LucideIcons.fileBarChart2,
        'label': 'Laporan',
        'color': const Color(0xFF00695C), // Teal
        'screen': DailySalesScreen(),
      },
      {
        'icon': LucideIcons.scan,
        'label': 'Scan QR',
        'color': const Color(0xFFAA00FF), // Purple
        'screen': const ScanScreen(),
      },
      {
        'icon': LucideIcons.alertTriangle,
        'label': 'Stok Tipis',
        'color': const Color(0xFFC51162), // Pink
        'screen': const LowStockReportScreen(),
      },
    ];

    // Admin only items
    if (auth.isAdmin) {
      items.addAll([
        {
          'icon': LucideIcons.truck,
          'label': 'Supplier',
          'color': const Color(0xFF6200EA), // Deep Purple
          'screen': const SuppliersListScreen(),
        },
        {
          'icon': LucideIcons.archive,
          'label': 'Pembelian',
          'color': const Color(0xFF64DD17), // Light Green
          'screen': const PurchasesScreen(),
        },
        {
          'icon': LucideIcons.userCog,
          'label': 'Admin',
          'color': const Color(0xFF263238), // Dark Blue Grey
          'screen': const UsersListScreen(),
        },
      ]);
    }

    return items;
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Livin style: soft blue background for all icons
    const softBlue = Color(0xFFE8F4FD);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container with soft blue background
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: softBlue,
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(int lowStockCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateTo(const LowStockReportScreen()),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6D00),
                  const Color(0xFFFF9100).withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.alertTriangle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Peringatan Stok!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$lowStockCount barang perlu restock segera',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomNavItem(
                icon: LucideIcons.home,
                label: 'Beranda',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: LucideIcons.package,
                label: 'Barang',
                index: 1,
              ),
              _buildCenterNavItem(),
              _buildBottomNavItem(
                icon: LucideIcons.barChart3,
                label: 'Laporan',
                index: 3,
              ),
              _buildBottomNavItem(
                icon: LucideIcons.settings,
                label: 'Pengaturan',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? mandiriBlueDark : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? mandiriBlueDark : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 2),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [mandiriBlueLight, mandiriBlueDark],
            ),
            boxShadow: [
              BoxShadow(
                color: mandiriBlueDark.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              LucideIcons.shoppingCart,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
