import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../ui/app_form.dart';
import 'customers_provider.dart';
import 'customer_model.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isSaving = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _addressController =
        TextEditingController(text: widget.customer?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<CustomersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _nameController.text.trim();

    setState(() => _isSaving = true);
    final success = _isEditing
        ? await provider.updateCustomer(widget.customer!.id, name,
            _phoneController.text.trim(), _addressController.text.trim())
        : await provider.addCustomer(
            name, _phoneController.text.trim(), _addressController.text.trim());
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_isEditing ? "$name diperbarui" : "$name ditambahkan"),
      ));
    } else {
      showErrorSnack(context, "Pelanggan gagal disimpan. Coba lagi.");
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDestructive(
      context,
      title: "Hapus pelanggan?",
      message:
          "${widget.customer!.name} akan dihapus. Riwayat transaksinya tetap tersimpan.",
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await context.read<CustomersProvider>().deleteCustomer(widget.customer!.id);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text("${widget.customer!.name} dihapus")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFormScaffold(
      title: _isEditing ? "Edit Pelanggan" : "Tambah Pelanggan",
      formKey: _formKey,
      saveLabel: "Simpan Pelanggan",
      isSaving: _isSaving,
      onSave: _save,
      onDelete: _isEditing ? _delete : null,
      deleteTooltip: "Hapus pelanggan",
      children: [
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Nama",
            hintText: "Nama orang atau bengkel",
            prefixIcon: Icon(LucideIcons.user, size: 20),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? "Nama wajib diisi" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: "Nomor HP / WhatsApp",
            hintText: "08xxxxxxxxxx",
            prefixIcon: Icon(LucideIcons.phone, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Alamat (opsional)",
            prefixIcon: Icon(LucideIcons.mapPin, size: 20),
          ),
        ),
      ],
    );
  }
}
