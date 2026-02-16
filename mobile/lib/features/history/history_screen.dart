import '../../ui/desktop_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import 'history_provider.dart';

import 'models/transaction_model.dart';

import '../returns/return_selection_screen.dart';
import '../auth/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Multi-select state
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Provider is singleton and initializes itself.
    // No need to refetch on every build unless explicit refresh.
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
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

  void _selectDateRange(BuildContext context) async {
    final provider = Provider.of<HistoryProvider>(context, listen: false);
    final initialDateRange =
        provider.selectedDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked);
    }
  }

  void _confirmDeleteTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: Text(
          "Transaksi untuk ${transaction.customerName} sebesar Rp ${NumberFormat('#,###').format(transaction.totalAmount)} akan dihapus permanen.\n\nTindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = Provider.of<HistoryProvider>(context, listen: false);
      final success = await provider.deleteTransaction(transaction.id);

      if (context.mounted) {
        Navigator.pop(context); // Close detail modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? "Transaksi berhasil dihapus"
                  : "Gagal menghapus transaksi",
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _confirmBulkDelete(BuildContext context) async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Hapus ${_selectedIds.length} Transaksi?"),
        content: const Text(
          "Transaksi terpilih akan dihapus permanen.\n\nTindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus Semua"),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = Provider.of<HistoryProvider>(context, listen: false);
      final count = await provider.deleteMultipleTransactions(
        _selectedIds.toList(),
      );

      setState(() {
        _isSelectMode = false;
        _selectedIds.clear();
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$count transaksi berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _confirmDeleteFiltered(
    BuildContext context,
    List<TransactionModel> transactions,
  ) async {
    if (transactions.isEmpty) return;

    final provider = Provider.of<HistoryProvider>(context, listen: false);
    final dateRange = provider.selectedDateRange;

    String rangeText = dateRange != null
        ? "${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}"
        : "30 transaksi terakhir";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Semua Transaksi?"),
        content: Text(
          "Semua ${transactions.length} transaksi di rentang:\n$rangeText\n\nakan dihapus permanen. Tindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus Semua"),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ids = transactions.map((t) => t.id).toList();
      final count = await provider.deleteMultipleTransactions(ids);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$count transaksi berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... vars ...
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    final content = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: _isSelectMode
            ? IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: _toggleSelectMode,
              )
            : null,
        title: Text(
          _isSelectMode
              ? "${_selectedIds.length} dipilih"
              : "Laporan & Riwayat",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _isSelectMode ? Colors.red.shade50 : Colors.white,
        foregroundColor: _isSelectMode ? Colors.red : Colors.black,
        elevation: 0.5,
        actions: _isSelectMode
            ? [
                // Select All
                Consumer<HistoryProvider>(
                  builder: (context, history, _) => IconButton(
                    icon: Icon(
                      _selectedIds.length == history.transactions.length
                          ? LucideIcons.checkSquare
                          : LucideIcons.square,
                    ),
                    onPressed: () => _selectAll(
                      history.transactions.map((t) => t.id).toList(),
                    ),
                    tooltip: "Pilih Semua",
                  ),
                ),
                // Delete Selected
                IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: _selectedIds.isNotEmpty
                      ? () => _confirmBulkDelete(context)
                      : null,
                  tooltip: "Hapus Terpilih",
                ),
              ]
            : [
                // Normal mode actions
                if (isAdmin)
                  IconButton(
                    icon: const Icon(LucideIcons.checkSquare),
                    onPressed: _toggleSelectMode,
                    tooltip: "Mode Pilih",
                  ),
                if (isAdmin)
                  Consumer<HistoryProvider>(
                    builder: (context, history, _) => PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.moreVertical),
                      onSelected: (value) {
                        if (value == 'delete_filtered') {
                          _confirmDeleteFiltered(context, history.transactions);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete_filtered',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                size: 18,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Hapus ${history.transactions.length} Ditampilkan",
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(LucideIcons.calendarRange),
                  onPressed: () => _selectDateRange(context),
                  tooltip: "Filter Tanggal",
                ),
              ],
      ),
      drawer: null,
      body: Consumer<HistoryProvider>(
        builder: (context, history, child) {
          return Column(
            // ... existing column content ...
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    if (history.selectedDateRange != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${DateFormat('dd MMM').format(history.selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(history.selectedDateRange!.end)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => history.setDateRange(null),
                              child: const Icon(
                                LucideIcons.xCircle,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryBox(
                            "Total Omset",
                            currencyFormat.format(history.totalRevenue),
                            LucideIcons.banknote,
                            Colors.blue.shade50,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryBox(
                            "Keuntungan",
                            currencyFormat.format(history.totalProfit),
                            LucideIcons.trendingUp,
                            Colors.green.shade50,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: history.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : history.transactions.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Force Table View on Windows even if window is small (scrollable)
                          if (constraints.maxWidth > 900 ||
                              DesktopScaffold.isDesktop) {
                            return _buildDesktopTable(
                              context,
                              history.transactions,
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: history.transactions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final transaction = history.transactions[index];
                              final isSelected = _selectedIds.contains(
                                transaction.id,
                              );

                              if (_isSelectMode) {
                                return _buildSelectableCard(
                                  context,
                                  transaction,
                                  isSelected,
                                );
                              }
                              return _buildTransactionCard(
                                context,
                                transaction,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(activeRoute: '/history', body: content);
    }

    return content;
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

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM, HH:mm');

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetailModal(context, transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(transaction.date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(transaction.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Profit: ${currencyFormat.format(transaction.totalProfit)}",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableCard(
    BuildContext context,
    TransactionModel transaction,
    bool isSelected,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM, HH:mm');

    return GestureDetector(
      onTap: () => _toggleSelection(transaction.id),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red.shade300 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Icon(
                isSelected ? LucideIcons.checkSquare : LucideIcons.square,
                color: isSelected ? Colors.red : Colors.grey[400],
                size: 24,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(transaction.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(transaction.date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileX, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada data laporan",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(BuildContext context, TransactionModel transaction) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Detail Transaksi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            if (transaction.type == 'return')
              Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "TRANSAKSI RETUR (PENGEMBALIAN)",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailRow(
                    "ID Transaksi",
                    transaction.id.substring(0, 8).toUpperCase(),
                  ),
                  _buildDetailRow(
                    "Tanggal",
                    dateFormat.format(transaction.date),
                  ),
                  _buildDetailRow("Pelanggan", transaction.customerName),
                  const Divider(height: 32),
                  const Text(
                    "Barang",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...transaction.items.map((item) {
                    final returnedQty =
                        transaction.returnedItems[item.itemId] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${item.quantity}x ${item.itemName}"),
                                if (returnedQty > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      "Sudah Diretur: $returnedQty unit",
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormat.format(
                              item.sellPrice * item.quantity,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        currencyFormat.format(transaction.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Keuntungan",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        currencyFormat.format(transaction.totalProfit),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (transaction.type == 'sale')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReturnSelectionScreen(
                                transaction: transaction,
                              ),
                            ),
                          );
                          // Refresh happens automatically via Firestore Stream
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(LucideIcons.undo2, size: 16),
                        label: const Text("Retur Barang"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  // Delete Button (Admin only)
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (!auth.isAdmin) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmDeleteTransaction(context, transaction),
                            icon: const Icon(LucideIcons.trash2, size: 16),
                            label: const Text("Hapus Transaksi"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[400]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.mutedForeground)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1000, // Fixed min width to trigger scroll if needed
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 12,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Tanggal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ID',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Pelanggan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Item',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Profit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Aksi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: transactions.map((t) {
                  final isReturn = t.type == 'return';
                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>((
                      Set<MaterialState> states,
                    ) {
                      if (isReturn) return Colors.red.shade50.withOpacity(0.5);
                      return null;
                    }),
                    cells: [
                      DataCell(Text(dateFormat.format(t.date))),
                      DataCell(Text(t.id.substring(0, 8).toUpperCase())),
                      DataCell(Text(t.customerName)),
                      DataCell(Text("${t.items.length} Barang")),
                      DataCell(
                        Text(
                          currencyFormat.format(t.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currencyFormat.format(t.totalProfit),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(LucideIcons.eye, size: 18),
                          onPressed: () => _showDetailModal(context, t),
                          tooltip: "Lihat Detail",
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
