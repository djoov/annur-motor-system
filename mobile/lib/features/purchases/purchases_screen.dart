import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../ui/app_drawer.dart';
import '../../ui/desktop_scaffold.dart';
import 'purchases_provider.dart';
import 'purchase_entry_screen.dart';
import '../../core/theme.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PurchasesProvider>(context, listen: false);
      if (provider.purchases.isEmpty) {
        provider.fetchPurchases();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    // Desktop Layout
    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/purchases',
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PurchaseEntryScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
        body: Consumer<PurchasesProvider>(
          builder: (context, provider, child) {
            return _buildListBody(
              context,
              provider,
              dateFormat,
              currencyFormat,
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pembelian"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchaseEntryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<PurchasesProvider>(
        builder: (context, provider, child) {
          return _buildListBody(context, provider, dateFormat, currencyFormat);
        },
      ),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    PurchasesProvider provider,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    if (provider.isLoading && provider.purchases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.purchases.isEmpty) {
      return const Center(child: Text("Belum ada data pembelian"));
    }

    return RefreshIndicator(
      onRefresh: provider.fetchPurchases,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.purchases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final purchase = provider.purchases[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ExpansionTile(
              title: Text(
                purchase.supplierName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(dateFormat.format(purchase.date)),
              trailing: Text(
                currencyFormat.format(purchase.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              children: [
                ...purchase.items.map(
                  (item) => ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text(item.name),
                    subtitle: Text(
                      "${item.quantity} x ${currencyFormat.format(item.buyPrice)}",
                    ),
                    trailing: Text(
                      currencyFormat.format(item.quantity * item.buyPrice),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
