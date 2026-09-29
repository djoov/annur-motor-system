import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/app_form.dart';
import '../history/models/transaction_model.dart';
import 'return_provider.dart';

const _tabular = [FontFeature.tabularFigures()];

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Pick how many of each item the customer brings back. Stock is added back
/// and a negative "return" transaction is recorded.
class ReturnSelectionScreen extends StatefulWidget {
  final TransactionModel transaction;
  const ReturnSelectionScreen({super.key, required this.transaction});

  @override
  State<ReturnSelectionScreen> createState() => _ReturnSelectionScreenState();
}

class _ReturnSelectionScreenState extends State<ReturnSelectionScreen> {
  /// {itemId: quantity to return now}
  final Map<String, int> _returnQuantities = {};
  bool _isSaving = false;

  /// Units still returnable = bought − already returned earlier.
  int _maxReturnable(TransactionItem item) =>
      item.quantity - (widget.transaction.returnedItems[item.itemId] ?? 0);

  int get _refundTotal => widget.transaction.items.fold(
        0,
        (sum, i) => sum + (_returnQuantities[i.itemId] ?? 0) * i.sellPrice,
      );

  Future<void> _process() async {
    final items = [
      for (final item in widget.transaction.items)
        if ((_returnQuantities[item.itemId] ?? 0) > 0)
          {
            'itemId': item.itemId,
            'itemName': item.itemName,
            'quantity': _returnQuantities[item.itemId],
            'sellPrice': item.sellPrice,
            'buyPrice': item.buyPrice,
          },
    ];
    final count = items.fold<int>(0, (s, i) => s + (i['quantity'] as int));

    final ok = await confirmDestructive(
      context,
      title: "Proses retur?",
      message:
          "$count barang dikembalikan ke stok dan uang ${_rupiah.format(_refundTotal)} dikembalikan ke pelanggan.",
      action: "Proses Retur",
    );
    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);
    final success = await context.read<ReturnProvider>().processReturn(
          originalTransactionId: widget.transaction.id,
          itemsToReturn: items,
          customerId: widget.transaction.customerId,
          customerName: widget.transaction.customerName,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Retur diproses. Kembalikan ${_rupiah.format(_refundTotal)}"),
        ),
      );
      navigator.pop();
    } else {
      showErrorSnack(context, "Retur gagal diproses. Coba lagi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final refund = _refundTotal;

    return Scaffold(
      appBar: AppBar(title: const Text("Retur Barang")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            "${t.customerName} · ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(t.date)}",
            style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pilih jumlah barang yang dikembalikan",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < t.items.length; i++) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  _ReturnLine(
                    item: t.items[i],
                    alreadyReturned: t.returnedItems[t.items[i].itemId] ?? 0,
                    maxReturnable: _maxReturnable(t.items[i]),
                    value: _returnQuantities[t.items[i].itemId] ?? 0,
                    onChanged: (v) => setState(
                        () => _returnQuantities[t.items[i].itemId] = v),
                  ),
                ],
              ],
            ),
          ),
        ],
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
                const Expanded(
                  child: Text(
                    "Uang dikembalikan",
                    style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                  ),
                ),
                Text(
                  _rupiah.format(refund),
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
                onPressed: refund > 0 && !_isSaving ? _process : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.undo2, size: 20),
                label: const Text("Proses Retur"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnLine extends StatelessWidget {
  final TransactionItem item;
  final int alreadyReturned;
  final int maxReturnable;
  final int value;
  final ValueChanged<int> onChanged;

  const _ReturnLine({
    required this.item,
    required this.alreadyReturned,
    required this.maxReturnable,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final done = maxReturnable <= 0;

    Widget stepButton(IconData icon, VoidCallback? onTap, String tooltip) =>
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton.outlined(
            tooltip: tooltip,
            onPressed: onTap,
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(icon, size: 18),
          ),
        );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.mutedForeground : AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Dibeli ${item.quantity} × ${_rupiah.format(item.sellPrice)}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                    fontFeatures: _tabular,
                  ),
                ),
                if (alreadyReturned > 0)
                  Text(
                    done
                        ? "Semua sudah diretur"
                        : "Sudah diretur $alreadyReturned",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warningStrong,
                    ),
                  ),
              ],
            ),
          ),
          if (!done) ...[
            stepButton(
              LucideIcons.minus,
              value > 0 ? () => onChanged(value - 1) : null,
              "Kurangi",
            ),
            SizedBox(
              width: 40,
              child: Text(
                "$value",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular,
                ),
              ),
            ),
            stepButton(
              LucideIcons.plus,
              value < maxReturnable ? () => onChanged(value + 1) : null,
              "Tambah",
            ),
          ],
        ],
      ),
    );
  }
}
