import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme.dart';
import '../models/pos_models.dart';
import '../pos_provider.dart';

export '../../../ui/stock_badge.dart';

const posTabular = [FontFeature.tabularFigures()];

final posRupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Adds [item] to the cart with haptic + a short message when stock runs out.
void posAddToCart(BuildContext context, PosProvider provider, Item item) {
  final added = provider.addToCart(item);
  if (added) {
    HapticFeedback.selectionClick();
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          item.stockDisplay <= 0
              ? "${item.name} sedang habis"
              : "Stok ${item.name} hanya ${item.stockDisplay}",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}

/// − qty + with 40 dp buttons. Minus turns into a trash icon at qty 1.
class QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback onTap, String tooltip,
        {bool filled = false, bool danger = false}) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: filled ? AppColors.primary : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 18,
                color: filled
                    ? Colors.white
                    : (danger
                        ? AppColors.destructiveStrong
                        : AppColors.foreground),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        quantity <= 1
            ? button(LucideIcons.trash2, onMinus, "Hapus", danger: true)
            : button(LucideIcons.minus, onMinus, "Kurangi"),
        SizedBox(
          width: 40,
          child: Text(
            "$quantity",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: posTabular,
            ),
          ),
        ),
        button(LucideIcons.plus, onPlus, "Tambah", filled: true),
      ],
    );
  }
}

/// One control for how the customer pays: Tunai · Transfer/QRIS · Hutang.
class PaymentMethodSelector extends StatelessWidget {
  final PosProvider provider;

  const PaymentMethodSelector({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final current = provider.isDebt ? 'debt' : provider.paymentType;

    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: 'cash',
          label: Text("Tunai"),
          icon: Icon(LucideIcons.banknote, size: 18),
        ),
        ButtonSegment(
          value: 'transfer',
          label: Text("Transfer"),
          icon: Icon(LucideIcons.smartphone, size: 18),
        ),
        ButtonSegment(
          value: 'debt',
          label: Text("Hutang"),
          icon: Icon(LucideIcons.wallet, size: 18),
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) {
        final v = s.first;
        if (v == 'debt') {
          provider.setDebt(true);
        } else {
          provider.setDebt(false);
          provider.setPaymentType(v);
        }
      },
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.mutedForeground,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primarySoft
              : AppColors.surface,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.border),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Customer dropdown; shows a warning when "Hutang" is chosen without a customer.
class CustomerPicker extends StatelessWidget {
  final PosProvider provider;

  const CustomerPicker({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final value = provider.selectedCustomerId.isEmpty
        ? 'umum'
        : provider.selectedCustomerId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Pelanggan",
            prefixIcon: Icon(LucideIcons.user, size: 18),
          ),
          items: [
            const DropdownMenuItem(
              value: 'umum',
              child: Text("Pelanggan Umum"),
            ),
            ...provider.customers.map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null) provider.setCustomer(v);
          },
        ),
        if (provider.needsCustomerForDebt)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: AppColors.warningStrong),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Pilih pelanggan untuk mencatat hutang.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warningStrong,
                      fontWeight: FontWeight.w500,
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

/// Complementary items for what's in the cart ("Sering dibeli bersama").
class CrossSellStrip extends StatelessWidget {
  final PosProvider provider;

  const CrossSellStrip({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final suggestions = provider.smartCrossSellSuggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sering dibeli bersama",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in suggestions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => posAddToCart(context, provider, item),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    posRupiah.format(item.sellPrice),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.mutedForeground,
                                      fontFeatures: posTabular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.circlePlus,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
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

/// Mobile: floating navy bar with item count + total; opens the cart.
class CartSummaryBar extends StatelessWidget {
  final int itemCount;
  final int total;
  final VoidCallback onTap;

  const CartSummaryBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandNavy,
      elevation: 3,
      shadowColor: AppColors.brandNavy.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            children: [
              const Icon(LucideIcons.shoppingCart,
                  color: AppColors.brandYellow, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$itemCount barang",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    Text(
                      posRupiah.format(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandYellow,
                        fontFeatures: posTabular,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text(
                      "Keranjang",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight,
                        size: 18, color: AppColors.brandNavy),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Total" label + big amount row used above the pay button.
class TotalRow extends StatelessWidget {
  final int itemCount;
  final int total;

  const TotalRow({super.key, required this.itemCount, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "$itemCount barang",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Text(
          posRupiah.format(total),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            fontFeatures: posTabular,
          ),
        ),
      ],
    );
  }
}
