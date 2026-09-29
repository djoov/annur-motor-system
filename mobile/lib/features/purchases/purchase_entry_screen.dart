import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/app_list.dart';
import '../../ui/app_form.dart';
import '../../ui/stock_badge.dart';
import '../suppliers/suppliers_provider.dart';
import '../items/items_provider.dart';
import '../scan/scan_screen.dart';
import 'purchases_provider.dart';
import 'purchase_model.dart';
import '../pos/models/pos_models.dart';

const _tabular = [FontFeature.tabularFigures()];

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Record goods bought from a supplier; saving adds the quantities to stock.
class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({super.key});

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  final List<PurchaseItem> _cart = [];
  final _invoiceController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isSaving = false;

  int get _total => _cart.fold(0, (s, i) => s + i.quantity * i.buyPrice);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuppliersProvider>().fetchSuppliers();
      context.read<ItemsProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen(returnCodeOnly: true)),
    );
    if (code is! String || !mounted) return;
    final item = context.read<ItemsProvider>().findByCode(code);
    if (item != null) {
      _showAddSheet(item);
    } else {
      showErrorSnack(context, "Kode $code belum terdaftar. Tambahkan dulu di Produk.");
    }
  }

  void _showAddSheet(Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddItemSheet(
        item: item,
        onAdd: (qty, price) {
          setState(() {
            _cart.add(PurchaseItem(
              itemId: item.id,
              name: item.name,
              quantity: qty,
              buyPrice: price,
            ));
            _searchController.clear();
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedSupplierId == null) {
      showErrorSnack(context, "Pilih supplier dulu");
      return;
    }
    final provider = context.read<PurchasesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);
    final success = await provider.createPurchase(
      _invoiceController.text.trim().isEmpty
          ? "AUTO-${DateTime.now().millisecondsSinceEpoch}"
          : _invoiceController.text.trim(),
      _selectedSupplierId!,
      _selectedSupplierName,
      _cart,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Pembelian ${_rupiah.format(_total)} disimpan, stok bertambah",
          ),
        ),
      );
    } else {
      showErrorSnack(context, "Pembelian gagal disimpan. Coba lagi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SuppliersProvider>().suppliers;
    final items = context.watch<ItemsProvider>().items;
    final q = _searchController.text.trim().toLowerCase();
    final results = q.isEmpty
        ? const <Item>[]
        : items
            .where((i) =>
                i.name.toLowerCase().contains(q) ||
                i.code.toLowerCase().contains(q))
            .take(30)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Catat Pembelian")),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedSupplierId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Supplier",
                  prefixIcon: Icon(LucideIcons.truck, size: 20),
                ),
                hint: Text(suppliers.isEmpty
                    ? "Belum ada supplier — tambah di menu Supplier"
                    : "Pilih supplier"),
                items: [
                  for (final s in suppliers)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (value) => setState(() {
                  _selectedSupplierId = value;
                  _selectedSupplierName =
                      suppliers.firstWhere((s) => s.id == value).name;
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _invoiceController,
                decoration: const InputDecoration(
                  labelText: "Nomor faktur (opsional)",
                  prefixIcon: Icon(LucideIcons.receiptText, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Barang yang dibeli",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchController,
                      hint: "Cari barang",
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: IconButton.filled(
                      onPressed: _scan,
                      tooltip: "Scan barcode",
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(LucideIcons.scanLine, size: 24),
                    ),
                  ),
                ],
              ),
              if (q.isNotEmpty) ...[
                const SizedBox(height: 8),
                Material(
                  color: AppColors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: results.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "Barang tidak ditemukan.",
                            style: TextStyle(color: AppColors.mutedForeground),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < results.length; i++) ...[
                              if (i > 0)
                                const Divider(indent: 16, endIndent: 16),
                              ListTile(
                                title: Text(results[i].name),
                                subtitle: Text(results[i].code),
                                trailing: StockBadge(results[i].stockDisplay),
                                onTap: () => _showAddSheet(results[i]),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
              const SizedBox(height: 16),
              if (_cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Belum ada barang. Cari atau scan barang di atas.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                  ),
                )
              else
                Material(
                  color: AppColors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _cart.length; i++) ...[
                        if (i > 0) const Divider(indent: 16, endIndent: 16),
                        ListTile(
                          contentPadding:
                              const EdgeInsets.only(left: 16, right: 4),
                          title: Text(
                            _cart[i].name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            "${_cart[i].quantity} × ${_rupiah.format(_cart[i].buyPrice)}",
                            style: const TextStyle(fontFeatures: _tabular),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _rupiah.format(
                                    _cart[i].quantity * _cart[i].buyPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: _tabular,
                                ),
                              ),
                              IconButton(
                                tooltip: "Hapus",
                                icon: const Icon(LucideIcons.x, size: 18),
                                onPressed: () =>
                                    setState(() => _cart.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Total · ${_cart.length} barang",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
                Text(
                  _rupiah.format(_total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _cart.isEmpty || _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.save, size: 20),
                label: const Text("Simpan & Tambah Stok"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final Item item;
  final void Function(int qty, int price) onAdd;

  const _AddItemSheet({required this.item, required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _qtyController = TextEditingController();
  late final _priceController = TextEditingController(
    text: widget.item.buyPrice > 0 ? '${widget.item.buyPrice}' : '',
  );

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final price = int.tryParse(_priceController.text) ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.item.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "Stok sekarang ${widget.item.stockDisplay}",
            style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: "Jumlah",
                    suffixText: "pcs",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: "Harga beli / pcs",
                    prefixText: "Rp ",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: qty > 0 && price > 0
                  ? () {
                      widget.onAdd(qty, price);
                      Navigator.pop(context);
                    }
                  : null,
              child: Text(
                qty > 0 && price > 0
                    ? "Tambahkan · ${_rupiah.format(qty * price)}"
                    : "Isi jumlah dan harga",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
