import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../ui/app_form.dart';
import 'suppliers_provider.dart';
import 'supplier_model.dart';

class SupplierFormScreen extends StatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactPersonController;
  bool _isSaving = false;

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _addressController =
        TextEditingController(text: widget.supplier?.address ?? '');
    _contactPersonController =
        TextEditingController(text: widget.supplier?.contactPerson ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<SuppliersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final contact = _contactPersonController.text.trim();

    setState(() => _isSaving = true);
    final success = _isEditing
        ? await provider.updateSupplier(
            widget.supplier!.id, name, phone, address, contact)
        : await provider.addSupplier(name, phone, address, contact);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_isEditing ? "$name diperbarui" : "$name ditambahkan"),
      ));
    } else {
      showErrorSnack(context, "Supplier gagal disimpan. Coba lagi.");
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDestructive(
      context,
      title: "Hapus supplier?",
      message:
          "${widget.supplier!.name} akan dihapus. Riwayat pembelian tetap tersimpan.",
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await context.read<SuppliersProvider>().deleteSupplier(widget.supplier!.id);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text("${widget.supplier!.name} dihapus")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFormScaffold(
      title: _isEditing ? "Edit Supplier" : "Tambah Supplier",
      formKey: _formKey,
      saveLabel: "Simpan Supplier",
      isSaving: _isSaving,
      onSave: _save,
      onDelete: _isEditing ? _delete : null,
      deleteTooltip: "Hapus supplier",
      children: [
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Nama toko / distributor",
            prefixIcon: Icon(LucideIcons.store, size: 20),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? "Nama wajib diisi" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactPersonController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Nama sales / kontak (opsional)",
            prefixIcon: Icon(LucideIcons.user, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: "Nomor HP / WhatsApp",
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
