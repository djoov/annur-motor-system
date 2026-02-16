import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';

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
      Provider.of<StockOpnameProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockOpnameProvider>(context);

    // Desktop Layout
    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/stock-opname',
        body: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Stock Opname (Audit)"),
            elevation: 0,
            backgroundColor:
                Colors.transparent, // Let desktop background show or keep white
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.plus),
                onPressed: () {
                  provider.startNewOpname();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StockOpnameFormScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _buildList(provider),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Opname (Audit)"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              provider.startNewOpname();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockOpnameFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildList(provider),
    );
  }

  Widget _buildList(StockOpnameProvider provider) {
    return provider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : provider.history.isEmpty
        ? const Center(child: Text("Belum ada riwayat audit"))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final opname = provider.history[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.clipboardCheck,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(opname.date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Oleh: ${opname.staffName} • ${opname.items.length} Barang",
                  ),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                    // View Detail (Future Improvement)
                    // For now just show a simple dialog
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Detail Audit"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...opname.items
                                .map(
                                  (e) => ListTile(
                                    title: Text(e.itemName),
                                    subtitle: Text(
                                      "Sistem: ${e.systemStock} -> Fisik: ${e.actualStock}",
                                    ),
                                    trailing: Text(
                                      "${e.difference > 0 ? '+' : ''}${e.difference}",
                                      style: TextStyle(
                                        color: e.difference == 0
                                            ? Colors.grey
                                            : (e.difference > 0
                                                  ? Colors.green
                                                  : Colors.red),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Tutup"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
  }
}
