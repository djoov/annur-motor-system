import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import 'pos_provider.dart';
import 'models/pos_models.dart';
import 'receipt_preview_screen.dart';
import 'widgets/pos_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  /// Cash handed over by the customer (only for "Tunai"); null = not entered.
  int? _cashReceived;

  void _checkout(PosProvider provider) {
    final draftData = provider.calculateTransactionSummary();
    if (draftData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Keranjang masih kosong")),
      );
      return;
    }
    // Replace so going back from the receipt doesn't land on an emptied cart.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewScreen(
          transactionData: draftData,
          isDraft: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PosProvider>();
    final isCash = !provider.isDebt && provider.paymentType == 'cash';

    // Drop a stale cash amount if the total grew past it.
    if (_cashReceived != null && _cashReceived! < provider.totalAmount) {
      _cashReceived = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang"),
        actions: [
          if (provider.cart.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(provider),
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: const Text("Kosongkan"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.destructiveStrong,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.cart.isEmpty
          ? _EmptyCart(onBack: () => Navigator.pop(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Section(
                  child: Column(
                    children: [
                      for (var i = 0; i < provider.cart.length; i++) ...[
                        if (i > 0) const Divider(indent: 16, endIndent: 16),
                        _CartLine(
                          item: provider.cart[i],
                          onMinus: () => provider.updateQuantity(
                              provider.cart[i].id, -1),
                          onPlus: () =>
                              posAddToCart(context, provider, provider.cart[i]),
                        ),
                      ],
                    ],
                  ),
                ),
                if (provider.smartCrossSellSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  CrossSellStrip(provider: provider),
                ],
                const SizedBox(height: 24),
                const _Label("Pelanggan"),
                CustomerPicker(provider: provider),
                const SizedBox(height: 20),
                const _Label("Pembayaran"),
                PaymentMethodSelector(provider: provider),
                if (isCash) ...[
                  const SizedBox(height: 20),
                  const _Label("Uang diterima"),
                  _CashPicker(
                    total: provider.totalAmount,
                    selected: _cashReceived,
                    onSelected: (v) => setState(() => _cashReceived = v),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: provider.cart.isEmpty
          ? null
          : _PayBar(
              provider: provider,
              change: isCash && _cashReceived != null
                  ? _cashReceived! - provider.totalAmount
                  : null,
              onPay: () => _checkout(provider),
            ),
    );
  }

  Future<void> _confirmClear(PosProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kosongkan keranjang?"),
        content: Text("${provider.totalItems} barang akan dihapus dari keranjang."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text("Kosongkan"),
          ),
        ],
      ),
    );
    if (ok == true) provider.clearCart();
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;

  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CartLine({
    required this.item,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
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
                      errorBuilder: (_, __, ___) => const _ImageFallback(),
                    )
                  : const _ImageFallback(),
            ),
          ),
          const SizedBox(width: 12),
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
                  "${posRupiah.format(item.sellPrice)} × ${item.quantity}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                    fontFeatures: posTabular,
                  ),
                ),
                Text(
                  posRupiah.format(item.sellPrice * item.quantity),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: posTabular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QtyStepper(quantity: item.quantity, onMinus: onMinus, onPlus: onPlus),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

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

/// Quick cash amounts; the chosen one drives the change shown in the pay bar.
class _CashPicker extends StatelessWidget {
  final int total;
  final int? selected;
  final ValueChanged<int?> onSelected;

  const _CashPicker({
    required this.total,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = PosProvider.getSmartCashSuggestions(total);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cash in options)
          ChoiceChip(
            label: Text(
              cash == total ? "Uang pas" : posRupiah.format(cash),
              style: const TextStyle(fontFeatures: posTabular),
            ),
            selected: selected == cash,
            showCheckmark: false,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected == cash ? AppColors.primary : AppColors.foreground,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            onSelected: (on) => onSelected(on ? cash : null),
          ),
      ],
    );
  }
}

class _PayBar extends StatelessWidget {
  final PosProvider provider;
  final int? change;
  final VoidCallback onPay;

  const _PayBar({
    required this.provider,
    required this.change,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final blocked = provider.needsCustomerForDebt;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TotalRow(itemCount: provider.totalItems, total: provider.totalAmount),
          if (change != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Kembalian",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.successStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  posRupiah.format(change),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successStrong,
                    fontFeatures: posTabular,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: blocked ? null : onPay,
              icon: const Icon(LucideIcons.circleCheck, size: 20),
              label: Text(
                blocked
                    ? "Pilih pelanggan dulu"
                    : (provider.isDebt ? "Catat Hutang" : "Bayar"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyCart({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.shoppingCart,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            const Text(
              "Keranjang kosong",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              "Pilih barang atau scan barcode untuk mulai.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onBack,
              child: const Text("Pilih Barang"),
            ),
          ],
        ),
      ),
    );
  }
}
