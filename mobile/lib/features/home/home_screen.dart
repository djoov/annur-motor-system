import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme.dart';
import '../../ui/duo_icon.dart';
import '../../ui/bottom_nav_metrics.dart';
import '../auth/auth_provider.dart';
import '../auth/user_provider.dart';
import '../items/items_provider.dart';
import '../history/history_provider.dart';
import '../dashboard/dashboard_provider.dart';
import '../stock_request/stock_request_provider.dart';

// Screens
import '../pos/pos_screen.dart';
import '../items/items_list_screen.dart';
import '../items/bulk_import_screen.dart';
import '../categories/categories_list_screen.dart';
import '../customers/customers_list_screen.dart';
import '../debts/debts_list_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../purchases/purchases_screen.dart';
import '../stock_request/stock_request_screen.dart';
import '../stock_opname/stock_opname_list_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../reports/daily_sales/daily_sales_screen.dart';
import '../reports/low_stock_report_screen.dart';
import '../scan/scan_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/users_list_screen.dart';

const _tabular = [FontFeature.tabularFigures()];

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 Beranda · 1 Produk · 2 Kasir · 3 Riwayat · 4 Setelan
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<ItemsProvider>().fetchItems();
    context.read<HistoryProvider>().fetchTransactions();
    context.read<DashboardProvider>().fetchStats();
    if (context.read<AuthProvider>().isAdmin) {
      context.read<UserProvider>().fetchUsers();
    }
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) _selectTab(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _buildBody(),
            Positioned(
              bottom: BottomNavMetrics.bottomOffset(context),
              left: 16,
              right: 16,
              child: _BottomNav(
                selectedIndex: _selectedIndex,
                onSelect: _selectTab,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return const ItemsListScreen(showBackButton: false);
      case 2:
        return const PosScreen();
      case 3:
        return const HistoryScreen();
      case 4:
        return const SettingsScreen();
      default:
        return _BerandaContent(
          onSelectTab: _selectTab,
          onOpen: _open,
          onRefresh: _loadData,
        );
    }
  }
}

// ===========================================================================
// BERANDA
// ===========================================================================

class _BerandaContent extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  final ValueChanged<Widget> onOpen;
  final VoidCallback onRefresh;

  const _BerandaContent({
    required this.onSelectTab,
    required this.onOpen,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          onRefresh();
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SalesHeader(
                        isAdmin: isAdmin,
                        onOpenProfile: () => onOpen(const ProfileScreen()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _QuickActions(
                              isAdmin: isAdmin,
                              onOpen: onOpen,
                              onShowAllMenu: () => _showAllMenu(context),
                            ),
                            const SizedBox(height: 28),
                            _AttentionSection(isAdmin: isAdmin, onOpen: onOpen),
                            const SizedBox(height: 28),
                            _RecentTransactions(
                              onSeeAll: () => onSelectTab(3),
                            ),
                            // Space for the floating bottom nav
                            const SizedBox(height: 128),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllMenu(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final pendingUsers = _pendingUserCount(context.read<UserProvider>());

    void go(Widget screen) {
      Navigator.pop(context);
      onOpen(screen);
    }

    void tab(int index) {
      Navigator.pop(context);
      onSelectTab(index);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                "Semua Menu",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
            ),
            const _MenuGroupTitle("Penjualan"),
            _MenuTile(
              icon: DuoIcons.history,
              label: "Riwayat Transaksi",
              onTap: () => tab(3),
            ),
            if (isAdmin)
              _MenuTile(
                icon: DuoIcons.chart,
                label: "Laporan Penjualan",
                onTap: () => go(DailySalesScreen()),
              ),
            _MenuTile(
              icon: DuoIcons.users,
              label: "Pelanggan",
              onTap: () => go(const CustomersListScreen()),
            ),
            _MenuTile(
              icon: DuoIcons.wallet,
              label: "Hutang Pelanggan",
              onTap: () => go(const DebtsListScreen()),
            ),
            const _MenuGroupTitle("Barang & Stok"),
            _MenuTile(
              icon: DuoIcons.package,
              label: "Daftar Produk",
              onTap: () => tab(1),
            ),
            _MenuTile(
              icon: DuoIcons.scan,
              label: "Scan Cek Harga",
              onTap: () => go(const ScanScreen()),
            ),
            _MenuTile(
              icon: DuoIcons.category,
              label: "Kategori",
              onTap: () => go(const CategoriesListScreen()),
            ),
            _MenuTile(
              icon: DuoIcons.lowStock,
              label: "Stok Menipis",
              onTap: () => go(const LowStockReportScreen()),
            ),
            _MenuTile(
              icon: DuoIcons.stockRequest,
              label: "Permintaan Stok",
              onTap: () => go(const StockRequestScreen()),
            ),
            _MenuTile(
              icon: DuoIcons.opname,
              label: "Stock Opname",
              onTap: () => go(const StockOpnameListScreen()),
            ),
            const _MenuGroupTitle("Pembelian"),
            _MenuTile(
              icon: DuoIcons.supplier,
              label: "Supplier",
              onTap: () => go(const SuppliersListScreen()),
            ),
            if (isAdmin) ...[
              _MenuTile(
                icon: DuoIcons.purchase,
                label: "Pembelian Barang",
                onTap: () => go(const PurchasesScreen()),
              ),
              _MenuTile(
                icon: DuoIcons.import,
                label: "Import Barang (CSV)",
                onTap: () => go(const BulkImportScreen()),
              ),
            ],
            const _MenuGroupTitle("Akun & Aplikasi"),
            if (isAdmin)
              _MenuTile(
                icon: DuoIcons.userAdmin,
                label: "Kelola Pengguna",
                badge: pendingUsers > 0 ? "$pendingUsers baru" : null,
                onTap: () => go(const UsersListScreen()),
              ),
            _MenuTile(
              icon: DuoIcons.user,
              label: "Profil Saya",
              onTap: () => go(const ProfileScreen()),
            ),
            _MenuTile(
              icon: DuoIcons.settings,
              label: "Pengaturan & Printer",
              onTap: () => tab(4),
            ),
          ],
        ),
      ),
    );
  }
}

