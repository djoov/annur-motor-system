import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/app_list.dart';
import '../../ui/app_form.dart';
import '../pos/models/pos_models.dart';
import '../items/items_provider.dart';
import '../auth/auth_provider.dart';
import 'stock_opname_provider.dart';
import '../scan/scan_screen.dart';

/// Count physical stock item by item, then apply the differences at once.
class StockOpnameFormScreen extends StatefulWidget {
  const StockOpnameFormScreen({super.key});

  @override
  State<StockOpnameFormScreen> createState() => _StockOpnameFormScreenState();
}

class _StockOpnameFormScreenState extends State<StockOpnameFormScreen> {
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Local search over ItemsProvider — does not touch the Kasir's search state.
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemsProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen(returnCodeOnly: true)),
    );
    if (code is! String || !mounted) return;
    final item = context.read<ItemsProvider>().findByCode(code);
    if (item != null) {
      _showCountSheet(item);
    } else {
      _searchController.text = code;
      showErrorSnack(context, "Kode $code tidak ada di daftar barang");
    }
  }

  void _showCountSheet(Item item) {
    final existing = context
        .read<StockOpnameProvider>()
        .activeItems
        .where((i) => i.itemId == item.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CountSheet(
        item: item,
        initial: existing.isEmpty ? item.stockDisplay : existing.first.actualStock,
        onSave: (actual) {
          context.read<StockOpnameProvider>().addItemToOpname(
                item.id,
                item.name,
                item.stockDisplay,
                actual,
                null,
              );
          _searchController.clear();
        },
      ),
    );
  }

  Future<void> _finalize(StockOpnameProvider provider) async {
    final changed =
        provider.activeItems.where((i) => i.difference != 0).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Simpan hasil hitung?"),
        content: Text(
          changed == 0
              ? "Semua barang yang dihitung sudah cocok dengan sistem. Hasil audit tetap disimpan."
              : "Stok $changed barang akan disesuaikan dengan hasil hitung fisik.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Simpan & Sesuaikan"),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await provider.finalizeOpname(
        auth.user?.uid ?? 'unknown',
        auth.userModel?.name ?? auth.user?.displayName ?? 'Staff',
        _noteController.text.trim(),
      );
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            changed == 0
                ? "Audit disimpan, stok sudah cocok"
                : "Audit disimpan, $changed stok disesuaikan",
          ),
        ),
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, "Gagal menyimpan audit: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final opname = context.watch<StockOpnameProvider>();
    final items = context.watch<ItemsProvider>().items;
    final q = _searchController.text.trim().toLowerCase();
    final results = q.isEmpty
        ? const <Item>[]
        : items
            .where((i) =>
                i.name.toLowerCase().contains(q) ||
                i.code.toLowerCase().contains(q))
            .take(50)
            .toList();
    final counted = opname.activeItems;

    return PopScope(
      canPop: counted.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirmDestructive(
          context,
          title: "Buang hitungan?",
          message: "${counted.length} barang yang sudah dihitung belum disimpan.",
          action: "Buang",
        );
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Hitung Stok")),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchController,
                      hint: "Cari barang untuk dihitung",
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: IconButton.filled(
                      onPressed: _scan,
                      tooltip: "Scan barcode",
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(LucideIcons.scanLine, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: q.isNotEmpty
                  ? (results.isEmpty
                      ? const AppEmptyState(
                          icon: LucideIcons.search,
                          title: "Barang tidak ditemukan",
                          message: "Coba kata lain atau scan barcode-nya.",
                        )
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const Divider(indent: 16, endIndent: 16),
                          itemBuilder: (context, i) {
                            final item = results[i];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text("Stok sistem ${item.stockDisplay}"),
                              trailing: const Icon(LucideIcons.plus,
                                  color: AppColors.primary),
                              onTap: () => _showCountSheet(item),
                            );
                          },
                        ))
                  : counted.isEmpty
                      ? const AppEmptyState(
                          icon: LucideIcons.clipboardList,
                          title: "Mulai menghitung",
                          message:
                              "Scan barcode atau cari barang, lalu isi jumlah yang ada di rak.",
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              "${counted.length} barang dihitung",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: AppColors.surface,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0; i < counted.length; i++) ...[
                                    if (i > 0)
                                      const Divider(indent: 16, endIndent: 16),
                                    _CountedRow(
                                      item: counted[i],
                                      onRemove: () =>
                                          opname.removeItem(counted[i].itemId),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
        bottomNavigationBar: counted.isEmpty
            ? null
            : Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: "Catatan audit (opsional)",
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed:
                            opname.isLoading ? null : () => _finalize(opname),
                        icon: opname.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.circleCheck, size: 20),
                        label: const Text("Simpan Hasil Hitung"),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CountedRow extends StatelessWidget {
  final dynamic item; // OpnameItem
  final VoidCallback onRemove;

  const _CountedRow({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final int diff = item.difference;
    final (Color bg, Color fg) = diff == 0
        ? (AppColors.successSoft, AppColors.successStrong)
        : diff > 0
            ? (AppColors.primarySoft, AppColors.primary)
            : (AppColors.destructiveSoft, AppColors.destructiveStrong);

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text("Sistem ${item.systemStock} → fisik ${item.actualStock}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              diff == 0 ? "Cocok" : "${diff > 0 ? '+' : ''}$diff",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            tooltip: "Hapus dari hitungan",
            icon: const Icon(LucideIcons.x, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _CountSheet extends StatefulWidget {
  final Item item;
  final int initial;
  final ValueChanged<int> onSave;

  const _CountSheet({
    required this.item,
    required this.initial,
    required this.onSave,
  });

  @override
  State<_CountSheet> createState() => _CountSheetState();
}

class _CountSheetState extends State<_CountSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initial}');

  int get _value => int.tryParse(_controller.text) ?? 0;

  void _step(int delta) {
    final v = (_value + delta).clamp(0, 999999);
    _controller.text = '$v';
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = _value - widget.item.stockDisplay;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.item.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "Stok di sistem: ${widget.item.stockDisplay}",
            style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton.outlined(
                  tooltip: "Kurangi",
                  onPressed: () => _step(-1),
                  icon: const Icon(LucideIcons.minus),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(labelText: "Jumlah di rak"),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton.outlined(
                  tooltip: "Tambah",
                  onPressed: () => _step(1),
                  icon: const Icon(LucideIcons.plus),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            diff == 0
                ? "Cocok dengan sistem"
                : "Selisih ${diff > 0 ? '+' : ''}$diff",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: diff == 0
                  ? AppColors.successStrong
                  : AppColors.destructiveStrong,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                widget.onSave(_value);
                Navigator.pop(context);
              },
              child: const Text("Simpan Hitungan"),
            ),
          ),
        ],
      ),
    );
  }
}
