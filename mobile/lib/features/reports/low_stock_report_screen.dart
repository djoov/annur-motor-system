import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../ui/app_list.dart';
import '../../ui/stock_badge.dart';
import '../items/items_provider.dart';
import '../items/item_detail_screen.dart';
import '../pos/models/pos_models.dart';
import '../../ui/desktop_scaffold.dart';

class LowStockReportScreen extends StatefulWidget {
  const LowStockReportScreen({super.key});

  @override
  State<LowStockReportScreen> createState() => _LowStockReportScreenState();
}

class _LowStockReportScreenState extends State<LowStockReportScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<ItemsProvider>().fetchItems();
    });
  }

  /// Plain-text restock list (e.g. to send to a supplier on WhatsApp).
  String _shoppingList(List<Item> items) {
    final lines = [
      "Daftar belanja stok Annur Motor:",
      for (final i in items)
        "- ${i.name}${i.code.isNotEmpty ? ' (${i.code})' : ''} — sisa ${i.stockDisplay}",
    ];
    return lines.join("\n");
  }

  Future<void> _share(List<Item> items) async {
    final text = _shoppingList(items);
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      // Desktop / unsupported: fall back to clipboard
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Daftar belanja disalin")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemsProvider>();
    final items = [...provider.lowStockDisplayItems]
      ..sort((a, b) => a.stockDisplay.compareTo(b.stockDisplay));

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text("Stok Menipis"),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: "Bagikan daftar belanja",
              icon: const Icon(LucideIcons.fileUp),
              onPressed: () => _share(items),
            ),
        ],
      ),
      body: _buildBody(provider, items),
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(activeRoute: '/low_stock', body: scaffold);
    }
    return scaffold;
  }

  Widget _buildBody(ItemsProvider provider, List<Item> items) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (items.isEmpty) {
      return const AppEmptyState(
        icon: LucideIcons.circleCheck,
        title: "Stok aman",
        message: "Tidak ada barang dengan sisa $kLowStockThreshold atau kurang.",
      );
    }

    final out = items.where((i) => i.stockDisplay <= 0).length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              [
                if (out > 0) "$out habis",
                if (items.length - out > 0)
                  "${items.length - out} sisa $kLowStockThreshold atau kurang",
              ].join(" · "),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: AppListPanelSliver(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final meta = [
                if (item.code.isNotEmpty) item.code,
                if (item.locationDisplay != null &&
                    item.locationDisplay!.isNotEmpty)
                  "Rak ${item.locationDisplay}",
              ].join(" · ");
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: meta.isEmpty ? null : Text(meta),
                trailing: StockBadge(item.stockDisplay),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: OutlinedButton.icon(
              onPressed: () => _share(items),
              icon: const Icon(LucideIcons.fileUp, size: 18),
              label: const Text("Bagikan daftar belanja ke supplier"),
            ),
          ),
        ),
      ],
    );
  }
}
