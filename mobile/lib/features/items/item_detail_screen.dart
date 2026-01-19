import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../pos/models/pos_models.dart';
import 'item_form_screen.dart';
import 'items_provider.dart';
import '../auth/auth_provider.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;

  const ItemDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Item _item;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _adjustStock(String location, int delta) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    final provider = Provider.of<ItemsProvider>(context, listen: false);
    final success = await provider.quickUpdateStock(_item.id, location, delta);

    if (success) {
      // Refresh item from provider
      final updatedItem = provider.items.firstWhere(
        (i) => i.id == _item.id,
        orElse: () => _item,
      );
      setState(() => _item = updatedItem);
    }

    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final item = _item;
    final isAdmin = Provider.of<AuthProvider>(context).isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Detail Produk"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemFormScreen(item: item),
                ),
              );
            },
            icon: const Icon(LucideIcons.pencil),
            tooltip: "Edit Barang",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Image
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.white,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        print("Image Error: $error");
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.imageOff,
                                size: 48,
                                color: AppColors.mutedForeground,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Gagal memuat gambar",
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        LucideIcons.package,
                        size: 64,
                        color: AppColors.mutedForeground,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & Code
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          item.code,
                          style: const TextStyle(
                            fontFamily: 'Monospace',
                            fontWeight: FontWeight.bold,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category ?? 'Umum',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Description
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    _buildSectionTitle("Deskripsi Produk"),
                    const SizedBox(height: 8),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],

                  // Pricing
                  _buildSectionTitle("Informasi Harga"),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    "Harga Umum",
                    currencyFormat.format(item.sellPrice),
                    isHighlight: true,
                  ),
                  _buildInfoRow(
                    "Harga Bengkel",
                    currencyFormat.format(item.priceWorkshop),
                  ),
                  // Only Admin can see buy price & margin
                  if (isAdmin) ...[
                    _buildInfoRow(
                      "Harga Beli (Modal)",
                      currencyFormat.format(item.buyPrice),
                    ),
                    // Profit calculation
                    if (item.sellPrice > item.buyPrice)
                      _buildInfoRow(
                        "Estimasi Margin",
                        currencyFormat.format(item.sellPrice - item.buyPrice) +
                            " (${((item.sellPrice - item.buyPrice) / item.buyPrice * 100).toStringAsFixed(1)}%)",
                        isHighlight: true,
                      ),
                  ],

                  const SizedBox(height: 24),

                  // Stock & Location
                  _buildSectionTitle("Stok & Lokasi"),
                  const SizedBox(height: 12),

                  // Display / Toko - with Quick Stock Buttons
                  _buildStockCard(
                    title: "Toko (Display)",
                    icon: LucideIcons.store,
                    iconColor: AppColors.primary,
                    stock: item.stockDisplay,
                    location: item.locationDisplay,
                    onMinus: () => _adjustStock('display', -1),
                    onPlus: () => _adjustStock('display', 1),
                  ),

                  // Warehouse / Gudang - with Quick Stock Buttons
                  _buildStockCard(
                    title: "Gudang",
                    icon: LucideIcons.warehouse,
                    iconColor: Colors.orange,
                    stock: item.stockWarehouse,
                    location: item.locationWarehouse,
                    onMinus: () => _adjustStock('warehouse', -1),
                    onPlus: () => _adjustStock('warehouse', 1),
                  ),

                  // Total Stock Summary
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.boxes, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text(
                              "Total Stok",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${item.stockDisplay + item.stockWarehouse} Unit",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tags Section
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Tags / Label"),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.foreground,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.mutedForeground)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isHighlight ? 16 : 14,
              color: isHighlight ? AppColors.primary : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required int stock,
    String? location,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                "$stock Unit",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: stock <= 5 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          if (location != null && location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 36),
                Text(
                  "Rak: $location",
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Quick Stock Adjustment Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStockButton(
                icon: LucideIcons.minus,
                color: Colors.red,
                onTap: onMinus,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  "$stock",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStockButton(
                icon: LucideIcons.plus,
                color: Colors.green,
                onTap: onPlus,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _isUpdating ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
