import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../items/items_provider.dart';
import '../../ui/app_drawer.dart';
import '../../ui/desktop_scaffold.dart';

class LowStockReportScreen extends StatefulWidget {
  const LowStockReportScreen({super.key});

  @override
  State<LowStockReportScreen> createState() => _LowStockReportScreenState();
}

class _LowStockReportScreenState extends State<LowStockReportScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<ItemsProvider>(context, listen: false).fetchItems(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Desktop Layout
    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/report-stock',
        body: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text("Laporan Stok Menipis"),
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.foreground,
              bottom: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.mutedForeground,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: "Toko (Display)", icon: Icon(LucideIcons.store)),
                  Tab(
                    text: "Gudang (Warehouse)",
                    icon: Icon(LucideIcons.warehouse),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildStockList(isWarehouse: false),
                _buildStockList(isWarehouse: true),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Laporan Stok Menipis"),
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.foreground,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: "Toko (Display)", icon: Icon(LucideIcons.store)),
              Tab(
                text: "Gudang (Warehouse)",
                icon: Icon(LucideIcons.warehouse),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStockList(isWarehouse: false),
            _buildStockList(isWarehouse: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStockList({required bool isWarehouse}) {
    return Consumer<ItemsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = isWarehouse
            ? provider.lowStockWarehouseItems
            : provider.lowStockDisplayItems;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.checkCircle2,
                  size: 64,
                  color: AppColors.success.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  isWarehouse ? "Stok Gudang Aman" : "Stok Toko Aman",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tidak ada barang dengan stok <= 5",
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final currentStock = isWarehouse
                ? item.stockWarehouse
                : item.stockDisplay;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.input),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.alertTriangle, color: Colors.red),
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Kode: ${item.code}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(
                    "Sisa: $currentStock",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
