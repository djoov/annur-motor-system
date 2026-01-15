import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../pos/models/pos_models.dart';
import 'item_form_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;

  const ItemDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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

                  // Only show Buy Price if needed? Assume Detail is for Staff too, maybe hide Buy Price?
                  // User said "show details", usually buy price is sensitive. Let's hide it for safety or make it consistent with Form.
                  // For now, let's omit Buy Price here to keep it cleaner for generic use.
                  const SizedBox(height: 24),

                  // Stock & Location
                  _buildSectionTitle("Stok & Lokasi"),
                  const SizedBox(height: 12),

                  // Display / Toko
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.store, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text(
                              "Toko (Display)",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${item.stockDisplay} Unit",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.stockDisplay <= 5
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            if (item.locationDisplay != null &&
                                item.locationDisplay!.isNotEmpty)
                              Text(
                                "Rak: ${item.locationDisplay}",
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Warehouse / Gudang
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.warehouse, color: Colors.orange),
                            SizedBox(width: 12),
                            Text(
                              "Gudang",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${item.stockWarehouse} Unit",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.stockWarehouse <= 5
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            if (item.locationWarehouse != null &&
                                item.locationWarehouse!.isNotEmpty)
                              Text(
                                "Rak: ${item.locationWarehouse}",
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
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
}
