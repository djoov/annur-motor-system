import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme.dart';

import '../../../ui/desktop_scaffold.dart';
import '../../../ui/app_list.dart';
import 'daily_sales_provider.dart';
import '../../../../core/services/export_service.dart';

const _tabular = [FontFeature.tabularFigures()];

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Owner-only daily report (shows profit).
class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({super.key});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  Future<void> _selectDate() async {
    final provider = context.read<DailySalesProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: "Pilih tanggal",
    );
    if (picked != null) provider.setDate(picked);
  }

  void _shiftDay(int days) {
    final provider = context.read<DailySalesProvider>();
    final next = provider.selectedDate.add(Duration(days: days));
    if (next.isAfter(DateTime.now())) return;
    provider.setDate(next);
  }

  Future<void> _handleExport() async {
    final provider = context.read<DailySalesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (provider.transactions.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Tidak ada transaksi untuk diekspor")),
      );
      return;
    }

    try {
      const headers = [
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
        final itemsStr =
            trx.items.map((i) => "${i.itemName} (${i.quantity})").join('; ');
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
      await ExportService.exportToCSV(
        headers: headers,
        data: rows,
        fileName: "Laporan_Penjualan_$dateStr.csv",
      );
      messenger.showSnackBar(
        SnackBar(content: Text("Laporan $dateStr diekspor")),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Gagal ekspor: $e"),
          backgroundColor: AppColors.destructiveStrong,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Penjualan"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download),
            tooltip: "Ekspor CSV",
            onPressed: _handleExport,
          ),
        ],
      ),
      body: Consumer<DailySalesProvider>(
        builder: (context, provider, _) => _buildContent(provider),
      ),
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(activeRoute: '/daily_sales', body: scaffold);
    }
    return scaffold;
  }

  Widget _buildContent(DailySalesProvider provider) {
    final date = provider.selectedDate;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final items = [...provider.salesItems]
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: "Hari sebelumnya",
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => _shiftDay(-1),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(LucideIcons.calendar, size: 18),
                    label: Text(
                      isToday
                          ? "Hari ini, ${DateFormat('d MMMM', 'id_ID').format(date)}"
                          : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Hari berikutnya",
                  icon: const Icon(LucideIcons.arrowRight),
                  onPressed: isToday ? null : () => _shiftDay(1),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brandNavy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Omzet",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _rupiah.format(provider.totalRevenue),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandYellow,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeroStat("Laba", _rupiah.format(provider.totalProfit)),
                      const SizedBox(width: 24),
                      _HeroStat("Transaksi", "${provider.transactions.length}"),
                      const SizedBox(width: 24),
                      _HeroStat("Barang", "${provider.totalItemsSold}"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              "Barang terjual",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (provider.isLoading && items.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          )
        else if (items.isEmpty)
          const SliverToBoxAdapter(
            child: AppEmptyState(
              icon: LucideIcons.packageX,
              title: "Tidak ada penjualan",
              message: "Belum ada transaksi di tanggal ini.",
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: AppListPanelSliver(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${item.quantity} terjual",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _rupiah.format(item.totalRevenue),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFeatures: _tabular,
                            ),
                          ),
                          Text(
                            "laba ${_rupiah.format(item.totalProfit)}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.successStrong,
                              fontFeatures: _tabular,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFeatures: _tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
