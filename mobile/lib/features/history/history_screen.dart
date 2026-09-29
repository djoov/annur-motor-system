import '../../ui/desktop_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/bottom_nav_metrics.dart';
import 'history_provider.dart';

import 'models/transaction_model.dart';

import '../returns/return_selection_screen.dart';
import '../auth/auth_provider.dart';
import '../pos/receipt_preview_screen.dart';

const _tabular = [FontFeature.tabularFigures()];

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

enum _Range { latest, today, week, custom }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Multi-select state (admin only)
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};
  _Range _range = _Range.latest;

  @override
  void initState() {
    super.initState();
    // Reflect a date range that may already be set on the shared provider.
    final existing = context.read<HistoryProvider>().selectedDateRange;
    if (existing != null) _range = _Range.custom;
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  void _selectAll(List<String> allIds) {
    setState(() {
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(allIds);
      }
    });
  }

  Future<void> _setRange(_Range range) async {
    final provider = context.read<HistoryProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (range) {
      case _Range.latest:
        provider.setDateRange(null);
      case _Range.today:
        provider.setDateRange(DateTimeRange(start: today, end: today));
      case _Range.week:
        provider.setDateRange(DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ));
      case _Range.custom:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now,
          initialDateRange: provider.selectedDateRange ??
              DateTimeRange(
                start: today.subtract(const Duration(days: 7)),
                end: today,
              ),
          helpText: "Pilih rentang tanggal",
          saveText: "Terapkan",
        );
        if (picked == null) return;
        provider.setDateRange(picked);
    }
    setState(() => _range = range);
  }

  String _rangeLabel(HistoryProvider history) {
    final r = history.selectedDateRange;
    switch (_range) {
      case _Range.latest:
        return "30 transaksi terakhir";
      case _Range.today:
        return "Hari ini";
      case _Range.week:
        return "7 hari terakhir";
      case _Range.custom:
        if (r == null) return "30 transaksi terakhir";
        final f = DateFormat('d MMM', 'id_ID');
        return "${f.format(r.start)} – ${DateFormat('d MMM yyyy', 'id_ID').format(r.end)}";
    }
  }

  // ---------------------------------------------------------------------------
  // Delete flows (admin)
  // ---------------------------------------------------------------------------

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext sheetContext,
    TransactionModel transaction,
  ) async {
    final ok = await _confirm(
      "Hapus transaksi?",
      "Transaksi ${transaction.customerName} sebesar ${_rupiah.format(transaction.totalAmount)} akan dihapus permanen. Stok barang tidak dikembalikan.",
      "Hapus",
    );
    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success =
        await context.read<HistoryProvider>().deleteTransaction(transaction.id);
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? "Transaksi dihapus" : "Transaksi gagal dihapus",
        ),
      ),
    );
  }

  Future<void> _confirmBulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final ok = await _confirm(
      "Hapus ${_selectedIds.length} transaksi?",
      "Transaksi terpilih akan dihapus permanen. Stok barang tidak dikembalikan.",
      "Hapus",
    );
    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final count = await context
        .read<HistoryProvider>()
        .deleteMultipleTransactions(_selectedIds.toList());
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
    messenger.showSnackBar(
      SnackBar(content: Text("$count transaksi dihapus")),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final history = context.watch<HistoryProvider>();
    final transactions = history.transactions;

    final content = Scaffold(
      appBar: AppBar(
        leading: _isSelectMode
            ? IconButton(
                tooltip: "Batal pilih",
                icon: const Icon(LucideIcons.x),
                onPressed: _toggleSelectMode,
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text(
          _isSelectMode ? "${_selectedIds.length} dipilih" : "Riwayat",
        ),
        actions: _isSelectMode
            ? [
                TextButton(
                  onPressed: () =>
                      _selectAll(transactions.map((t) => t.id).toList()),
                  child: Text(
                    _selectedIds.length == transactions.length
                        ? "Batal semua"
                        : "Pilih semua",
                  ),
                ),
                IconButton(
                  tooltip: "Hapus terpilih",
                  icon: const Icon(LucideIcons.trash2,
                      color: AppColors.destructiveStrong),
                  onPressed:
                      _selectedIds.isNotEmpty ? _confirmBulkDelete : null,
                ),
              ]
            : [
                if (isAdmin && transactions.isNotEmpty)
                  IconButton(
                    tooltip: "Pilih beberapa untuk dihapus",
                    icon: const Icon(LucideIcons.checkSquare),
                    onPressed: _toggleSelectMode,
                  ),
              ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters + summary
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _rangeChip("Terbaru", _Range.latest),
                      _rangeChip("Hari ini", _Range.today),
                      _rangeChip("7 hari", _Range.week),
                      ChoiceChip(
                        avatar: const Icon(LucideIcons.calendarRange,
                            size: 16, color: AppColors.primary),
                        label: Text(_range == _Range.custom
                            ? _rangeLabel(history)
                            : "Pilih tanggal"),
                        selected: _range == _Range.custom,
                        showCheckmark: false,
                        onSelected: (_) => _setRange(_Range.custom),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Summary(
                  label: _rangeLabel(history),
                  count: transactions.length,
                  revenue: history.totalRevenue.toInt(),
                  profit: isAdmin ? history.totalProfit.toInt() : null,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: history.isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : transactions.isEmpty
                    ? _EmptyHistory(
                        filtered: _range != _Range.latest,
                        onShowLatest: () => _setRange(_Range.latest),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900 ||
                              DesktopScaffold.isDesktop) {
                            return _buildDesktopTable(transactions, isAdmin);
                          }
                          return _buildGroupedList(transactions, isAdmin);
                        },
                      ),
          ),
        ],
      ),
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(activeRoute: '/history', body: content);
    }
    return content;
  }

  Widget _rangeChip(String label, _Range value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _range == value,
        showCheckmark: false,
        onSelected: (_) => _setRange(value),
      ),
    );
  }

  /// Transactions grouped under "Hari ini", "Kemarin", or a date header.
  Widget _buildGroupedList(List<TransactionModel> transactions, bool isAdmin) {
    final entries = <Object>[]; // String = header, TransactionModel = row
    String? lastKey;
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      if (key != lastKey) {
        entries.add(_dayLabel(t.date));
        lastKey = key;
      }
      entries.add(t);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        BottomNavMetrics.top(context) + 16,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        if (e is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              e,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
              ),
            ),
          );
        }
        final t = e as TransactionModel;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TransactionTile(
            transaction: t,
            showProfit: isAdmin,
            selectMode: _isSelectMode,
            selected: _selectedIds.contains(t.id),
            onTap: _isSelectMode
                ? () => _toggleSelection(t.id)
                : () => _showDetailSheet(t, isAdmin),
          ),
        );
      },
    );
  }

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "Hari ini";
    if (diff == 1) return "Kemarin";
    return DateFormat('EEEE, d MMMM', 'id_ID').format(date);
  }

  // ---------------------------------------------------------------------------
  // Detail sheet
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _receiptData(TransactionModel t) => {
        'id': t.id,
        'customerName': t.customerName,
        'paymentMethod': t.paymentMethod,
        'totalAmount': t.totalAmount,
        'items': [
          for (final i in t.items)
            {
              'id': i.itemId,
              'itemId': i.itemId,
              'name': i.itemName,
              'itemName': i.itemName,
              'quantity': i.quantity,
              'sellPrice': i.sellPrice,
            },
        ],
      };

  void _showDetailSheet(TransactionModel transaction, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Detail transaksi",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                _TypeBadge(transaction: transaction),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow("Tanggal",
                DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(transaction.date)),
            _DetailRow("Pelanggan", transaction.customerName),
            _DetailRow("Pembayaran", _paymentLabel(transaction.paymentMethod)),
            if (transaction.cashierName != '-')
              _DetailRow("Kasir", transaction.cashierName),
            _DetailRow(
                "No. transaksi", transaction.id.substring(0, 8).toUpperCase()),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              "Barang",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final item in transaction.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${item.quantity} × ${_rupiah.format(item.sellPrice)}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                              fontFeatures: _tabular,
                            ),
                          ),
                          if ((transaction.returnedItems[item.itemId] ?? 0) > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Sudah diretur ${transaction.returnedItems[item.itemId]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.destructiveStrong,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _rupiah.format(item.sellPrice * item.quantity),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Total",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _rupiah.format(transaction.totalAmount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Laba",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.successStrong,
                      ),
                    ),
                  ),
                  Text(
                    _rupiah.format(transaction.totalProfit),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.successStrong,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (transaction.type != 'return')
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptPreviewScreen(
                        transactionData: _receiptData(transaction),
                      ),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.printer, size: 20),
                label: const Text("Lihat / Cetak Ulang Struk"),
              ),
            if (transaction.type == 'sale') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReturnSelectionScreen(transaction: transaction),
                    ),
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(LucideIcons.undo2, size: 20),
                label: const Text("Retur Barang"),
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    _confirmDeleteTransaction(sheetContext, transaction),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.destructiveStrong,
                ),
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: const Text("Hapus Transaksi"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop table
  // ---------------------------------------------------------------------------

  Widget _buildDesktopTable(List<TransactionModel> transactions, bool isAdmin) {
    final dateFormat = DateFormat('dd/MM/yy HH:mm');
    const header = TextStyle(fontWeight: FontWeight.w700, fontSize: 13);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1000),
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 20,
              showCheckboxColumn: _isSelectMode,
              headingRowColor:
                  const WidgetStatePropertyAll(AppColors.background),
              columns: [
                const DataColumn(label: Text('Tanggal', style: header)),
                const DataColumn(label: Text('Pelanggan', style: header)),
                const DataColumn(label: Text('Barang', style: header)),
                const DataColumn(label: Text('Bayar', style: header)),
                const DataColumn(
                    label: Text('Total', style: header), numeric: true),
                if (isAdmin)
                  const DataColumn(
                      label: Text('Laba', style: header), numeric: true),
                const DataColumn(label: Text('', style: header)),
              ],
              rows: [
                for (final t in transactions)
                  DataRow(
                    selected: _selectedIds.contains(t.id),
                    onSelectChanged: _isSelectMode
                        ? (_) => _toggleSelection(t.id)
                        : null,
                    color: t.type == 'return'
                        ? const WidgetStatePropertyAll(AppColors.destructiveSoft)
                        : null,
                    cells: [
                      DataCell(Text(dateFormat.format(t.date),
                          style: const TextStyle(fontFeatures: _tabular))),
                      DataCell(Text(t.customerName)),
                      DataCell(Text("${t.items.length} barang")),
                      DataCell(_TypeBadge(transaction: t)),
                      DataCell(Text(
                        _rupiah.format(t.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFeatures: _tabular,
                        ),
                      )),
                      if (isAdmin)
                        DataCell(Text(
                          _rupiah.format(t.totalProfit),
                          style: const TextStyle(
                            color: AppColors.successStrong,
                            fontWeight: FontWeight.w600,
                            fontFeatures: _tabular,
                          ),
                        )),
                      DataCell(
                        TextButton(
                          onPressed: () => _showDetailSheet(t, isAdmin),
                          child: const Text("Detail"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _paymentLabel(String method) {
  switch (method) {
    case 'cash':
      return 'Tunai';
    case 'transfer':
      return 'Transfer';
    case 'debt':
      return 'Hutang';
    default:
      return method.isEmpty ? '-' : method;
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _Summary extends StatelessWidget {
  final String label;
  final int count;
  final int revenue;

  /// Null for staff — profit is owner-only information.
  final int? profit;

  const _Summary({
    required this.label,
    required this.count,
    required this.revenue,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(String title, String value, {Color? color}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color ?? AppColors.foreground,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label · $count transaksi",
          style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            cell("Omzet", _rupiah.format(revenue)),
            if (profit != null) ...[
              const SizedBox(width: 16),
              cell("Laba", _rupiah.format(profit),
                  color: AppColors.successStrong),
            ],
          ],
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final TransactionModel transaction;

  const _TypeBadge({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final (String text, Color bg, Color fg) = transaction.type == 'return'
        ? ("Retur", AppColors.destructiveSoft, AppColors.destructiveStrong)
        : transaction.paymentMethod == 'debt'
            ? (
                transaction.paymentStatus == 'paid' ? "Hutang lunas" : "Hutang",
                AppColors.warningSoft,
                AppColors.warningStrong,
              )
            : (_paymentLabel(transaction.paymentMethod), AppColors.muted,
                AppColors.mutedForeground);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final bool showProfit;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.showProfit,
    required this.selectMode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final itemCount = t.items.fold<int>(0, (s, i) => s + i.quantity);

    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (selectMode) ...[
                Icon(
                  selected ? LucideIcons.checkSquare : LucideIcons.square,
                  color: selected ? AppColors.primary : AppColors.mutedForeground,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              SizedBox(
                width: 48,
                child: Text(
                  DateFormat('HH:mm').format(t.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.customerName.isNotEmpty
                          ? t.customerName
                          : "Pelanggan Umum",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TypeBadge(transaction: t),
                        const SizedBox(width: 8),
                        Text(
                          "$itemCount barang",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _rupiah.format(t.totalAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                    ),
                  ),
                  if (showProfit) ...[
                    const SizedBox(height: 2),
                    Text(
                      "+${_rupiah.format(t.totalProfit)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.successStrong,
                        fontWeight: FontWeight.w600,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final bool filtered;
  final VoidCallback onShowLatest;

  const _EmptyHistory({required this.filtered, required this.onShowLatest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.receipt,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            Text(
              filtered ? "Tidak ada transaksi di rentang ini" : "Belum ada transaksi",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              filtered
                  ? "Coba pilih tanggal lain."
                  : "Transaksi dari Kasir akan muncul di sini.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
            if (filtered) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onShowLatest,
                child: const Text("Tampilkan terbaru"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
