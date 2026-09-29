import '../../ui/desktop_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Shortcuts
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/bottom_nav_metrics.dart';

import 'pos_provider.dart';
import 'models/pos_models.dart';
import 'widgets/pos_widgets.dart';

import 'receipt_preview_screen.dart';
import 'cart_screen.dart';
import '../scan/scan_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch(PosProvider provider) {
    _searchController.clear();
    provider.searchItems('');
    setState(() {});
  }

  Future<void> _scanBarcode(PosProvider provider) async {
    final code = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanScreen(returnCodeOnly: true),
      ),
    );
    if (code is! String || !mounted) return;

    final exactItem = provider.findItemByCode(code);
    if (exactItem != null) {
      posAddToCart(context, provider, exactItem);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text("Ditambahkan: ${exactItem.name}"),
            duration: const Duration(seconds: 1),
          ),
        );
      _clearSearch(provider);
    } else {
      setState(() => _searchController.text = code);
      provider.searchItems(code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kode $code tidak ada di daftar barang"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final posProvider = context.watch<PosProvider>();

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 800;
        final isDesktop = constraints.maxWidth > 1200;
        final showCartBar = !isTablet && posProvider.cart.isNotEmpty;
        final navTop = BottomNavMetrics.top(context);

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.f2): () =>
                _searchFocusNode.requestFocus(),
            const SingleActivator(LogicalKeyboardKey.f4): () {
              if (posProvider.cart.isNotEmpty) {
                _handleCheckout(context, posProvider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Keranjang masih kosong")),
                );
              }
            },
            const SingleActivator(LogicalKeyboardKey.escape): () {
              _clearSearch(posProvider);
              _searchFocusNode.unfocus();
            },
          },
          child: FocusScope(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(title: const Text("Kasir")),
              body: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            _buildSearchHeader(posProvider, isTablet),
                            Expanded(
                              child: _buildItemGrid(
                                posProvider,
                                crossAxisCount:
                                    isDesktop ? 5 : (isTablet ? 4 : 2),
                                bottomPadding: isTablet
                                    ? 24
                                    : navTop + (showCartBar ? 84 : 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isTablet)
                        SizedBox(
                          width: constraints.maxWidth > 1100 ? 400 : 340,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              border: Border(
                                left: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: _CartPanel(
                              provider: posProvider,
                              onCheckout: () =>
                                  _handleCheckout(context, posProvider),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showCartBar)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: navTop + 10,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: CartSummaryBar(
                            itemCount: posProvider.totalItems,
                            total: posProvider.totalAmount,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(activeRoute: '/pos', body: content);
    }
    return content;
  }

  Widget _buildSearchHeader(PosProvider provider, bool isTablet) {
    final categories =
        provider.categories.isEmpty ? const ["Semua"] : provider.categories;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (val) {
                    provider.searchItems(val);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: isTablet
                        ? "Cari nama, kode, atau tag (F2)"
                        : "Cari nama, kode, atau tag",
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            tooltip: "Hapus pencarian",
                            onPressed: () => _clearSearch(provider),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton.filled(
                  onPressed: () => _scanBarcode(provider),
                  tooltip: "Scan barcode",
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(LucideIcons.scanLine,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                return ChoiceChip(
                  label: Text(cat),
                  selected: provider.selectedCategory == cat,
                  showCheckmark: false,
                  onSelected: (_) => provider.filterCategory(cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(
    PosProvider provider, {
    required int crossAxisCount,
    required double bottomPadding,
  }) {
    if (provider.isLoading && provider.filteredItems.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.filteredItems.isEmpty) {
      final searching = _searchController.text.isNotEmpty ||
          provider.selectedCategory != "Semua";
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
                searching ? "Barang tidak ditemukan" : "Belum ada barang",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                searching
                    ? "Coba kata lain atau scan barcode-nya."
                    : "Tambahkan barang di menu Produk.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
              if (searching) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    _clearSearch(provider);
                    provider.filterCategory("Semua");
                  },
                  child: const Text("Tampilkan semua barang"),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: 236,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.filteredItems.length,
      itemBuilder: (context, index) {
        final item = provider.filteredItems[index];
        return _ItemCard(
          item: item,
          inCart: provider.quantityInCart(item.id),
          onTap: () => posAddToCart(context, provider, item),
        );
      },
    );
  }

  Future<void> _handleCheckout(
    BuildContext context,
    PosProvider provider,
  ) async {
    if (provider.needsCustomerForDebt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih pelanggan untuk mencatat hutang")),
      );
      return;
    }

    final draftData = provider.calculateTransactionSummary();
    if (draftData != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPreviewScreen(
            transactionData: draftData,
            isDraft: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Keranjang masih kosong")),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Product card
// ---------------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  final Item item;
  final int inCart;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = item.stockDisplay <= 0;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    Widget placeholder() => Container(
          color: AppColors.muted,
          alignment: Alignment.center,
          child: const Icon(LucideIcons.package,
              size: 32, color: AppColors.mutedForeground),
        );

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: inCart > 0 ? AppColors.primary : AppColors.border,
          width: inCart > 0 ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => placeholder(),
                        )
                      : placeholder(),
                  if (isOut)
                    Container(color: Colors.white.withValues(alpha: 0.6)),
                  Positioned(left: 8, top: 8, child: StockBadge(item.stockDisplay)),
                  if (inCart > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 30, minHeight: 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brandNavy,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "$inCart",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandYellow,
                            fontFeatures: posTabular,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 38,
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isOut
                            ? AppColors.mutedForeground
                            : AppColors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    posRupiah.format(item.sellPrice),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                      fontFeatures: posTabular,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tablet / desktop cart panel
// ---------------------------------------------------------------------------

class _CartPanel extends StatelessWidget {
  final PosProvider provider;
  final VoidCallback onCheckout;

  const _CartPanel({required this.provider, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final cart = provider.cart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Pesanan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (cart.isNotEmpty)
                TextButton.icon(
                  onPressed: provider.clearCart,
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  label: const Text("Kosongkan"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.destructiveStrong,
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shoppingCart,
                            size: 40, color: AppColors.mutedForeground),
                        SizedBox(height: 12),
                        Text(
                          "Keranjang kosong",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Tap barang di kiri atau scan barcode.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final item in cart) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    posRupiah.format(
                                        item.sellPrice * item.quantity),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: posTabular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            QtyStepper(
                              quantity: item.quantity,
                              onMinus: () =>
                                  provider.updateQuantity(item.id, -1),
                              onPlus: () =>
                                  posAddToCart(context, provider, item),
                            ),
                          ],
                        ),
                      ),
                      const Divider(indent: 20, endIndent: 20),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: CrossSellStrip(provider: provider),
                    ),
                  ],
                ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomerPicker(provider: provider),
              const SizedBox(height: 12),
              PaymentMethodSelector(provider: provider),
              const SizedBox(height: 16),
              TotalRow(
                itemCount: provider.totalItems,
                total: provider.totalAmount,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: cart.isEmpty || provider.needsCustomerForDebt
                      ? null
                      : onCheckout,
                  icon: const Icon(LucideIcons.circleCheck, size: 20),
                  label: Text(
                    provider.isDebt ? "Catat Hutang (F4)" : "Bayar (F4)",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
