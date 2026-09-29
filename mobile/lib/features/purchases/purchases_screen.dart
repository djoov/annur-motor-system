import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../ui/desktop_scaffold.dart';
import '../../ui/app_list.dart';
import 'purchases_provider.dart';
import 'purchase_entry_screen.dart';
import 'purchase_model.dart';
import '../../core/theme.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Owner-only: purchases from suppliers.
class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PurchasesProvider>();
      if (provider.purchases.isEmpty) provider.fetchPurchases();
    });
  }

  void _openEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PurchaseEntryScreen()),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      const template = 'FAKTUR,SUPPLIER,NAMA_BARANG,QTY,HARGA,TANGGAL\n'
          'INV-001,PT Suppliers,Oli Yamalube,10,50000,2025-01-18\n'
          'INV-001,PT Suppliers,Kampas Rem,5,75000,2025-01-18\n'
          'INV-002,PT Honda,Busi NGK,20,25000,2025-01-18';

      if (kIsWeb) {
        _showMessage("Template tersedia di: template_pembelian.csv");
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/template_pembelian.csv');
        await file.writeAsString(template);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Template Import Pembelian',
          ),
        );
      }
    } catch (e) {
      _showMessage("Gagal membuat template: $e");
    }
  }

  /// Imports purchase HISTORY only (stock is not changed). Rows with the same
  /// invoice number are grouped into one purchase record.
  Future<void> _importCSV() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Import riwayat pembelian"),
        content: const Text(
          "Import CSV hanya menyimpan catatan pembelian lama dan tidak mengubah stok barang. "
          "Untuk barang yang baru datang, pakai Catat Pembelian.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Pilih File CSV"),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final content = kIsWeb
          ? String.fromCharCodes(result.files.first.bytes!)
          : await File(result.files.first.path!).readAsString();

      final rows = Csv().decode(content);
      if (rows.isEmpty) {
        _showMessage("File CSV kosong");
        return;
      }

      final dataRows = rows.length > 1 &&
              rows[0][0].toString().toUpperCase().contains('FAKTUR')
          ? rows.sublist(1)
          : rows;

      int toInt(Object? v) =>
          int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      // invoice -> (supplier, items)
      final grouped = <String, (String, List<PurchaseItem>)>{};
      int skipped = 0;
      for (final row in dataRows) {
        if (row.length < 5) {
          skipped++;
          continue;
        }
        final invoice = row[0].toString().trim();
        final supplier = row[1].toString().trim();
        final itemName = row[2].toString().trim();
        if (invoice.isEmpty || supplier.isEmpty || itemName.isEmpty) {
          skipped++;
          continue;
        }
        final entry = grouped.putIfAbsent(invoice, () => (supplier, []));
        entry.$2.add(PurchaseItem(
          itemId: '',
          name: itemName,
          quantity: toInt(row[3]),
          buyPrice: toInt(row[4]),
        ));
      }

      if (!mounted) return;
      final provider = context.read<PurchasesProvider>();
      int imported = 0;
      for (final e in grouped.entries) {
        final okOne = await provider.importPurchase(
          invoiceNumber: e.key,
          supplierName: e.value.$1,
          items: e.value.$2,
        );
        if (okOne) imported++;
      }

      _showMessage(
        "$imported faktur diimpor"
        "${skipped > 0 ? ', $skipped baris dilewati' : ''}",
      );
      provider.fetchPurchases();
    } catch (e) {
      _showMessage("Import gagal: $e");
    }
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton.extended(
      onPressed: _openEntry,
      icon: const Icon(LucideIcons.plus),
      label: const Text("Catat Pembelian"),
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text("Pembelian"),
        actions: [
          PopupMenuButton<String>(
            tooltip: "Lainnya",
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (v) {
              if (v == 'import') _importCSV();
              if (v == 'template') _downloadTemplate();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(LucideIcons.fileUp),
                  title: Text("Import riwayat (CSV)"),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'template',
                child: ListTile(
                  leading: Icon(LucideIcons.download),
                  title: Text("Unduh template CSV"),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: fab,
      body: Consumer<PurchasesProvider>(
        builder: (context, provider, _) => _buildListBody(provider),
      ),
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(activeRoute: '/purchases', body: scaffold);
    }
    return scaffold;
  }

  Widget _buildListBody(PurchasesProvider provider) {
    if (provider.isLoading && provider.purchases.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.purchases.isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.packagePlus,
        title: "Belum ada pembelian",
        message: "Catat barang yang datang dari supplier. Stok otomatis bertambah.",
        actionLabel: "Catat Pembelian",
        onAction: _openEntry,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchPurchases,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: provider.purchases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final purchase = provider.purchases[index];
          return Material(
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                purchase.supplierName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "${DateFormat('d MMM yyyy', 'id_ID').format(purchase.date)} · #${purchase.invoiceNumber}",
              ),
              trailing: Text(
                _rupiah.format(purchase.total),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              children: [
                for (final item in purchase.items)
                  ListTile(
                    dense: true,
                    title: Text(item.name),
                    subtitle: Text(
                      "${item.quantity} × ${_rupiah.format(item.buyPrice)}",
                    ),
                    trailing: Text(
                      _rupiah.format(item.quantity * item.buyPrice),
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