int _pendingUserCount(UserProvider users) => users.users
    .where((u) => u.role != 'admin' && u.role != 'staff')
    .length;

// ---------------------------------------------------------------------------
// Header: logo-navy block with today's sales in logo yellow
// ---------------------------------------------------------------------------

class _SalesHeader extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onOpenProfile;

  const _SalesHeader({required this.isAdmin, required this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final topInset = MediaQuery.of(context).padding.top;

    final userName = auth.userModel?.name ?? '';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    final dateText = DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now());

    final yesterdayKey = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
    final yesterdaySales = dashboard.weeklyRevenue[yesterdayKey]?.toInt();

    final onHeaderMuted = TextStyle(
      fontSize: 14,
      color: Colors.white.withValues(alpha: 0.78),
      fontFeatures: _tabular,
    );

    final isFirstLoad = dashboard.isLoading && dashboard.transactionCount == 0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 16, 12, 28),
      decoration: const BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Annur Motor",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName.isNotEmpty ? "$dateText · $userName" : dateText,
                      style: onHeaderMuted.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenProfile,
                tooltip: "Profil",
                iconSize: 44,
                icon: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.brandYellow,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text("Penjualan hari ini", style: onHeaderMuted),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                isFirstLoad ? "Rp —" : _rupiah.format(dashboard.totalSales),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandYellow,
                  height: 1.15,
                  fontFeatures: _tabular,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text("${dashboard.transactionCount} transaksi", style: onHeaderMuted),
              // Profit & comparisons are owner-only information
              if (isAdmin)
                Text(
                  "Laba ${_rupiah.format(dashboard.todayProfit)}",
                  style: onHeaderMuted,
                ),
              if (isAdmin && yesterdaySales != null)
                Text(
                  "Kemarin ${_rupiah.format(yesterdaySales)}",
                  style: onHeaderMuted,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions (Kasir lives in the bottom nav, so it is not repeated here)
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  final bool isAdmin;
  final ValueChanged<Widget> onOpen;
  final VoidCallback onShowAllMenu;

  const _QuickActions({
    required this.isAdmin,
    required this.onOpen,
    required this.onShowAllMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuickAction(
          icon: DuoIcons.scan,
          label: "Cek Harga",
          onTap: () => onOpen(const ScanScreen()),
        ),
        _QuickAction(
          icon: DuoIcons.users,
          label: "Pelanggan",
          onTap: () => onOpen(const CustomersListScreen()),
        ),
        isAdmin
            ? _QuickAction(
                icon: DuoIcons.chart,
                label: "Laporan",
                onTap: () => onOpen(DailySalesScreen()),
              )
            : _QuickAction(
                icon: DuoIcons.stockRequest,
                label: "Minta Stok",
                onTap: () => onOpen(const StockRequestScreen()),
              ),
        _QuickAction(
          icon: DuoIcons.grid,
          label: "Semua Menu",
          onTap: onShowAllMenu,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final DuoIcons icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              DuoIconTile(icon, size: 56),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Perlu perhatian" — only things that need action today
// ---------------------------------------------------------------------------

class _AttentionSection extends StatelessWidget {
  final bool isAdmin;
  final ValueChanged<Widget> onOpen;

  const _AttentionSection({required this.isAdmin, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ItemsProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final stockRequests = context.watch<StockRequestProvider>();
    final users = context.watch<UserProvider>();

    final lowStock = items.lowStockDisplayItems;
    final outOfStock = lowStock.where((i) => i.stockDisplay <= 0).length;
    final almostOut = lowStock.length - outOfStock;
    final pendingRequests = isAdmin ? stockRequests.pendingCount : 0;
    final pendingUsers = isAdmin ? _pendingUserCount(users) : 0;
    final unpaidDebt = isAdmin ? dashboard.totalUnpaidDebt : 0;

    final rows = <Widget>[
      if (lowStock.isNotEmpty)
        _AttentionRow(
          icon: LucideIcons.triangleAlert,
          color: outOfStock > 0 ? AppColors.destructive : AppColors.warning,
          title: "${lowStock.length} barang stok menipis",
          subtitle: [
            if (outOfStock > 0) "$outOfStock habis",
            if (almostOut > 0) "$almostOut sisa ≤ 5",
          ].join(" · "),
          onTap: () => onOpen(const LowStockReportScreen()),
        ),
      if (pendingRequests > 0)
        _AttentionRow(
          icon: LucideIcons.packagePlus,
          color: AppColors.primary,
          title: "$pendingRequests permintaan stok",
          subtitle: "Menunggu persetujuan Anda",
          onTap: () => onOpen(const StockRequestScreen()),
        ),
      if (pendingUsers > 0)
        _AttentionRow(
          icon: LucideIcons.shieldCheck,
          color: AppColors.primary,
          title: "$pendingUsers akun baru",
          subtitle: "Setujui agar bisa memakai aplikasi",
          onTap: () => onOpen(const UsersListScreen()),
        ),
      if (unpaidDebt > 0)
        _AttentionRow(
          icon: LucideIcons.wallet,
          color: AppColors.warning,
          title: "Piutang belum lunas",
          subtitle: _rupiah.format(unpaidDebt),
          onTap: () => onOpen(const DebtsListScreen()),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle("Perlu perhatian"),
        const SizedBox(height: 12),
        _Panel(
          children: rows.isNotEmpty
              ? rows
              : const [
                  _AttentionRow(
                    icon: LucideIcons.circleCheck,
                    color: AppColors.success,
                    title: "Semua aman",
                    subtitle: "Tidak ada stok menipis atau yang perlu disetujui",
                  ),
                ],
        ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _AttentionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: AppColors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent transactions (live, last 5 from the past 7 days)
// ---------------------------------------------------------------------------

class _RecentTransactions extends StatelessWidget {
  final VoidCallback onSeeAll;

  const _RecentTransactions({required this.onSeeAll});

  static String _paymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
      case 'tunai':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      case 'debt':
      case 'hutang':
      case 'credit':
        return 'Hutang';
      default:
        return method.isEmpty
            ? '-'
            : method[0].toUpperCase() + method.substring(1);
    }
  }

  static String _timeLabel(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    return isToday
        ? DateFormat('HH:mm').format(date)
        : DateFormat('d MMM', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final recent = dashboard.recentTransactions;

    Widget content;
    if (dashboard.isLoading && recent.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    } else if (recent.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(LucideIcons.receipt, size: 28, color: AppColors.mutedForeground),
            SizedBox(height: 8),
            Text(
              "Belum ada transaksi minggu ini",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Tekan tombol Kasir di bawah untuk mulai berjualan.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        children: [
          for (final tx in recent)
            _TransactionRow(
              time: _timeLabel(tx['date'] as DateTime),
              customer: (tx['customerName'] as String?)?.isNotEmpty == true
                  ? tx['customerName'] as String
                  : 'Pelanggan Umum',
              detail:
                  "${tx['itemsCount']} barang · ${_paymentLabel(tx['paymentMethod']?.toString() ?? '')}",
              amount: _rupiah.format(tx['totalAmount'] as int),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle("Transaksi terakhir")),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text(
                "Lihat semua",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _Panel(children: [content]),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String time;
  final String customer;
  final String detail;
  final String amount;

  const _TransactionRow({
    required this.time,
    required this.customer,
    required this.detail,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
                fontFeatures: _tabular,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
    );
  }
}

/// White card with hairline border; children are separated by dividers.
class _Panel extends StatelessWidget {
  final List<Widget> children;

  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.muted,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuGroupTitle extends StatelessWidget {
  final String text;

  const _MenuGroupTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final DuoIcons icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 52,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: DuoIconTile(icon, size: 40),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
      ),
      trailing: badge == null
          ? const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.mutedForeground,
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}

// ===========================================================================
// FLOATING BOTTOM NAV
// ===========================================================================

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _BottomNav({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: LucideIcons.house,
                label: "Beranda",
                selected: selectedIndex == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: LucideIcons.package,
                label: "Produk",
                selected: selectedIndex == 1,
                onTap: () => onSelect(1),
              ),
              _KasirNavItem(
                selected: selectedIndex == 2,
                onTap: () => onSelect(2),
              ),
              _NavItem(
                icon: LucideIcons.history,
                label: "Riwayat",
                selected: selectedIndex == 3,
                onTap: () => onSelect(3),
              ),
              _NavItem(
                icon: LucideIcons.settings,
                label: "Setelan",
                selected: selectedIndex == 4,
                onTap: () => onSelect(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.mutedForeground;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The primary action of the app: logo navy + yellow, matching the Beranda header.
class _KasirNavItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _KasirNavItem({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: "Kasir",
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandNavy.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.shoppingCart,
                    size: 20,
                    color: AppColors.brandYellow,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kasir",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
