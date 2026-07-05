import '../../ui/desktop_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Shortcuts
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';

import '../../ui/input.dart';

import 'pos_provider.dart';
import 'models/pos_models.dart';

import '../history/history_screen.dart';

import 'receipt_preview_screen.dart';
import 'cart_screen.dart'; // Import CartScreen
import '../scan/scan_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PosProvider>(context, listen: false).fetchData();
    });
  }

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(); // Added FocusNode

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final posProvider = Provider.of<PosProvider>(context);

    // Main Content
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 800;
        final isDesktop = constraints.maxWidth > 1200;

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.f2): () {
              // F2: Focus Search
              _searchFocusNode.requestFocus();
            },
            const SingleActivator(LogicalKeyboardKey.f4): () {
              // F4: Checkout
              if (posProvider.cart.isNotEmpty) {
                _handleCheckout(context, posProvider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Keranjang kosong")),
                );
              }
            },
            const SingleActivator(LogicalKeyboardKey.escape): () {
              // Esc: Clear Search & Unfocus
              _searchController.clear();
              posProvider.searchItems('');
              _searchFocusNode.unfocus();
            },
          },
          child: FocusScope(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("MekanikHub POS"),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.history),
                    tooltip: 'Riwayat Transaksi',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw),
                    tooltip: 'Refresh Data',
                    onPressed: () {
                      posProvider.fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Data diperbarui")),
                      );
                    },
                  ),
                  // Cart Icon: ONLY show on Mobile (when Panel is hidden)
                  if (!isTablet)
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.shoppingCart),
                          tooltip: 'Keranjang',
                          onPressed: () => _showCartModal(context),
                        ),
                        if (posProvider.totalItems > 0)
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${posProvider.totalItems}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(width: 8),
                ],
              ),
              drawer: null,
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Items (Expanded)
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        // Search & Categories
                        _buildHeader(posProvider),

                        // Item Grid
                        Expanded(
                          child: Selector<PosProvider, List<Item>>(
                            selector: (_, provider) => provider.filteredItems,
                            builder: (_, items, __) {
                              return posProvider.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : items.isEmpty
                                  ? const Center(
                                      child: Text("Barang tidak ditemukan"),
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        top: 16,
                                        bottom: 80,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: isDesktop
                                                ? 5
                                                : (isTablet ? 4 : 2),
                                            childAspectRatio: isDesktop
                                                ? 0.75
                                                : (isTablet ? 0.8 : 0.65),
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                          ),
                                      itemCount: items.length,
                                      itemBuilder: (context, index) {
                                        return _buildItemCard(
                                          items[index],
                                          posProvider,
                                        );
                                      },
                                    );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: Cart Panel (Only Desktop/Tablet)
                  if (isTablet)
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: _buildCartPanel(
                          context,
                          posProvider,
                          isTablet: true,
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

  Widget _buildHeader(PosProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomInput(
                    placeholder: "Cari Kode / Nama / Tags... (F2)",
                    controller: _searchController,
                    focusNode: _searchFocusNode, // Connect FocusNode
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(LucideIcons.x),
                            onPressed: () {
                              _searchController.clear();
                              provider.searchItems('');
                            },
                          ),
                        IconButton(
                          icon: const Icon(LucideIcons.scanLine),
                          tooltip: 'Scan Barcode',
                          onPressed: () async {
                            // Navigate to ScanScreen
                            final code = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ScanScreen(),
                              ),
                            );

                            if (code != null &&
                                code is String &&
                                context.mounted) {
                              // Auto-Add Logic
                              final exactItem = provider.findItemByCode(code);
                              if (exactItem != null) {
                                provider.addToCart(exactItem);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Ditambahkan: ${exactItem.name}",
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                                // Clear search to keep UI clean, as item is already in cart
                                _searchController.clear();
                                provider.searchItems('');
                              } else {
                                // Fallback to Search
                                setState(() {
                                  _searchController.text = code;
                                });
                                provider.searchItems(code);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Barang tidak ditemukan dalam database",
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    onChanged: (val) => provider.searchItems(val),
                  ),
                ),
                const SizedBox(width: 12),
                // Workshop Mode Toggle
                Column(
                  children: [
                    const Text(
                      "Mode Bengkel",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: provider.isWorkshopMode,
                      onChanged: (val) {
                        // Confirmation if cart not empty?
                        if (provider.cart.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Ubah Harga?"),
                              content: const Text(
                                "Mengubah mode akan mereset harga barang di keranjang.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Batal"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    provider.setWorkshopMode(val);
                                  },
                                  child: const Text("Ya, Ubah"),
                                ),
                              ],
                            ),
                          );
                        } else {
                          provider.setWorkshopMode(val);
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children:
                  (provider.categories.isEmpty
                          ? ["Semua"]
                          : provider.categories)
                      .map((cat) {
                        final isSelected = provider.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => provider.filterCategory(cat),
                            backgroundColor: AppColors.background,
                            selectedColor: AppColors.primary.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.foreground,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            checkmarkColor: AppColors.primary,
                          ),
                        );
                      })
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Item item, PosProvider provider) {
    // Traffic Light Logic
    final isDisplayAvailable = item.stockDisplay > 0;
    final isWarehouseAvailable = item.stockWarehouse > 0;
    final isOutOfStock = !isDisplayAvailable && !isWarehouseAvailable;

    // Price to show (Workshop vs Normal)
    final displayPrice = provider.isWorkshopMode && item.priceWorkshop > 0
        ? item.priceWorkshop
        : item.sellPrice;

    return GestureDetector(
      onTap: isOutOfStock
          ? null
          : () {
              if (!isDisplayAvailable && isWarehouseAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Stok Toko HABIS! Ambil dari GUDANG."),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.amber,
                  ),
                );
              }
              provider.addToCart(item);
            },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area (Smaller)
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade50,
                        child: Icon(
                          LucideIcons.image,
                          color: Colors.grey.shade300,
                          size: 32,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade50,
                      child: Icon(
                        LucideIcons.package,
                        color: Colors.grey.shade300,
                        size: 32,
                      ),
                    ),

                  // Out of Stock Overlay
                  if (isOutOfStock)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text(
                        "HABIS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                  // Stock Badge (Traffic Light Style)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDisplayAvailable
                            ? Colors.green.withOpacity(0.9)
                            : (isWarehouseAvailable
                                  ? Colors.amber.withOpacity(0.9)
                                  : Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDisplayAvailable
                            ? "Toko: ${item.stockDisplay}"
                            : (isWarehouseAvailable
                                  ? "Gudang: ${item.stockWarehouse}"
                                  : "0"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Workshop Badge
                  if (provider.isWorkshopMode && item.priceWorkshop > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          LucideIcons.wrench,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10), // Reduced padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category ?? '-',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: AppColors.foreground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Text(
                      currencyFormat.format(displayPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  Widget _buildCartPanel(
    BuildContext context,
    PosProvider provider, {
    bool isTablet = false,
    ScrollController? scrollController,
  }) {
    return Column(
      children: [
        // Receipt Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.receipt,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                "Rincian Pesanan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (provider.cart.isNotEmpty)
                TextButton.icon(
                  onPressed: () => provider.clearCart(),
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: const Text(
                    "Reset",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    backgroundColor: Colors.red.withOpacity(0.05),
                  ),
                ),
              if (!isTablet)
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),

        // Cart Items List
        Expanded(
          child: provider.cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.shoppingCart,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Keranjang Kosong",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Pilih barang dari menu\nuntuk menambahkan pesanan",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: provider.cart.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = provider.cart[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.foreground,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      currencyFormat.format(item.sellPrice),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (item.category != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        "•  ${item.category!}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Qty Controllers & Total
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(
                                  item.sellPrice * item.quantity,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        provider.updateQuantity(item.id, -1),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.minus,
                                        size: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      "${item.quantity}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        provider.updateQuantity(item.id, 1),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.plus,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Footer: Summary & Actions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean Transaction Details Block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Customer Row
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.user,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Pelanggan",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            // Logic to open customer selection if needed again
                            // For now relies on the list below or we can move the list here in a dialog
                          },
                          child: Row(
                            children: [
                              Text(
                                provider.selectedCustomer?.name ?? "Umum",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              // const Icon(LucideIcons.chevronDown, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    // Customer Chips List (Compact)
                    SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCustomerChip(
                            provider,
                            'umum',
                            'Umum',
                            compact: true,
                          ),
                          ...provider.customers.map(
                            (c) => _buildCustomerChip(
                              provider,
                              c.id,
                              c.name,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Payment Settings Block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceChip(
                            label: "Lunas",
                            isSelected: !provider.isDebt,
                            onSelected: () => provider.setDebt(false),
                            color: Colors.green,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildChoiceChip(
                            label: "Hutang",
                            isSelected: provider.isDebt,
                            onSelected: () => provider.setDebt(true),
                            color: Colors.red,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    if (!provider.isDebt) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceChip(
                              label: "Tunai",
                              isSelected: provider.paymentType == 'cash',
                              onSelected: () => provider.setPaymentType('cash'),
                              color: AppColors.primary,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildChoiceChip(
                              label: "Transfer",
                              isSelected: provider.paymentType == 'transfer',
                              onSelected: () =>
                                  provider.setPaymentType('transfer'),
                              color: Colors.purple,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Total Tagihan",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${provider.totalItems} Barang",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        currencyFormat.format(provider.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Checkout Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: provider.cart.isEmpty
                      ? null
                      : () => _handleCheckout(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: provider.cart.isEmpty ? 0 : 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCircle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Proses Pembayaran (F4)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: provider.cart.isEmpty
                              ? Colors.grey.shade500
                              : Colors.white,
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
    );
  }

  Widget _buildCustomerChip(
    PosProvider provider,
    String id,
    String label, {
    bool compact = false,
  }) {
    final isSelected =
        (id == 'umum' && provider.selectedCustomer == null) ||
        (provider.selectedCustomer?.id == id);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          if (id == 'umum') {
            provider.setCustomer('umum');
          } else {
            provider.setCustomer(id);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: compact ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: compact ? 11 : 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color color,
    bool compact = false,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckout(
    BuildContext context,
    PosProvider provider,
  ) async {
    // 1. Calculate Draft (No DB Write)
    final draftData = provider.calculateTransactionSummary();

    if (draftData != null && context.mounted) {
      // 2. Navigate to Preview (Confirmation)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPreviewScreen(
            transactionData: draftData,
            isDraft: true, // Enable Confirmation Mode
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaksi kosong atau gagal")),
      );
    }
  }
}
