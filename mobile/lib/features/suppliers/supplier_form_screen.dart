import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/button.dart';
import '../../ui/input.dart';
import 'suppliers_provider.dart';
import 'supplier_model.dart';

class SupplierFormScreen extends StatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormScreen({Key? key, this.supplier}) : super(key: key);

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.supplier?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.supplier?.address ?? '',
    );
    _contactPersonController = TextEditingController(
      text: widget.supplier?.contactPerson ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SuppliersProvider>(context);
    final isEditing = widget.supplier != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Supplier" : "Tambah Supplier"),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Informasi Supplier",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              CustomInput(
                placeholder: "Nama Toko / PT",
                controller: _nameController,
                validator: (v) =>
                    v == null || v.isEmpty ? "Nama wajib diisi" : null,
                suffixIcon: const Icon(LucideIcons.store, size: 18),
              ),
              const SizedBox(height: 16),

              CustomInput(
                placeholder: "Kontak Person / Sales",
                controller: _contactPersonController,
                suffixIcon: const Icon(LucideIcons.user, size: 18),
              ),
              const SizedBox(height: 16),

              CustomInput(
                placeholder: "Nomor Telepon",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                suffixIcon: const Icon(LucideIcons.phone, size: 18),
              ),
              const SizedBox(height: 16),

              CustomInput(
                placeholder: "Alamat Lengkap",
                controller: _addressController,
                keyboardType: TextInputType.multiline,
                suffixIcon: const Icon(LucideIcons.mapPin, size: 18),
              ),
              const SizedBox(height: 48),

              CustomButton(
                text: "Simpan Supplier",
                icon: LucideIcons.save,
                isLoading: provider.isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text;
                    final phone = _phoneController.text;
                    final address = _addressController.text;
                    final contactPerson = _contactPersonController.text;

                    bool success;
                    if (isEditing) {
                      success = await provider.updateSupplier(
                        widget.supplier!.id,
                        name,
                        phone,
                        address,
                        contactPerson,
                      );
                    } else {
                      success = await provider.addSupplier(
                        name,
                        phone,
                        address,
                        contactPerson,
                      );
                    }

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? "Supplier diperbarui"
                                : "Supplier ditambahkan",
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: "Hapus Supplier",
                  icon: LucideIcons.trash2,
                  isDestructive: true,
                  isOutline: true,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Hapus Supplier?"),
                        content: const Text(
                          "Tindakan ini tidak bisa dibatalkan.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Hapus",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await provider.deleteSupplier(widget.supplier!.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Supplier dihapus")),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
