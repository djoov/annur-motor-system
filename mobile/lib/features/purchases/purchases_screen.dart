import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../ui/app_drawer.dart';
import '../../ui/desktop_scaffold.dart';
import 'purchases_provider.dart';
import 'purchase_entry_screen.dart';
import 'purchase_model.dart';
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

  Future<void> _downloadTemplate() async {
    try {
      // CSV template content
      const template =
          'FAKTUR,SUPPLIER,NAMA_BARANG,QTY,HARGA,TANGGAL\n'
          'INV-001,PT Suppliers,Oli Yamalube,10,50000,2025-01-18\n'
          'INV-001,PT Suppliers,Kampas Rem,5,75000,2025-01-18\n'
          'INV-002,PT Honda,Busi NGK,20,25000,2025-01-18';

      if (kIsWeb) {
        // For web, trigger download via blob
        _showMessage("Template tersedia di: template_pembelian.csv");
      } else {
        // For mobile, save to downloads and share
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/template_pembelian.csv');
        await file.writeAsString(template);

        await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'Template Import Pembelian');
      }
    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  Future<void> _importCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      String content;
      if (kIsWeb) {
        content = String.fromCharCodes(result.files.first.bytes!);
      } else {
        final file = File(result.files.first.path!);
        content = await file.readAsString();
      }

      final rows = const CsvToListConverter().convert(content, eol: '\n');
      if (rows.isEmpty) {
        _showMessage("File CSV kosong");
        return;
      }

      // Skip header row if exists
      final dataRows =
          rows.length > 1 &&
              rows[0][0].toString().toUpperCase().contains('FAKTUR')
          ? rows.sublist(1)
          : rows;

      final provider = Provider.of<PurchasesProvider>(context, listen: false);
      int imported = 0;
      int failed = 0;

      for (var row in dataRows) {
        if (row.length < 6)
          continue; // Must have: Invoice, Supplier, ItemName, Qty, Price, Date

        try {
          final invoiceNumber = row[0].toString().trim();
          final supplierName = row[1].toString().trim();
          final itemName = row[2].toString().trim();
          final qty =
              int.tryParse(
                row[3].toString().replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              0;
          final price =
              int.tryParse(
                row[4].toString().replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              0;
          // Date in column 5 (optional)

          if (invoiceNumber.isEmpty ||
              supplierName.isEmpty ||
              itemName.isEmpty) {
            failed++;
            continue;
          }

          final item = PurchaseItem(
            itemId: '', // Will be matched by name in provider
            name: itemName,
            buyPrice: price,
            quantity: qty,
          );

          final success = await provider.importPurchase(
            invoiceNumber: invoiceNumber,
            supplierName: supplierName,
            items: [item],
          );

          if (success) {
            imported++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
        }
      }

      _showMessage("Import selesai: $imported berhasil, $failed gagal");
      provider.fetchPurchases();
    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
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
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'import',
              mini: true,
              onPressed: _importCSV,
              backgroundColor: Colors.orange,
              child: const Icon(LucideIcons.fileUp, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'add',
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
          ],
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
            icon: const Icon(LucideIcons.download),
            tooltip: "Download Template CSV",
            onPressed: _downloadTemplate,
          ),
          IconButton(
            icon: const Icon(LucideIcons.fileUp),
            tooltip: "Import CSV",
            onPressed: _importCSV,
          ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.archive,
              size: 64,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            const Text("Belum ada data pembelian"),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _importCSV,
              icon: const Icon(LucideIcons.fileUp),
              label: const Text("Import dari CSV"),
            ),
          ],
        ),
      );
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
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.receipt,
                  color: AppColors.primary,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      purchase.supplierName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "#${purchase.invoiceNumber}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                dateFormat.format(purchase.date),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                currencyFormat.format(purchase.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              children: [
                Container(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      ...purchase.items.map(
                        (item) => ListTile(
                          visualDensity: VisualDensity.compact,
                          title: Text(item.name),
                          subtitle: Text(
                            "${item.quantity} x ${currencyFormat.format(item.buyPrice)}",
                          ),
                          trailing: Text(
                            currencyFormat.format(
                              item.quantity * item.buyPrice,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
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
