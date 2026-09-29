import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Stock level at which an item counts as "menipis" (matches ItemsProvider).
const int kLowStockThreshold = 5;

/// Traffic-light stock label: 0 → red "Habis", ≤ 5 → amber "Sisa n", else green.
class StockBadge extends StatelessWidget {
  final int stock;

  const StockBadge(this.stock, {super.key});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String text) = stock <= 0
        ? (AppColors.destructive, Colors.white, "Habis")
        : stock <= kLowStockThreshold
            ? (AppColors.warningSoft, AppColors.warningStrong, "Sisa $stock")
            : (AppColors.successSoft, AppColors.successStrong, "Stok $stock");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
