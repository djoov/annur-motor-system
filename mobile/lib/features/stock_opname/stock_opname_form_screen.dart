import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/button.dart';
import '../../ui/input.dart';
import '../pos/models/pos_models.dart';
import '../pos/pos_provider.dart'; // Reuse PosProvider to search items
import '../auth/auth_provider.dart';
import 'stock_opname_provider.dart';
import '../scan/scan_screen.dart';

class StockOpnameFormScreen extends StatefulWidget {
  const StockOpnameFormScreen({super.key});

  @override
  State<StockOpnameFormScreen> createState() => _StockOpnameFormScreenState();
}

class _StockOpnameFormScreenState extends State<StockOpnameFormScreen> {
  final _searchController = TextEditingController();
  final _actualStockController = TextEditingController();
  final _noteController = TextEditingController(); // Opname-level note

  Item? _selectedItem;

  void _onItemSelect(Item item) {
    setState(() {
      _selectedItem = item;
      _searchController.clear();
      _actualStockController.text =
          '${item.stockDisplay}'; // Default to system stock
    });
    // Show input dialog
    _showInputSheet();
  }

  void _showInputSheet() {
    if (_selectedItem == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Input Stok Fisik: ${_selectedItem!.name}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _actualStockController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Jumlah Fisik (Real)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Stok Sistem: ${_selectedItem!.stockDisplay}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: "Simpan",
              onPressed: () {
                final actual = int.tryParse(_actualStockController.text) ?? 0;
                Provider.of<StockOpnameProvider>(
                  context,
                  listen: false,
                ).addItemToOpname(
                  _selectedItem!.id,
                  _selectedItem!.name,
                  _selectedItem!.stockDisplay,
                  actual,
                  null, // Item note (optional, skip for speed)
                );
                Navigator.pop(context);
                setState(() => _selectedItem = null);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opnameProvider = Provider.of<StockOpnameProvider>(context);
    final posProvider = Provider.of<PosProvider>(context); // Use for searching
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Audit Stok Baru")),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomInput(
              placeholder: "Cari Barang / Scan Barcode...",
              controller: _searchController,
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.scanLine),
                onPressed: () async {
                  final code = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  );

                  if (code != null && code is String) {
                    setState(() {
                      _searchController.text = code;
                    });
                    posProvider.searchItems(code);
                  }
                },
              ),
              onChanged: (val) {
                posProvider.searchItems(val);
              },
            ),
          ),

          // 2. Search Results (if typing) OR Active List
          Expanded(
            child: _searchController.text.isNotEmpty
                ? ListView.builder(
                    itemCount: posProvider.filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = posProvider.filteredItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text("Stok: ${item.stockDisplay}"),
                        onTap: () => _onItemSelect(item),
                      );
                    },
                  )
                : Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Daftar Hitungan Sementara",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: opnameProvider.activeItems.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = opnameProvider.activeItems[index];
                            final diff = item.difference;
                            return ListTile(
                              title: Text(item.itemName),
                              subtitle: Text(
                                "Sistem: ${item.systemStock} -> Fisik: ${item.actualStock}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${diff > 0 ? '+' : ''}$diff",
                                    style: TextStyle(
                                      color: diff == 0
                                          ? Colors.green
                                          : Colors
                                                .red, // 0 is good, diff is bad
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    onPressed: () =>
                                        opnameProvider.removeItem(item.itemId),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),

          // 3. Footer Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: "Catatan Audit",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "Selesai & Finalisasi",
                  isLoading: opnameProvider.isLoading,
                  icon: LucideIcons.checkCircle,
                  onPressed: opnameProvider.activeItems.isEmpty
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Finalisasi Audit?"),
                              content: const Text(
                                "Stok di sistem akan diperbarui secara otomatis sesuai dengan hitungan fisik. Tindakan ini tidak dapat dibatalkan.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Batal"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Ya, Sesuaikan Stok"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await opnameProvider.finalizeOpname(
                                authProvider.user?.uid ?? 'unknown',
                                authProvider.user?.displayName ?? 'Staff',
                                _noteController.text,
                              );
                              if (context.mounted) {
                                Navigator.pop(context); // Back to list
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Audit berhasil disimpan & stok diperbarui.",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Gagal: $e")),
                                );
                              }
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
