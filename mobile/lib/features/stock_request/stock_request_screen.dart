import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../ui/desktop_scaffold.dart';
import '../auth/auth_provider.dart';
import '../items/items_provider.dart';
import 'stock_request_model.dart';
import 'stock_request_provider.dart';

class StockRequestScreen extends StatefulWidget {
  const StockRequestScreen({super.key});

  @override
  State<StockRequestScreen> createState() => _StockRequestScreenState();
}

class _StockRequestScreenState extends State<StockRequestScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StockRequestProvider>(context, listen: false).fetchRequests();
      Provider.of<ItemsProvider>(context, listen: false).fetchItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockRequestProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final itemsProvider = Provider.of<ItemsProvider>(context);
    final isAdmin = authProvider.isAdmin;

    // Get low stock items for Staff, filtered by search
    List<dynamic> lowStockItems = itemsProvider.lowStockDisplayItems;
    if (_searchQuery.isNotEmpty) {
      lowStockItems = lowStockItems
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.code.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Sort: Low stock first (1-5), then out of stock (0), then by category, then by name
    lowStockItems.sort((a, b) {
      // First: items with low stock (1-5) come before out of stock (0)
      final aIsLow = a.stockDisplay > 0 && a.stockDisplay <= 5;
      final bIsLow = b.stockDisplay > 0 && b.stockDisplay <= 5;
      if (aIsLow && !bIsLow) return -1;
      if (!aIsLow && bIsLow) return 1;

      // Second: sort by category
      final categoryCompare = (a.category ?? 'Umum').compareTo(
        b.category ?? 'Umum',
      );
      if (categoryCompare != 0) return categoryCompare;

      // Third: sort by name
      return a.name.compareTo(b.name);
    });

    return DesktopScaffold(
      activeRoute: '/stock-request',
      title: "Permintaan Stok",
      // No FAB for staff, admin doesn't need it either
      floatingActionButton: null,
      body: isAdmin
          ? _buildAdminView(provider)
          : _buildStaffView(itemsProvider, lowStockItems, provider),
    );
  }

  // --- STAFF VIEW ---
  Widget _buildStaffView(
    ItemsProvider itemsProvider,
    List<dynamic> lowStockItems,
    StockRequestProvider requestProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Cari barang menipis...",
                prefixIcon: Icon(LucideIcons.search, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Barang Perlu Restock",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${lowStockItems.length} item",
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Item List (Vertical)
          Expanded(
            child: itemsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : lowStockItems.isEmpty
                ? _buildNoLowStockState()
                : ListView.separated(
                    itemCount: lowStockItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = lowStockItems[index];
                      return _buildLowStockListTile(context, item);
                    },
                  ),
          ),

          // My Request History (Collapsible)
          const Divider(height: 32),
          ExpansionTile(
            initiallyExpanded: false,
            title: Row(
              children: [
                const Icon(LucideIcons.history, size: 18),
                const SizedBox(width: 8),
                const Text("Riwayat Permintaan Saya"),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${requestProvider.requests.length}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            children: requestProvider.requests.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "Belum ada permintaan",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ]
                : requestProvider.requests.take(5).map((req) {
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        req.status == 'approved'
                            ? LucideIcons.checkCircle
                            : req.status == 'rejected'
                            ? LucideIcons.xCircle
                            : LucideIcons.clock,
                        color: req.status == 'approved'
                            ? Colors.green
                            : req.status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                        size: 18,
                      ),
                      title: Text(
                        req.itemName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        "${req.requestQty} pcs • ${DateFormat('dd MMM').format(req.createdAt)}",
                      ),
                      trailing: Text(
                        req.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: req.status == 'approved'
                              ? Colors.green
                              : req.status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ],
      ),
    );
  }

  // --- LOW STOCK LIST TILE (Vertical) ---
  Widget _buildLowStockListTile(BuildContext context, dynamic item) {
    final isOutOfStock = item.stockDisplay <= 0;
    final hasWarehouseStock = item.stockWarehouse > 0;

    return InkWell(
      onTap: hasWarehouseStock
          ? () => _showQuickRequestDialog(context, item)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutOfStock ? Colors.red[200]! : Colors.orange[200]!,
          ),
        ),
        child: Row(
          children: [
            // Status Badge
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isOutOfStock ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  isOutOfStock ? "HABIS" : "LOW",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Item Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Toko: ${item.stockDisplay} • Gudang: ${item.stockWarehouse}",
                    style: TextStyle(
                      fontSize: 11,
                      color: hasWarehouseStock
                          ? Colors.grey[600]
                          : Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),

            // Action Icon
            const SizedBox(width: 8),
            if (hasWarehouseStock)
              Icon(LucideIcons.chevronRight, size: 20, color: AppColors.primary)
            else
              Icon(LucideIcons.ban, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLowStockState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.packageCheck, size: 64, color: Colors.green[200]),
          const SizedBox(height: 16),
          const Text(
            "Semua stok toko aman! 👍",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- ADMIN VIEW ---
  Widget _buildAdminView(StockRequestProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daftar Permintaan Masuk",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.requests.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: provider.requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = provider.requests[index];
                      return _buildRequestCard(
                        context,
                        request,
                        true,
                        provider,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- QUICK REQUEST DIALOG ---
  void _showQuickRequestDialog(BuildContext context, dynamic item) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Request: ${item.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Stok Gudang tersedia: ${item.stockWarehouse}"),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Jumlah Request",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Jumlah tidak valid!")),
                );
                return;
              }
              if (qty > item.stockWarehouse) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Melebihi stok gudang!")),
                );
                return;
              }

              Navigator.pop(ctx);

              final provider = Provider.of<StockRequestProvider>(
                context,
                listen: false,
              );
              final success = await provider.createRequest(
                itemId: item.id,
                itemName: item.name,
                quantity: qty,
              );

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Request berhasil dikirim!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Kirim Request"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.packageOpen, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Belum ada permintaan stok",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    StockRequest request,
    bool isAdmin,
    StockRequestProvider provider,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = LucideIcons.xCircle;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon / Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(LucideIcons.package, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Jumlah: ${request.requestQty} items",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${request.requesterName} • ${DateFormat('dd MMM HH:mm').format(request.createdAt)}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        request.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin && request.status == 'pending') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.red),
                        onPressed: () =>
                            _handleRejection(context, provider, request),
                        tooltip: "Tolak",
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.check,
                          color: Colors.green,
                        ),
                        onPressed: () =>
                            _handleApproval(context, provider, request),
                        tooltip: "Setujui",
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleApproval(
    BuildContext context,
    StockRequestProvider provider,
    StockRequest request,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Setujui Permintaan?"),
        content: Text(
          "Stok Gudang akan dikurangi ${request.requestQty} dan ditambahkan ke Display.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Setujui"),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await provider.approveRequest(request);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Permintaan disetujui! Stok berhasil dipindahkan."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Gagal: ${e.toString().replaceAll('Exception:', '')}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleRejection(
    BuildContext context,
    StockRequestProvider provider,
    StockRequest request,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tolak Permintaan?"),
        content: const Text("Permintaan akan ditandai sebagai ditolak."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Tolak"),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await provider.rejectRequest(request);
    }
  }
}
