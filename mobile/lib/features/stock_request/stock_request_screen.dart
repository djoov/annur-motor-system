import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../ui/app_list.dart';
import '../../ui/app_form.dart';
import '../../ui/stock_badge.dart';
import '../../ui/desktop_scaffold.dart';
import '../auth/auth_provider.dart';
import '../items/items_provider.dart';
import '../pos/models/pos_models.dart';
import 'stock_request_model.dart';
import 'stock_request_provider.dart';

/// Staff: ask the owner to restock low items. Admin: approve / reject.
class StockRequestScreen extends StatefulWidget {
  const StockRequestScreen({super.key});

  @override
  State<StockRequestScreen> createState() => _StockRequestScreenState();
}

class _StockRequestScreenState extends State<StockRequestScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockRequestProvider>().fetchRequests();
      context.read<ItemsProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final body = isAdmin ? const _AdminView() : _buildStaffView();

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/stock-request',
        title: "Permintaan Stok",
        body: body,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Permintaan Stok")),
      body: body,
    );
  }

  // ---------------------------------------------------------------------------
  // Staff
  // ---------------------------------------------------------------------------

  Widget _buildStaffView() {
    final itemsProvider = context.watch<ItemsProvider>();
    final requests = context.watch<StockRequestProvider>().requests;
    final q = _searchController.text.toLowerCase();

    final items = itemsProvider.lowStockDisplayItems
        .where((i) =>
            q.isEmpty ||
            i.name.toLowerCase().contains(q) ||
            i.code.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        final byStock = a.stockDisplay.compareTo(b.stockDisplay);
        return byStock != 0 ? byStock : a.name.compareTo(b.name);
      });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: AppSearchField(
              controller: _searchController,
              hint: "Cari barang yang perlu ditambah",
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              "Stok menipis · tap untuk minta tambah",
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
          ),
        ),
        if (itemsProvider.isLoading && itemsProvider.items.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          )
        else if (items.isEmpty)
          SliverToBoxAdapter(
            child: AppEmptyState(
              icon: LucideIcons.circleCheck,
              title: q.isEmpty ? "Stok aman" : "Barang tidak ditemukan",
              message: q.isEmpty
                  ? "Tidak ada barang yang menipis saat ini."
                  : "Coba kata lain.",
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: AppListPanelSliver(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final pending = requests.any(
                  (r) => r.itemId == item.id && r.status == 'pending',
                );
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    pending
                        ? "Sudah diminta, menunggu pemilik"
                        : (item.locationDisplay?.isNotEmpty == true
                            ? "Rak ${item.locationDisplay}"
                            : item.code),
                  ),
                  trailing: StockBadge(item.stockDisplay),
                  onTap: () => _showRequestSheet(item),
                );
              },
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
            child: Text(
              "Permintaan saya (${requests.length})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (requests.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Belum ada permintaan.",
                style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: AppListPanelSliver(
              itemCount: requests.length > 10 ? 10 : requests.length,
              itemBuilder: (context, index) =>
                  _RequestRow(request: requests[index]),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  void _showRequestSheet(Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RequestSheet(item: item, parentContext: context),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  final Item item;
  final BuildContext parentContext;

  const _RequestSheet({required this.item, required this.parentContext});

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _qtyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      showErrorSnack(context, "Isi jumlah yang diminta");
      return;
    }
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final navigator = Navigator.of(context);
    setState(() => _isSending = true);
    final ok = await context.read<StockRequestProvider>().createRequest(
          itemId: widget.item.id,
          itemName: widget.item.name,
          quantity: qty,
        );
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Permintaan $qty ${widget.item.name} terkirim ke pemilik"
              : "Permintaan gagal dikirim. Coba lagi.",
        ),
        backgroundColor: ok ? null : AppColors.destructiveStrong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),
          Row(children: [StockBadge(widget.item.stockDisplay)]),
          const SizedBox(height: 20),
          TextField(
            controller: _qtyController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: "Jumlah yang diminta",
              suffixText: "pcs",
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in const [5, 10, 20, 50])
                ActionChip(
                  label: Text("$n"),
                  onPressed: () => _qtyController.text = "$n",
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSending ? null : _send,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Kirim Permintaan"),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------

class _AdminView extends StatelessWidget {
  const _AdminView();

  Future<void> _approve(BuildContext context, StockRequest request) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Setujui permintaan?"),
        content: Text(
          "Stok ${request.itemName} akan bertambah ${request.requestQty}. "
          "Setujui kalau barangnya sudah tersedia di toko.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Setujui"),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<StockRequestProvider>().approveRequest(request);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Disetujui. Stok ${request.itemName} +${request.requestQty}",
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Gagal menyetujui: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
          backgroundColor: AppColors.destructiveStrong,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context, StockRequest request) async {
    final ok = await confirmDestructive(
      context,
      title: "Tolak permintaan?",
      message:
          "Permintaan ${request.requestQty} ${request.itemName} dari ${request.requesterName} akan ditolak.",
      action: "Tolak",
    );
    if (!ok || !context.mounted) return;
    await context.read<StockRequestProvider>().rejectRequest(request);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockRequestProvider>();
    final pending =
        provider.requests.where((r) => r.status == 'pending').toList();
    final done = provider.requests.where((r) => r.status != 'pending').toList();

    if (provider.isLoading && provider.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.requests.isEmpty) {
      return const AppEmptyState(
        icon: LucideIcons.packageOpen,
        title: "Belum ada permintaan",
        message: "Permintaan tambah stok dari karyawan akan muncul di sini.",
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          pending.isEmpty
              ? "Tidak ada yang menunggu"
              : "Menunggu persetujuan (${pending.length})",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final r in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.itemName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          "+${r.requestQty}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${r.requesterName} · ${DateFormat('d MMM, HH:mm', 'id_ID').format(r.createdAt)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _reject(context, r),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.destructiveStrong,
                            ),
                            child: const Text("Tolak"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _approve(context, r),
                            child: const Text("Setujui"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            "Sudah diproses",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                for (var i = 0; i < done.length && i < 30; i++) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  _RequestRow(request: done[i], showRequester: true),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  final StockRequest request;
  final bool showRequester;

  const _RequestRow({required this.request, this.showRequester = false});

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (request.status) {
      'approved' => ("Disetujui", AppColors.successSoft, AppColors.successStrong),
      'rejected' => ("Ditolak", AppColors.destructiveSoft, AppColors.destructiveStrong),
      _ => ("Menunggu", AppColors.warningSoft, AppColors.warningStrong),
    };
    final date = DateFormat('d MMM', 'id_ID').format(request.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        "${request.requestQty} × ${request.itemName}",
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(showRequester ? "${request.requesterName} · $date" : date),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }
}
