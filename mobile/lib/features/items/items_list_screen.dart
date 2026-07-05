import 'package:flutter/material.dart';
import '../../ui/desktop_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../ui/input.dart';
import 'items_provider.dart';
import 'item_form_screen.dart';
import 'item_detail_screen.dart';
import 'bulk_import_screen.dart';
import '../../core/services/export_service.dart';
import '../auth/auth_provider.dart';

class ItemsListScreen extends StatefulWidget {
  final String? initialQuery;
  final bool showBackButton;

  const ItemsListScreen({
    Key? key,
    this.initialQuery,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? "";
    _searchQuery = (widget.initialQuery ?? "").toLowerCase();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleExport(
    BuildContext context,
    ItemsProvider provider,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menyiapkan data eksport...")),
      );

      final items = provider.items;
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada data barang untuk diexport")),
        );
        return;
      }

      final csvData = items.map((item) {
        // Prefix code with = to force Excel to treat as text (preserves leading zeros)
        final formattedCode = '="${item.code}"';
        return [
          formattedCode,
          item.name,
          item.buyPrice,
          item.sellPrice,
          item.priceWorkshop,
          item.stockDisplay, // was stock, better use stockDisplay for clarity or stock getter
          item.stockWarehouse, // Fixed from qtyWarehouse
          item.tags.join(','),
          item.category,
          item.locationDisplay ?? '',
          item.locationWarehouse ?? '',
          item.description ?? '', // Added Description
        ];
      }).toList();

      final headers = [
        "KODE",
        "NAMA BARANG",
        "HARGA BELI",
        "HARGA JUAL (UMUM)",
        "HARGA JUAL (BENGKEL)",
        "STOK TOKO",
        "STOK GUDANG",
        "TAGS",
        "KATEGORI",
        "LOKASI TOKO",
        "LOKASI GUDANG",
        "DESKRIPSI", // Added Header
      ];

      final fileName =
          "Data_Barang_MekanikHub_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv";

      await ExportService.exportToCSV(
        headers: headers,
        data: csvData,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil export data barang."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: Items are fetched in initState/PostFrameCallback or handled by provider.
    final provider = Provider.of<ItemsProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.items.isEmpty) provider.fetchItems();
    });

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final fab = FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ItemFormScreen()),
        );
      },
      backgroundColor: AppColors.primary,
      child: const Icon(LucideIcons.plus, color: Colors.white),
    );

    // Desktop Layout
    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/items',
        floatingActionButton: fab, // Pass FAB to desktop scaffold
        body: _buildListBody(context, provider, currencyFormat, true),
      );
    }

    // Mobile Layout
    return Scaffold(
      drawer: null,
      floatingActionButton: fab,
      backgroundColor: AppColors.background,
      body: _buildListBody(context, provider, currencyFormat, false),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    ItemsProvider provider,
    NumberFormat currencyFormat,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Force Desktop (Grid) if DesktopScaffold says so or width > 900
        // But here we rely on the passed isDesktop param mostly,
        // though the constraints are valid too.
        final forceGrid = isDesktop || constraints.maxWidth > 900;

        return Consumer<ItemsProvider>(
          builder: (context, provider, child) {
            final filteredItems =
                provider.items.where((item) {
                    final matchesTag = item.tags.any(
                      (tag) => tag.toLowerCase().contains(_searchQuery),
                    );
                    return item.name.toLowerCase().contains(_searchQuery) ||
                        item.code.toLowerCase().contains(_searchQuery) ||
                        matchesTag;
                  }).toList()
                  // Sort by category first, then by name within category
                  ..sort((a, b) {
                    final categoryCompare = (a.category ?? '').compareTo(
                      b.category ?? '',
                    );
                    if (categoryCompare != 0) return categoryCompare;
                    return a.name.compareTo(b.name);
                  });

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  snap: false,
                  title: const Text("Manajemen Barang"),
                  actions: [
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw),
                      tooltip: "Refresh Data",
                      onPressed: () {
                        provider.fetchItems();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Memperbarui data barang...'),
                          ),
                        );
                      },
                    ),
                    if (Provider.of<AuthProvider>(context).isAdmin) ...[
                      IconButton(
                        icon: const Icon(LucideIcons.download),
                        tooltip: "Export Data (Excel)",
                        onPressed: () => _handleExport(context, provider),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.fileInput),
                        tooltip: "Import CSV",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BulkImportScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(80),
                    child: Container(
                      color: AppColors.surface, // Match AppBar bg
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: CustomInput(
                        placeholder: "Cari Nama / Kode Barang...",
                        controller: _searchController,
                        suffixIcon: const Icon(LucideIcons.search, size: 20),
                      ),
                    ),
                  ),
                ),

                // Total Items Count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      "${filteredItems.length} barang${_searchQuery.isNotEmpty ? ' ditemukan' : ''}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),

                if (provider.isLoading && provider.items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredItems.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.packageOpen,
                            size: 64,
                            color: AppColors.mutedForeground,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Tidak ada barang ditemukan",
                            style: TextStyle(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (forceGrid) // Use forceGrid here
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent:
                                130, // Use fixed height instead of aspect ratio
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = filteredItems[index];
                        return _buildItemCard(context, item, currencyFormat);
                      }, childCount: filteredItems.length),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = filteredItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: _buildItemCard(context, item, currencyFormat),
                        );
                      }, childCount: filteredItems.length),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    dynamic item,
    NumberFormat currencyFormat,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Image Thumbnail
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              LucideIcons.imageOff,
                              size: 16,
                              color: AppColors.mutedForeground,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          LucideIcons.package,
                          color: AppColors.mutedForeground,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.code,
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.category != null && item.category!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildBadge(
                          label: "Stok: ${item.stock}",
                          color: item.stock <= 5 ? Colors.red : Colors.green,
                        ),
                        Text(
                          currencyFormat.format(item.sellPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
