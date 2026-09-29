import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../ui/stock_badge.dart';
import '../pos/models/pos_models.dart';
import 'item_form_screen.dart';
import 'items_provider.dart';
import '../auth/auth_provider.dart';

const _tabular = [FontFeature.tabularFigures()];

class ItemDetailScreen extends StatefulWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Item _item;
  bool _isUpdating = false;

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _adjustStock(String location, int delta) async {
    if (_isUpdating) return;
    if (delta < 0 && _item.stockDisplay <= 0) return;

    setState(() => _isUpdating = true);

    final provider = Provider.of<ItemsProvider>(context, listen: false);
    final success = await provider.quickUpdateStock(_item.id, location, delta);

    if (!mounted) return;
    if (success) {
      final updatedItem = provider.items.firstWhere(
        (i) => i.id == _item.id,
        orElse: () => _item,
      );
      setState(() => _item = updatedItem);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stok gagal diubah. Coba lagi.")),
      );
    }
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final margin = item.sellPrice - item.buyPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Produk"),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
            ),
            icon: const Icon(LucideIcons.pencil),
            tooltip: "Edit barang",
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Image — capped height so the key info stays on screen
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 220,
                  color: AppColors.muted,
                  child: hasImage
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const _NoImage(
                            text: "Gambar gagal dimuat",
                          ),
                        )
                      : const _NoImage(text: "Belum ada foto"),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                item.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (item.code.isNotEmpty) _Pill(item.code),
                  _Pill(item.category ?? 'Umum'),
                  StockBadge(item.stockDisplay),
                ],
              ),
              const SizedBox(height: 24),

              // Prices
              _Panel(
                children: [
                  _InfoRow(
                    "Harga jual",
                    _rupiah.format(item.sellPrice),
                    strong: true,
                  ),
                  if (isAdmin) ...[
                    _InfoRow("Harga modal", _rupiah.format(item.buyPrice)),
                    _InfoRow(
                      "Untung per barang",
                      item.buyPrice > 0
                          ? "${_rupiah.format(margin)} (${(margin / item.buyPrice * 100).toStringAsFixed(1)}%)"
                          : _rupiah.format(margin),
                      color: margin < 0
                          ? AppColors.destructiveStrong
                          : AppColors.successStrong,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Stock
              _Panel(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Stok",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (item.locationDisplay != null &&
                                item.locationDisplay!.isNotEmpty)
                              Text(
                                "Rak ${item.locationDisplay}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StockButton(
                              icon: LucideIcons.minus,
                              tooltip: "Kurangi 1",
                              busy: _isUpdating,
                              onTap: item.stockDisplay > 0
                                  ? () => _adjustStock('display', -1)
                                  : null,
                            ),
                            SizedBox(
                              width: 96,
                              child: Text(
                                "${item.stockDisplay}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: _tabular,
                                ),
                              ),
                            ),
                            _StockButton(
                              icon: LucideIcons.plus,
                              tooltip: "Tambah 1",
                              busy: _isUpdating,
                              onTap: () => _adjustStock('display', 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Untuk koreksi cepat. Barang masuk dari supplier dicatat di Pembelian.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle("Deskripsi"),
                const SizedBox(height: 8),
                Text(
                  item.description!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],

              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle("Tag pencarian"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final tag in item.tags) _Pill(tag)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoImage extends StatelessWidget {
  final String text;

  const _NoImage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.package, size: 40, color: AppColors.mutedForeground),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

class _Panel extends StatelessWidget {
  final List<Widget> children;

  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;

  const _InfoRow(this.label, this.value, {this.strong = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 18 : 15,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColors.foreground,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool busy;
  final VoidCallback? onTap;

  const _StockButton({
    required this.icon,
    required this.tooltip,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton.outlined(
        tooltip: tooltip,
        onPressed: busy ? null : onTap,
        style: IconButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 22, color: AppColors.foreground),
      ),
    );
  }
}
