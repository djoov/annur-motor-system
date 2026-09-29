import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/app_list.dart';
import 'debt_provider.dart';
import 'models/debt_model.dart';

const _tabular = [FontFeature.tabularFigures()];

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class DebtsListScreen extends StatelessWidget {
  const DebtsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hutang Pelanggan")),
      body: Consumer<DebtProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.debts.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (provider.debts.isEmpty) {
            return const AppEmptyState(
              icon: LucideIcons.circleCheck,
              title: "Tidak ada hutang",
              message: "Semua pelanggan sudah lunas. Hutang baru dicatat dari Kasir dengan metode Hutang.",
            );
          }

          final debts = [...provider.debts]
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first
          final total = debts.fold<int>(0, (s, d) => s + d.remainingAmount);
          final customers = debts.map((d) => d.customerId).toSet().length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Hero: logo navy + yellow number (same language as Beranda)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.brandNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Belum dibayar",
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
                        _rupiah.format(total),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandYellow,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${debts.length} nota · $customers pelanggan",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Tap untuk mencatat pembayaran",
                style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
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
                    for (var i = 0; i < debts.length; i++) ...[
                      if (i > 0) const Divider(indent: 16, endIndent: 16),
                      _DebtRow(
                        debt: debts[i],
                        onTap: () => _showPaymentSheet(context, debts[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, DebtModel debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PaymentSheet(debt: debt, parentContext: context),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onTap;

  const _DebtRow({required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(debt.createdAt).inDays;
    final age = days == 0 ? "Hari ini" : "$days hari lalu";
    final partial = debt.remainingAmount < debt.totalAmount;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            InitialAvatar(debt.customerName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    partial
                        ? "$age · sudah dicicil"
                        : "$age · ${DateFormat('d MMM yyyy', 'id_ID').format(debt.createdAt)}",
                    style: TextStyle(
                      fontSize: 13,
                      color: days > 30
                          ? AppColors.destructiveStrong
                          : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _rupiah.format(debt.remainingAmount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
                if (partial)
                  Text(
                    "dari ${_rupiah.format(debt.totalAmount)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      fontFeatures: _tabular,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final DebtModel debt;

  /// Context of the list screen, so the result message outlives the sheet.
  final BuildContext parentContext;

  const _PaymentSheet({required this.debt, required this.parentContext});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.parse(_amountController.text);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final navigator = Navigator.of(context);
    final provider = context.read<DebtProvider>();

    setState(() => _isSaving = true);
    try {
      await provider.payDebt(widget.debt.id, amount, _noteController.text.trim());
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            amount >= widget.debt.remainingAmount
                ? "Hutang ${widget.debt.customerName} lunas"
                : "Pembayaran ${_rupiah.format(amount)} dicatat",
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text("Pembayaran gagal dicatat: $e"),
          backgroundColor: AppColors.destructiveStrong,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.debt;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                debt.customerName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                "Sisa hutang ${_rupiah.format(debt.remainingAmount)}",
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.mutedForeground,
                  fontFeatures: _tabular,
                ),
              ),
              if (debt.logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Sudah dibayar",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                for (final log in debt.logs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              DateFormat('d MMM yyyy', 'id_ID').format(log.date),
                              if (log.note.isNotEmpty) log.note,
                            ].join(" · "),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                        Text(
                          _rupiah.format(log.amount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: _tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFeatures: _tabular,
                ),
                decoration: const InputDecoration(
                  labelText: "Jumlah dibayar",
                  prefixText: "Rp ",
                ),
                validator: (value) {
                  final val = int.tryParse(value ?? '');
                  if (val == null || val <= 0) return "Isi jumlah pembayaran";
                  if (val > debt.remainingAmount) {
                    return "Lebih dari sisa hutang (${_rupiah.format(debt.remainingAmount)})";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(LucideIcons.circleCheck,
                      size: 16, color: AppColors.primary),
                  label: Text("Lunasi semua · ${_rupiah.format(debt.remainingAmount)}"),
                  onPressed: () => _amountController.text =
                      debt.remainingAmount.toString(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: "Catatan (opsional)",
                  hintText: "Contoh: transfer BRI",
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Simpan Pembayaran"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
