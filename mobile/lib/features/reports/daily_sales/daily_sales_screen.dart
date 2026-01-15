import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme.dart';
import '../../../ui/app_drawer.dart';
import '../../../ui/desktop_scaffold.dart';
import 'daily_sales_provider.dart';
import '../../../../core/services/export_service.dart';

class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({Key? key}) : super(key: key);

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  Future<void> _selectDate(BuildContext context) async {
    final provider = Provider.of<DailySalesProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.setDate(picked);
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    final provider = Provider.of<DailySalesProvider>(context, listen: false);
    if (provider.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada transaksi untuk diexport.")),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Menyiapkan laporan...")));

    try {
      final headers = [
        "WAKTU",
        "NO. INVOICE",
        "PELANGGAN",
        "ITEM",
        "METODE BAYAR",
        "STATUS BAYAR",
        "KASIR",
        "TOTAL",
        "PROFIT",
      ];

      final rows = provider.transactions.map((trx) {
        final itemsStr = trx.items
            .map((i) => "${i.itemName} (${i.quantity})")
            .join('; ');

        return [
          DateFormat('HH:mm:ss').format(trx.date),
          trx.id,
          trx.customerName,
          itemsStr,
          trx.paymentMethod,
          trx.paymentStatus,
          trx.cashierName,
          trx.totalAmount,
          trx.totalProfit,
        ];
      }).toList();

      final dateStr = DateFormat('yyyy-MM-dd').format(provider.selectedDate);
      final fileName = "Laporan_Penjualan_$dateStr.csv";

      await ExportService.exportToCSV(
        headers: headers,
        data: rows,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Laporan $dateStr berhasil diexport."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    // Desktop Layout
    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/report-sales',
        body: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Penjualan Harian"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.download),
                tooltip: "Export Laporan",
                onPressed: () => _handleExport(context),
              ),
              IconButton(
                icon: const Icon(LucideIcons.calendar),
                onPressed: () => _selectDate(context),
                tooltip: "Pilih Tanggal",
              ),
            ],
          ),
          body: Consumer<DailySalesProvider>(
            builder: (context, provider, child) {
              return _buildContent(provider, dateFormat, currencyFormat);
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Penjualan Harian"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendar),
            onPressed: () => _selectDate(context),
            tooltip: "Pilih Tanggal",
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<DailySalesProvider>(
        builder: (context, provider, child) {
          return _buildContent(provider, dateFormat, currencyFormat);
        },
      ),
    );
  }

  Widget _buildContent(
    DailySalesProvider provider,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    return Column(
      children: [
        // Header Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    dateFormat.format(provider.selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (provider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox(
                      "Total Omset",
                      currencyFormat.format(provider.totalRevenue),
                      LucideIcons.banknote,
                      Colors.blue.shade50,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryBox(
                      "Keuntungan",
                      currencyFormat.format(provider.totalProfit),
                      LucideIcons.trendingUp,
                      Colors.green.shade50,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox(
                      "Barang Terjual",
                      "${provider.totalItemsSold} Pcs",
                      LucideIcons.package,
                      Colors.orange.shade50,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Item List
        Expanded(
          child: provider.isLoading && provider.salesItems.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.salesItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.packageX,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Tidak ada penjualan pada tanggal ini",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.salesItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = provider.salesItems[index];
                    return _buildItemCard(item, currencyFormat);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryBox(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(DailySalesItem item, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${item.quantity} Terjual",
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(item.totalRevenue),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Profit: ${currencyFormat.format(item.totalProfit)}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
