import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';

import '../../ui/app_list.dart';
import '../../ui/desktop_scaffold.dart';
import 'stock_opname_provider.dart';
import 'stock_opname_form_screen.dart';

class StockOpnameListScreen extends StatefulWidget {
  const StockOpnameListScreen({super.key});

  @override
  State<StockOpnameListScreen> createState() => _StockOpnameListScreenState();
}

class _StockOpnameListScreenState extends State<StockOpnameListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockOpnameProvider>().fetchHistory();
    });
  }

  void _startNew() {
    context.read<StockOpnameProvider>().startNewOpname();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StockOpnameFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockOpnameProvider>();
    final fab = FloatingActionButton.extended(
      onPressed: _startNew,
      icon: const Icon(LucideIcons.clipboardList),
      label: const Text("Mulai Hitung Stok"),
    );

    final scaffold = Scaffold(
      appBar: AppBar(title: const Text("Stock Opname")),
      floatingActionButton: fab,
      body: _buildList(provider),
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(activeRoute: '/stock-opname', body: scaffold);
    }
    return scaffold;
  }

  Widget _buildList(StockOpnameProvider provider) {
    if (provider.isLoading && provider.history.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (provider.history.isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.clipboardCheck,
        title: "Belum pernah hitung stok",
        message:
            "Cocokkan jumlah barang di rak dengan catatan aplikasi. Selisihnya disesuaikan otomatis.",
        actionLabel: "Mulai Hitung Stok",
        onAction: _startNew,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: AppListPanelSliver(
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final opname = provider.history[index];
              final mismatched =
                  opname.items.where((e) => e.difference != 0).length;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(opname.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "${opname.staffName} · ${opname.items.length} barang"
                  "${mismatched > 0 ? ' · $mismatched selisih' : ' · semua cocok'}",
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
                onTap: () => _showDetail(opname),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  void _showDetail(dynamic opname) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              "Hitung stok ${DateFormat('d MMM yyyy', 'id_ID').format(opname.date)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              [
                "Oleh ${opname.staffName}",
                if ((opname.note ?? '').isNotEmpty) opname.note,
              ].join(" · "),
              style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 12),
            for (final e in opname.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.itemName),
                subtitle: Text("Sistem ${e.systemStock} → fisik ${e.actualStock}"),
                trailing: Text(
                  e.difference == 0
                      ? "Cocok"
                      : "${e.difference > 0 ? '+' : ''}${e.difference}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: e.difference == 0
                        ? AppColors.successStrong
                        : (e.difference > 0
                            ? AppColors.primary
                            : AppColors.destructiveStrong),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
