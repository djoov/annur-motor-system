import 'package:flutter/material.dart';
import '../../ui/desktop_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../ui/bottom_nav_metrics.dart';
import '../../ui/stock_badge.dart';
import '../pos/models/pos_models.dart';
import 'items_provider.dart';
import 'item_form_screen.dart';
import 'item_detail_screen.dart';
import 'bulk_import_screen.dart';
import '../../core/services/export_service.dart';
import '../auth/auth_provider.dart';

enum _StockFilter { all, low, out }

class ItemsListScreen extends StatefulWidget {
  final String? initialQuery;
  final bool showBackButton;

  const ItemsListScreen({
    super.key,
    this.initialQuery,
    this.showBackButton = true,
  });

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  _StockFilter _filter = _StockFilter.all;

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ItemsProvider>();
      if (provider.items.isEmpty) provider.fetchItems();
    });

    _searchController.text = widget.initialQuery ?? "";
    _searchQuery = (widget.initialQuery ?? "").toLowerCase();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ItemFormScreen()),
    );
  }

  Future<void> _handleExport(ItemsProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final items = provider.items;
      if (items.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Belum ada barang untuk diekspor")),
        );
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text("Menyiapkan file CSV...")),
      );

      final csvData = items.map((item) {
        return [
          '="${item.code}"',
          item.name,
          item.buyPrice,
          item.sellPrice,
          item.stockDisplay,
          item.tags.join(','),
          item.category ?? 'Umum',
          item.locationDisplay ?? '',
          item.description ?? '',
        ];
      }).toList();

      const headers = [
        "KODE",
        "NAMA BARANG",
        "HARGA BELI",
        "HARGA JUAL",
        "STOK",
        "TAGS",
        "KATEGORI",
        "LOKASI",
        "DESKRIPSI",
      ];

      final fileName =
          "Data_Barang_Annur_App_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv";

      await ExportService.exportToCSV(
        headers: headers,
        data: csvData,
        fileName: fileName,
      );

      messenger.showSnackBar(
        SnackBar(content: Text("${items.length} barang berhasil diekspor")),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Gagal ekspor: $e"),
          backgroundColor: AppColors.destructiveStrong,
        ),
      );
    }
  }

  List<Item> _visibleItems(List<Item> items) {
    final list = items.where((item) {
      final q = _searchQuery;
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.code.toLowerCase().contains(q) ||
          item.tags.any((tag) => tag.toLowerCase().contains(q));
      final matchesStock = switch (_filter) {
        _StockFilter.all => true,
        _StockFilter.low =>
          item.stockDisplay > 0 && item.stockDisplay <= kLowStockThreshold,
        _StockFilter.out => item.stockDisplay <= 0,
      };
      return matchesSearch && matchesStock;
    }).toList()
      ..sort((a, b) {
        final byCategory = (a.category ?? '').compareTo(b.category ?? '');
        return byCategory != 0 ? byCategory : a.name.compareTo(b.name);
      });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isTab = !widget.showBackButton;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final fab = Padding(
      // Keep the button above HomeScreen's floating nav when shown as a tab.
      padding: EdgeInsets.only(
        bottom: isTab && !DesktopScaffold.isDesktop
            ? BottomNavMetrics.height + 8
            : 0,
      ),
      child: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(LucideIcons.plus),
        label: const Text("Tambah Barang"),
      ),
    );

    final body = _buildListBody(context, isAdmin);

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/items',
        floatingActionButton: fab,
        body: body,
      );
    }

    return Scaffold(floatingActionButton: fab, body: body);
  }

  Widget _buildListBody(BuildContext context, bool isAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = DesktopScaffold.isDesktop || constraints.maxWidth > 900;
        final bottomSpace = widget.showBackButton
            ? 96.0
            : BottomNavMetrics.top(context) + 88;

        return Consumer<ItemsProvider>(
          builder: (context, provider, _) {
            final items = _visibleItems(provider.items);
            final lowCount = provider.items
                .where((i) =>
                    i.stockDisplay > 0 && i.stockDisplay <= kLowStockThreshold)
                .length;
            final outCount =
                provider.items.where((i) => i.stockDisplay <= 0).length;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: widget.showBackButton,
                  title: const Text("Produk"),
                  actions: [
                    if (isAdmin)
                      PopupMenuButton<String>(
                        tooltip: "Lainnya",
                        icon: const Icon(LucideIcons.ellipsisVertical),
                        onSelected: (v) {
                          if (v == 'export') _handleExport(provider);
                          if (v == 'import') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BulkImportScreen(),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'import',
                            child: ListTile(
                              leading: Icon(LucideIcons.fileInput),
                              title: Text("Import dari CSV"),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'export',
                            child: ListTile(
                              leading: Icon(LucideIcons.download),
                              title: Text("Ekspor ke CSV"),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(124),
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: "Cari nama, kode, atau tag",
                              prefixIcon:
                                  const Icon(LucideIcons.search, size: 20),
                              suffixIcon: _searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: "Hapus pencarian",
                                      icon: const Icon(LucideIcons.x, size: 18),
                                      onPressed: _searchController.clear,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _filterChip(
                                    "Semua (${provider.items.length})",
                                    _StockFilter.all),
                                const SizedBox(width: 8),
                                _filterChip(
                                    "Menipis ($lowCount)", _StockFilter.low),
                                const SizedBox(width: 8),
                                _filterChip("Habis ($outCount)", _StockFilter.out),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (provider.isLoading && provider.items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyItems(
                      hasItems: provider.items.isNotEmpty,
                      onAdd: _openForm,
                      onReset: () {
                        _searchController.clear();
                        setState(() => _filter = _StockFilter.all);
                      },
                    ),
                  )
                else if (useGrid)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 88,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ItemRow(
                          item: items[index],
                          price: _rupiah.format(items[index].sellPrice),
                          bordered: true,
                        ),
                        childCount: items.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    // Lazily built rows inside one bordered white panel.
                    sliver: DecoratedSliver(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(indent: 84, endIndent: 16),
                        itemBuilder: (context, index) => _ItemRow(
                          item: items[index],
                          price: _rupiah.format(items[index].sellPrice),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: bottomSpace)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String label, _StockFilter value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Item item;
  final String price;
  final bool bordered;

  const _ItemRow({
    required this.item,
    required this.price,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final meta = [
      if (item.code.isNotEmpty) item.code,
      if (item.category != null && item.category!.isNotEmpty) item.category!,
    ].join(" · ");

    final row = InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: hasImage
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _Thumb(),
                      )
                    : const _Thumb(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                StockBadge(item.stockDisplay),
              ],
            ),
          ],
        ),
      ),
    );

    if (!bordered) return row;
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: row,
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.muted,
      alignment: Alignment.center,
      child: const Icon(LucideIcons.package,
          size: 22, color: AppColors.mutedForeground),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  final bool hasItems;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  const _EmptyItems({
    required this.hasItems,
    required this.onAdd,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.packageOpen,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            Text(
              hasItems ? "Barang tidak ditemukan" : "Belum ada barang",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              hasItems
                  ? "Coba kata lain atau ubah filter stok."
                  : "Tambahkan barang pertama untuk mulai berjualan.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            hasItems
                ? OutlinedButton(
                    onPressed: onReset,
                    child: const Text("Tampilkan semua"),
                  )
                : FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text("Tambah Barang"),
                  ),
          ],
        ),
      ),
    );
  }
}
