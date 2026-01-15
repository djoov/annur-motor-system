import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../ui/button.dart';
import '../../ui/input.dart';
import '../../core/theme.dart';
import '../suppliers/suppliers_provider.dart';
import '../items/items_provider.dart';
import 'purchases_provider.dart';
import 'purchase_model.dart';
import '../pos/models/pos_models.dart';

class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  String? _selectedSupplierId;
  String _selectedSupplierName = '';

  // List of items being purchased
  final List<PurchaseItem> _cart = [];

  // Temporary fields for adding item
  String? _selectedItemId;
  String _selectedItemName = '';
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SuppliersProvider>(context, listen: false).fetchSuppliers();
      Provider.of<ItemsProvider>(context, listen: false).fetchItems();
    });
  }

  void _addItem() {
    if (_selectedItemId == null ||
        _quantityController.text.isEmpty ||
        _buyPriceController.text.isEmpty)
      return;

    final qty = int.tryParse(_quantityController.text) ?? 0;
    final price = int.tryParse(_buyPriceController.text) ?? 0;

    if (qty > 0 && price > 0) {
      setState(() {
        _cart.add(
          PurchaseItem(
            itemId: _selectedItemId!,
            name: _selectedItemName,
            quantity: qty,
            buyPrice: price,
          ),
        );
        // Reset inputs
        _selectedItemId = null;
        _selectedItemName = '';
        _quantityController.clear();
        _buyPriceController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SuppliersProvider>(context);
    final itemProvider = Provider.of<ItemsProvider>(context);
    final purchaseProvider = Provider.of<PurchasesProvider>(context);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Input Pembelian")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Select Supplier
                  const Text(
                    "Pilih Supplier",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSupplierId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text("Pilih Supplier"),
                    items: supplierProvider.suppliers.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplierId = value;
                        _selectedSupplierName = supplierProvider.suppliers
                            .firstWhere((s) => s.id == value)
                            .name;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // 2. Add Items
                  const Text(
                    "Tambah Barang",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Item Selection
                  DropdownButtonFormField<String>(
                    value: _selectedItemId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text("Pilih Barang"),
                    items: itemProvider.items.map((i) {
                      return DropdownMenuItem(
                        value: i.id,
                        child: Text("${i.name} (Stok: ${i.stock})"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedItemId = value;
                        final item = itemProvider.items.firstWhere(
                          (i) => i.id == value,
                        );
                        _selectedItemName = item.name;
                        _buyPriceController.text = item.buyPrice
                            .toString(); // Default to current buy price
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: CustomInput(
                          placeholder: "Jumlah",
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomInput(
                          placeholder: "Harga Beli / Unit",
                          controller: _buyPriceController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: "Tambah ke Daftar",
                    onPressed: _addItem,
                    isOutline: true,
                  ),

                  // 3. Item List
                  if (_cart.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Daftar Barang Dibeli",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return Card(
                          elevation: 0,
                          color: AppColors.muted.withOpacity(0.5),
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${item.quantity} x ${currencyFormat.format(item.buyPrice)}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeItem(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Pembelian",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currencyFormat.format(
                          _cart.fold<int>(
                            0,
                            (sum, item) =>
                                sum + (item.quantity * item.buyPrice),
                          ),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: "Simpan Transaksi",
                    isLoading: purchaseProvider.isLoading,
                    onPressed: _cart.isEmpty || _selectedSupplierId == null
                        ? null
                        : () async {
                            final success = await purchaseProvider
                                .createPurchase(
                                  _selectedSupplierId!,
                                  _selectedSupplierName,
                                  _cart,
                                );
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Pembelian berhasil disimpan"),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
